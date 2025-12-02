---@type overseer.TemplateFileDefinition
return {
  name = "Gemini CLI",
  builder = function()
    return {
      cmd = { "gemini" },
      name = "Gemini",
      components = { "default", { "unique", replace = false }, },
      tags = { "agent", "AI" },
    }
  end,
}
