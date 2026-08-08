local function stop_coverage()
  if vim.env.NVIM_WORKTRUNK_COVERAGE == "1" then
    require("luacov.runner").shutdown()
  end
end

if vim.fn.executable("wt") ~= 1 then
  stop_coverage()
  print("worktrunk.nvim integration test skipped: wt not found")
  return
end

local function run(command)
  local result = vim.system(command, { text = true }):wait()
  if result.code ~= 0 then
    error(vim.trim(result.stderr ~= "" and result.stderr or result.stdout))
  end
end

local original_cwd = vim.fn.getcwd()
local root = vim.fn.tempname()
vim.fn.mkdir(root, "p")
vim.fn.writefile({ "integration test" }, root .. "/README.md")
run({ "git", "init", "-q", "-b", "main", root })
run({ "git", "-C", root, "config", "user.email", "test@example.com" })
run({ "git", "-C", root, "config", "user.name", "Test" })
run({ "git", "-C", root, "add", "README.md" })
run({ "git", "-C", root, "commit", "-qm", "initial" })

local switched
local autocmd = vim.api.nvim_create_autocmd("User", {
  pattern = "WorktrunkSwitch",
  callback = function(event)
    switched = event.data
  end,
})

vim.api.nvim_set_current_dir(root)
require("worktrunk").switch_args({ "--create", "--no-hooks", "feature" })
local completed = vim.wait(15000, function()
  return switched ~= nil
end, 20)

vim.api.nvim_del_autocmd(autocmd)
vim.api.nvim_set_current_dir(original_cwd)

if not completed then
  vim.fn.delete(root, "rf")
  error("timed out waiting for Worktrunk switch")
end

local branch =
  vim.trim(vim.system({ "git", "-C", switched.path, "branch", "--show-current" }, { text = true }):wait().stdout)
assert(branch == "feature", "expected feature branch, got " .. branch)
assert(vim.uv.fs_realpath(switched.path) ~= vim.uv.fs_realpath(root), "expected a separate worktree")

vim.fn.delete(switched.path, "rf")
vim.fn.delete(root, "rf")
stop_coverage()
print("worktrunk.nvim integration test passed")
