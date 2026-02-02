-- Test Plugin with Sequential Command Dispatching
--
-- This plugin extends the original test functionality with a sequential command
-- dispatcher that automatically selects the best available terminal method:
--
-- 1. vim-tmux-runner (VtrSendCommandToRunner) - when running inside tmux
-- 2. toggleterm plugin - when available and outside tmux
-- 3. native neovim terminal - as final fallback
--
-- For non-tmux environments, the plugin maintains persistent terminal instances
-- to allow viewing execution logs and reusing the same terminal across commands.
--
-- Command dispatching helpers and persistent variables
local function in_tmux()
  return os.getenv("TMUX") ~= nil
end

local native_term_bufnr
local last_test_file

local function can_use_overseer()
  local ok = pcall(require, "overseer")
  return ok
end

local function can_use_toggleterm()
  local ok = pcall(require, "toggleterm")
  return ok
end

local function send_to_overseer(cmd)
  local overseer = require("overseer")
  local task = overseer.new_task({
    cmd = "sh",
    args = { "-c", cmd },
    name = "Test",
    components = { "default" },
  })
  task:start()
end

local function send_to_toggleterm(cmd)
  -- Use toggleterm's command interface instead of API
  -- This opens a terminal (or reuses existing one) and sends the command
  vim.cmd(string.format("TermExec cmd='%s' direction=horizontal size=15", cmd:gsub("'", "'\"'\"'")))
end

local function get_native_term()
  if native_term_bufnr == nil or not vim.api.nvim_buf_is_valid(native_term_bufnr) then
    vim.cmd("belowright split | terminal")
    vim.cmd("resize 15")
    native_term_bufnr = vim.api.nvim_get_current_buf()
  end
  return native_term_bufnr
end

-- Tmux pane management functions
local function has_vtr_pane_attached()
  -- Check if vim-tmux-runner has a pane attached
  local result = vim.fn.system("tmux list-panes -F '#{pane_id}' 2>/dev/null")
  if vim.v.shell_error ~= 0 then
    return false
  end
  
  -- VTR stores the pane info in a variable, check if it exists
  local vtr_pane = vim.g.VtrRunner
  return vtr_pane ~= nil and vtr_pane ~= ''
end

local function get_tmux_panes()
  -- Get all panes with their status
  local result = vim.fn.system("tmux list-panes -F '#{pane_index}:#{pane_current_command}:#{pane_active}' 2>/dev/null")
  if vim.v.shell_error ~= 0 then
    return {}
  end
  
  local panes = {}
  for line in result:gmatch("[^\r\n]+") do
    local pane_index, command, is_active = line:match("([^:]+):([^:]+):([^:]+)")
    if pane_index then
      table.insert(panes, {
        id = pane_index,
        command = command,
        is_active = is_active == "1",
        is_idle = command == "zsh" or command == "bash" or command == "fish"
      })
    end
  end
  return panes
end

local function find_marked_pane()
  -- Check if there's a marked pane in the current session
  local result = vim.fn.system("tmux list-panes -F '#{pane_index}:#{pane_marked}' 2>/dev/null")
  if vim.v.shell_error ~= 0 then
    return nil
  end
  
  for line in result:gmatch("[^\r\n]+") do
    local pane_index, is_marked = line:match("([^:]+):([^:]+)")
    if pane_index and is_marked == "1" then
      return pane_index
    end
  end
  return nil
end

local function find_idle_pane(panes)
  -- Find a pane that's not the current one and is idle
  for _, pane in ipairs(panes) do
    if not pane.is_active and pane.is_idle then
      return pane.id
    end
  end
  return nil
end

local function create_tmux_split()
  -- Create a new tmux split below the current pane
  local result = vim.fn.system("tmux split-window -v -c '#{pane_current_path}' -P -F '#{pane_id}' 2>/dev/null")
  if vim.v.shell_error == 0 then
    return result:gsub("%s+", "") -- trim whitespace
  end
  return nil
end

