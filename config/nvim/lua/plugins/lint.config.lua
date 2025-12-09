return {
  "mfussenegger/nvim-lint",
  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },
  config = function()
    local lint = require("lint")
    lint.linters_by_ft = {
      markdown = { "vale" },
      python = { "mypy", "flake8", "ruff" },
      clojure = { "clj-kondo" },
      javascript = { "eslint_d" },
      javascriptreact = { "eslint_d" },
      typescript = { "deno", "eslint_d" },
      typescriptreact = { "deno", "eslint_d" },
    }

    -- vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost" }, {
    --   callback = function() lint.try_lint() end,
    -- })

    vim.api.nvim_create_user_command("Lint", function()
      lint.try_lint()
    end, {
      desc = "Lint current buffer",
    })
  end,
}
