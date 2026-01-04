# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a [LazyVim](https://lazyvim.github.io/) configuration - a Neovim distribution built on top of Lazy.nvim plugin manager.

## Commands

- **Install plugins**: `:Lazy install` or restart Neovim (plugins auto-install on first run)
- **Update plugins**: `:Lazy update`
- **Clean unused plugins**: `:Lazy clean`
- **Sync plugin changes**: `:Lazy sync`
- **Check plugin status**: `:Lazy`
- **Reload configuration**: `:so $MYVIMRC` or restart Neovim

## Configuration Structure

- `init.lua` - Entry point that bootstraps lazy.nvim and loads the config
- `lua/config/lazy.lua` - Plugin manager setup (LazyVim + custom plugins)
- `lua/config/options.lua` - Neovim options (overrides LazyVim defaults)
- `lua/config/keymaps.lua` - Custom keymaps (extends LazyVim defaults)
- `lua/config/autocmds.lua` - Custom autocommands
- `lua/plugins/` - Language-specific plugins (LSP configuration)

## Custom Language Plugins

Language-specific LSP configurations are in `lua/plugins/`:

- `golang.lua` - gopls with unusedparams/shadow analysis and gofumpt
- `typescript.lua` - ts_ls with formatting enabled + treesitter for tsx
- `swift.lua` - sourcekit-lsp for Swift files

These extend nvim-lspconfig with language server settings.

## Keymaps

- `<Tab>` / `<C-Tab>` - Navigate buffers (next/previous)
- `H` / `L` - Jump to beginning/end of line

## Code Style

Lua code follows these Stylua settings:
- Indent with 2 spaces
- Column width: 120

## Notes

- This configuration inherits all of LazyVim's default plugins and settings
- See [LazyVim documentation](https://lazyvim.github.io/) for keymaps and features
