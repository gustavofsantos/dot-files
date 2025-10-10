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

local function can_use_toggleterm()
  local ok = pcall(require, "toggleterm")
  return ok
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

local function dispatch_command(cmd)
  -- 1. Try vim-tmux-runner if inside tmux
  if in_tmux() then
    vim.cmd('VtrSendCommandToRunner ' .. cmd)
    return
  end

  -- 2. Try toggleterm if available
  if can_use_toggleterm() then
    send_to_toggleterm(cmd)
    return
  end

  -- 3. Fallback to native neovim terminal
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
  local buf = vim.api.nvim_get_current_buf()
  local buf_info = get_buffer_info(buf)

  if vim.fn.expand('%') ~= '' then
    vim.cmd('write')
  end

  local relative_path = vim.fn.fnamemodify(buf_info.filepath, ':~:.')
  last_test_file = relative_path

  -- The file is executable; assume we should run it directly
  if vim.fn.executable(filename) == 1 then
    vim.cmd('!./' .. filename)
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
