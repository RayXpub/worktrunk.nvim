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

local invalid, decode_error = cli.decode_json("not json")
assert_equal(nil, invalid, "invalid JSON is rejected")
assert(decode_error:find("Worktrunk returned invalid JSON", 1, true), "invalid JSON returns a useful error")

local subcommands = vim.fn.getcompletion("Worktrunk ", "cmdline")
assert(vim.tbl_contains(subcommands, "switch"), "main command completes switch")
assert(vim.tbl_contains(subcommands, "create"), "main command completes create")
assert_equal({}, vim.fn.getcompletion("Worktrunk switch feature ", "cmdline"), "nested arguments are not completed")

local valid, setup_error = pcall(config.setup, { cwd_scope = "buffer" })
assert_equal(false, valid, "invalid cwd scope is rejected")
assert(setup_error:find("cwd_scope", 1, true), "cwd scope validation returns a useful error")

valid, setup_error = pcall(config.setup, { picker = { status = "verbose" } })
assert_equal(false, valid, "invalid picker status is rejected")
assert(setup_error:find("picker.status", 1, true), "picker status validation returns a useful error")

worktrunk.setup({ confirm_create = false })
assert_equal(false, config.options.confirm_create, "public setup applies configuration")
worktrunk.setup()

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

local original_list = cli.list
local original_select = vim.ui.select
local picker_label
cli.list = function(_, callback)
  callback({ { branch = "main", path = "/tmp/repo", current = true, symbols = "^|" } })
end
vim.ui.select = function(items, options, callback)
  picker_label = options.format_item(items[1])
  callback(nil)
end
config.setup()
worktrunk.select()
assert(picker_label:find("🏠", 1, true), "picker translates main symbol to an icon")
assert(picker_label:find("✅", 1, true), "picker translates upstream status to an icon")
assert(not picker_label:find("^", 1, true), "picker hides raw symbols in icon mode")
cli.list = original_list
vim.ui.select = original_select

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

if vim.env.NVIM_WORKTRUNK_COVERAGE == "1" then
  require("luacov.runner").shutdown()
end

print("worktrunk.nvim tests passed")
