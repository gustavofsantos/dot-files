local bookmarks = require("personal-plugins.project-bookmarks")
local cmd = require("personal-plugins.cmd_palette")
bookmarks.setup({
  max_recent_searches = 10,
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
  keymap = "<leader>;a" }

cmd.add {
  name = "Search project bookmarks",
  cmd = bookmarks.search_bookmarks,
  category = cmd.categories.navigation,
  icon = "",
  keymap = "<leader>;s" }

cmd.add {
  name = "Search all bookmarks",
  cmd = bookmarks.search_all_bookmarks,
  category = cmd.categories.navigation,
  keymap = "<leader>;g" }
