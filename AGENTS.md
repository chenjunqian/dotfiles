# Dotfiles Configuration Repository

## Project Overview

This is a personal dotfiles configuration repository primarily used for storing and managing development environment configuration files. This repository focuses on providing unified development environment settings, including:

- **LazyVim Configuration**: IDE configuration based on Neovim
- **Python Toolchain**: uv-managed CPython (3.15) plus LazyVim's stock Python extra in Neovim
- **Tmux Configuration**: Terminal multiplexer settings
- **Zsh Configuration**: Shell environment (Oh My Zsh, proxy helpers, NVM)
- **Ghostty Configuration**: Terminal emulator settings
- **Antigravity CLI (agy) Configuration**: AI CLI agent settings, permissions, and models
- **Pi Agent Configuration**: Pi coding agent settings, default model, and UI preferences
- **DSH (DeepSeek Harness) Configuration**: web profile user patch layer, bundle selection, and pinned plugin versions
- **Automated Installation Script**: Environment configuration for Ubuntu systems

## Main Files Description

### Core Configuration Files

- `.config/nvim/` - LazyVim configuration directory containing all Neovim settings
- `.tmux.conf` - Configuration file for Tmux terminal multiplexer
- `.zshrc` - Zsh shell configuration (Oh My Zsh, proxy helpers, NVM)
- `.config/ghostty/config.ghostty` - Ghostty terminal configuration
- `.config/opencode/opencode.jsonc` - OpenCode AI assistant configuration
- `.gemini/antigravity-cli/settings.json` - Antigravity CLI (`agy`) configuration
- `.pi/agent/settings.json` - Pi coding agent configuration
- `.dsh/profiles/web/` - DSH (DeepSeek Harness) web profile configuration (patch layer, bundles, plugin lockfile)
- `scripts/dsh-sync.sh` - Link (symlink) / mirror (copy) the DSH web-profile config between `~/.dsh` and this repo
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
  - `markdown-preview.nvim`: Live browser markdown preview
  - `neo-tree.nvim`: File explorer
  - `noice.nvim`: UI improvements
  - `nvim-treesitter`: Syntax highlighting
  - `render-markdown.nvim`: In-buffer rich rendered markdown preview
  - `todo-comments.nvim`: TODO highlighting
  - `trouble.nvim`: Diagnostics viewer
  - `which-key.nvim`: Keybinding helper

- **Configuration Structure**:
  - `lua/config/options.lua`: Neovim options (relative line numbers disabled)
  - `lua/config/keymaps.lua`: Custom key mappings
  - `lua/config/autocmds.lua`: Auto commands
  - `lua/config/lazy.lua`: Plugin manager configuration (LazyVim extras are imported here)
  - `lua/plugins/`: Plugin specifications

#### Markdown Support

LazyVim's `lang.markdown` extra is imported, with diagnostics turned off in
`lua/plugins/markdown.lua` + `lua/config/autocmds.lua`:

- **No lint diagnostics**: `nvim-lint`'s `markdownlint-cli2` linter is removed for
  `markdown` / `markdown.mdx`, and `FileType` autocmds disable diagnostics display for
  `markdown`, `markdown.mdx`, `rmd`, `norg`, `org` buffers — so MD013 line-length /
  MD033 inline-HTML warnings no longer clutter writing and preview.
- **marksman LSP disabled**: it indexes the whole project and floods Neovim with
  per-document diagnostics (buffer/memory blowup on repos with thousands of `.md`).
- **Still available**: `<leader>cp` (`markdown-preview.nvim`), rich in-buffer rendering
  (`render-markdown.nvim`, toggle with `<leader>um`), treesitter highlighting, and
  formatting (`prettier`, `markdown-toc` via `<leader>cf`; the `markdownlint-cli2`
  conform formatter only fires when markdownlint diagnostics exist, so it stays idle).
- Temporarily re-enable diagnostics with `:lua vim.diagnostic.enable(true)`.

#### Python Support

Python is LazyVim's stock `lang.python` extra — imported in `lua/config/lazy.lua`,
no custom plugin spec file:

