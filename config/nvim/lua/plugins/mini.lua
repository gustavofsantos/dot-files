return {
  { "echasnovski/mini.ai", version = '*', event = "BufRead", opts = {} },
  {
    "echasnovski/mini.bracketed",
    version = '*',
    event = "BufRead",
    opts = {
      diagnostic = { options = { severity = vim.diagnostic.severity.ERROR } },
    }
  },
  {
    "echasnovski/mini.hipatterns",
    event = "BufRead",
    config = function()
      local hipatterns = require("mini.hipatterns")
      hipatterns.setup({
        highlighters = {
          hex_color = hipatterns.gen_highlighter.hex_color(),
        },
      })
    end,
  },
}
