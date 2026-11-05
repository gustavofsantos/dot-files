-- snacks.image runs a hardcoded `mmdc` for Mermaid. shims/mmdc speaks mmdc's flags and renders
-- with bin/pele (Pele + resvg). It is on Neovim's PATH only, so the real mmdc stays untouched
-- everywhere else. Delete this line to go back to mmdc.
vim.env.PATH = vim.fn.stdpath("config") .. "/shims:" .. vim.env.PATH

require("snacks").setup({
  ---@class snacks.image.Config
  ---@field enabled? boolean enable image viewer
  ---@field wo? vim.wo|{} options for windows showing the image
  ---@field bo? vim.bo|{} options for the image buffer
  ---@field formats? string[]
  --- Resolves a reference to an image with src in a file (currently markdown only).
  --- Return the absolute path or url to the image.
  --- When `nil`, the path is resolved relative to the file.
  ---@field resolve? fun(file: string, src: string): string?
  ---@field convert? snacks.image.convert.Config
  image = {
    doc = {
      max_width = 120,
    }
  }
})
