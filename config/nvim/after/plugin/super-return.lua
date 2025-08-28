local SeuBarriga = {}
function SeuBarriga.handles(buf)
  local full_file_path = ""
  local directory_matcher = "Workplace/seubarriga/"
  local directory_worktree_matcher = "Workplace/seubarriga-worktrees/"
  local file_matcher = "test/"
end

function SeuBarriga.then_cmd(buf)
  local base_cmd = "lein with-profile test midje "
  local file_to_namespace = ""
  local cmd = base_cmd .. file_to_namespace

  return cmd
end


local projects = { SeuBarriga }

local function handle()
  local buf = vim.api.nvim_get_current_buf()
  for _, value in ipairs(projects) do
    if value.handles(buf) then
      local cmd = value.then_cmd(buf)
      vim.cmd("TmuxRunCommand " .. vim.fn.shellescape(cmd))
      break
    end
  end

end


vim.api.nvim_create_user_command("SuperReturn", handle, { desc = "Run it"})
