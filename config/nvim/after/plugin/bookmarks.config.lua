local bookmarks = require("personal-plugins.project-bookmarks")
local cmd = require("personal-plugins.cmd_palette")
bookmarks.setup({
  -- You can customize these settings:
  -- data_dir = vim.fn.stdpath("data") .. "/project-bookmarks",
  -- project_identification = "git_root", -- "git_root", "cwd", or function
  -- max_recent_searches = 10,
})

cmd.add {
  name = "Bookmark current file",
  cmd = function() 
    vim.ui.input({ prompt = "Note (optional): " }, function(note)
      if note ~= nil then -- User didn't cancel
        bookmarks.add_bookmark(note ~= "" and note or nil)
      end
    end)
  end,
  category = cmd.categories.navigation,
  icon = "",
  keymap = "<leader>Ba" }

cmd.add {
  name = "Remove bookmark",
  cmd = bookmarks.remove_bookmark,
  category = cmd.categories.navigation,
  icon = "",
  predicate = bookmarks.is_current_file_bookmarked,
  keymap = "<leader>Br" }

cmd.add {
  name = "Edit bookmark note",
  cmd = bookmarks.edit_bookmark_note,
  category = cmd.categories.navigation,
  icon = "󰏫",
  predicate = bookmarks.is_current_file_bookmarked }

cmd.add {
  name = "Search project bookmarks",
  cmd = bookmarks.search_bookmarks,
  category = cmd.categories.navigation,
  icon = "",
  keymap = "<leader>Bs" }

cmd.add {
  name = "Search all bookmarks",
  cmd = bookmarks.search_all_bookmarks,
  category = cmd.categories.navigation,
  icon = "" }

cmd.add {
  name = "Show project info",
  cmd = bookmarks.get_project_info,
  category = cmd.categories.navigation,
  icon = "" }

