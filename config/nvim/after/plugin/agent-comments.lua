--- Agent Comments: annotate code selections, extract them as a single prompt
--- for pasting into an AI coding agent (Claude Code, Cursor, ...) running in
--- another terminal split.
---
--- Workflow:
---   1. Select a region in Visual mode, press <CR> -> a floating input opens.
---   2. Type your comment. <C-s> saves it (ephemeral, in-memory) and drops a
---      sign in the sign column; <C-c> cancels and closes the input. <Esc>
---      only leaves insert mode -- it never closes the input.
---   3. Repeat across files/regions, then run :AgentCommentsFlush to render
---      everything into a markdown prompt, written to a temp file, opened in
---      a new buffer, and copied to the system clipboard. Comments are
---      rendered in the order they were written, not grouped by file.
---
--- @class AgentComments
local M = {}

--- @class AgentComment
--- @field id integer
--- @field bufnr integer
--- @field filepath string
--- @field relpath string
--- @field filetype string
--- @field start_line integer
--- @field end_line integer
--- @field code_lines string[]
--- @field text string
--- @field extmark_id integer?

--- In-memory, ephemeral store. Intentionally never persisted to disk.
--- @type AgentComment[]
M._comments = {}
M._next_id = 1
M._ns = vim.api.nvim_create_namespace("agent_comments")

vim.api.nvim_set_hl(0, "AgentCommentSign", { link = "DiagnosticSignInfo", default = true })

local SIGN_TEXT = "💬"

--- @param comment AgentComment
--- @return string range
local function format_range(comment)
  if comment.start_line == comment.end_line then
    return tostring(comment.start_line)
  end
  return comment.start_line .. "-" .. comment.end_line
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
    title = title or " Comment  (<C-s> save · <C-c> cancel) ",
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

--- Record a comment for the given buffer/range and place a sign.
--- @param bufnr integer
--- @param start_line integer 1-indexed, inclusive
--- @param end_line integer 1-indexed, inclusive
--- @param text string
local function save_comment(bufnr, start_line, end_line, text)
  local filepath = vim.api.nvim_buf_get_name(bufnr)
  local code_lines = vim.api.nvim_buf_get_lines(bufnr, start_line - 1, end_line, false)
  local filetype = vim.bo[bufnr].filetype

  local extmark_id = vim.api.nvim_buf_set_extmark(bufnr, M._ns, start_line - 1, 0, {
    sign_text = SIGN_TEXT,
    sign_hl_group = "AgentCommentSign",
  })

  local id = M._next_id
  M._next_id = id + 1

  local entry = {
    id = id,
    bufnr = bufnr,
    filepath = filepath,
    relpath = vim.fn.fnamemodify(filepath, ":~:."),
    filetype = filetype,
    start_line = start_line,
    end_line = end_line,
    code_lines = code_lines,
    text = text,
    extmark_id = extmark_id,
  }
  table.insert(M._comments, entry)

  vim.notify(
    string.format("Agent comment added: %s:%s", vim.fn.fnamemodify(filepath, ":t"), format_range(entry)),
    vim.log.levels.INFO
  )
end

--- Add a comment for a line range in the current buffer (entry point for
--- the visual-mode mapping / :AgentCommentAdd command).
--- @param start_line integer
--- @param end_line integer
function M.add_comment(start_line, end_line)
  local bufnr = vim.api.nvim_get_current_buf()
  local filepath = vim.api.nvim_buf_get_name(bufnr)
  if filepath == "" then
    vim.notify("AgentComments: buffer has no file to reference", vim.log.levels.WARN)
    return
  end

  if start_line > end_line then
    start_line, end_line = end_line, start_line
  end

  open_input(function(text)
    if vim.trim(text) == "" then
      return
    end
    save_comment(bufnr, start_line, end_line, text)
  end)
end

--- Find the comment closest to the cursor in the current buffer: an exact
--- range match wins, otherwise the nearest by distance to its range.
--- @return AgentComment? comment
--- @return integer? index into M._comments
local function find_comment_near_cursor()
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]

  local best, best_idx, best_dist
  for idx, c in ipairs(M._comments) do
    if c.bufnr == bufnr then
      local dist
      if cursor_line >= c.start_line and cursor_line <= c.end_line then
        dist = 0
      else
        dist = math.min(math.abs(cursor_line - c.start_line), math.abs(cursor_line - c.end_line))
      end
      if not best_dist or dist < best_dist then
        best, best_idx, best_dist = c, idx, dist
      end
    end
  end

  return best, best_idx
end

--- Delete a specific comment (by identity) and its sign.
--- @param comment AgentComment
function M.delete_comment(comment)
  for idx, c in ipairs(M._comments) do
    if c.id == comment.id then
      if c.extmark_id and vim.api.nvim_buf_is_valid(c.bufnr) then
        pcall(vim.api.nvim_buf_del_extmark, c.bufnr, M._ns, c.extmark_id)
      end
      table.remove(M._comments, idx)
      break
    end
  end

  vim.notify(
    string.format("AgentComments: deleted comment at %s:%s", vim.fn.fnamemodify(comment.filepath, ":t"),
      format_range(comment)),
    vim.log.levels.INFO
  )
end

