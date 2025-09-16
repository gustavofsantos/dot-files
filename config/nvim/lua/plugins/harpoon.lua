return {
  "ThePrimeagen/harpoon",
  branch = "harpoon2",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    local harpoon = require("harpoon")
    harpoon:setup()

    vim.keymap.set("n", "<leader>a", function() harpoon:list():add() end, { desc = "Harpoon file" })
    vim.keymap.set("n", "<leader>1", function() harpoon:list():select(1) end, { desc = "Navigate first" })
    vim.keymap.set("n", "<leader>2", function() harpoon:list():select(2) end, { desc = "Navigate second" })
    vim.keymap.set("n", "<leader>3", function() harpoon:list():select(3) end, { desc = "Navigate third" })
    vim.keymap.set("n", "<leader>4", function() harpoon:list():select(4) end, { desc = "Navigate fourth" })

    vim.keymap.set("n", "<C-e>", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end)

    vim.keymap.set("n", "<C-S-P>", function() harpoon:list():prev() end)
    vim.keymap.set("n", "<C-S-N>", function() harpoon:list():next() end)
  end
}
