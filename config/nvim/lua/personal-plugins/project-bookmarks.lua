--- Project Bookmarks Plugin for Neovim
--- Bookmark files with notes, scoped per project/directory
---
--- @class ProjectBookmarks
--- @field private _config table Plugin configuration
--- @field private _db table Database helper instance
local M = {}

-- Default configuration
local default_config = {
  -- Directory to store bookmark databases (one JSON per project)
  data_dir = vim.fn.stdpath("data") .. "/project-bookmarks",
  -- How to identify projects (git_root, cwd, or custom function)
  project_identification = "git_root", -- "git_root", "cwd", function
  -- Maximum number of recent searches to remember
  max_recent_searches = 10,
}

--- Plugin configuration
M._config = default_config
M._db = nil

--- Initialize the plugin
--- @param user_config? table Optional user configuration
function M.setup(user_config)
  M._config = vim.tbl_deep_extend("force", default_config, user_config or {})
  
  -- Ensure data directory exists
  vim.fn.mkdir(M._config.data_dir, "p")
  
  -- Initialize database helper
  local db = require("personal-plugins.project-bookmarks-db")
  M._db = db.new(M._config)
  
  -- Create user commands
  M._create_user_commands()
end

--- Get the current project root
--- @return string project_root
function M._get_project_root()
  if type(M._config.project_identification) == "function" then
    return M._config.project_identification()
  elseif M._config.project_identification == "git_root" then
    -- Try to find git root
    local git_root = vim.fs.find(".git", {
      upward = true,
      type = "directory",
      path = vim.fn.getcwd()
    })[1]
    
    if git_root then
      return vim.fn.fnamemodify(git_root, ":h")
    else
      -- Fallback to current working directory
      return vim.fn.getcwd()
    end
  else
    return vim.fn.getcwd()
  end
end

--- Generate a project identifier from path
--- @param project_root string The project root path
--- @return string project_id
function M._get_project_id(project_root)
  -- Use the last part of the path as project ID, with hash for uniqueness
  local project_name = vim.fn.fnamemodify(project_root, ":t")
  local hash = vim.fn.sha256(project_root):sub(1, 8)
  return project_name .. "_" .. hash
end

--- Add a bookmark for the current file
--- @param note? string Optional note for the bookmark
function M.add_bookmark(note)
  local current_file = vim.fn.expand("%:p")
  if current_file == "" then
    vim.notify("No file to bookmark", vim.log.levels.WARN)
    return
  end
  
  -- If note is provided, use it directly
  if note then
    M._save_bookmark_with_note(current_file, note)
    return
  end
  
  -- Switch to insert mode before showing input
  local original_mode = vim.fn.mode()
  if original_mode ~= 'i' then
    vim.cmd('startinsert')
  end
  
  -- Prompt for note with insert mode active
  vim.ui.input({
    prompt = "Note (optional): ",
    default = "",
  }, function(input_note)
    -- Return to normal mode after input
    if vim.fn.mode() == 'i' then
      vim.cmd('stopinsert')
    end
    
    -- Process the bookmark
    if input_note ~= nil then -- User didn't cancel
      M._save_bookmark_with_note(current_file, input_note ~= "" and input_note or nil)
    end
  end)
end