- **LSP**: `pyright` (type checking) and `ruff` (linting + formatting), installed
  automatically by Mason on first use. `basedpyright` and the old `ruff_lsp` can be
  selected instead via `vim.g.lazyvim_python_lsp` / `vim.g.lazyvim_python_ruff` in
  `lua/config/options.lua` (must be set there, LazyVim reads them while importing the extra).
- **Formatting**: no Python formatter is configured in `conform.nvim`, so `<leader>cf`
  falls back to the Ruff LSP. The `ruff_format` / `ruff_organize_imports` conform
  formatters can be enabled by adding them to `formatters_by_ft`.
- **Virtual envs**: `venv-selector.nvim` — `<leader>cv` (or `:VenvSelect`) picks the
  interpreter for the current project. Created by `uv venv` (`.venv/`) works out of the box.
- **Tests / debugging**: `neotest-python` ships with the extra but is only activated
  when the LazyVim extra `test.core` is enabled (`:LazyExtras`). DAP-related
  plugins (`nvim-dap`, `nvim-dap-python`, `nvim-dap-go`, `nvim-dap-ui`, etc.) are
  disabled in `lua/plugins/dap.lua`.

Python itself is provided by [uv](https://docs.astral.sh/uv/), installed by
`quick_setup.sh`:

```bash
uv python install --default 3.15   # latest stable CPython
uv python list                     # installed interpreters
uv venv --python 3.15              # create .venv for a project
uv add --dev pytest ruff           # project dev dependencies
```

This puts `~/.local/bin/python`, `python3` and `python3.15` on `PATH` ahead of the
Ubuntu system interpreters, which stay untouched at `/usr/bin/python3` (3.14).
The script also installs `python3-venv` / `python3-dev` for the system Python.
The `uv` and `ruff` Oh My Zsh plugins in `.zshrc` add its aliases/completions.

#### Tmux Configuration Features

- **Plugins**:
  - `tmux-sensible`: Sensible default settings
  - `tmux-resurrect`: Session restoration
  - `tmux-gruvbox`: Gruvbox theme (dark)

- **Key Bindings**:
  - `|`: Horizontal window split
  - `-`: Vertical window split
  - Mouse support enabled

#### Antigravity CLI Configuration Features

- **Configuration File**: `.gemini/antigravity-cli/settings.json`
- **Default Model**: Configured model (e.g. Gemini 3.8 Flash High)
- **Permissions**: Safe auto-allow permissions (file reading, specific directory writes) and command safety denylists (`rm -rf /`, `sudo*`)
- **Tool Permissions**: Configured execution policies (`always-proceed`)

#### Pi Agent Configuration Features

- **Configuration File**: `.pi/agent/settings.json` (symlinked to `~/.pi/agent/settings.json`)
- **Default Model**: Not pinned in settings; the `restore-last-session` extension carries the model and thinking level over from the latest session (Pi auto-selects on the first-ever session)
- **Theme**: Custom `gruvbox` dark theme (`.pi/agent/themes/gruvbox.json`, symlinked to `~/.pi/agent/themes`), matching the tmux gruvbox theme
- **Packages**: `npm:pi-web-access` (web search, URL/PDF/YouTube/GitHub fetching). Works keyless via Exa MCP; optional API keys go in `~/.pi/agent/web-search.json`
- **Extensions**: (symlinked to `~/.pi/agent/extensions`)
  - `restore-last-session.ts` — new sessions inherit the model and thinking level of the latest previous session; falls back to scanning session history when the project has no record
  - `notify-on-done.ts` — notifies when a run settles (`agent_settled`) and Pi is waiting for input. Backend chosen automatically: OSC 777/99 terminal notification (wrapped in a tmux DCS passthrough inside tmux), `notify-send` desktop notification, or BEL. Override with `PI_NOTIFY_BACKEND=auto|terminal|desktop|bell|off` and suppress short runs with `PI_NOTIFY_MIN_MS` (e.g. `5000`)

`quick_setup.sh` runs `pi update --extensions` after linking to (re)install declared packages.

> Note: Pi also stores runtime state (e.g. `lastChangelogVersion`) in `settings.json`; commits may include those small updates after a Pi upgrade.

#### DSH (DeepSeek Harness) Configuration Features

DSH composes each profile from layered patches: the bundle layers listed in
`dsh.profile.bundles`, then the profile's own `cordis.patch.yml`, then the
home-level `$DSH_HOME/cordis.patch.yml`, then any `--patch` overlays. Only the
user-authored layers are backed up here — the rest of `~/.dsh` is either
rebuildable (dependencies), machine-local runtime state (sessions, attachments,
caches, `storages/`), or secret (`.credentials.yaml` holds the API key in
cleartext and is never committed).

- **Profile**: `web` only. Only `~/.dsh/profiles/web` is tracked; any other
  profile under `~/.dsh/profiles` is left alone and is not backed up here.
- **Tracked files** (`.dsh/profiles/web/`):
  - `cordis.patch.yml` — the real config: default model (`deepseek-flash`,
    reasoning effort `high`), provider models, permission presets and their
    `defaultPreset`, UI theme, welcome-notice version
  - `package.json` — enabled bundles (`@deepseek-ai/dsh-base`,
    `@deepseek-ai/dsh-web-app`, `dshmarket`, `@xbzbing/dsh-git-panel`,
    `@dongasai/dsh-editor`, `dsh-cost-meter`) and the installed marketplace
    plugins
  - `pnpm-lock.yaml` — pinned plugin versions used by `dsh plugin install`
- **Not tracked**: `pnpm-workspace.yaml` is regenerated by pnpm/the plugin
  manager (`nodeLinker: hoisted`, `allowBuilds`). If a restore warns about a
  blocked build, re-add the exact key pnpm prints under `allowBuilds`.
- **Two sync modes, with a healer** (`scripts/dsh-sync.sh`):
  - **linked** — `cordis.patch.yml`, `package.json`: `~/.dsh/profiles/web/<file>`
    is a symlink into the repo, so an edit on either side shows up on both and
    in `git status`. dsh writes them through `writeFileAtomic` (temp file +
    rename), and a rename replaces the symlink with a regular file — `link`
    adopts that content and re-creates the symlink.
  - **mirrored** — `pnpm-lock.yaml`: the live file is a **regular file** and the
    repo keeps a copy. It cannot be a symlink: pnpm 11 runs in the profile
    directory and refuses to write a symlinked lockfile
    (`ERR_PNPM_LOCKFILE_IS_SYMLINK`), which broke every install/update from
    `dsh plugin` *and* the plugin market's "update all". `watch` copies
    live → repo whenever pnpm rewrites it; `link` also pushes repo → live when
    the repo copy is newer.
  - A systemd user service (`dsh-sync.service`, from
    `scripts/systemd/dsh-sync.service.in`) runs `dsh-sync.sh watch`, which heals
    within a couple of seconds of every dsh write. Without the service the
    package.json link breaks silently on the next settings save and the
    lockfile copy goes stale; `status` reports both.
- **Commands**: `scripts/dsh-sync.sh link|save|restore|status`. `link` and
  `save` are the same (reconcile, newer side wins); `restore` forces the repo
  content onto a fresh machine and backs up whatever was there. `quick_setup.sh`
  runs `link`, then installs and starts the watcher.
- **Installing/updating plugins**: `dsh plugin --profile web add <pkg>` or the
  in-GUI plugin market work directly now — no need to stop the watcher. pnpm
  rewrites the lockfile and the plugin manager appends the bundle to
  `dsh.profile.bundles`; the watcher picks both up within seconds. Then
  **restart `dsh web`**: host plugin rows and the client bundles are scanned at
  startup only. `dsh --profile web --dump-config` shows a new row (e.g.
  `cost-meter`) without a restart and confirms the patch loaded.
- **Version sensitivity**: patch entries target plugin ids, so upgrading dsh can
  invalidate a patch that a newer bundle renamed. Check with
  `dsh --profile web --dump-config` after an upgrade.

## Installation and Usage

### Ubuntu System Automatic Installation

Run the following script for complete development environment installation:

```bash
bash quick_setup.sh
```

This script will:
1. Install system dependencies (curl, wget, unzip, tmux, python3-venv, python3-dev)
2. Install the terminal font (JetBrains Maple Mono: JetBrains Mono Latin + Maple Mono CJK, 2:1 aligned, Nerd Font icons)
3. Install Neovim
4. Install uv and the latest stable CPython (becomes the default `python`/`python3`)
5. Back up existing Neovim configurations
6. Copy LazyVim configuration to ~/.config/nvim
7. Copy tmux configuration to ~/.tmux.conf
8. Copy ghostty configuration to ~/.config/ghostty
9. Copy opencode configuration to ~/.config/opencode
10. Copy Antigravity CLI configuration to ~/.gemini/antigravity-cli
11. Copy pi configuration to ~/.pi/agent
12. Link DSH web profile configuration into ~/.dsh (`scripts/dsh-sync.sh link`; symlinks for the patch layer and `package.json`, a mirrored `pnpm-lock.yaml`) and start the `dsh-sync` user service that heals it after dsh's atomic writes
13. Copy zsh configuration to ~/.zshrc

### Terminal font

Ghostty is configured with `font-family = JetBrains Maple Mono`
([Fusion-JetBrainsMapleMono](https://github.com/SpaceTimee/Fusion-JetBrainsMapleMono), OFL-1.1):
JetBrains Mono glyphs for Latin, Maple Mono for CJK, strictly 2:1 cell metrics,
bundled Nerd Font icons. This avoids the mixed-width misalignment you get from
teaming JetBrains Mono (0.6em advance) with a 1em-wide CJK fallback.

`quick_setup.sh` installs it to `~/.local/share/fonts/JetBrainsMapleMono`
(`~/Library/Fonts/JetBrainsMapleMono` on macOS) when the family is missing.
Bump `FUSION_FONT_VERSION` in `quick_setup.sh` to upgrade.

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
│   ├── ghostty/
│   │   ├── config.ghostty       # Ghostty terminal config
│   │   ├── config.ghostty.linux # Linux-specific ghostty config
│   │   └── config.ghostty.macos # macOS-specific ghostty config
│   ├── nvim/                    # LazyVim configuration
│   │   ├── lua/
│   │   │   ├── config/          # Neovim configuration files
│   │   │   └── plugins/         # Plugin specifications
│   │   ├── init.lua             # Entry point
│   │   ├── lazy-lock.json       # Plugin lock file
│   │   └── stylua.toml          # Lua formatter config
│   └── opencode/
│       └── opencode.jsonc       # OpenCode AI configuration
├── .gemini/
│   └── antigravity-cli/
│       └── settings.json        # Antigravity CLI configuration
├── .pi/
│   └── agent/
│       ├── settings.json        # Pi coding agent configuration
│       ├── extensions/
│       │   ├── notify-on-done.ts        # Notify when a run settles
│       │   └── restore-last-session.ts  # Carry over model/thinking to new sessions
│       └── themes/
│           └── gruvbox.json     # Pi gruvbox theme
├── .dsh/
│   └── profiles/
│       └── web/
│           ├── cordis.patch.yml # User patch layer (model, permissions, theme)
│           ├── package.json     # Enabled bundles + installed plugins
│           └── pnpm-lock.yaml   # Pinned plugin versions
├── scripts/
│   ├── dsh-sync.sh              # Link + mirror DSH config into ~/.dsh
│   └── systemd/
│       └── dsh-sync.service.in  # User service template (watch mode)
├── .gitignore                   # Git ignore file
├── .tmux.conf                  # Tmux configuration
├── .zshrc                      # Zsh configuration
├── quick_setup.sh              # Automatic setup & symlinking script
└── templates/
    └── zshrc.local.example     # Machine-local zsh config template
```

## Maintenance Notes

- Regularly update plugin versions using LazyVim's update mechanism
- Test new version compatibility
- Backup important configuration changes
- DSH config lives in the repo: `cordis.patch.yml`/`package.json` are symlinked,
  `pnpm-lock.yaml` is mirrored as a regular file (pnpm refuses a symlinked
  lockfile). The `dsh-sync` user service heals both after every dsh/pnpm write.
  If `scripts/dsh-sync.sh status` reports a broken link or drift and no service
  is running, run `link` by hand
- Never commit `~/.dsh/.credentials.yaml` or the rest of `~/.dsh` (sessions,
  attachments, dependencies)
- Keep documentation synchronized with updates
- Use lazy.nvim's health check to verify configuration