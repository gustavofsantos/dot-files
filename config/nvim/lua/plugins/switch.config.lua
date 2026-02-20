return {
  "AndrewRadev/switch.vim",
  cmd = { "Switch" },
  keys = {
    { "<leader>ss", "<cmd>Switch<CR>", desc = "Switch" }
  },
  config = function()
    vim.cmd([[let g:switch_custom_definitions =
          \ [
          \   {
          \     '^\(.*\)TODO\(.*\)$': '\1DOING\2',
          \     '^\(.*\)DOING\(.*\)$': '\1DONE\2',
          \     '^\(.*\)DONE\(.*\)$': '\1TODO\2',
          \     '^\(.*\)\[ \]\(.*\)$': '\1\[/\]\2',
          \     '^\(.*\)\[/\]\(.*\)$': '\1\[x\]\2',
          \     '^\(.*\)\[x\]\(.*\)$': '\1\[ \]\2',
          \     ':ok': ':fail',
          \     ':fail': ':ok',
          \     'it': 'fit',
          \     'fit': 'xit',
          \     'xit': 'it',
          \     'true': 'false',
          \     'false': 'true',
          \     'True': 'False',
          \     'False': 'True',
          \   }
          \ ]
      ]])
  end,
}
