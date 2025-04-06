local support = require("tasks.support")

local beyond_cwd = "/opt/loggi/py/apps/beyond/"
local beyond_local_env = {
  POSTGRES_DB = "dev_db",
  POSTGRES_PASSWORD = "postgres",
  POSTGRES_USER = "postgres",
  POSTGRES_HOST = "localhost",
  POSTGRES_PORT = "5432",
}

local function register_tasks(overseer)
  overseer.register_template({
    name = "Beyond: Run python file",
    params = support.get_params,
    builder = function(params)
      return {
        cmd = { "poetry" },
        args = { "run", "python", params.file_relative_path },
        cwd = beyond_cwd,
        env = beyond_local_env
      }
    end,
    condition = { dir = beyond_cwd }
  })

  overseer.register_template({
    name = "Beyond: Run test file",
    params = support.get_params,
    builder = function(params)
      return {
        cmd = { "poetry" },
        args = { "run", "pytest", "-vv", "-x", "--disable-warnings", "--ds", "beyond_app.settings.test", params.file_relative_path },
        cwd = beyond_cwd,
        env = beyond_local_env
      }
    end,
    condition = { dir = beyond_cwd }
  })

  overseer.register_template({
    name = "Beyond: Run tests",
    builder = function()
      return {
        cmd = { "poetry" },
        args = { "run", "pytest", "-vv", "-x", "--disable-warnings", "--ds", "beyond_app.settings.test", "src/beyond_app" },
        cwd = beyond_cwd,
        env = beyond_local_env,
      }
    end,
    condition = { dir = beyond_cwd },
  })

  overseer.register_template({
    name = "beyond: run flake8",
    builder = function()
      return {
        cmd = { "poetry", "run", "flake8" },
        args = {},
        cwd = "/opt/loggi/py/apps/beyond/",
        components = { "default" },
      }
    end,
    condition = { dir = beyond_cwd },
  })

  overseer.register_template({
    name = "beyond: run black check",
    builder = function()
      return {
        cmd = { "poetry", "run", "black" },
        args = { "--check", "." },
        cwd = "/opt/loggi/py/apps/beyond/",
        components = { "default" },
        env = {},
      }
    end,
    condition = { dir = beyond_cwd },
  })

  overseer.register_template({
    name = "beyond: run black format",
    builder = function()
      return {
        cmd = { "poetry", "run", "black" },
        args = { "." },
        cwd = "/opt/loggi/py/apps/beyond/",
        components = { "default" },
      }
    end,
    condition = { dir = beyond_cwd },
  })

  overseer.register_template({
    name = "beyond: build proto",
    builder = function()
      return {
        cmd = { "poetry", "run", "python" },
        args = { "../../libs/buildproto.py", "apps/beyond/src/proto" },
        cwd = "/opt/loggi/py/apps/beyond/",
        components = { "default" },
        env = {},
      }
    end,
    condition = { dir = beyond_cwd },
  })

  overseer.register_template({
    name = "beyond: run migrations",
    builder = function()
      return {
        cmd = { "docker", "compose", "up", "app_migrations" },
        cwd = "/opt/loggi/py/apps/beyond/",
        components = { "default" },
      }
    end,
    condition = { dir = beyond_cwd },
  })

  overseer.register_template({
    name = "docker compose: start dev_db",
    builder = function()
      return {
        cmd = { "docker", "compose", "up", "-d", "dev_db" },
        cwd = "/opt/loggi/py/apps/beyond/",
        components = { "default" },
      }
    end,
    condition = { dir = beyond_cwd },
  })

  overseer.register_template({
    name = "docker compose: clear dev_db data",
    builder = function()
      return {
        cmd = { "docker", "compose", "down", "-v", "dev_db" },
        cwd = "/opt/loggi/py/apps/beyond/",
        components = { "default" },
      }
    end,
    condition = { dir = beyond_cwd },
  })
end

return register_tasks
