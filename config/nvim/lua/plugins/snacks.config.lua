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
