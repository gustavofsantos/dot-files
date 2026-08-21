--- Review: annotate code where you read it and queue the notes for whatever
--- coding agent you are running next door.
---
--- This plugin is stateless. Every comment lives in the `review` queue (see
--- `review --help`), keyed by workspace; the plugin only draws what the command
--- reports and acts on it by id. Nothing is duplicated in memory, so a comment
--- added here, from a shell, or from another nvim shows up in all of them.
---
--- Workflow:
---   1. Select a region in Visual mode, press <CR> -> a floating input opens.
---   2. Type your comment. <C-s> queues it (`review add`) and drops a sign in
---      the sign column; <C-c> cancels. <Esc> only leaves insert mode -- it
---      never throws the text away.
---   3. The agent runs `review pull`, which dequeues everything and hands it
---      over. Pulled comments disappear from the signs on the next refresh.
---
--- @class Review
local M = {}

--- @class ReviewItem
--- @field id string
--- @field file string
--- @field path string
--- @field start_line integer
--- @field end_line integer
--- @field comment string
--- @field status string
--- @field lane string?
--- @field author string?

M._ns = vim.api.nvim_create_namespace("review")

--- The queue command. Override with $REVIEW_CMD (e.g. a checkout under test).
M.cmd = vim.env.REVIEW_CMD or "review"

local SIGN_TEXT = "💬"

vim.api.nvim_set_hl(0, "ReviewSign", { link = "DiagnosticSignInfo", default = true })

--- @param res vim.SystemCompleted
--- @return string? stdout  nil once the failure has been reported to the user
local function unwrap(res)
  if res.code ~= 0 then
    local err = vim.trim(res.stderr or "")
    vim.notify("Review: " .. (err ~= "" and err or "command failed"), vim.log.levels.ERROR)
    return nil
  end
  return res.stdout or ""
end

--- @return boolean available
local function executable()
  if vim.fn.executable(M.cmd) == 1 then
    return true
  end
  vim.notify(
    string.format("Review: `%s` is not on $PATH -- run ./setup.sh to link bin/", M.cmd),
    vim.log.levels.ERROR
  )
  return false
end

--- Run the queue command and return its stdout, or nil on failure (the error is
--- surfaced to the user; callers just bail). Synchronous: only for the commands
--- a keystroke is waiting on.
--- @param args string[] arguments after the command name
--- @param opts { stdin: string?, cwd: string? }?
--- @return string? stdout
local function run(args, opts)
  if not executable() then
    return nil
  end
  opts = opts or {}
  local cmd = { M.cmd }
  vim.list_extend(cmd, args)
  return unwrap(vim.system(cmd, {
    cwd = opts.cwd or M.workspace_cwd(),
    stdin = opts.stdin,
    text = true,
  }):wait())
end

--- Same, without blocking: for the sign redraws that ride on autocmds.
--- @param args string[]
--- @param cwd string
--- @param on_stdout fun(stdout: string)
local function run_async(args, cwd, on_stdout)
  if not executable() then
    return
  end
  local cmd = { M.cmd }
  vim.list_extend(cmd, args)
  vim.system(cmd, { cwd = cwd, text = true }, function(res)
    if res.code ~= 0 then
      return -- a background redraw never interrupts with an error popup
    end
    vim.schedule(function()
      on_stdout(res.stdout or "")
    end)
  end)
end

--- Which directory the command resolves the workspace from: the current file's
--- directory when there is one (so a file outside nvim's cwd still lands in its
--- own repo), otherwise nvim's cwd.
--- @param bufnr integer? defaults to the current buffer
--- @return string
function M.workspace_cwd(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr or 0)
  if name ~= "" then
    local dir = vim.fn.fnamemodify(name, ":p:h")
    if vim.fn.isdirectory(dir) == 1 then
      return dir
    end
  end
  return vim.fn.getcwd()
end

--- @param out string? stdout of `review list --format json`
--- @return ReviewItem[]
local function decode(out)
  if not out or out == "" then
    return {}
  end
  local ok, decoded = pcall(vim.json.decode, out)
  if not ok or type(decoded) ~= "table" then
    return {}
  end
  return decoded.reviews or {}
end

--- Reads are deliberately `--all-lanes`: one tree can carry several branches at
--- once, and the editor is your whole-tree view of them. Without this, launching
--- nvim from a shell pinned to $REVIEW_LANE would silently hide every other
--- lane's comments -- a file with a note on it would look unannotated. Writes
--- still inherit the pin, so a comment you add lands in the lane you are on.
--- @param file string? absolute path to scope the query to one file
--- @return string[] args
local function list_args(file)
  local args = { "list", "--format", "json", "--all-lanes" }
  if file then
    vim.list_extend(args, { "--file", file })
  end
  return args
end

--- Ask the queue for pending comments, blocking until it answers.
--- @param file string? absolute path to scope the query to one file
--- @return ReviewItem[]
local function query(file)
  return decode(run(list_args(file)))
end

