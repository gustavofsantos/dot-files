--- Telescope picker for Project Bookmarks
--- Custom picker that searches both file paths and notes with preview
local M = {}

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local previewers = require("telescope.previewers")

--- Format timestamp for display
--- @param timestamp number Unix timestamp
--- @return string formatted_time
local function format_time(timestamp)
  if not timestamp or timestamp == 0 then
    return "unknown"
  end
  return os.date("%Y-%m-%d %H:%M", timestamp)
end

--- Create entry maker for bookmarks
--- @param project_root? string Current project root for relative path display
--- @return function entry_maker
local function create_entry_maker(project_root)
  return function(bookmark)
    local display_path = bookmark.relative_path or bookmark.file_path

    -- If we're searching all projects, show project info
    if not project_root and bookmark.project_id then
      local project_name = bookmark.project_id:match("^(.+)_[^_]+$") or bookmark.project_id
      display_path = "[" .. project_name .. "] " .. display_path
    end

    local note_preview = bookmark.note or ""
    if #note_preview > 50 then
      note_preview = note_preview:sub(1, 47) .. "..."
    end

    local display_line = display_path
    if note_preview ~= "" then
      display_line = display_line .. " │ " .. note_preview
    end
    display_line = display_line .. " │ " .. format_time(bookmark.updated_at)

    return {
      value = bookmark,
      display = display_line,
      ordinal = display_path .. " " .. (bookmark.note or ""),
      path = bookmark.file_path,
      lnum = bookmark.line_number or 1,
    }
  end
end

--- Create custom previewer for bookmarks
--- @return table previewer
local function create_bookmark_previewer()
  return previewers.new_buffer_previewer({
    title = "Bookmark Preview",
    define_preview = function(self, entry, status)
      local bookmark = entry.value

      -- Show file content with line highlight
      if vim.fn.filereadable(bookmark.file_path) == 1 then
        conf.buffer_previewer_maker(bookmark.file_path, self.state.bufnr, {
          bufname = self.state.bufname,
          winid = self.state.winid,
          preview = {
            msg = bookmark.relative_path or bookmark.file_path,
          },
        })

        -- Highlight the bookmarked line with proper bounds checking
        if bookmark.line_number and bookmark.line_number > 0 then
          vim.schedule(function()
            -- Check if window and buffer are still valid
            if not vim.api.nvim_win_is_valid(self.state.winid) or not vim.api.nvim_buf_is_valid(self.state.bufnr) then
              return
            end

            -- Get the total number of lines in the buffer
            local line_count = vim.api.nvim_buf_line_count(self.state.bufnr)
            local target_line = math.min(bookmark.line_number, line_count)

            if target_line > 0 and target_line <= line_count then
              -- Set cursor position safely
              local ok, _ = pcall(vim.api.nvim_win_set_cursor, self.state.winid, { target_line, 0 })
              if ok then
                -- Add highlight if cursor was set successfully
                vim.api.nvim_buf_add_highlight(
                  self.state.bufnr,
                  -1,
                  "TelescopePreviewLine",
                  target_line - 1,
                  0,
                  -1
                )
              end
            end
          end)
        end
      else
        -- File doesn't exist, show bookmark info
        local lines = {
          "File: " .. bookmark.file_path,
          "Status: File not found",
          "",
          "Bookmark Info:",
          "  Created: " .. format_time(bookmark.created_at),
          "  Updated: " .. format_time(bookmark.updated_at),
          "  Line: " .. (bookmark.line_number or "unknown"),
          "",
        }

        if bookmark.note and bookmark.note ~= "" then
          table.insert(lines, "Note:")
          -- Split note into multiple lines if needed
          for line in bookmark.note:gmatch("[^\\n]+") do
            table.insert(lines, "  " .. line)
          end
        end

        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
        vim.api.nvim_buf_set_option(self.state.bufnr, "filetype", "")
      end
    end,
  })
end

