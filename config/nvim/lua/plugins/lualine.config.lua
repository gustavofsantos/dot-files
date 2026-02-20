return {
  'nvim-lualine/lualine.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  opts = {
    sections = {
      lualine_a = { 'mode' },
      lualine_b = { 'diagnostics' },
      lualine_c = { { 'filename', path = 1 } },
      lualine_x = { 'overseer' },
      lualine_y = { 'location' },
      lualine_z = {}
    },
    inactive_sections = {
      lualine_a = {},
      lualine_b = {},
      lualine_c = { 'filename' },
      lualine_x = { 'overseer', 'location' },
      lualine_y = {},
      lualine_z = {}
    },
    extensions = {
      'fugitive',
      'lazy',
      'oil',
      'overseer',
      'quickfix',
      'toggleterm'
    }
  }
}
