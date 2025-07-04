local cmd_palette = require("cmd_palette")

local M = {}

---Register a command
---@param params table
function M.register_cmd(params)
  cmd_palette.add(params)
end

---Populates the command list
function M.populate()
  M.register_cmd({
    name = "Say Hello",
    cmd = function()
      print("Hello from the command palette!")
    end,
    category = "action",
  })

  M.register_cmd({
    name = "Say Goodbye",
    cmd = function()
      print("Goodbye from the command palette!")
    end,
    category = "action",
  })
end

---Toggle the command palette visibility
function M.toggle()
  cmd_palette.open()
end

M.populate()

return M
