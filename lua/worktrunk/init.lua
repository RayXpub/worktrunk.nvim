local cli = require("worktrunk.cli")
local config = require("worktrunk.config")

local M = {}

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO, { title = "Worktrunk" })
end

local function current_directory()
  return vim.fn.getcwd()
end

local function change_directory(path)
  if config.options.cwd_scope == "global" then
    vim.api.nvim_set_current_dir(path)
  else
    local command = config.options.cwd_scope == "tab" and "tcd" or "lcd"
    vim.cmd(command .. " " .. vim.fn.fnameescape(path))
  end
end

local function finish_switch(result)
  change_directory(result.path)
  vim.api.nvim_exec_autocmds("User", {
    pattern = "WorktrunkSwitch",
    data = result,
  })
  notify(("Switched to %s"):format(result.branch or result.path))
end

function M.setup(options)
  config.setup(options)
end

function M.switch(branch)
  if not branch or branch == "" then
    return M.select()
  end
  cli.switch(current_directory(), branch, false, nil, finish_switch)
end

function M.switch_args(args)
  if #args == 0 then
    return M.select()
  end
  cli.switch_args(current_directory(), args, finish_switch)
end

function M.select()
  cli.list(current_directory(), function(items)
    if #items == 0 then
      notify("No worktrees found", vim.log.levels.WARN)
      return
    end

    vim.ui.select(items, {
      prompt = "Worktree",
      format_item = function(item)
        local marker = item.current and "@" or " "
        local name = item.branch or item.sha or "detached"
        local status = item.symbols and item.symbols ~= "" and (" [%s]"):format(item.symbols) or ""
        local location = item.path or (item.remote and (item.remote .. " branch") or "branch only")
        return ("%s %s%s  %s"):format(marker, name, status, location)
      end,
    }, function(item)
      if item then
        M.switch(item.path or item.branch)
      end
    end)
  end)
end

function M.create(branch, base)
  local function create(name)
    if not name or vim.trim(name) == "" then
      return
    end

    local function run()
      cli.switch(current_directory(), vim.trim(name), true, base, finish_switch)
    end

    if config.options.confirm_create then
      vim.ui.select({ "Create", "Cancel" }, {
        prompt = ("Create worktree '%s'?"):format(vim.trim(name)),
      }, function(choice)
        if choice == "Create" then
          run()
        end
      end)
    else
      run()
    end
  end

  if branch and branch ~= "" then
    create(branch)
  else
    vim.ui.input({ prompt = "New branch: " }, create)
  end
end

function M.list()
  cli.run({ "-C", current_directory(), "list", "--no-progressive" }, function(result)
    local lines = vim.split(vim.trim(result.stdout), "\n", { plain = true })
    vim.cmd("botright new")
    local buffer = vim.api.nvim_get_current_buf()
    vim.bo[buffer].buftype = "nofile"
    vim.bo[buffer].bufhidden = "wipe"
    vim.bo[buffer].swapfile = false
    vim.bo[buffer].filetype = "worktrunk"
    vim.api.nvim_buf_set_name(buffer, "Worktrunk list")
    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
    vim.bo[buffer].modifiable = false
  end)
end

function M.run(args)
  if #args == 0 then
    notify("A Worktrunk command is required", vim.log.levels.WARN)
    return
  end

  vim.cmd("botright new")
  local buffer = vim.api.nvim_get_current_buf()
  vim.bo[buffer].bufhidden = "wipe"
  local command = vim.list_extend({ config.options.command }, args)
  local job = vim.fn.jobstart(command, { term = true, cwd = current_directory() })
  if job <= 0 then
    vim.api.nvim_buf_delete(buffer, { force = true })
    notify("Failed to start Worktrunk", vim.log.levels.ERROR)
    return
  end
  vim.cmd("startinsert")
end

function M.command(args)
  local subcommand = args[1]
  if not subcommand then
    return M.select()
  end

  if subcommand == "switch" then
    local switch_args = vim.list_slice(args, 2)
    return M.switch_args(switch_args)
  elseif subcommand == "create" then
    return M.create(args[2], args[3])
  elseif subcommand == "list" and #args == 1 then
    return M.list()
  elseif subcommand == "previous" then
    return M.switch("-")
  end

  M.run(args)
end

return M
