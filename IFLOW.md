# Dotfiles Configuration Repository

## Project Overview

This is a personal dotfiles configuration repository primarily used for storing and managing development environment configuration files. This repository focuses on providing unified development environment settings, including:

- **LunarVim Configuration**: IDE configuration based on Neovim
- **Tmux Configuration**: Terminal multiplexer settings
- **Automated Installation Script**: Environment configuration for Ubuntu systems

## Main Files Description

### Core Configuration Files

- `config.lua` - Main configuration file for LunarVim, containing plugins, key bindings, and appearance settings
- `.tmux.conf` - Configuration file for Tmux terminal multiplexer
- `lvim-setup-ubuntu.sh` - Automated script for installing and configuring development environment on Ubuntu systems

### Configuration Details

#### LunarVim Configuration Features

- **Theme**: Uses Nordic theme, providing a dark interface
- **Plugin Management**: Includes multiple useful plugins
  - `nvim-ts-autotag`: Automatic tag completion
  - `mini.map`: Code minimap
  - `goto-preview`: Definition preview
  - `symbols-outline.nvim`: Symbol outline
  - `far.vim`: Find and replace tool
  - `todo-comments.nvim`: TODO comment highlighting
  - `markdown-preview.nvim`: Markdown preview
  - `lsp_signature.nvim`: LSP signature help
  - `gopher.nvim`: Go development support
  - `nvim-dap-go`: Go debugging support

- **Key Bindings**:
  - `<C-s>`: Save file
  - `L`: Jump to end of line
  - `H`: Jump to beginning of line
  - `<Tab>`/`<S-Tab>`: Buffer switching

#### Tmux Configuration Features

- **Plugins**:
  - `tmux-sensible`: Sensible default settings
  - `tmux-resurrect`: Session restoration
  - `tmux-gruvbox`: Gruvbox theme

- **Key Bindings**:
  - `|`: Horizontal window split
  - `-`: Vertical window split
  - Mouse support enabled

## Installation and Usage

### Ubuntu System Automatic Installation

Run the following script for complete development environment installation:

```bash
bash lvim-setup-ubuntu.sh
```

This script will:
1. Install necessary system dependencies (curl, wget, unzip, tmux, nodejs, npm, pip, cargo)
2. Install Neovim
3. Install LunarVim

### Manual Configuration Steps

1. **Tmux Configuration**:
   ```bash
   # Copy configuration file
   cp .tmux.conf ~/.tmux.conf
   
   # Install TPM plugin manager
   git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
   
   # Install plugins (press Prefix + I in tmux)
   ```

2. **LunarVim Configuration**:
   ```bash
   # Copy configuration file
   cp config.lua ~/.config/lvim/config.lua
   
   # Recompile plugins (execute in LunarVim)
   :PackerCompile
   ```

## Development Conventions

- **Configuration Management**: All configuration files should maintain simplicity and readability
- **Plugin Selection**: Prioritize lightweight and actively maintained plugins
- **Key Bindings**: Follow common editor key binding habits
- **Theme Consistency**: Maintain visual consistency across different tools

## Project Structure

```
dotfiles/
├── .gitignore           # Git ignore file
├── .tmux.conf          # Tmux configuration
├── config.lua          # LunarVim configuration
├── IFLOW.md            # Project documentation
└── lvim-setup-ubuntu.sh # Ubuntu installation script
```

## Maintenance Notes

- Regularly update plugin versions
- Test new version compatibility
- Backup important configuration changes
- Keep documentation synchronized with updates