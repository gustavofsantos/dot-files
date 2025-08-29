-- SuperReturn Configuration Examples
-- This file demonstrates how to extend SuperReturn with new runners

local SuperReturn = require('personal-plugins.super-return')

-- =============================================================================
-- EXAMPLE: Adding a JavaScript/Node.js test runner
-- =============================================================================

SuperReturn.register_runner("javascript", {
  name = "JavaScript Test Runner",
  description = "Run JavaScript tests with Jest or similar",

  matches = function(buf_info)
    -- Match JavaScript/TypeScript files
    return SuperReturn.matchers.extension(buf_info, {"js", "ts", "jsx", "tsx"})
  end,

  build_command = function(buf_info)
    -- Check for package.json to determine test command
    local package_json = buf_info.dirname .. "/package.json"
    if vim.fn.filereadable(package_json) == 1 then
      -- Could parse package.json here to determine test script
      return "npm test"
    else
      -- Fallback to jest directly
      return "jest " .. buf_info.filename
    end
  end,

  execution_strategy = "terminal",
  priority = 5
})

-- =============================================================================
-- EXAMPLE: Adding a Python test runner
-- =============================================================================

SuperReturn.register_runner("python", {
  name = "Python Test Runner",
  description = "Run Python tests with pytest",

  matches = function(buf_info)
    -- Match Python files
    return SuperReturn.matchers.extension(buf_info, "py")
  end,

  build_command = function(buf_info)
    -- Check for different Python test frameworks
    local has_pytest = vim.fn.filereadable(buf_info.dirname .. "/pytest.ini") == 1 or
                      vim.fn.filereadable(buf_info.dirname .. "/pyproject.toml") == 1
    local has_unittest = string.find(buf_info.filename, "test_") ~= nil

    if has_pytest then
      return "pytest " .. buf_info.filename
    elseif has_unittest then
      return "python -m unittest " .. buf_info.filename
    else
      return "python " .. buf_info.filename
    end
  end,

  execution_strategy = "terminal",
  priority = 5
})

-- =============================================================================
-- EXAMPLE: Using Overseer execution strategy
-- =============================================================================

SuperReturn.add_execution_strategy("notify_only", {
  name = "notify_only",
  execute = function(cmd)
    vim.notify("Would run: " .. cmd, vim.log.levels.INFO)
    -- Just notify, don't actually execute
  end
})


-- =============================================================================
-- UTILITY FUNCTIONS FOR ADVANCED CONFIGURATION
-- =============================================================================

-- Function to check if a file exists in any parent directory
local function find_file_in_parent_dirs(filename, start_dir)
  local current_dir = start_dir or vim.fn.getcwd()
  local max_depth = 10

  for i = 1, max_depth do
    local test_path = current_dir .. "/" .. filename
    if vim.fn.filereadable(test_path) == 1 then
      return test_path
    end

    local parent = vim.fn.fnamemodify(current_dir, ":h")
    if parent == current_dir then
      break -- Reached root
    end
    current_dir = parent
  end

  return nil
end

-- Function to determine project type based on files
local function detect_project_type(buf_info)
  local project_indicators = {
    rails = {"Gemfile", "config/application.rb"},
    node = {"package.json"},
    python = {"requirements.txt", "setup.py", "pyproject.toml"},
    clojure = {"project.clj", "deps.edn"},
    rust = {"Cargo.toml"},
    go = {"go.mod"}
  }

  for project_type, files in pairs(project_indicators) do
    for _, file in ipairs(files) do
      if find_file_in_parent_dirs(file, buf_info.dirname) then
        return project_type
      end
    end
  end

  return "unknown"
end

-- =============================================================================
-- ADVANCED EXAMPLE: Auto-detecting project runners
-- =============================================================================

SuperReturn.register_runner("auto_detect", {
  name = "Auto-Detect Runner",
  description = "Automatically detect project type and run appropriate tests",

  matches = function(buf_info)
    -- Match all files, but with lowest priority
    return true
  end,

  build_command = function(buf_info)
    local project_type = detect_project_type(buf_info)

    if project_type == "rails" then
      return "bundle exec rails test"
    elseif project_type == "node" then
      return "npm test"
    elseif project_type == "python" then
      return "python -m pytest"
    elseif project_type == "clojure" then
      return "lein test"
    elseif project_type == "rust" then
      return "cargo test"
    elseif project_type == "go" then
      return "go test ./..."
    else
      return nil -- No command for unknown project types
    end
  end,

  execution_strategy = "terminal",
  priority = 1 -- Lowest priority so specific runners take precedence
})

-- =============================================================================
-- EXAMPLE: Switching existing runner to use Overseer
-- =============================================================================

-- You can also modify existing runners to use overseer by unregistering and re-registering
-- Uncomment the following to make SeuBarriga use overseer instead of tmux:

SuperReturn.register_runner("seubarriga", {
  name = "SeuBarriga",
  description = "Clojure test runner for SeuBarriga project via Overseer",

  matches = function(buf_info)
    local directory_patterns = {
      "Workplace/seubarriga/",
      "Workplace/seubarriga%-worktrees/"
    }
    local file_patterns = { "test/" }

    return SuperReturn.matchers.directory(buf_info, directory_patterns) or
           SuperReturn.matchers.file(buf_info, file_patterns)
  end,

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

  execution_strategy = "overseer",
  priority = 15
})

-- Uncomment the line below to enable auto-detection
-- (Note: This would override the default behavior, so use carefully)
-- SuperReturn.register_runner("auto_detect", auto_detect_runner)
