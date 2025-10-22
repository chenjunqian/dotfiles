# Dotfiles Configuration Repository

## Project Overview

This is a personal dotfiles configuration repository primarily used for storing and managing development environment configuration files. This repository focuses on providing unified development environment settings, including:

- **LazyVim Configuration**: IDE configuration based on Neovim
- **Tmux Configuration**: Terminal multiplexer settings
- **Automated Installation Script**: Environment configuration for Ubuntu systems

## Main Files Description

### Core Configuration Files

- `.config/nvim/` - LazyVim configuration directory containing all Neovim settings
- `.tmux.conf` - Configuration file for Tmux terminal multiplexer
- `quick_setup.sh` - Automated script for installing and configuring development environment on Ubuntu systems

### Configuration Details

#### LazyVim Configuration Features

- **Theme**: Uses TokyoNight theme (default in LazyVim)
- **Plugin Management**: Uses lazy.nvim plugin manager with the following key plugins:
  - `blink.cmp`: Completion engine
  - `bufferline.nvim`: Buffer tabs
  - `catppuccin`: Color scheme
  - `conform.nvim`: Code formatting
  - `flash.nvim`: navigation
  - `fzf-lua`: Fuzzy finder
  - `gitsigns.nvim`: Git integration
  - `grug-far.nvim`: Find and replace
  - `neo-tree.nvim`: File explorer
  - `noice.nvim`: UI improvements
  - `nvim-treesitter`: Syntax highlighting
  - `todo-comments.nvim`: TODO highlighting
  - `trouble.nvim`: Diagnostics viewer
  - `which-key.nvim`: Keybinding helper

- **Configuration Structure**:
  - `lua/config/options.lua`: Neovim options (relative line numbers disabled)
  - `lua/config/keymaps.lua`: Custom key mappings
  - `lua/config/autocmds.lua`: Auto commands
  - `lua/config/lazy.lua`: Plugin manager configuration
  - `lua/plugins/`: Plugin specifications

#### Tmux Configuration Features

- **Plugins**:
  - `tmux-sensible`: Sensible default settings
  - `tmux-resurrect`: Session restoration
  - `tmux-gruvbox`: Gruvbox theme (dark)

- **Key Bindings**:
  - `|`: Horizontal window split
  - `-`: Vertical window split
  - Mouse support enabled

## Installation and Usage

### Ubuntu System Automatic Installation

Run the following script for complete development environment installation:

```bash
bash quick_setup.sh
```

This script will:
1. Install system dependencies (curl, wget, unzip, tmux)
2. Install Neovim
3. Backup existing Neovim configurations
4. Copy LazyVim configuration to ~/.config/nvim
5. Copy tmux configuration to ~/.tmux.conf

### Manual Configuration Steps

1. **Tmux Configuration**:
   ```bash
   # Copy configuration file
   cp .tmux.conf ~/.tmux.conf
   
   # Install TPM plugin manager
   git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
   
   # Install plugins (press Prefix + I in tmux)
   ```

2. **LazyVim Configuration**:
   ```bash
   # Backup existing configuration (optional but recommended)
   mv ~/.config/nvim{,.bak}
   mv ~/.local/share/nvim{,.bak}
   mv ~/.local/state/nvim{,.bak}
   mv ~/.cache/nvim{,.bak}
   
   # Copy configuration
   cp -r .config/nvim ~/.config/nvim
   
   # Start Neovim and plugins will be automatically installed
   nvim
   ```

## Development Conventions

- **Configuration Management**: All configuration files should maintain simplicity and readability
- **Plugin Selection**: Prioritize lightweight and actively maintained plugins
- **Key Bindings**: Follow common editor key binding habits
- **Theme Consistency**: Maintain visual consistency across different tools
- **Line Numbers**: Absolute line numbers enabled, relative line numbers disabled

## Project Structure

```
dotfiles/
├── .config/
│   └── nvim/             # LazyVim configuration
│       ├── lua/
│       │   ├── config/   # Neovim configuration files
│       │   └── plugins/  # Plugin specifications
│       ├── init.lua      # Entry point
│       ├── lazy-lock.json # Plugin lock file
│       └── stylua.toml   # Lua formatter config
├── .gitignore            # Git ignore file
├── .tmux.conf           # Tmux configuration
├── IFLOW.md             # Project documentation
└── quick_setup.sh       # Ubuntu installation script
```

## Maintenance Notes

- Regularly update plugin versions using LazyVim's update mechanism
- Test new version compatibility
- Backup important configuration changes
- Keep documentation synchronized with updates
- Use lazy.nvim's health check to verify configuration