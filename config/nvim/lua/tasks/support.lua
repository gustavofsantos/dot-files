local M  = {}

function M.get_selected_text()
  local is_visual_mode = vim.fn.mode() == 'v' or vim.fn.mode() == 'V'
  if is_visual_mode then
    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")
    local start_line, start_col = start_pos[2], start_pos[3]
    local end_line, end_col = end_pos[2], end_pos[3]
    local lines = vim.fn.getline(start_line, end_line)

    if #lines == 0 then
      return nil
    end

    -- Adjust the columns for the first and last line
    if #lines == 1 then
      lines[1] = lines[1]:sub(start_col, end_col)
    else
      lines[1] = lines[1]:sub(start_col)
      lines[#lines] = lines[#lines]:sub(1, end_col)
    end

    return table.concat(lines, "\n")
  end
  return nil
end

function M.get_params()
  return {
    file = vim.fn.expand("%"),
    file_path = vim.fn.expand("%:p"),
    file_name = vim.fn.expand("%:t"),
    file_ext = vim.fn.expand("%:e"),
    file_dir = vim.fn.expand("%:p:h"),
    file_relative_path = vim.fn.expand("%:~:."),
    cwd = vim.fn.getcwd(),
    is_visual_mode = vim.fn.mode() == 'v' or vim.fn.mode() == 'V',
    selected_text = M.get_selected_text()
  }
end

return M