--- Show bookmarks for current project
--- @param bookmarks table Hash table of bookmarks
--- @param project_root string Project root path
--- @param opts table Options with callbacks
function M.show_bookmarks(bookmarks, project_root, opts)
  opts = opts or {}

  -- Convert hash table to array
  local bookmark_list = {}
  for _, bookmark in pairs(bookmarks) do
    table.insert(bookmark_list, bookmark)
  end

  -- Sort by updated time (most recent first)
  table.sort(bookmark_list, function(a, b)
    return (a.updated_at or 0) > (b.updated_at or 0)
  end)

  -- Use ivy theme for consistency
  local theme_opts = require("telescope.themes").get_ivy({
    layout_config = {
      height = 0.4,
    },
  })

  pickers
      .new(vim.tbl_extend("force", theme_opts, opts), {
        prompt_title = "Project Bookmarks",
        finder = finders.new_table({
          results = bookmark_list,
          entry_maker = create_entry_maker(project_root),
        }),
        sorter = conf.generic_sorter(opts),
        previewer = create_bookmark_previewer(),
        attach_mappings = function(prompt_bufnr, map)
          -- Default action: open file
          actions.select_default:replace(function()
            local entry = action_state.get_selected_entry()
            actions.close(prompt_bufnr)
            if opts.on_select then
              opts.on_select(entry.value)
            end
          end)

          -- Delete bookmark
          map("i", "<C-d>", function()
            local entry = action_state.get_selected_entry()
            if entry and opts.on_delete then
              local success = opts.on_delete(entry.value)
              if success then
                -- Refresh the picker
                local current_picker = action_state.get_current_picker(prompt_bufnr)
                current_picker:refresh(finders.new_table({
                  results = vim.tbl_filter(function(bookmark)
                    return bookmark.file_path ~= entry.value.file_path
                  end, bookmark_list),
                  entry_maker = create_entry_maker(project_root),
                }))
              end
            end
          end)

          -- Edit note
          map("i", "<C-e>", function()
            local entry = action_state.get_selected_entry()
            if entry and opts.on_edit_note then
              actions.close(prompt_bufnr)
              opts.on_edit_note(entry.value)
            end
          end)

          return true
        end,
      })
      :find()
end

--- Show bookmarks from all projects
--- @param all_bookmarks table Array of all bookmarks
--- @param opts table Options with callbacks
function M.show_all_bookmarks(all_bookmarks, opts)
  opts = opts or {}

  -- Sort by updated time (most recent first)
  table.sort(all_bookmarks, function(a, b)
    return (a.updated_at or 0) > (b.updated_at or 0)
  end)

  -- Use ivy theme for consistency
  local theme_opts = require("telescope.themes").get_ivy({
    layout_config = {
      height = 0.4,
    },
  })

  pickers
      .new(vim.tbl_extend("force", theme_opts, opts), {
        prompt_title = "All Bookmarks",
        finder = finders.new_table({
          results = all_bookmarks,
          entry_maker = create_entry_maker(), -- No project root for global search
        }),
        sorter = conf.generic_sorter(opts),
        previewer = create_bookmark_previewer(),
        attach_mappings = function(prompt_bufnr, map)
          -- Default action: open file
          actions.select_default:replace(function()
            local entry = action_state.get_selected_entry()
            actions.close(prompt_bufnr)
            if opts.on_select then
              opts.on_select(entry.value)
            end
          end)

          return true
        end,
      })
      :find()
end

--- Show recent bookmarks (across all projects, limited number)
--- @param all_bookmarks table Array of all bookmarks
--- @param limit number Maximum number of recent bookmarks to show
--- @param opts table Options with callbacks
function M.show_recent_bookmarks(all_bookmarks, limit, opts)
  opts = opts or {}
  limit = limit or 20

  -- Sort by updated time and take only the most recent
  table.sort(all_bookmarks, function(a, b)
    return (a.updated_at or 0) > (b.updated_at or 0)
  end)

  local recent_bookmarks = {}
  for i = 1, math.min(limit, #all_bookmarks) do
    table.insert(recent_bookmarks, all_bookmarks[i])
  end

  -- Use ivy theme for consistency
  local theme_opts = require("telescope.themes").get_ivy({
    layout_config = {
      height = 0.4,
    },
  })

  pickers
      .new(vim.tbl_extend("force", theme_opts, opts), {
        prompt_title = string.format("Recent Bookmarks (Top %d)", #recent_bookmarks),
        finder = finders.new_table({
          results = recent_bookmarks,
          entry_maker = create_entry_maker(),
        }),
        sorter = conf.generic_sorter(opts),
        previewer = create_bookmark_previewer(),
        attach_mappings = function(prompt_bufnr, map)
          actions.select_default:replace(function()
            local entry = action_state.get_selected_entry()
            actions.close(prompt_bufnr)
            if opts.on_select then
              opts.on_select(entry.value)
            end
          end)

          return true
        end,
      })
      :find()
end

return M
