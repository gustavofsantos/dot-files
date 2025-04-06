local register_docker_tasks = require("tasks.common.docker")

local function register_tasks(overseer)
  register_docker_tasks(overseer)
end


return register_tasks
