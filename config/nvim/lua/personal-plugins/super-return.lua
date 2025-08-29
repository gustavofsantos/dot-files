-- SuperReturn Plugin: Flexible Test Runner for Neovim
-- Allows running commands based on file type and project structure

local SuperReturn = {}

-- =============================================================================
-- UTILITY FUNCTIONS
-- =============================================================================

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

local function matches_pattern(text, pattern)
  if type(pattern) == "string" then
    return string.find(text, pattern) ~= nil
  elseif type(pattern) == "table" then
    for _, p in ipairs(pattern) do
      if string.find(text, p) then
        return true
      end
    end
  end
  return false
end

-- =============================================================================
-- EXECUTION STRATEGIES
-- =============================================================================

SuperReturn.execution_strategies = {}

-- Tmux execution strategy
SuperReturn.execution_strategies.tmux = {
  name = "tmux",
  execute = function(cmd)
    vim.cmd("TmuxRunCommand " .. vim.fn.shellescape(cmd))
  end
}

-- Overseer execution strategy
SuperReturn.execution_strategies.overseer = {
  name = "overseer",
  execute = function(cmd)
    -- Check if overseer is available
    local ok, overseer = pcall(require, 'overseer')
    if not ok then
      vim.notify("Overseer plugin not found. Please install overseer.nvim", vim.log.levels.ERROR)
      return false
    end

    -- Create and run a new overseer task using shell component
    local task = overseer.new_task({
      name = "SuperReturn: " .. cmd,
      cmd = cmd,
      components = {
        "default",
        {
          "on_output_quickfix",
          open = false,  -- Don't auto-open quickfix
          open_height = 10,
        },
        "on_result_diagnostics",
        "display_duration",
      },
    })

    -- Start the task
    task:start()

    -- Optional: Focus on the task list
    -- Uncomment the following line if you want to auto-focus overseer
    -- vim.cmd("OverseerOpen")

    vim.notify("Task dispatched to Overseer: " .. cmd, vim.log.levels.INFO)
    return true
  end
}

-- Terminal execution strategy
SuperReturn.execution_strategies.terminal = {
  name = "terminal",
  execute = function(cmd)
    vim.cmd("!" .. cmd)
  end
}

-- =============================================================================
-- MATCHERS
-- =============================================================================

SuperReturn.matchers = {}

function SuperReturn.matchers.directory(buf_info, patterns)
  for _, pattern in ipairs(patterns) do
    if matches_pattern(buf_info.filepath, pattern) then
      return true
    end
  end
  return false
end

function SuperReturn.matchers.file(buf_info, patterns)
  for _, pattern in ipairs(patterns) do
    if matches_pattern(buf_info.filename, pattern) then
      return true
    end
  end
  return false
end

function SuperReturn.matchers.extension(buf_info, extensions)
  if type(extensions) == "string" then
    return buf_info.extension == extensions
  elseif type(extensions) == "table" then
    for _, ext in ipairs(extensions) do
      if buf_info.extension == ext then
        return true
      end
    end
  end
  return false
end

-- =============================================================================
-- COMMAND BUILDERS
-- =============================================================================

SuperReturn.command_builders = {}

function SuperReturn.command_builders.clojure_test(buf_info)
  -- Convert file path to Clojure namespace
  local namespace = string.gsub(buf_info.filepath, "/", ".")
  namespace = string.gsub(namespace, "_", "-")
  namespace = string.gsub(namespace, "^.*%.clojure%.", "")
  namespace = string.gsub(namespace, "%.clj$", "")

  return string.format("lein with-profile test midje %s", namespace)
end

function SuperReturn.command_builders.simple_test(buf_info, base_cmd)
  return base_cmd .. " " .. buf_info.filename
end

-- =============================================================================
-- RUNNER REGISTRY
-- =============================================================================

SuperReturn.runners = {}

function SuperReturn.register_runner(name, config)
  SuperReturn.runners[name] = config
end

function SuperReturn.unregister_runner(name)
  SuperReturn.runners[name] = nil
end

-- =============================================================================
-- DEFAULT RUNNERS
-- =============================================================================

