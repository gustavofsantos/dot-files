return {
  "nickkadutskyi/jb.nvim",
  lazy = false,
  priority = 1000,
  opts = {},
  config = function()
    require("jb").setup({
      integrations = {
        ghostty = true,
      },
    })

  end,
}
