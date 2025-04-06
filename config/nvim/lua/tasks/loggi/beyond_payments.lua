local function register_tasks(overseer)
  overseer.register_template({
    name = "payment: start dev server",
    builder = function()
      return {
        cmd = { "poetry@payment-api" },
        args = { "run", "uvicorn", "app.main:app", "--host", "0.0.0.0",
          "--port", "8000", "--workers", "1", "--no-access-log", "--reload" },
        cwd = "/opt/loggi/beyond-payment/",
        components = { "default" },
        env = {},
      }
    end,
    condition = {
      dir = "/opt/loggi/beyond-payment/",
    },
  })

  overseer.register_template({
    name = "payment: start production session",
    builder = function()
      return {
        cmd = { "start-beyond-payments-session.sh" },
        components = { "default" },
        cwd = "/opt/loggi/beyond-payment/",
      }
    end,
    condition = {
      dir = "/opt/loggi/beyond-payment/",
    },
  })

  overseer.register_template({
    name = "payment: format (ruff)",
    builder = function()
      return {
        cmd = { "poetry@payment-api" },
        args = { "run", "ruff", "format", "." },
        cwd = "/opt/loggi/beyond-payment/",
        components = { "default" },
        env = {},
      }
    end,
    condition = {
      dir = "/opt/loggi/beyond-payment/",
    },
  })

  overseer.register_template({
    name = "payment: lint (ruff)",
    builder = function()
      return {
        cmd = { "poetry@payment-api" },
        args = { "run", "ruff", "check", "--fix", "." },
        cwd = "/opt/loggi/beyond-payment/",
        components = { "default" },
        env = {},
      }
    end,
    condition = {
      dir = "/opt/loggi/beyond-payment/",
    },
  })

  overseer.register_template({
    name = "payment: lint (mypy)",
    builder = function()
      return {
        cmd = { "poetry@payment-api" },
        args = { "run", "mypy", "." },
        cwd = "/opt/loggi/beyond-payment/",
        components = { "default" },
        env = {},
      }
    end,
    condition = {
      dir = "/opt/loggi/beyond-payment/",
    },
  })

  overseer.register_template({
    name = "payment: run migrations",
    builder = function()
      return {
        cmd = { "poetry@payment-api", "run", "alembic", "upgrade", "head" },
        args = {},
        cwd = "/opt/loggi/beyond-payment/",
        components = { "default" },
        env = { APP_DB_HOST = "localhost" },
      }
    end,
    condition = {
      dir = "/opt/loggi/beyond-payment/",
    },
  })

  overseer.register_template({
    name = "payment: run migrations (test)",
    builder = function()
      return {
        cmd = { "poetry@payment-api", "run", "alembic", "-x", "env=test", "upgrade", "head" },
        args = {},
        cwd = "/opt/loggi/beyond-payment/",
        components = { "default" },
        env = { APP_DB_HOST = "localhost" },
      }
    end,
    condition = {
      dir = "/opt/loggi/beyond-payment/",
    },
  })

  overseer.register_template({
    name = "payment: run migrations down",
    builder = function()
      return {
        cmd = { "poetry@payment-api", "run", "alembic", "downgrade", "-1" },
        args = {},
        cwd = "/opt/loggi/beyond-payment/",
        components = { "default" },
        env = { APP_DB_HOST = "localhost" },
      }
    end,
    condition = {
      dir = "/opt/loggi/beyond-payment/",
    },
  })

  overseer.register_template({
    name = "payment: run migrations down (test)",
    builder = function()
      return {
        cmd = { "poetry@payment-api", "run", "alembic", "-x", "env=test", "downgrade", "-1" },
        args = {},
        cwd = "/opt/loggi/beyond-payment/",
        components = { "default" },
        env = { APP_DB_HOST = "localhost" },
      }
    end,
    condition = {
      dir = "/opt/loggi/beyond-payment/",
    },
  })
end

return register_tasks
