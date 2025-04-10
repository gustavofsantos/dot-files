vim.api.nvim_create_user_command("Q", function()
  vim.cmd("q")
end, { desc = "Quit" })

vim.api.nvim_create_user_command("Qall", function()
  vim.cmd("qall")
end, { desc = "Quit all" })

vim.api.nvim_create_user_command("QA", function()
  vim.cmd("qa")
end, { desc = "Quit all" })

vim.api.nvim_create_user_command("E", function()
  vim.cmd("e")
end, { desc = "Edit file" })

vim.api.nvim_create_user_command("W", function()
  vim.cmd("w")
end, { desc = "Write file" })

vim.api.nvim_create_user_command("Wq", function()
  vim.cmd("wq")
end, { desc = "Write and quit" })

vim.api.nvim_create_user_command("WQ", function()
  vim.cmd("wq")
end, { desc = "Write and quit" })

vim.api.nvim_create_user_command("Wa", function()
  vim.cmd("wa")
end, { desc = "Write all" })

vim.api.nvim_create_user_command("WA", function()
  vim.cmd("wa")
end, { desc = "Write all" })


vim.api.nvim_create_user_command(
  "Journal",
  function ()
    local journals_dir = os.getenv("JOURNALS_HOME")
    local file = journals_dir .. "/" .. os.date("%Y-%m-%d") .. ".md"
    vim.cmd("edit " .. file)
  end,
  { desc = "Open daily journal file", bang = true, nargs = 0 }
)

vim.api.nvim_create_user_command(
  "Worklog",
  ":vsp | :e ~/notes/worklog.md",
  { desc = "Open worklog file", bang = true, nargs = 0 }
)

vim.api.nvim_create_user_command("TaskNotes", function()
  local notes_dir = os.getenv("NOTES_HOME")
  -- Get the current git branch name
  local branch_name = vim.fn.system("git branch --show-current 2> /dev/null | tr -d '\n'")

  -- Extract the file name after the first slash, if any
  local filename = vim.fn.match("(.*)/(.+)", branch_name) or branch_name

  -- Transform the filename to uppercase
  filename = vim.fn.toupper(filename)

  -- Construct the file path
  local file_path = vim.fn.expand(notes_dir .. filename .. ".md")

  -- Check if the file exists and is writable
  if vim.fn.filewritable(file_path) then
    vim.cmd("e " .. file_path)
  else
    -- Create the new markdown file
    vim.cmd("enew " .. file_path)

    -- Write a header with the transformed filename
    local content = "# " .. filename .. "\n\n"
    vim.fn.setfile(file_path, content)
  end
end, { desc = "Open task notes", bang = true, nargs = 0 })
