return {
  "akinsho/toggleterm.nvim",
  dependencies = {},
  enabled = false,
  version = "*",
  event = "BufEnter",
  config = function()
    require("toggleterm").setup({
      size = function(term)
        if term.direction == "horizontal" then
          return 15
        elseif term.direction == "vertical" then
          return vim.o.columns * 0.5
        end
      end,
      open_mapping = [[<c-t>]],
      insert_mappings = true,
      terminal_mappings = true,
      persist_size = true,
      persist_mode = true,
      shade_terminals = true,
      start_in_insert = true,
    })
  end,
}
