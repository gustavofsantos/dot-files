local M = {}

M.jump_to_declaration = vim.lsp.buf.definition
M.jump_to_implementation = vim.lsp.buf.implementation
M.hover = vim.lsp.buf.hover
M.rename_symbol = vim.lsp.buf.rename
M.references = vim.lsp.buf.references
M.code_action = vim.lsp.buf.code_action
M.hover = function()
  vim.lsp.buf.hover()
end

return M
