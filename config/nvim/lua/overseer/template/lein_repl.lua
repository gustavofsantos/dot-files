---@type overseer.TemplateFileDefinition
return {
  name = "Leiningen REPL",
  builder = function()
    return {
      cmd = { "lein" },
      args = { "update-in", ":plugins", "conj", "'[cider/cider-nrepl,\"0.57.0\"]'", "--", "update-in", ":repl-options", "assoc", ":init", "'(do)'", "--", "with-profile", "+test", "repl" },
      name = "Lein REPL",
      components = { "default" },
      tags = { "clojure", "repl" },
    }
  end,
}
