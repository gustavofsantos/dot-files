return {
  "miikanissi/modus-themes.nvim",
  priority = 1000,
  config = function()
    require("modus-themes").setup()
    vim.cmd.colorscheme("modus")
  end
}
