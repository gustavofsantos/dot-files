local function is_beyond_py()
  return vim.fn.expand("%:p:h"):find("/opt/loggi/py/apps/beyond") ~= nil
end

local function is_beyond_payment()
  return vim.fn.expand("%:p:h"):find("/opt/loggi/beyond%-payment") ~= nil
end

local function is_loggiweb()
  return vim.fn.expand("%:p:h"):find("/opt/loggi/web") ~= nil
end

local function default_beyond_env()
  return {
    POSTGRES_DB = "dev_db",
    POSTGRES_PASSWORD = "postgres",
    POSTGRES_USER = "postgres",
    POSTGRES_HOST = "localhost",
    POSTGRES_PORT = "5432",
    UNLEASH_URL = "http://localhost:4242/api"
  }
end

local function default_beyond_payment_env()
  return {
    APP_DB_HOST = "localhost",
    APP_DB_PORT = "5432",
    APP_TEST_DB_HOST = "localhost",
    APP_TEST_DB_PORT = "5434",
    APP_DB_NAME = "postgres",
    APP_DB_USER = "postgres",
    APP_DB_PASSWORD = "postgres",
  }
end


return {
  {
    "vim-test/vim-test",
    dependencies = { "christoomey/vim-tmux-runner" },
    cmd = { "TestFile", "TestNearest", "TestSuite", "TestLast" },
    config = function()
      if vim.env.TMUX then
        vim.cmd([[let test#strategy = "vtr"]])
      -- elseif vim.env.WEZTERM_PANE then
      --   vim.cmd([[let test#strategy = "wezterm"]])
      else
        vim.cmd([[let test#strategy = "toggleterm"]])
      end
      vim.cmd([[let test#strategy = "toggleterm"]])

      vim.cmd([[let test#javascript#playwright#options = "--headed --retries 0 --workers 1"]])

      if is_beyond_py() then
        vim.cmd([[let test#python#runner = "pytest"]])
        vim.cmd([[let test#python#pytest#options = "-x --disable-warnings -q --ds beyond_app.settings.test"]])

        vim.keymap.set("n", "<leader>tn",
          "<cmd>TestNearest UNLEASH_URL=http://localhost:4242/api APP_DB_HOST=localhost POSTGRES_HOST=localhost POSTGRES_DB=dev_db POSTGRES_PASSWORD=postgres POSTGRES_HOST=localhost POSTGRES_PORT=5432<CR>",
          opts)
        vim.keymap.set("n", "<leader>tf",
          "<cmd>TestFile UNLEASH_URL=http://localhost:4242/api APP_DB_HOST=localhost POSTGRES_HOST=localhost POSTGRES_DB=dev_db POSTGRES_PASSWORD=postgres POSTGRES_HOST=localhost POSTGRES_PORT=5432<CR>",
          opts)
        vim.keymap.set("n", "<leader>ta",
          "<cmd>TestSuite UNLEASH_URL=http://localhost:4242/api APP_DB_HOST=localhost POSTGRES_HOST=localhost POSTGRES_DB=dev_db POSTGRES_PASSWORD=postgres POSTGRES_HOST=localhost POSTGRES_PORT=5432<CR>",
          opts)
        vim.keymap.set("n", "<leader>tl",
          "<cmd>TestLast<CR>",
          opts)
      elseif is_beyond_payment() then
        vim.cmd([[let test#python#runner = "pytest"]])
        vim.cmd([[let test#python#pytest#executable = "poe test"]])
        vim.cmd([[let test#python#pytest#options = ""]])
      elseif is_loggiweb() then
        vim.cmd([[let test#python#runner = "pytest"]])
        vim.cmd([[let test#python#pytest#executable = "docker compose exec -e DJANGO_SETTINGS_MODULE=settings.test loggi_web_app pytest"]])
        vim.cmd([[let test#python#pytest#options = "-x --disable-warnings -q"]])
      end
    end,
  },
}
