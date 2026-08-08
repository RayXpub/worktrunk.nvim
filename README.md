# worktrunk.nvim

An unofficial Neovim integration for [Worktrunk](https://worktrunk.dev/).
Manage worktrees without leaving Neovim.
The plugin runs `wt` asynchronously and updates Neovim's working directory to
the path returned by Worktrunk after a switch.

## Requirements

- Neovim 0.10+
- [Worktrunk](https://worktrunk.dev/worktrunk/#install) available as `wt`

## Installation

With `lazy.nvim`:

```lua
{
  "RayXpub/worktrunk.nvim",
  opts = {},
  keys = {
    { "<leader>ww", "<cmd>Worktrunk<cr>", desc = "Worktrees" },
    { "<leader>wc", "<cmd>WorktrunkCreate<cr>", desc = "Create worktree" },
  },
}
```

For local development, point your plugin manager at this directory or add it
to `runtimepath`:

```lua
vim.opt.runtimepath:prepend("/path/to/worktrunk.nvim")
require("worktrunk").setup()
```

## Usage

```vim
:Worktrunk                       " Select an existing worktree
:Worktrunk switch feature-auth   " Switch by branch or path
:Worktrunk switch --create fix   " Pass switch flags directly to wt
:Worktrunk create fix main       " Create branch `fix` from `main`
:Worktrunk previous              " Switch to the previous worktree
:Worktrunk list                  " Show wt list in a scratch buffer
:Worktrunk remove feature-auth   " Run another wt command in a terminal
```

Convenience commands are also available:

```vim
:WorktrunkSwitch [branch]
:WorktrunkCreate [branch] [base]
:WorktrunkList
```

Switching changes Neovim's working directory; existing buffers remain open.
File explorers and other integrations can react to the `User WorktrunkSwitch`
event. The event's `data` contains Worktrunk's JSON switch result:

```lua
vim.api.nvim_create_autocmd("User", {
  pattern = "WorktrunkSwitch",
  callback = function(event)
    print("Now in " .. event.data.path)
  end,
})
```

## Configuration

Defaults:

```lua
require("worktrunk").setup({
  command = "wt",
  cwd_scope = "global", -- "global", "tab", or "window"
  confirm_create = true,
  picker = {
    include_branches = false,
    include_remotes = false,
    status = "icons", -- "icons", "symbols", or "none"
    icons = {
      ["^"] = "🏠", -- main worktree
      ["|"] = "✅", -- synchronized with upstream
      ["!"] = "📝", -- modified files
      ["?"] = "✨", -- untracked files
      ["+"] = "📦", -- staged files
      ["↑"] = "⬆️", -- ahead of main
      ["↓"] = "⬇️", -- behind main
      ["⇡"] = "⬆️", -- ahead of upstream
      ["⇣"] = "⬇️", -- behind upstream
      ["✘"] = "❌", -- conflicts
      ["_"] = "🧹", -- empty and safe to remove
    },
  },
})
```

The complete default icon mapping is in `lua/worktrunk/config.lua`. Override
only the entries you want to change; setup merges them with the defaults.

### Picker status icons

| Icon | Worktrunk symbol | Meaning |
| --- | --- | --- |
| 🏠 | `^` | Main worktree |
| ✅ | `\|` | Synchronized with upstream |
| 📝 | `!` | Modified files |
| ✨ | `?` | Untracked files |
| 📦 | `+` | Staged files |
| ⬆️ | `↑` | Ahead of the default branch |
| ⬆️ | `⇡` | Ahead of upstream; commits need pushing |
| ⬇️ | `↓` | Behind the default branch |
| ⬇️ | `⇣` | Behind upstream |
| 🔄 | `↕` | Diverged from the default branch |
| 🔄 | `⇅` | Diverged from upstream |
| ❌ | `✘` | Merge conflicts |
| ❌ | `✗` | Would conflict with the default branch |
| 🧹 | `_` | Empty, clean, and safe to remove |
| ✅ | `⊂` | Integrated and safe to remove |
| 🟰 | `–` | At the default branch commit with uncommitted changes |
| 🚫 | `∅` | No common ancestor with the default branch |
| 🔄 | `↻` | Git operation in progress |
| 🗑️ | `⊟` | Prunable worktree with a missing directory |
| 🔒 | `⊞` | Locked worktree |
| ⚠️ | `⚑` | Worktree path mismatch or duplicate branch |
| 🌿 | `/` | Branch without a worktree |

Setting `include_branches` or `include_remotes` widens the picker. Selecting a
branch without a worktree asks Worktrunk to create its worktree before the
plugin switches to it.

Commands other than `switch`, `create`, and `list` open in a terminal so that
interactive prompts continue to work. Since a child terminal cannot change
Neovim's directory, use the native switch commands when changing worktrees.

## Testing

```sh
nvim --headless -u tests/minimal_init.lua -l tests/worktrunk_spec.lua
nvim --headless -u tests/minimal_init.lua -l tests/worktrunk_integration.lua
```

## License

[MIT](LICENSE)
