-- Cursorized defines every Transient* group explicitly, readable on the strip.
local H = dofile(debug.getinfo(1, "S").source:sub(2):match("(.*)/") .. "/helpers.lua")
local test, eq = H.test, H.eq

vim.o.termguicolors = true
require("transient")

local GROUPS = { "TransientNormal", "TransientTitle", "TransientCrumb", "TransientKey",
  "TransientAction", "TransientLoop", "TransientMenu", "TransientHint" }

local function hex(n) return n and string.format("#%06x", n) end

local function luminance(h)
  local function lin(c) c = c / 255; return c <= 0.04045 and c / 12.92 or ((c + 0.055) / 1.055) ^ 2.4 end
  local r, g, b = tonumber(h:sub(2, 3), 16), tonumber(h:sub(4, 5), 16), tonumber(h:sub(6, 7), 16)
  return 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b)
end

local function contrast(a, b)
  local x, y = luminance(a), luminance(b)
  if x < y then x, y = y, x end
  return (x + 0.05) / (y + 0.05)
end

for _, variant in ipairs({ "light", "dark" }) do
  for _, transparent in ipairs({ false, true }) do
    local label = variant .. (transparent and " transparent" or "")
    test("cursorized " .. label .. ": every group defined and readable on the strip", function()
      vim.g.cursorized = { transparent = transparent }
      vim.o.background = variant
      vim.cmd.colorscheme("cursorized")

      local spec = {}
      for _, g in ipairs(GROUPS) do
        local hl = vim.api.nvim_get_hl(0, { name = g, link = false })
        eq(nil, vim.api.nvim_get_hl(0, { name = g }).link, g .. " is explicit, not a fallback link")
        H.truthy(hl.fg, g .. " has a foreground")
        spec[g] = hl
      end

      local strip_bg = hex(spec.TransientNormal.bg)
      H.truthy(strip_bg, "strip has a background")
      local normal_bg = hex(vim.api.nvim_get_hl(0, { name = "Normal" }).bg)
      H.truthy(normal_bg ~= strip_bg, "strip bg differs from Normal")

      local menu, loop, action = hex(spec.TransientMenu.fg), hex(spec.TransientLoop.fg), hex(spec.TransientAction.fg)
      H.truthy(menu ~= loop and loop ~= action and menu ~= action, "entry kinds are distinct")
      for _, g in ipairs(GROUPS) do
        if g ~= "TransientNormal" then
          local ratio = contrast(hex(spec[g].fg), strip_bg)
          H.truthy(ratio >= 4.5, ("%s fg %s on %s: %.2f"):format(g, hex(spec[g].fg), strip_bg, ratio))
        end
      end
    end)
  end
end

H.done()
