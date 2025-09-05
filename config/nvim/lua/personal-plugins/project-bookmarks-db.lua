--- Database helper for Project Bookmarks
--- Handles JSON file operations for storing bookmarks per project
---
--- @class ProjectBookmarksDB
--- @field private _config table Plugin configuration
--- @field private _cache table In-memory cache of loaded projects
local M = {}

--- Create new database instance
--- @param config table Plugin configuration
--- @return ProjectBookmarksDB
function M.new(config)
  local db = {
    _config = config,
    _cache = {},
  }
  setmetatable(db, { __index = M })
  return db
end

--- Get the database file path for a project
--- @param project_id string Project identifier
--- @return string file_path
function M:_get_db_file_path(project_id)
  return self._config.data_dir .. "/" .. project_id .. ".json"
end

--- Load project database from disk
--- @param project_id string Project identifier
--- @return table? bookmarks Table of bookmarks or nil on error
--- @return string? error_message
function M:_load_project_db(project_id)
  local file_path = self:_get_db_file_path(project_id)
  
  -- Check if file exists
  local file = io.open(file_path, "r")
  if not file then
    -- File doesn't exist, return empty table
    return {}
  end
  
  local content = file:read("*all")
  file:close()
  
  if not content or content == "" then
    return {}
  end
  
  -- Parse JSON
  local success, result = pcall(vim.json.decode, content)
  if not success then
    return nil, "Failed to parse JSON from " .. file_path .. ": " .. tostring(result)
  end
  
  return result
end

--- Save project database to disk
--- @param project_id string Project identifier
--- @param bookmarks table Table of bookmarks
--- @return boolean success
--- @return string? error_message
function M:_save_project_db(project_id, bookmarks)
  local file_path = self:_get_db_file_path(project_id)
  
  -- Encode to JSON
  local success, json_content = pcall(vim.json.encode, bookmarks)
  if not success then
    return false, "Failed to encode bookmarks to JSON: " .. tostring(json_content)
  end
  
  -- Write to file
  local file = io.open(file_path, "w")
  if not file then
    return false, "Failed to open file for writing: " .. file_path
  end
  
  file:write(json_content)
  file:close()
  
  -- Update cache
  self._cache[project_id] = bookmarks
  
  return true
end

--- Get project bookmarks (from cache or disk)
--- @param project_id string Project identifier
--- @return table? bookmarks Table of bookmarks or nil on error
--- @return string? error_message
function M:_get_project_bookmarks(project_id)
  -- Check cache first
  if self._cache[project_id] then
    return self._cache[project_id]
  end
  
  -- Load from disk
  local bookmarks, err = self:_load_project_db(project_id)
  if not bookmarks then
    return nil, err
  end
  
  -- Cache the result
  self._cache[project_id] = bookmarks
  
  return bookmarks
end

--- Add a bookmark
--- @param project_id string Project identifier
--- @param file_path string Full file path (used as key)
--- @param bookmark table Bookmark data
--- @return boolean success
--- @return string? error_message
function M:add_bookmark(project_id, file_path, bookmark)
  local bookmarks, err = self:_get_project_bookmarks(project_id)
  if not bookmarks then
    return false, err
  end
  
  -- Add or update bookmark
  bookmarks[file_path] = bookmark
  
  -- Save to disk
  return self:_save_project_db(project_id, bookmarks)
end

--- Remove a bookmark
--- @param project_id string Project identifier
--- @param file_path string Full file path
--- @return boolean success
--- @return string? error_message
function M:remove_bookmark(project_id, file_path)
  local bookmarks, err = self:_get_project_bookmarks(project_id)
  if not bookmarks then
    return false, err
  end
  
  if not bookmarks[file_path] then
    return false, "Bookmark not found"
  end
  
  -- Remove bookmark
  bookmarks[file_path] = nil
  
  -- Save to disk
  return self:_save_project_db(project_id, bookmarks)
end

--- Update a bookmark
--- @param project_id string Project identifier
--- @param file_path string Full file path
--- @param bookmark table Updated bookmark data
--- @return boolean success
--- @return string? error_message
function M:update_bookmark(project_id, file_path, bookmark)
  local bookmarks, err = self:_get_project_bookmarks(project_id)
  if not bookmarks then
    return false, err
  end
  
  if not bookmarks[file_path] then
    return false, "Bookmark not found"
  end
  
  -- Update bookmark
  bookmarks[file_path] = bookmark
  
  -- Save to disk
  return self:_save_project_db(project_id, bookmarks)
