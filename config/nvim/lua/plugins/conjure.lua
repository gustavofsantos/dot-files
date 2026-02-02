return {
  "Olical/conjure",
  ft = { "clojure" },
  cond = string.find(vim.fn.getcwd(), "Workplace/seubarriga") ~= nil,
  lazy = true,
  init = function()
    vim.g['conjure#extract#tree_sitter#enabled'] = true
    vim.g["conjure#mapping#doc_word"] = "gk"

    vim.api.nvim_create_autocmd("VimEnter", {
      pattern = "*",
      callback = function()
        local cwd = vim.fn.getcwd()
        if string.find(cwd, "Workplace/seubarriga") ~= nil then
          local overseer = require("overseer")
          local task = overseer.new_task({
            cmd = "lein",
            args = { "update-in", ":plugins", "conj", "'[cider/cider-nrepl,\"0.57.0\"]'", "--", "update-in", ":repl-options", "assoc", ":init", "'(do)'", "--", "with-profile", "+test", "repl" },
            name = "Lein REPL",
            components = { "default" },
          })
          task:start()
        end
      end,
      once = true,
    })
  end,
  config = function()
    -- Auto-reload namespace on save
    vim.api.nvim_create_autocmd("BufWritePost", {
      pattern = "*.clj",
      callback = function()
        vim.cmd("ConjureEvalBuf")
      end,
      desc = "Reload namespace after saving Clojure file"
    })

    vim.api.nvim_create_user_command("ConjureReloadChanged", function()
        local base = "origin/master" -- Adjust this to your base branch if different
        local cmd = "git diff --name-only " .. base .. "..HEAD"
        local result = vim.fn.system(cmd)
        if vim.v.shell_error ~= 0 then
          vim.notify("Failed to get changed files: " .. result, vim.log.levels.ERROR)
          return
        end
        local files = vim.split(result, "\n", { trimempty = true })
        local namespaces = {}
        for _, file in ipairs(files) do
          if file:match("%.clj$") and not file:match("_test%.clj$") and not file:match("^test/") then
            local path = vim.fn.getcwd() .. "/" .. file
            if vim.fn.filereadable(path) == 1 then
              local lines = vim.fn.readfile(path, "", 50)
              for _, line in ipairs(lines) do
                local ns = line:match("^%s*%(%s*ns%s+([^%s%(%)]+)")
                if ns then
                  table.insert(namespaces, ns)
                  break
                end
              end
            end
          end
        end
        if #namespaces == 0 then
          vim.notify("No namespaces to reload", vim.log.levels.INFO)
          return
        end
        for _, ns in ipairs(namespaces) do
          vim.cmd("ConjureEval (require '" .. ns .. " :reload)")
        end
        vim.notify("Reloaded " .. #namespaces .. " namespaces", vim.log.levels.INFO)
      end,
      {
        desc = "Reload all changed Clojure namespaces"
      })
  end,
  dependencies = {
    "guns/vim-sexp",
    "tpope/vim-sexp-mappings-for-regular-people",
    {
      "PaterJason/cmp-conjure",
      lazy = true,
      config = function()
        local cmp = require("cmp")
        local config = cmp.get_config()
        table.insert(config.sources, { name = "conjure" })
        return cmp.setup(config)
      end,
    },
    {
      "julienvincent/nvim-paredit",
      config = function()
        require("nvim-paredit").setup()
      end
    }
  },
}
