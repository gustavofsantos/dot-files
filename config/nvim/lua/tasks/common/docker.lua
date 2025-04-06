local function register_tasks(overseer)
  overseer.register_template({
    name = "docker: kill all",
    builder = function()
      return {
        cmd = { "docker", "kill", "$(docker ps -q)" },
        components = { "default" },
        env = {},
      }
    end
  })

  overseer.register_template({
    name = "docker compose: start all (detached)",
    builder = function()
      return {
        cmd = { "docker", "compose", "up", "-d" },
        components = { "default" },
        env = {},
      }
    end
  })

  overseer.register_template({
    name = "docker compose: ps",
    builder = function()
      return {
        cmd = { "docker", "compose", "ps" },
        components = { "default" },
      }
    end
  })
end

return register_tasks
