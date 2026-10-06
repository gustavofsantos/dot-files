-- Example transient menus. The trigger is <leader>m, not <leader>: a root owns its trigger
-- key, and <leader> still belongs to the plain mappings and which-key.
local t = require("transient")

local TRIGGER = "<leader>m"

local root = t.menu(TRIGGER)

local file = root:on("f", "file")
file:on("f", "find", ":Telescope find_files<cr>")
file:on("r", "recent", function()
  require("telescope.builtin").oldfiles({ only_cwd = true })
end)

local win = root:on("w", "window"):after("loop")
win:on("h", "narrower", "<C-w><")
win:on("l", "wider", "<C-w>>")
win:on("j", "shorter", "<C-w>-")
win:on("k", "taller", "<C-w>+")
win:on("=", "equalize", "<C-w>="):close()

-- Visual mode: a separate root on the same trigger, so it can carry its own keys.
local visual = t.menu(TRIGGER, "x")
visual:on("s", "sort", ":sort<cr>")
visual:on("y", "yank to clipboard", '"+y')
visual:on("J", "join", "J")
visual:on("u", "lowercase", "u")
visual:on("U", "uppercase", "U")
visual:on("c", "count lines", function(ctx)
  local a, b = vim.fn.getpos("v")[2], vim.fn.getpos(".")[2]
  vim.notify(("%d lines selected (%s mode)"):format(math.abs(b - a) + 1, ctx.mode))
end)
-- Loops only for keys that keep the selection; u/U above end Visual mode, so they close.
local extend = visual:on("e", "extend"):after("loop")
extend:on("j", "down", "j")
extend:on("k", "up", "k")
extend:on("w", "word", "w")
extend:on("b", "word back", "b")
extend:on("o", "other end", "o")