--- Internal function to save bookmark with note
--- @param current_file string Full path to current file
--- @param note? string Optional note for the bookmark
function M._save_bookmark_with_note(current_file, note)
  local project_root = M._get_project_root()
  local project_id = M._get_project_id(project_root)
  
  -- Make file path relative to project root
  local relative_path = vim.fn.fnamemodify(current_file, ":.")
  if vim.startswith(current_file, project_root) then
    relative_path = current_file:sub(#project_root + 2) -- +2 to remove leading slash
  end
  
  local bookmark = {
    file_path = current_file,
    relative_path = relative_path,
    note = note or "",
    created_at = os.time(),
    updated_at = os.time(),
    line_number = vim.fn.line("."),
    project_root = project_root,
  }
  
  local success, err = M._db:add_bookmark(project_id, current_file, bookmark)
  if success then
    local msg = "Bookmarked: " .. relative_path
    if note and note ~= "" then
      msg = msg .. " (Note: " .. note .. ")"
    end
    vim.notify(msg, vim.log.levels.INFO)
  else
    vim.notify("Failed to add bookmark: " .. (err or "Unknown error"), vim.log.levels.ERROR)
  end
end

--- Remove bookmark for the current file
function M.remove_bookmark()
  local current_file = vim.fn.expand("%:p")
  if current_file == "" then
    vim.notify("No current file", vim.log.levels.WARN)
    return
  end
  
  local project_root = M._get_project_root()
  local project_id = M._get_project_id(project_root)
  
  local success, err = M._db:remove_bookmark(project_id, current_file)
  if success then
    local relative_path = vim.fn.fnamemodify(current_file, ":.")
    vim.notify("Removed bookmark: " .. relative_path, vim.log.levels.INFO)
  else
    vim.notify("Failed to remove bookmark: " .. (err or "Unknown error"), vim.log.levels.ERROR)
  end
end

--- Edit note for the current file's bookmark
function M.edit_bookmark_note()
  local current_file = vim.fn.expand("%:p")
  if current_file == "" then
    vim.notify("No current file", vim.log.levels.WARN)
    return
  end
  
  local project_root = M._get_project_root()
  local project_id = M._get_project_id(project_root)
  
  local bookmark = M._db:get_bookmark(project_id, current_file)
  if not bookmark then
    vim.notify("File not bookmarked. Add bookmark first.", vim.log.levels.WARN)
    return
  end
  
  -- Switch to insert mode before showing input
  local original_mode = vim.fn.mode()
  if original_mode ~= 'i' then
    vim.cmd('startinsert')
  end
  
  -- Prompt for new note with insert mode active
  vim.ui.input({
    prompt = "Edit note: ",
    default = bookmark.note or "",
  }, function(new_note)
    -- Return to normal mode after input
    if vim.fn.mode() == 'i' then
      vim.cmd('stopinsert')
    end
    
    if new_note ~= nil then -- nil means cancelled
      bookmark.note = new_note
      bookmark.updated_at = os.time()
      
      local success, err = M._db:update_bookmark(project_id, current_file, bookmark)
      if success then
        vim.notify("Updated bookmark note", vim.log.levels.INFO)
      else
        vim.notify("Failed to update note: " .. (err or "Unknown error"), vim.log.levels.ERROR)
      end
    end
  end)
end

--- Check if current file is bookmarked
--- @return boolean is_bookmarked
function M.is_current_file_bookmarked()
  local current_file = vim.fn.expand("%:p")
  if current_file == "" then
    return false
  end
  
  local project_root = M._get_project_root()
  local project_id = M._get_project_id(project_root)
  
  return M._db:get_bookmark(project_id, current_file) ~= nil
end

--- Open bookmark search picker
function M.search_bookmarks()
  if not M._db then
    vim.notify("Project bookmarks not initialized. Run :BookmarkInfo to debug.", vim.log.levels.ERROR)
    return
  end
  
  local project_root = M._get_project_root()
  local project_id = M._get_project_id(project_root)
  
  -- Debug info
  vim.notify("Searching bookmarks for project: " .. project_id, vim.log.levels.DEBUG)
  
  local bookmarks = M._db:get_all_bookmarks(project_id)
  if not bookmarks or vim.tbl_isempty(bookmarks) then
    vim.notify("No bookmarks found in current project: " .. project_root, vim.log.levels.INFO)
    return
  end
  
  local picker = require("personal-plugins.project-bookmarks-picker")
  picker.show_bookmarks(bookmarks, project_root, {
    on_select = function(bookmark)
      -- Open the file and jump to the bookmarked line
      vim.cmd("edit " .. vim.fn.fnameescape(bookmark.file_path))
      if bookmark.line_number and bookmark.line_number > 0 then
        vim.fn.cursor(bookmark.line_number, 1)
      end
    end,
    on_delete = function(bookmark)
      local success, err = M._db:remove_bookmark(project_id, bookmark.file_path)
      if success then
        vim.notify("Removed bookmark: " .. bookmark.relative_path, vim.log.levels.INFO)
        return true -- Signal successful deletion
      else
        vim.notify("Failed to remove bookmark: " .. (err or "Unknown error"), vim.log.levels.ERROR)
        return false
      end
    end,
    on_edit_note = function(bookmark)
      -- Switch to insert mode before showing input
      local original_mode = vim.fn.mode()
      if original_mode ~= 'i' then
        vim.cmd('startinsert')
      end
      
      vim.ui.input({
        prompt = "Edit note: ",
        default = bookmark.note or "",
      }, function(new_note)
        -- Return to normal mode after input
        if vim.fn.mode() == 'i' then
          vim.cmd('stopinsert')
        end
        
        if new_note ~= nil then
          bookmark.note = new_note
          bookmark.updated_at = os.time()
          
          local success, err = M._db:update_bookmark(project_id, bookmark.file_path, bookmark)
          if success then
            vim.notify("Updated bookmark note", vim.log.levels.INFO)
            return true
          else
            vim.notify("Failed to update note: " .. (err or "Unknown error"), vim.log.levels.ERROR)
            return false
          end
        end
      end)
    end
  })
end

--- Search bookmarks across all projects
function M.search_all_bookmarks()
  if not M._db then
    vim.notify("Project bookmarks not initialized. Run :BookmarkInfo to debug.", vim.log.levels.ERROR)
    return
  end
  
  local all_bookmarks = M._db:get_all_projects_bookmarks()
  if not all_bookmarks or vim.tbl_isempty(all_bookmarks) then
    vim.notify("No bookmarks found", vim.log.levels.INFO)
    return
  end
  
  local picker = require("personal-plugins.project-bookmarks-picker")
  picker.show_all_bookmarks(all_bookmarks, {
    on_select = function(bookmark)
      vim.cmd("edit " .. vim.fn.fnameescape(bookmark.file_path))
      if bookmark.line_number and bookmark.line_number > 0 then
        vim.fn.cursor(bookmark.line_number, 1)
      end
    end
  })
end

--- Get current project info for debugging
function M.get_project_info()
  local project_root = M._get_project_root()
  local project_id = M._get_project_id(project_root)
  local bookmarks = M._db:get_all_bookmarks(project_id)
  local count = bookmarks and vim.tbl_count(bookmarks) or 0
  
  print("Project Info:")
  print("  Root: " .. project_root)
  print("  ID: " .. project_id)
  print("  Bookmarks: " .. count)
end

--- Create user commands
function M._create_user_commands()
  vim.api.nvim_create_user_command("BookmarkAdd", function(opts)
    M.add_bookmark(opts.args ~= "" and opts.args or nil)
  end, {
    nargs = "?",
    desc = "Add bookmark for current file with optional note"
  })
  
  vim.api.nvim_create_user_command("BookmarkRemove", function()
    M.remove_bookmark()
  end, {
    desc = "Remove bookmark for current file"
  })
  
  vim.api.nvim_create_user_command("BookmarkEditNote", function()
    M.edit_bookmark_note()
  end, {
    desc = "Edit note for current file's bookmark"
  })
  
  vim.api.nvim_create_user_command("BookmarkSearch", function()
    M.search_bookmarks()
  end, {
    desc = "Search bookmarks in current project"
  })
  
  vim.api.nvim_create_user_command("BookmarkSearchAll", function()
    M.search_all_bookmarks()
  end, {
    desc = "Search bookmarks across all projects"
  })
  
  vim.api.nvim_create_user_command("BookmarkInfo", function()
    M.get_project_info()
  end, {
    desc = "Show current project bookmark info"
  })
end

return M