end

--- Get a specific bookmark
--- @param project_id string Project identifier
--- @param file_path string Full file path
--- @return table? bookmark Bookmark data or nil if not found
function M:get_bookmark(project_id, file_path)
  local bookmarks, err = self:_get_project_bookmarks(project_id)
  if not bookmarks then
    vim.notify("Database error: " .. (err or "Unknown error"), vim.log.levels.ERROR)
    return nil
  end
  
  return bookmarks[file_path]
end

--- Get all bookmarks for a project
--- @param project_id string Project identifier
--- @return table? bookmarks Table of all bookmarks or nil on error
function M:get_all_bookmarks(project_id)
  local bookmarks, err = self:_get_project_bookmarks(project_id)
  if not bookmarks then
    vim.notify("Database error: " .. (err or "Unknown error"), vim.log.levels.ERROR)
    return nil
  end
  
  return bookmarks
end

--- Get all bookmarks from all projects
--- @return table all_bookmarks Array of all bookmarks with project info
function M:get_all_projects_bookmarks()
  local all_bookmarks = {}
  
  -- Get all JSON files in the data directory
  local data_dir = self._config.data_dir
  local handle = vim.loop.fs_scandir(data_dir)
  
  if not handle then
    return all_bookmarks
  end
  
  while true do
    local name, type = vim.loop.fs_scandir_next(handle)
    if not name then
      break
    end
    
    -- Process JSON files
    if type == "file" and vim.endswith(name, ".json") then
      local project_id = name:sub(1, -6) -- Remove .json extension
      local bookmarks = self:_get_project_bookmarks(project_id)
      
      if bookmarks then
        -- Convert hash table to array and add project info
        for file_path, bookmark in pairs(bookmarks) do
          table.insert(all_bookmarks, vim.tbl_extend("force", bookmark, {
            project_id = project_id,
          }))
        end
      end
    end
  end
  
  -- Sort by updated_at (most recent first)
  table.sort(all_bookmarks, function(a, b)
    return (a.updated_at or 0) > (b.updated_at or 0)
  end)
  
  return all_bookmarks
end

--- Clean up invalid bookmarks (files that no longer exist)
--- @param project_id string Project identifier
--- @return number count Number of cleaned bookmarks
function M:cleanup_project(project_id)
  local bookmarks, err = self:_get_project_bookmarks(project_id)
  if not bookmarks then
    vim.notify("Database error: " .. (err or "Unknown error"), vim.log.levels.ERROR)
    return 0
  end
  
  local cleaned_count = 0
  local valid_bookmarks = {}
  
  for file_path, bookmark in pairs(bookmarks) do
    -- Check if file exists
    local stat = vim.loop.fs_stat(file_path)
    if stat and stat.type == "file" then
      valid_bookmarks[file_path] = bookmark
    else
      cleaned_count = cleaned_count + 1
    end
  end
  
  if cleaned_count > 0 then
    self:_save_project_db(project_id, valid_bookmarks)
  end
  
  return cleaned_count
end

--- Get database statistics
--- @return table stats Database statistics
function M:get_stats()
  local stats = {
    total_projects = 0,
    total_bookmarks = 0,
    projects = {},
  }
  
  -- Scan data directory
  local data_dir = self._config.data_dir
  local handle = vim.loop.fs_scandir(data_dir)
  
  if not handle then
    return stats
  end
  
  while true do
    local name, type = vim.loop.fs_scandir_next(handle)
    if not name then
      break
    end
    
    if type == "file" and vim.endswith(name, ".json") then
      local project_id = name:sub(1, -6)
      local bookmarks = self:_get_project_bookmarks(project_id)
      
      if bookmarks then
        local bookmark_count = vim.tbl_count(bookmarks)
        stats.total_projects = stats.total_projects + 1
        stats.total_bookmarks = stats.total_bookmarks + bookmark_count
        
        stats.projects[project_id] = {
          bookmark_count = bookmark_count,
          file_path = self:_get_db_file_path(project_id),
        }
      end
    end
  end
  
  return stats
end

return M
