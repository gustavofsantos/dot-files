local register_common_tasks = require("tasks.common")
local register_loggi_tasks = require("tasks.loggi")

local function register_tasks(overseer)
  register_common_tasks(overseer)
  register_loggi_tasks(overseer)
end

return register_tasks
