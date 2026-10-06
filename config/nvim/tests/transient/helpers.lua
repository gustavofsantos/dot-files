-- Minimal headless test harness: nvim --headless -u NONE -l <file>_test.lua
local here = debug.getinfo(1, "S").source:sub(2):match("(.*)/")
local config_dir = vim.fn.fnamemodify(here .. "/../..", ":p"):gsub("/$", "")
vim.opt.rtp:prepend(config_dir)
package.path = here .. "/?.lua;" .. package.path

local H = { config_dir = config_dir, failures = 0, count = 0 }

function H.test(name, fn)
  H.count = H.count + 1
  vim.cmd("silent! %bwipeout!")
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)
  local ok, err = xpcall(fn, debug.traceback)
  if ok then
    io.stdout:write("ok   " .. name .. "\n")
  else
    H.failures = H.failures + 1
    io.stdout:write("FAIL " .. name .. "\n     " .. tostring(err):gsub("\n", "\n     ") .. "\n")
  end
end

function H.eq(want, got, msg)
  if not vim.deep_equal(want, got) then
    error(("%sexpected %s, got %s"):format(msg and (msg .. ": ") or "", vim.inspect(want), vim.inspect(got)), 2)
  end
end

function H.truthy(v, msg)
  if not v then
    error(msg or "expected a truthy value", 2)
  end
end

function H.raises(fn, pattern)
  local ok, err = pcall(fn)
  if ok then
    error("expected an error matching " .. pattern, 2)
  end
  if not tostring(err):find(pattern) then
    error(("error %q does not match %q"):format(tostring(err), pattern), 2)
  end
end

--- A key source that replays `keys` (strings in <> notation), then runs dry.
function H.keys(list)
  local i = 0
  return function()
    i = i + 1
    local k = list[i]
    return k and vim.api.nvim_replace_termcodes(k, true, true, true) or nil
  end
end

--- A renderer that records every view; proves the engine needs no window.
function H.recorder()
  local r = { views = {}, closed = 0 }
  r.show = function(view)
    table.insert(r.views, vim.deepcopy(view))
  end
  r.close = function()
    r.closed = r.closed + 1
  end
  return r
end

--- Type keys as the user would (mappings apply) and run them to completion.
function H.type(keys)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), "mx", false)
end

function H.buffer(lines)
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
end

function H.done()
  io.stdout:write(("%d tests, %d failures\n"):format(H.count, H.failures))
  vim.cmd(H.failures == 0 and "qa!" or "cq!")
end

return H
