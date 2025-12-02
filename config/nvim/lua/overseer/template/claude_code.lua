---@type overseer.TemplateFileDefinition
return {
    name = "Claude Code",
    builder = function()
      return {
        cmd = { "claude" },
        name = "Claude",
        components = { "default", { "unique", replace = false } },
        tags = { "agent", "AI" },
      }
    end,
}