--- Edit a specific comment's text (by identity), reopening the floating
--- input pre-filled with its current text.
--- @param comment AgentComment
function M.edit_comment(comment)
  open_input(function(text)
    if vim.trim(text) == "" then
      vim.notify("AgentComments: empty comment, left unchanged", vim.log.levels.WARN)
      return
    end
    comment.text = text
    vim.notify(
      string.format("AgentComments: updated comment at %s:%s", vim.fn.fnamemodify(comment.filepath, ":t"),
        format_range(comment)),
      vim.log.levels.INFO
    )
  end, vim.split(comment.text, "\n", { plain = true }), " Edit comment  (<C-s> save · <C-c> cancel) ")
end

--- Delete the single comment nearest the cursor in the current buffer.
function M.delete_at_cursor()
  local comment = find_comment_near_cursor()
  if not comment then
    vim.notify("AgentComments: no comment near cursor in this buffer", vim.log.levels.WARN)
    return
  end
  M.delete_comment(comment)
end

--- Edit the text of the single comment nearest the cursor in the current
--- buffer, reopening the floating input pre-filled with its current text.
function M.edit_at_cursor()
  local comment = find_comment_near_cursor()
  if not comment then
    vim.notify("AgentComments: no comment near cursor in this buffer", vim.log.levels.WARN)
    return
  end
  M.edit_comment(comment)
end

--- Populate the (window-local) location list with all pending comments and
--- open it. <CR> on an entry jumps to that file/line natively; from there,
--- use :AgentCommentDelete / :AgentCommentEdit (or their keymaps) on the
--- cursor as usual.
function M.list()
  if #M._comments == 0 then
    vim.notify("AgentComments: no pending comments", vim.log.levels.INFO)
    return
  end

  local items = {}
  for idx, c in ipairs(M._comments) do
    local first_line = vim.split(c.text, "\n", { plain = true })[1] or ""
    table.insert(items, {
      filename = c.filepath,
      lnum = c.start_line,
      col = 1,
      text = string.format("%d. [%s] %s", idx, format_range(c), first_line),
    })
  end

  vim.fn.setloclist(0, {}, " ", {
    title = "Agent Comments",
    items = items,
  })
  vim.cmd("lopen")
end

--- Remove all stored comments and their signs without writing anything out.
function M.clear()
  local count = #M._comments
  for _, c in ipairs(M._comments) do
    if c.extmark_id and vim.api.nvim_buf_is_valid(c.bufnr) then
      pcall(vim.api.nvim_buf_del_extmark, c.bufnr, M._ns, c.extmark_id)
    end
  end
  M._comments = {}
  return count
end

--- Discard all pending comments (public command handler).
function M.discard()
  local count = M.clear()
  if count == 0 then
    vim.notify("AgentComments: nothing to discard", vim.log.levels.INFO)
  else
    vim.notify(string.format("AgentComments: discarded %d comment(s)", count), vim.log.levels.INFO)
  end
end

--- Render all pending comments into a single markdown prompt, in the order
--- they were written -- M._comments is append-only, so iterating it directly
--- preserves authoring order across files. Comments are numbered so the
--- order is explicit to whatever reads the prompt.
--- @return string
local function render()
  local out = {
    "Please address the following comments about specific code regions,",
    "in the order they are listed:",
    "",
  }

  for idx, c in ipairs(M._comments) do
    table.insert(out, string.format("## %d. %s:%s", idx, c.relpath, format_range(c)))
    table.insert(out, "")
    table.insert(out, "```" .. (c.filetype or ""))
    vim.list_extend(out, c.code_lines)
    table.insert(out, "```")
    table.insert(out, "")
    for _, line in ipairs(vim.split(c.text, "\n", { plain = true })) do
      table.insert(out, "> " .. line)
    end
    table.insert(out, "")
  end

  return table.concat(out, "\n")
end

--- Extract all pending comments to a markdown prompt: write it to a temp
--- file, open that file in a new buffer, copy it to the clipboard, and
--- clear the in-memory store.
function M.flush()
  if #M._comments == 0 then
    vim.notify("AgentComments: no comments to flush", vim.log.levels.WARN)
    return
  end

  local count = #M._comments
  local content = render()

  local tmpfile = vim.fn.tempname() .. "-agent-comments.md"
  vim.fn.writefile(vim.split(content, "\n", { plain = true }), tmpfile)

  vim.fn.setreg("+", content)
  vim.fn.setreg('"', content)

  vim.cmd("botright vsplit " .. vim.fn.fnameescape(tmpfile))

  M.clear()

  vim.notify(
    string.format("AgentComments: flushed %d comment(s) -> %s (copied to clipboard)", count, tmpfile),
    vim.log.levels.INFO
  )
end

vim.api.nvim_create_user_command("AgentCommentAdd", function(opts)
  M.add_comment(opts.line1, opts.line2)
end, {
  range = true,
  desc = "Add an agent comment for the current line or visual selection",
})

vim.api.nvim_create_user_command("AgentCommentsFlush", function()
  M.flush()
end, {
  desc = "Extract all pending agent comments into a prompt buffer",
})

vim.api.nvim_create_user_command("AgentCommentsClear", function()
  M.discard()
end, {
  desc = "Discard all pending agent comments",
})

vim.api.nvim_create_user_command("AgentCommentDelete", function()
  M.delete_at_cursor()
end, {
  desc = "Delete the agent comment nearest the cursor",
})

vim.api.nvim_create_user_command("AgentCommentEdit", function()
  M.edit_at_cursor()
end, {
  desc = "Edit the agent comment nearest the cursor",
})

vim.api.nvim_create_user_command("AgentCommentsList", function()
  M.list()
end, {
  desc = "Open the location list of all pending agent comments",
})

return M
