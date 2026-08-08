if vim.g.loaded_worktrunk_nvim then
  return
end
vim.g.loaded_worktrunk_nvim = true

local function complete(_, command_line)
  local parts = vim.split(command_line, "%s+", { trimempty = true })
  if #parts <= 2 then
    return { "switch", "create", "list", "previous", "remove", "merge", "step", "config", "hook" }
  end
  return {}
end

vim.api.nvim_create_user_command("Worktrunk", function(command)
  require("worktrunk").command(command.fargs)
end, {
  nargs = "*",
  complete = complete,
  desc = "Manage Git worktrees with Worktrunk",
})

vim.api.nvim_create_user_command("WorktrunkSwitch", function(command)
  require("worktrunk").switch(command.args)
end, {
  nargs = "?",
  desc = "Select or switch to a Worktrunk worktree",
})

vim.api.nvim_create_user_command("WorktrunkCreate", function(command)
  require("worktrunk").create(command.fargs[1], command.fargs[2])
end, {
  nargs = "*",
  desc = "Create and switch to a Worktrunk worktree",
})

vim.api.nvim_create_user_command("WorktrunkList", function()
  require("worktrunk").list()
end, {
  desc = "Show Worktrunk worktrees",
})
