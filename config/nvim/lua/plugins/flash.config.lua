return {
  "folke/flash.nvim",
  event = "VeryLazy",
  ---@type Flash.Config
  opts = {},
  keys = {
    { "s", function() require("flash").jump() end,       desc = "Flash",            mode = { "n", "x", "o" }, noremap = true, silent = true },
    { "S", function() require("flash").treesitter() end, desc = "Flash Treesitter", mode = { "n", "x", "o" }, noremap = true, silent = true },
  }
}
