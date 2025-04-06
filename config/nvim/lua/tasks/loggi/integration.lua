local local_envs = {
  JVM_VERSION = "11",
  AWS_PLATFORM_ACCESS_KEY_ID = os.getenv("LOGGI_INTEGRATION_AWS_PLATFORM_ACCESS_KEY_ID"),
  AWS_PLATFORM_SECRET_ACCESS_KEY = os.getenv("LOGGI_INTEGRATION_AWS_PLATFORM_SECRET_ACCESS_KEY"),
  AWS_ACCESS_KEY_ID = os.getenv("LOGGI_INTEGRATION_AWS_ACCESS_KEY_ID"),
  AWS_SECRET_ACCESS_KEY = os.getenv("LOGGI_INTEGRATION_AWS_SECRET_ACCESS_KEY"),
  KAFKA_KEY = os.getenv("LOGGI_INTEGRATION_KAFKA_KEY"),
  KAFKA_SECRET = os.getenv("LOGGI_INTEGRATION_KAFKA_SECRET"),
  JMS_SQS_ENABLED = false,
  MICRONAUT_ENVIRONMENTS = "dev",
  MICRONAUT_SECURITY_ENABLED = false,
  DEFAULT_FTP_POLLING_PERIOD_MS = 30000
}

local function register_tasks(overseer)
  overseer.register_template({
    name = "start server",
    builder = function()
      return {
        cmd = { "./gradlew" },
        args = { "run" },
        cwd = "/opt/loggi/jvm/apps/integration/",
        components = {
          {
            "on_complete_notify",
            statuses = { "FAILURE" },
          },
          "default"
        },
        env = local_envs
      }
    end,
    condition = {
      dir = "/opt/loggi/jvm/apps/integration/",
    }
  })

  overseer.register_template({
    name = "run all tests",
    builder = function()
      return {
        cmd = { "./gradlew" },
        args = { "test", "--fail-fast" },
        cwd = "/opt/loggi/jvm/apps/integration/",
        components = {
          {
            "on_complete_notify",
            statuses = { "FAILURE" },
          },
          "default"
        },
        env = local_envs
      }
    end,
    condition = {
      dir = "/opt/loggi/jvm/apps/integration/",
    }
  })
end

return register_tasks
