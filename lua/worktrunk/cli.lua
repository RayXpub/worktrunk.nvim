local config = require("worktrunk.config")

local M = {}

local function notify_error(result)
  local message = vim.trim(result.stderr or "")
  if message == "" then
    message = vim.trim(result.stdout or "")
  end
  vim.notify(message ~= "" and message or "Worktrunk command failed", vim.log.levels.ERROR, {
    title = "Worktrunk",
  })
end

function M.run(args, callback)
  local command = vim.list_extend({ config.options.command }, args)

  vim.system(command, { text = true }, function(result)
    vim.schedule(function()
      if result.code ~= 0 then
        notify_error(result)
        return
      end
      callback(result)
    end)
  end)
end

function M.decode_json(output)
  local ok, decoded = pcall(vim.json.decode, output)
  if not ok then
    return nil, "Worktrunk returned invalid JSON: " .. decoded
  end
  return decoded
end

function M.list(cwd, callback)
  local args = { "-C", cwd, "list", "--format=json", "--no-progressive" }
  if config.options.picker.include_branches then
    table.insert(args, "--branches")
  end
  if config.options.picker.include_remotes then
    table.insert(args, "--remotes")
  end

  M.run(args, function(result)
    local decoded, err = M.decode_json(result.stdout)
    if not decoded then
      vim.notify(err, vim.log.levels.ERROR, { title = "Worktrunk" })
      return
    end

    local source = decoded.items or decoded
    local items = {}
    for _, item in ipairs(source) do
      local worktree = item.worktree
      local path = decoded.items and worktree and worktree.path or item.path
      if path or item.branch then
        table.insert(items, {
          branch = item.branch,
          path = path,
          remote = type(item.remote) == "string" and item.remote or nil,
          current = decoded.items and (worktree and worktree.current or false) or item.is_current,
          symbols = decoded.items and item.display and item.display.symbols or item.symbols,
          sha = decoded.items and item.head and item.head.short_sha
            or item.commit and item.commit.short_sha,
        })
      end
    end
    callback(items)
  end)
end

function M.switch_args(cwd, switch_args, callback)
  local args = { "-C", cwd, "switch", "--no-cd", "--format=json" }
  vim.list_extend(args, switch_args)

  M.run(args, function(result)
    local decoded, err = M.decode_json(result.stdout)
    if not decoded then
      vim.notify(err, vim.log.levels.ERROR, { title = "Worktrunk" })
      return
    end
    if type(decoded.path) ~= "string" or decoded.path == "" then
      vim.notify("Worktrunk did not return a worktree path", vim.log.levels.ERROR, {
        title = "Worktrunk",
      })
      return
    end
    callback(decoded)
  end)
end

function M.switch(cwd, branch, create, base, callback)
  local args = {}
  if create then
    table.insert(args, "--create")
  end
  if base and base ~= "" then
    vim.list_extend(args, { "--base", base })
  end
  table.insert(args, branch)
  M.switch_args(cwd, args, callback)
end

return M
