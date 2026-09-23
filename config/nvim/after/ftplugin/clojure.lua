vim.opt_local.colorcolumn = ""
vim.opt_local.number = false
vim.opt_local.relativenumber = false

if string.find(vim.fn.getcwd(), "Workplace/seubarriga") == nil then
  return
end

vim.g["conjure#extract#tree_sitter#enabled"] = true
vim.g["conjure#mapping#doc_word"] = "gk"

require("utils").packadd({ "vim-sexp", "vim-sexp-mappings-for-regular-people", "nvim-paredit", "conjure" }, function()
  require("nvim-paredit").setup()

  -- Auto-reload namespace on save
  vim.api.nvim_create_autocmd("BufWritePost", {
    pattern = "*.clj",
    callback = function()
      vim.cmd("ConjureEvalBuf")
    end,
    desc = "Reload namespace after saving Clojure file",
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
  end, {
    desc = "Reload all changed Clojure namespaces",
  })
end)
