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
  local runner = "VtrSendCommandToRunner"

  if vim.fn.expand('%') ~= '' then
    vim.cmd('write')
  end

  -- The file is executable; assume we should run it directly
  if vim.fn.executable(filename) == 1 then
    vim.cmd('!./' .. filename)
    -- 5A Clojure projects
  elseif string.find(filename, "Workplace/seubarriga") ~= nil and vim.fn.glob('test/**/*_test.clj') ~= '' then
    local relative_path = vim.fn.fnamemodify(buf_info.filepath, ':~:.')
    relative_path = string.gsub(relative_path, "^test/", "")
    local namespace = string.gsub(relative_path, "/", ".")
    namespace = string.gsub(namespace, "_", "-")
    namespace = string.gsub(namespace, "%.clj$", "")

    vim.cmd(runner .. string.format(" lein with-profile test midje %s", namespace))
  else
    print("No suitable test runner found for " .. filename)
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
