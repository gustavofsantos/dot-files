-- system_theme — follow the OS light/dark preference.
--
-- Sets 'background' from the system appearance. When a colorscheme is loaded
-- (g:colors_name), Neovim re-sources it on every 'background' change, so that
-- assignment is the whole refresh. It is only made when the value differs.
--
-- Detection:
--   macOS  `defaults read -g AppleInterfaceStyle` ("Dark", or exit 1 for light)
--   Linux  xdg-desktop-portal org.freedesktop.appearance color-scheme
--          (1 dark, 2 light, 0 no preference), then GNOME gsettings.
-- When nothing answers (SSH, no session bus), 'background' is left alone.
--
-- Staying in sync while running:
--   Linux  a `gdbus monitor` on the portal's SettingChanged signal
--   macOS  an async poll every `poll_ms`
--   both   a re-check on FocusGained
--
-- :SystemTheme [sync|on|off] — re-check now, resume, or pause following the
-- system (pause before toggling 'background' by hand, or it gets overridden).

local M = {}

local uv = vim.uv
local is_mac = uv.os_uname().sysname == "Darwin"

local PORTAL = {
  "--session",
  "--dest", "org.freedesktop.portal.Desktop",
  "--object-path", "/org/freedesktop/portal/desktop",
}

-- Linuxbrew's glib ships its own gsettings, which does not read the system
-- dconf database. Prefer the distro binary.
local GSETTINGS = vim.fn.executable("/usr/bin/gsettings") == 1 and "/usr/bin/gsettings" or "gsettings"

local config = { poll_ms = 3000, timeout_ms = 500 }
local state = { enabled = false, monitor = nil, timer = nil, augroup = nil }

local function run(cmd, on_done)
  if vim.fn.executable(cmd[1]) == 0 then
    if on_done then
      on_done(nil)
      return
    end
    return nil
  end
  local ok, proc = pcall(vim.system, cmd, { text = true, timeout = config.timeout_ms }, on_done)
  if not ok then
    if on_done then
      on_done(nil)
    end
    return nil
  end
  if not on_done then
    return proc:wait()
  end
end

local function parse_mac(res)
  if not res then
    return nil
  end
  if res.code == 0 and res.stdout:match("Dark") then
    return "dark"
  end
  -- The key only exists in dark mode; `defaults` exits 1 when it is missing.
  if res.code == 1 then
    return "light"
  end
  return nil
end

-- `(<uint32 1>,)` from ReadOne, `(<<uint32 1>>,)` from the older Read.
local function parse_portal(res)
  if not res or res.code ~= 0 then
    return nil
  end
  local value = tonumber(res.stdout:match("uint32 (%d)"))
  return ({ [1] = "dark", [2] = "light" })[value]
end

local function parse_gsettings(res)
  if not res or res.code ~= 0 then
    return nil
  end
  if res.stdout:match("prefer%-dark") then
    return "dark"
  end
  if res.stdout:match("prefer%-light") or res.stdout:match("default") then
    return "light"
  end
  return nil
end

local MAC_CMD = { "defaults", "read", "-g", "AppleInterfaceStyle" }
local PORTAL_CMD = vim.list_extend({ "gdbus", "call" }, PORTAL)
vim.list_extend(PORTAL_CMD, {
  "--method", "org.freedesktop.portal.Settings.ReadOne",
  "org.freedesktop.appearance", "color-scheme",
})
local GSETTINGS_CMD = { GSETTINGS, "get", "org.gnome.desktop.interface", "color-scheme" }

--- Detect the system appearance synchronously: "dark", "light", or nil.
function M.detect()
  if is_mac then
    return parse_mac(run(MAC_CMD))
  end
  return parse_portal(run(PORTAL_CMD)) or parse_gsettings(run(GSETTINGS_CMD))
end

--- Detect asynchronously; `cb` runs on the main loop with "dark", "light", or nil.
function M.detect_async(cb)
  local done = vim.schedule_wrap(cb)
  if is_mac then
    run(MAC_CMD, function(res)
      done(parse_mac(res))
    end)
    return
  end
  run(PORTAL_CMD, function(res)
    local bg = parse_portal(res)
    if bg then
      return done(bg)
    end
    run(GSETTINGS_CMD, function(res2)
      done(parse_gsettings(res2))
    end)
  end)
end

local function apply(bg)
  if bg and vim.o.background ~= bg then
    vim.o.background = bg
  end
end

--- Re-check the system now and apply the result.
function M.sync()
  M.detect_async(apply)
end

local function start_monitor()
  if vim.fn.executable("gdbus") == 0 then
    return false
  end
  local cmd = vim.list_extend({ "gdbus", "monitor" }, PORTAL)
  local ok, proc = pcall(vim.system, cmd, {
    text = true,
    stdout = function(_, data)
      if data and data:match("color%-scheme") then
        vim.schedule(M.sync)
      end
    end,
  }, function()
    state.monitor = nil
  end)
  if not ok then
    return false
  end
  state.monitor = proc
  return true
end

local function start_timer()
  state.timer = uv.new_timer()
  state.timer:start(config.poll_ms, config.poll_ms, function()
    M.detect_async(apply)
  end)
end

local function stop_watchers()
  if state.monitor then
    state.monitor:kill("sigterm")
    state.monitor = nil
  end
  if state.timer then
    state.timer:stop()
    state.timer:close()
    state.timer = nil
  end
end

--- Resume following the system appearance.
function M.enable()
  if state.enabled then
    return
  end
  state.enabled = true
  if is_mac then
    start_timer()
  else
    start_monitor()
  end
  M.sync()
end

--- Stop following the system appearance; 'background' stays as it is.
function M.disable()
  state.enabled = false
  stop_watchers()
end

--- Apply the system appearance once, synchronously, then keep following it.
--- Call before `:colorscheme` so startup loads the right variant only once.
function M.setup(opts)
  config = vim.tbl_extend("force", config, opts or {})

  apply(M.detect())

  state.augroup = vim.api.nvim_create_augroup("system_theme", { clear = true })
  vim.api.nvim_create_autocmd("FocusGained", {
    group = state.augroup,
    callback = function()
      if state.enabled then
        M.sync()
      end
    end,
  })
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = state.augroup,
    callback = stop_watchers,
  })

  vim.api.nvim_create_user_command("SystemTheme", function(args)
    local action = args.args ~= "" and args.args or "sync"
    if action == "on" then
      M.enable()
    elseif action == "off" then
      M.disable()
    else
      M.sync()
    end
  end, {
    nargs = "?",
    complete = function()
      return { "sync", "on", "off" }
    end,
    desc = "Follow the system light/dark appearance",
  })

  -- Watchers start after startup so they never delay the first screen.
  state.enabled = false
  vim.schedule(M.enable)
end

-- Exposed for tests.
M._parse = { mac = parse_mac, portal = parse_portal, gsettings = parse_gsettings }

return M