local function setup_vtr_pane()
  -- Check if VTR already has a pane attached
  if has_vtr_pane_attached() then
    return true
  end
  
  local target_pane = nil
  
  -- First priority: check for a marked pane
  target_pane = find_marked_pane()
  
  -- Second priority: find an idle pane
  if not target_pane then
    local panes = get_tmux_panes()
    target_pane = find_idle_pane(panes)
    
    -- If no idle pane and only one pane (current), create a new split
    if not target_pane and #panes == 1 then
      target_pane = create_tmux_split()
    end
  end
  
  -- Attach VTR to the target pane
  if target_pane then
    vim.cmd('silent VtrAttachToPane ' .. target_pane)
    return true
  end
  
  return false
end

local function dispatch_command(cmd)
  -- 1. Try overseer (highest priority)
  if can_use_overseer() then
    send_to_overseer(cmd)
    return
  end

  -- 2. Try vim-tmux-runner if inside tmux
  if in_tmux() then
    if setup_vtr_pane() then
      vim.cmd('silent VtrSendCommandToRunner ' .. cmd)
    else
      print("Error: Could not setup tmux pane for testing")
    end
    return
  end

  -- 3. Try toggleterm if available
  if can_use_toggleterm() then
    send_to_toggleterm(cmd)
    return
  end

  -- 4. Fallback to native neovim terminal
  local bufnr = get_native_term()
  local job_id = vim.fn.getbufvar(bufnr, 'terminal_job_id')
  if job_id > 0 then
    vim.fn.chansend(job_id, cmd .. "\n")
  end
end

local function get_buffer_info(buf)
  local bufname = vim.api.nvim_buf_get_name(buf)
  local filepath = vim.fn.fnamemodify(bufname, ':p')
  local filename = vim.fn.fnamemodify(bufname, ':t')
  local dirname = vim.fn.fnamemodify(bufname, ':p:h')
  local extension = vim.fn.fnamemodify(bufname, ':e')

  return {
    buf = buf,
    bufname = bufname,
    filepath = filepath,
    filename = filename,
    dirname = dirname,
    extension = extension
  }
end

local function run_tests(filename)
  -- If filename is provided, use it directly; otherwise use current buffer
  local target_file
  if filename and filename ~= '' then
    target_file = filename
  else
    local buf = vim.api.nvim_get_current_buf()
    local buf_info = get_buffer_info(buf)
    target_file = buf_info.filepath
  end

  -- Save current buffer if it's the active one
  if vim.fn.expand('%') ~= '' then
    vim.cmd('silent! write')
  end

  local relative_path = vim.fn.fnamemodify(target_file, ':~:.')
  last_test_file = relative_path

  -- The file is executable; assume we should run it directly
  if vim.fn.executable(target_file) == 1 then
    dispatch_command("./" .. vim.fn.fnamemodify(target_file, ':t'))
  else
    dispatch_command("testfile " .. relative_path)
  end
end


vim.api.nvim_create_user_command("RunTests",
  function(opts)
    local filename = opts.fargs[1] or vim.fn.expand('%:p')
    if filename and filename ~= '' then
      run_tests(filename)
    else
      print("Error: No file specified.")
    end
  end,
  {
    nargs = '?',     -- The command accepts 0 or 1 arguments
    complete = 'file', -- Provide file completion
    desc = 'Run tests for the specified file or current file'
  }
)

vim.api.nvim_create_user_command("TestVisit",
  function()
    if last_test_file and last_test_file ~= '' then
      vim.cmd('edit ' .. last_test_file)
    else
      print("Error: No last test file found. Run tests first with :RunTests")
    end
  end,
  {
    desc = 'Jump to the last test file that was run'
  }
)

vim.api.nvim_create_user_command("TestLast",
  function()
    if last_test_file and last_test_file ~= '' then
      run_tests(last_test_file)
    else
      print("Error: No last test found. Run tests first with :RunTests")
    end
  end,
  {
    desc = 'Re-run the last test that was executed'
  }
)
