return {
  "stevearc/overseer.nvim",
  event = "VeryLazy",
  config = function()
    local overseer = require("overseer")
    local overseer_constants = require("overseer.constants")
    local register_tasks = require("tasks")

    local STATUS = overseer_constants.STATUS

    overseer.setup({
      dap = false,
      actions = {
        ["wtf"] = {
          desc = "What the fuck did happen?",
          condition = function(task)
            return task.status == STATUS.FAILURE
          end,
          run = function(task)
            local bufnr = task.strategy.bufnr
            local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
            local output = ""
            for _, line in ipairs(lines) do
              output = output .. "\n" .. line
            end

            local prompt =
            "A problem has occurred in the terminal and I don't know why. Your role is to get a simple description about the problem."
            prompt = prompt .. "\n\n"
            prompt = prompt .. "<output>\n"
            prompt = prompt .. output
            prompt = prompt .. "\n"
            prompt = prompt .. "</output>\n"

            require("avante.api").ask({ question = prompt })
          end
        },
        task_list = {
          bindings = {
            ["W"] = "<cmd>OverseerQuickAction wtf<cr>"
          }
        }
      }
    })

    register_tasks(overseer)

    vim.api.nvim_create_user_command("OverseerRestartLast", function()
      local overseer = require("overseer")
      local tasks = overseer.list_tasks({ recent_first = true })
      if vim.tbl_isempty(tasks) then
        vim.notify("No tasks found", vim.log.levels.WARN)
      else
        overseer.run_action(tasks[1], "restart")
      end
    end, {})
  end,
}