--- vim.json.decode maps JSON null to vim.NIL -- a userdata, and so TRUTHY in Lua.
--- Optional record fields (lane, author) must go through this or a nil check
--- passes and the concatenation blows up.
--- @param value any
--- @return any? value  nil when the field was absent or JSON null
local function present(value)
  if value == nil or value == vim.NIL then
    return nil
  end
  return value
end

--- @param item ReviewItem
--- @return string range
local function format_range(item)
  if item.start_line == item.end_line then
    return tostring(item.start_line)
  end
  return item.start_line .. "-" .. item.end_line
end

--- Redraw the signs of one buffer straight from the queue.
--- @param bufnr integer?
function M.refresh(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
  local path = vim.api.nvim_buf_get_name(bufnr)
  if path == "" then
    vim.api.nvim_buf_clear_namespace(bufnr, M._ns, 0, -1)
    return
  end

  -- Signs are replaced only once the queue has answered, so they never blink.
  run_async(list_args(path), M.workspace_cwd(bufnr), function(out)
    if not vim.api.nvim_buf_is_valid(bufnr) then
      return
    end
    vim.api.nvim_buf_clear_namespace(bufnr, M._ns, 0, -1)
    local line_count = vim.api.nvim_buf_line_count(bufnr)
    for _, item in ipairs(decode(out)) do
      local line = math.min(item.start_line, line_count)
      pcall(vim.api.nvim_buf_set_extmark, bufnr, M._ns, line - 1, 0, {
        sign_text = SIGN_TEXT,
        sign_hl_group = "ReviewSign",
      })
    end
  end)
end

--- Redraw every listed buffer (after a bulk change like :ReviewClear).
function M.refresh_all()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      M.refresh(bufnr)
    end
  end
end

--- Open a floating scratch buffer for entering a (possibly multi-line) comment.
--- The only two ways out are the explicit <C-s> (save) and <C-c> (cancel)
--- mappings; <Esc> is deliberately left alone so muscle memory doesn't throw
--- the text away.
--- @param on_save fun(text: string) called with the typed text if saved via <C-s>
--- @param initial_lines string[]? pre-fill the input with existing text (edit mode)
--- @param title string? override the floating window title
local function open_input(on_save, initial_lines, title)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].filetype = "markdown"
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"

  if initial_lines and #initial_lines > 0 then
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, initial_lines)
  end

  local width = math.min(80, math.max(40, math.floor(vim.o.columns * 0.5)))
  local height = 6

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "cursor",
    row = 1,
    col = 0,
    width = width,
    height = height,
    style = "minimal",
    border = "rounded",
    title = title or " Review  (<C-s> queue · <C-c> cancel) ",
    title_pos = "center",
  })
  vim.wo[win].wrap = true
  vim.wo[win].signcolumn = "no"

  local closed = false
  local function close(should_save)
    if closed then return end
    closed = true
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    if vim.fn.mode():match("^i") then
      vim.cmd("stopinsert")
    end
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    if should_save then
      on_save(table.concat(lines, "\n"))
    end
  end

  local opts = { buffer = buf, nowait = true, silent = true }
  vim.keymap.set({ "n", "i" }, "<C-s>", function() close(true) end, opts)
  vim.keymap.set({ "n", "i" }, "<C-c>", function() close(false) end, opts)

  if initial_lines and #initial_lines > 0 then
    vim.api.nvim_win_set_cursor(win, { #initial_lines, #initial_lines[#initial_lines] })
    vim.cmd("startinsert!")
  else
    vim.cmd("startinsert")
  end
end

--- Queue a comment for a line range in the current buffer (entry point for the
--- visual-mode mapping / :ReviewAdd). The buffer is piped in as the code
--- snapshot, so an unsaved edit is captured exactly as it reads on screen.
--- @param start_line integer
--- @param end_line integer
function M.add(start_line, end_line)
  local bufnr = vim.api.nvim_get_current_buf()
  local path = vim.api.nvim_buf_get_name(bufnr)
  if path == "" then
    vim.notify("Review: buffer has no file to reference", vim.log.levels.WARN)
    return
  end

  if start_line > end_line then
    start_line, end_line = end_line, start_line
  end

  local range = start_line == end_line and tostring(start_line)
      or (start_line .. "-" .. end_line)
  local buffer_text = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n")
  local filetype = vim.bo[bufnr].filetype

  open_input(function(text)
    if vim.trim(text) == "" then
      return
    end

    local args = {
      "add",
      "--file", path,
      "--lines", range,
      "--comment", text,
      "--code-file", "-",
      "--format", "ids",
    }
    if filetype ~= "" then
      vim.list_extend(args, { "--filetype", filetype })
    end

    local out = run(args, { stdin = buffer_text })
    if not out then
      return
    end

    M.refresh(bufnr)
    vim.notify(
      string.format("Review queued %s: %s:%s", vim.trim(out), vim.fn.fnamemodify(path, ":t"), range),
      vim.log.levels.INFO
    )
  end)
end

--- Find the queued comment closest to the cursor in the current buffer: an
--- exact range match wins, otherwise the nearest by distance to its range.
--- The queue is asked fresh every time -- nothing is cached here.
--- @return ReviewItem?
local function find_near_cursor()
  local path = vim.api.nvim_buf_get_name(0)
  if path == "" then
    return nil
  end
  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]

  local best, best_dist
  for _, item in ipairs(query(path)) do
    local dist
    if cursor_line >= item.start_line and cursor_line <= item.end_line then
      dist = 0
    else
      dist = math.min(math.abs(cursor_line - item.start_line), math.abs(cursor_line - item.end_line))
    end
    if not best_dist or dist < best_dist then
      best, best_dist = item, dist
    end
  end

  return best
end

--- Drop the queued comment nearest the cursor.
function M.delete_at_cursor()
  local item = find_near_cursor()
  if not item then
    vim.notify("Review: no queued comment near the cursor in this buffer", vim.log.levels.WARN)
    return
  end
  if not run({ "drop", item.id }) then
    return
  end
  M.refresh()
  vim.notify(
    string.format("Review dropped %s: %s:%s", item.id, vim.fn.fnamemodify(item.path, ":t"),
      format_range(item)),
    vim.log.levels.INFO
  )
end

--- Rewrite the text of the queued comment nearest the cursor, reopening the
--- floating input pre-filled with what the queue currently holds.
function M.edit_at_cursor()
  local item = find_near_cursor()
  if not item then
    vim.notify("Review: no queued comment near the cursor in this buffer", vim.log.levels.WARN)
    return
  end

  open_input(function(text)
    if vim.trim(text) == "" then
      vim.notify("Review: empty comment, left unchanged", vim.log.levels.WARN)
      return
    end
    if not run({ "edit", item.id, "--comment", text }) then
      return
    end
    M.refresh()
    vim.notify(
      string.format("Review updated %s: %s:%s", item.id, vim.fn.fnamemodify(item.path, ":t"),
        format_range(item)),
      vim.log.levels.INFO
    )
  end, vim.split(item.comment, "\n", { plain = true }), " Edit review  (<C-s> save · <C-c> cancel) ")
end

--- Populate the (window-local) location list with the whole workspace queue and
--- open it. <CR> on an entry jumps to that file/line natively; from there,
--- :ReviewDelete / :ReviewEdit act on the comment under the cursor.
function M.list()
  local items = query()
  if #items == 0 then
    vim.notify("Review: the queue is empty for this workspace", vim.log.levels.INFO)
    return
  end

  local loclist = {}
  for _, item in ipairs(items) do
    local first = vim.split(item.comment, "\n", { plain = true })[1] or ""
    local tags = {}
    local author, lane = present(item.author), present(item.lane)
    if author then table.insert(tags, "@" .. author) end
    if lane then table.insert(tags, "#" .. lane) end
    local who = #tags > 0 and (table.concat(tags, " ") .. " ") or ""
    table.insert(loclist, {
      filename = item.path,
      lnum = item.start_line,
      col = 1,
      text = string.format("%s. [%s] %s%s", item.id, format_range(item), who, first),
    })
  end

  vim.fn.setloclist(0, {}, " ", { title = "Review queue", items = loclist })
  vim.cmd("lopen")
end

--- Drop every pending comment in this workspace.
function M.clear()
  local out = run({ "clear" })
  if not out then
    return
  end
  M.refresh_all()
  vim.notify("Review: " .. vim.trim(out), vim.log.levels.INFO)
end

vim.api.nvim_create_user_command("ReviewAdd", function(opts)
  M.add(opts.line1, opts.line2)
end, {
  range = true,
  desc = "Queue a review comment for the current line or visual selection",
})

vim.api.nvim_create_user_command("ReviewList", function()
  M.list()
end, {
  desc = "Open the location list of queued review comments",
})

vim.api.nvim_create_user_command("ReviewEdit", function()
  M.edit_at_cursor()
end, {
  desc = "Edit the queued review comment nearest the cursor",
})

vim.api.nvim_create_user_command("ReviewDelete", function()
  M.delete_at_cursor()
end, {
  desc = "Drop the queued review comment nearest the cursor",
})

vim.api.nvim_create_user_command("ReviewClear", function()
  M.clear()
end, {
  desc = "Drop every pending review comment in this workspace",
})

vim.api.nvim_create_user_command("ReviewRefresh", function()
  M.refresh_all()
end, {
  desc = "Redraw review signs from the queue (after an agent pulled, say)",
})

-- Signs are drawn from the queue, never from memory: refresh whenever a buffer
-- comes into view, and when focus returns to nvim (an agent may have pulled).
local group = vim.api.nvim_create_augroup("review_signs", { clear = true })
vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost" }, {
  group = group,
  callback = function(args)
    M.refresh(args.buf)
  end,
})
vim.api.nvim_create_autocmd("FocusGained", {
  group = group,
  callback = function()
    M.refresh()
  end,
})

return M
