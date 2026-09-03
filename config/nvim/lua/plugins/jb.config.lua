return {
  "nickkadutskyi/jb.nvim",
  lazy = false,
  enabled = false,
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
