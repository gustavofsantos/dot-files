local function gh(repo)
  return "https://github.com/" .. repo
end

-- Build steps. Registered before the first vim.pack.add so they also run on install.
vim.api.nvim_create_autocmd("PackChanged", {
  callback = function(ev)
    local name, kind = ev.data.spec.name, ev.data.kind
    if kind ~= "install" and kind ~= "update" then
      return
    end

    if name == "telescope-fzf-native.nvim" then
      vim.system({ "make" }, { cwd = ev.data.path })
    elseif name == "nvim-treesitter" then
      -- On install the plugin is not loaded yet; wait until startup is done.
      vim.schedule(function()
        vim.cmd("TSUpdate")
      end)
    end
  end,
})

vim.pack.add({
  gh("nvim-lua/plenary.nvim"),
  gh("nvim-tree/nvim-web-devicons"),
  gh("christoomey/vim-tmux-runner"),
  gh("tpope/vim-sleuth"),
  gh("tpope/vim-surround"),
  gh("tpope/vim-repeat"),
  gh("tpope/vim-dotenv"),
  gh("tpope/vim-fugitive"),
  gh("tpope/vim-rhubarb"),
  gh("mbbill/undotree"),

  gh("nvim-mini/mini.icons"),
  gh("onsails/lspkind.nvim"),
  { src = gh("saghen/blink.cmp"), version = vim.version.range("1.*") },
  gh("windwp/nvim-autopairs"),
  gh("numToStr/Comment.nvim"),
  gh("stevearc/conform.nvim"),
  gh("hat0uma/csvview.nvim"),
  gh("sindrets/diffview.nvim"),
  gh("folke/flash.nvim"),
  gh("lewis6991/gitsigns.nvim"),
  { src = gh("ThePrimeagen/harpoon"), version = "harpoon2" },
  gh("mfussenegger/nvim-lint"),
  gh("williamboman/mason.nvim"),
  gh("williamboman/mason-lspconfig.nvim"),
  gh("neovim/nvim-lspconfig"),
  gh("nvim-lualine/lualine.nvim"),
  { src = gh("echasnovski/mini.ai"), version = vim.version.range("*") },
  gh("echasnovski/mini.hipatterns"),
  gh("numToStr/Navigator.nvim"),
  gh("stevearc/oil.nvim"),
  gh("stevearc/overseer.nvim"),
  gh("stevearc/quicker.nvim"),
  gh("AndrewRadev/switch.vim"),
  { src = gh("nvim-telescope/telescope.nvim"), version = "v0.2.0" },
  gh("nvim-telescope/telescope-symbols.nvim"),
  gh("nvim-telescope/telescope-fzf-native.nvim"),
  gh("kkharji/sqlite.lua"),
  gh("prochri/telescope-all-recent.nvim"),
  { src = gh("akinsho/toggleterm.nvim"), version = vim.version.range("*") },
  { src = gh("nvim-treesitter/nvim-treesitter"), version = "main" },
  gh("vim-test/vim-test"),
  gh("folke/which-key.nvim"),
}, { load = true })

-- Installed now, loaded on demand from after/ftplugin/ (see utils.packadd).
vim.pack.add({
  gh("Olical/conjure"),
  gh("guns/vim-sexp"),
  gh("tpope/vim-sexp-mappings-for-regular-people"),
  gh("julienvincent/nvim-paredit"),
  gh("folke/lazydev.nvim"),
}, { load = function() end })

-- Plugin configs. Loaded by path: names like mini.ai.lua do not map to require().
local dir = vim.fn.stdpath("config") .. "/lua/plugins"
for _, file in ipairs(vim.fn.readdir(dir)) do
  if file:match("%.lua$") then
    dofile(dir .. "/" .. file)
  end
end
