local M = {}

local defaults = {
  command = "wt",
  cwd_scope = "global",
  confirm_create = true,
  picker = {
    include_branches = false,
    include_remotes = false,
    status = "icons",
    icons = {
      ["^"] = "🏠",
      ["|"] = "✅",
      ["!"] = "📝",
      ["?"] = "✨",
      ["+"] = "📦",
      ["↑"] = "⬆️",
      ["⇡"] = "⬆️",
      ["↓"] = "⬇️",
      ["⇣"] = "⬇️",
      ["↕"] = "🔄",
      ["⇅"] = "🔄",
      ["✘"] = "❌",
      ["✗"] = "❌",
      ["_"] = "🧹",
      ["⊂"] = "✅",
      ["–"] = "🟰",
      ["∅"] = "🚫",
      ["↻"] = "🔄",
      ["⊟"] = "🗑️",
      ["⊞"] = "🔒",
      ["⚑"] = "⚠️",
      ["/"] = "🌿",
    },
  },
}

M.options = vim.deepcopy(defaults)

function M.setup(options)
  options = options or {}
  M.options = vim.tbl_deep_extend("force", vim.deepcopy(defaults), options)

  if not vim.tbl_contains({ "global", "tab", "window" }, M.options.cwd_scope) then
    error("worktrunk.nvim: cwd_scope must be 'global', 'tab', or 'window'")
  end
  if not vim.tbl_contains({ "icons", "symbols", "none" }, M.options.picker.status) then
    error("worktrunk.nvim: picker.status must be 'icons', 'symbols', or 'none'")
  end
end

return M
