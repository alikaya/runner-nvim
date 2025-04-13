# Runner - Neovim Background Process Manager

A Neovim plugin that provides a seamless interface for running and managing background processes through Telescope.

## Features

- 🚀 Run predefined commands in background
- ⚡ Execute custom commands on the fly
- 📋 Manage running processes
- 💾 Persistent command storage
- 📊 Status line integration
- 🔍 Telescope interface

## Requirements

- Neovim >= 0.5.0
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)

## Installation

Using [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use {
    'your-username/runner.nvim',
    requires = {
        {'nvim-telescope/telescope.nvim'},
        {'nvim-lua/plenary.nvim'}
    }
}
```

## Setup

Add to your init.lua:

```lua
require('runner').setup()
```

## Usage

### Commands

- `:RunnerCommands` - Show available commands
- `:RunnerRunning` - Show and manage running processes
- `:RunnerCustom` - Execute a custom command
- `:RunnerAdd` - Add a new command to the list
- `:RunnerRemove` - Remove a command from the list

### Telescope Interface

In the commands list:
- `<CR>` - Run selected command
- `<C-e>` - Enter custom command

In the running processes list:
- `<CR>` - Stop selected process

### Status Line

The plugin automatically adds running process information to your status line. Example:
```
⚡ PHP Server, NPM Start
```

### Default Commands

- PHP Server (`php -S localhost:8000`)
- NPM Start (`npm start`)
- NPM Dev (`npm run dev`)
- Cargo Run (`cargo run`)
- Cargo Build (`cargo build`)

## Adding Custom Commands

You can add custom commands in two ways:

1. Using the `:RunnerAdd` command:
   ```
   :RunnerAdd
   > Command name: Python Server
   > Command: python -m http.server 8000
   ```

2. Through Telescope interface:
   - Open commands list with `:RunnerCommands`
   - Press `<C-e>` to add a custom command

Commands are stored in `~/.local/share/nvim/runner_commands.json` and persist across Neovim sessions.

## License

MIT
