--- Telescope picker for pending Agent Comments: navigate to them, edit their
--- text, or delete them individually, all without touching :AgentCommentsClear.
local M = {}

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local previewers = require("telescope.previewers")

--- @param comment AgentComment
--- @return string range
local function format_range(comment)
  if comment.start_line == comment.end_line then
    return tostring(comment.start_line)
  end
  return comment.start_line .. "-" .. comment.end_line
end

--- @return function entry_maker
local function create_entry_maker()
  return function(comment)
    local range = format_range(comment)
    local first_line = vim.split(comment.text, "\n", { plain = true })[1] or ""
    if #first_line > 60 then
      first_line = first_line:sub(1, 57) .. "..."
    end

    return {
      value = comment,
      display = string.format("%s:%s │ %s", comment.relpath, range, first_line),
      ordinal = comment.relpath .. " " .. comment.text,
      path = comment.filepath,
      lnum = comment.start_line,
    }
  end
end

--- Preview showing the comment text alongside the code it was left on.
--- @return table previewer
local function create_comment_previewer()
  return previewers.new_buffer_previewer({
    title = "Agent Comment",
    define_preview = function(self, entry)
      local c = entry.value
      local lines = { c.relpath .. ":" .. format_range(c), "" }
      for _, line in ipairs(vim.split(c.text, "\n", { plain = true })) do
        table.insert(lines, "> " .. line)
      end
      table.insert(lines, "")
      table.insert(lines, "```" .. (c.filetype or ""))
      vim.list_extend(lines, c.code_lines)
      table.insert(lines, "```")

      vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
      vim.bo[self.state.bufnr].filetype = "markdown"
    end,
  })
end

--- Show a picker over the given comments.
--- @param comments AgentComment[]
--- @param opts table with on_select(comment), on_delete(comment), on_edit(comment)
function M.show(comments, opts)
  opts = opts or {}

  local theme_opts = require("telescope.themes").get_ivy({
    layout_config = { height = 0.4 },
  })

  pickers
      .new(vim.tbl_extend("force", theme_opts, opts), {
        prompt_title = string.format("Agent Comments (%d)", #comments),
        finder = finders.new_table({
          results = comments,
          entry_maker = create_entry_maker(),
        }),
        sorter = conf.generic_sorter(opts),
        previewer = create_comment_previewer(),
        attach_mappings = function(prompt_bufnr, map)
          actions.select_default:replace(function()
            local entry = action_state.get_selected_entry()
            actions.close(prompt_bufnr)
            if entry and opts.on_select then
              opts.on_select(entry.value)
            end
          end)

          map({ "i", "n" }, "<C-d>", function()
            local entry = action_state.get_selected_entry()
            if not entry or not opts.on_delete then
              return
            end
            opts.on_delete(entry.value)

            local current_picker = action_state.get_current_picker(prompt_bufnr)
            local remaining = vim.tbl_filter(function(c)
              return c.id ~= entry.value.id
            end, comments)
            comments = remaining
            if #remaining == 0 then
              actions.close(prompt_bufnr)
              return
            end
            current_picker:refresh(finders.new_table({
              results = remaining,
              entry_maker = create_entry_maker(),
            }))
          end)

          map({ "i", "n" }, "<C-e>", function()
            local entry = action_state.get_selected_entry()
            if entry and opts.on_edit then
              actions.close(prompt_bufnr)
              opts.on_edit(entry.value)
            end
          end)

          return true
        end,
      })
      :find()
end

return M