-- SeuBarriga Clojure project runner
SuperReturn.register_runner("seubarriga", {
  name = "SeuBarriga",
  description = "Clojure test runner for SeuBarriga project",

  -- Matching criteria
  matches = function(buf_info)
    local directory_patterns = {
      "Workplace/seubarriga/",
      "Workplace/seubarriga%-worktrees/"
    }
    local file_patterns = { "test/" }

    return SuperReturn.matchers.directory(buf_info, directory_patterns) or
           SuperReturn.matchers.file(buf_info, file_patterns)
  end,

  -- Command builder (inlined for SeuBarriga-specific path manipulation)
  build_command = function(buf_info)
    -- Convert SeuBarriga test file path to Clojure namespace
    -- Example: test/seubarriga/services/order_entry_test.clj -> seubarriga.services.order-entry-test

    -- Get relative path from project root (assuming we're in a test directory)
    local cwd = vim.fn.getcwd()
    local relative_path = vim.fn.fnamemodify(buf_info.filepath, ':~:.')  -- Make relative to cwd

    -- Remove 'test/' prefix if present
    relative_path = string.gsub(relative_path, "^test/", "")

    -- Convert path separators to dots
    local namespace = string.gsub(relative_path, "/", ".")

    -- Convert underscores to hyphens (Clojure naming convention)
    namespace = string.gsub(namespace, "_", "-")

    -- Remove .clj extension
    namespace = string.gsub(namespace, "%.clj$", "")

    return string.format("lein with-profile test midje %s", namespace)
  end,

  -- Execution strategy
  execution_strategy = "tmux",

  -- Priority (higher numbers = higher priority)
  priority = 10
})

-- =============================================================================
-- MAIN HANDLER
-- =============================================================================

function SuperReturn.find_matching_runner(buf_info)
  local matching_runners = {}

  for name, runner in pairs(SuperReturn.runners) do
    if runner.matches(buf_info) then
      table.insert(matching_runners, {
        name = name,
        runner = runner,
        priority = runner.priority or 0
      })
    end
  end

  -- Sort by priority (highest first)
  table.sort(matching_runners, function(a, b)
    return a.priority > b.priority
  end)

  return matching_runners[1] -- Return highest priority match
end

function SuperReturn.execute_command(cmd, strategy_name)
  local strategy = SuperReturn.execution_strategies[strategy_name]
  if not strategy then
    vim.notify("Unknown execution strategy: " .. strategy_name, vim.log.levels.ERROR)
    return false
  end

  strategy.execute(cmd)
  return true
end

function SuperReturn.handle()
  local buf = vim.api.nvim_get_current_buf()
  local buf_info = get_buffer_info(buf)

  -- Skip if buffer has no file
  if buf_info.filepath == "" then
    vim.notify("No file associated with current buffer", vim.log.levels.WARN)
    return
  end

  local matching_runner = SuperReturn.find_matching_runner(buf_info)

  if not matching_runner then
    vim.notify("No runner found for current file", vim.log.levels.INFO)
    return
  end

  local cmd = matching_runner.runner.build_command(buf_info)
  if not cmd then
    vim.notify("Failed to build command for runner: " .. matching_runner.name, vim.log.levels.ERROR)
    return
  end

  vim.notify(string.format("Running: %s", cmd), vim.log.levels.INFO)

  local success = SuperReturn.execute_command(cmd, matching_runner.runner.execution_strategy)
  if success then
    vim.notify("Command executed successfully", vim.log.levels.INFO)
  end
end

-- =============================================================================
-- PUBLIC API
-- =============================================================================

-- Register a new execution strategy
function SuperReturn.add_execution_strategy(name, config)
  SuperReturn.execution_strategies[name] = config
end

-- Get all registered runners
function SuperReturn.get_runners()
  return SuperReturn.runners
end

-- Get all execution strategies
function SuperReturn.get_execution_strategies()
  return SuperReturn.execution_strategies
end

-- =============================================================================
-- NEOVIM INTEGRATION
-- =============================================================================

-- Create the user command
vim.api.nvim_create_user_command("SuperReturn", SuperReturn.handle, {
  desc = "Run current file with appropriate test runner"
})


return SuperReturn
