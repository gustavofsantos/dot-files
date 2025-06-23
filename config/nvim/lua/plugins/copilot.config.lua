local utils = require("utils")

return {
  "zbirenbaum/copilot.lua",
  cmd = "Copilot",
  event = "InsertEnter",
  enabled = utils.is_copilot_enabled,
  config = function()
    require("copilot").setup({
      filetypes = {
        lua = true,
        shell = true,
        sh = true,
        python = true,
        html = true,
        sql = true,
        javascript = true,
        javascriptreact = true,
        typescript = true,
        typescriptreact = true,
        ["*"] = false,
      },
      suggestion = { enabled = false },
      panel = { enabled = false },
      copilot_node_command = utils.is_copilot_enabled() and vim.fn.expand("$HOME") .. "/.nix-profile/bin/node" or nil,
    })
  end,
}
