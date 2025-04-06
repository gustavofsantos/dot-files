local register_beyond_payments_tasks = require("tasks.loggi.beyond_payments")
local register_beyond_py_tasks = require("tasks.loggi.beyond_py")
local register_web_tasks = require("tasks.loggi.web")
local register_integration_tasks = require("tasks.loggi.integration")

local function register_tasks(overseer)
  register_beyond_payments_tasks(overseer)
  register_beyond_py_tasks(overseer)
  register_web_tasks(overseer)
  register_integration_tasks(overseer)
end

return register_tasks
