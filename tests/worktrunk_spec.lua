local function assert_equal(expected, actual, message)
  if not vim.deep_equal(expected, actual) then
    error((message or "values differ") .. ": expected " .. vim.inspect(expected) .. ", got " .. vim.inspect(actual))
  end
end

local cli = require("worktrunk.cli")
local config = require("worktrunk.config")
local worktrunk = require("worktrunk")

assert_equal(2, vim.fn.exists(":Worktrunk"), "main command is registered")
assert_equal(2, vim.fn.exists(":WorktrunkSwitch"), "switch command is registered")

local decoded = assert(cli.decode_json('{"action":"switched","path":"/tmp/repo.feature"}'))
assert_equal("/tmp/repo.feature", decoded.path, "switch JSON is decoded")

local original_run = cli.run
local listed
cli.run = function(_, callback)
  callback({
    stdout = vim.json.encode({
      schema = 2,
      items = {
        {
          branch = "main",
          head = { short_sha = "1234567" },
          worktree = { path = "/tmp/repo", current = true },
          display = { symbols = "^" },
        },
        { branch = "without-worktree", head = { short_sha = "7654321" } },
      },
    }),
  })
end
cli.list("/tmp/repo", function(items)
  listed = items
end)
assert_equal(2, #listed, "branches without paths remain selectable")
assert_equal("main", listed[1].branch, "schema 2 branch is normalized")
assert_equal(true, listed[1].current, "schema 2 current state is normalized")
assert_equal(nil, listed[2].path, "branch-only item has no worktree path")
cli.run = original_run

local original_switch = cli.switch
local original_cwd = vim.fn.getcwd()
local target = vim.fn.tempname()
vim.fn.mkdir(target, "p")
local event_data
local autocmd = vim.api.nvim_create_autocmd("User", {
  pattern = "WorktrunkSwitch",
  callback = function(event)
    event_data = event.data
  end,
})
cli.switch = function(_, branch, _, _, callback)
  callback({ action = "switched", branch = branch, path = target })
end
config.setup({ cwd_scope = "global" })
worktrunk.switch("feature")
assert_equal(vim.uv.fs_realpath(target), vim.uv.fs_realpath(vim.fn.getcwd()), "switch changes cwd")
assert_equal("feature", event_data.branch, "switch event includes result")

vim.api.nvim_del_autocmd(autocmd)
cli.switch = original_switch
vim.api.nvim_set_current_dir(original_cwd)
vim.fn.delete(target, "rf")

print("worktrunk.nvim tests passed")
