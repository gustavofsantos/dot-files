local function register_tasks(overseer)
  overseer.register_template({
    name = "loggi web: start app",
    builder = function()
      return {
        cmd = { "docker" },
        args = { "compose", "up", "loggi_web_app" },
        cwd = "/opt/loggi/web/",
        components = { "default" },
      }
    end,
    condition = {
      dir = "/opt/loggi/web/",
    },
  })

  overseer.register_template({
    name = "loggi web: db migrate",
    builder = function()
      return {
        cmd = { "docker" },
        args = { "compose", "exec", "loggi_web_app", "bash", "-c", "./manage.py", "migrate" },
        cwd = "/opt/loggi/web/",
        components = { "default" },
      }
    end,
    condition = {
      dir = "/opt/loggi/web/",
    },
  })

  overseer.register_template({
    name = "loggi web: run test file",
    params = function()
      local file_name = vim.fn.expand("%"):gsub("^loggi/", "")
      return {
        file = file_name
      }
    end,
    builder = function(params)
      return {
        cmd = { "docker" },
        args = { "compose", "exec", "-e", "DJANGO_SETTINGS_MODULE=settings.test", "loggi_web_app", "pytest", "--", params.file },
        cwd = "/opt/loggi/web/",
        components = { "default" },
      }
    end,
    condition = {
      dir = "/opt/loggi/web/",
    },
  })

  overseer.register_template({
    name = "black format",
    builder = function()
      return {
        cmd = { "docker" },
        args = { "compose", "exec", "-w", "/opt/loggi", "loggi_web_app", "./ops/black.sh", "fix" },
        cwd = "/opt/loggi/web/",
        components = { "default" },
      }
    end,
  })

  overseer.register_template({
    name = "loggi web: buildproto",
    builder = function()
      return {
        cmd = { "poetry" },
        args = { "run", "python", "-m", "buildproto" },
        cwd = "/opt/loggi/web/loggi/",
        components = { "default" },
      }
    end,
    condition = {
      dir = "/opt/loggi/web/",
    },
  })
end

return register_tasks
