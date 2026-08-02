#!/bin/sh
set -eu
if (set -o pipefail) 2>/dev/null; then
  set -o pipefail
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_NVIM_DIR="${SCRIPT_DIR}/.config/nvim"
TARGET_NVIM_DIR="${HOME}/.config/nvim"
SOURCE_TMUX_CONF="${SCRIPT_DIR}/.tmux.conf"
TARGET_TMUX_CONF="${HOME}/.tmux.conf"
SOURCE_GHOSTTY_CONF="${SCRIPT_DIR}/.config/ghostty/config.ghostty"
TARGET_GHOSTTY_CONF="${HOME}/.config/ghostty/config.ghostty"
SOURCE_ZSH_CONF="${SCRIPT_DIR}/.zshrc"
TARGET_ZSH_CONF="${HOME}/.zshrc"
SOURCE_OPencode_CONF="${SCRIPT_DIR}/.config/opencode/opencode.jsonc"
TARGET_OPencode_CONF="${HOME}/.config/opencode/opencode.jsonc"
SOURCE_ZSH_LOCAL_TEMPLATE="${SCRIPT_DIR}/templates/zshrc.local.example"
TARGET_ZSH_LOCAL="${HOME}/.zshrc.local"
TIMESTAMP="$(date +%Y%m%d%H%M%S)"

case "$(uname -s)" in
  Darwin)
    PLATFORM="macos"
    ;;
  Linux)
    PLATFORM="linux"
    ;;
  *)
    PLATFORM=""
    ;;
esac

SOURCE_GHOSTTY_PLATFORM_CONF="${SCRIPT_DIR}/.config/ghostty/config.ghostty.${PLATFORM}"
TARGET_GHOSTTY_PLATFORM_CONF="${HOME}/.config/ghostty/config.ghostty.${PLATFORM}"

# ── helpers ──

log()    { printf '[quick_setup] %s\n' "$1"; }
warn()   { printf '[quick_setup] \033[33mwarning:\033[0m %s\n' "$1" >&2; }
fail()   { printf '[quick_setup] \033[31merror:\033[0m %s\n' "$1" >&2; exit 1; }
need_cmd() { command -v "$1" >/dev/null 2>&1; }

run_root() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  elif need_cmd sudo; then
    sudo "$@"
  else
    fail "sudo is required to install system packages"
  fi
}

download_file() {
  local url="$1" output="$2"
  if need_cmd curl; then
    curl -fsSL "$url" -o "$output"
  elif need_cmd wget; then
    wget -qO "$output" "$url"
  else
    fail "curl or wget is required to download files"
  fi
}

ensure_local_bin() { mkdir -p "${HOME}/.local/bin"; }

ensure_path_contains_local_bin() {
  case ":${PATH}:" in
    *":${HOME}/.local/bin:"*) return ;;
  esac

  local export_line='export PATH="$HOME/.local/bin:$PATH"'
  for f in "${HOME}/.profile" "${HOME}/.bashrc" "${HOME}/.zprofile"; do
    if [ -f "$f" ] && ! grep -Fq "$export_line" "$f"; then
      printf '\n%s\n' "$export_line" >> "$f"
      log "Added ~/.local/bin to PATH in $f"
    fi
  done

  if [ ! -f "${HOME}/.profile" ]; then
    printf '%s\n' "$export_line" >> "${HOME}/.profile"
    log "Added ~/.local/bin to PATH in ~/.profile"
  fi
}

backup_if_exists() {
  local path="$1"
  if [ -e "$path" ] && [ ! -L "$path" ]; then
    local backup_path="${path}.bak.${TIMESTAMP}"
    mv "$path" "$backup_path"
    log "Backed up ${path} to ${backup_path}"
  fi
}

symlink_config() {
  local src="$1" dst="$2"
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    log "Already symlinked: ${dst}"
    return
  fi
  backup_if_exists "$dst"
  mkdir -p "$(dirname "$dst")"
  rm -rf "$dst"
  ln -sf "$src" "$dst"
  log "Symlinked: ${dst} -> ${src}"
}

# ── package installation ──

install_macos_packages() {
  need_cmd brew || fail "Homebrew is required on macOS. Install it from https://brew.sh/"
  log "Installing packages via Homebrew..."
  brew install neovim tmux git curl ripgrep fd lazygit
}

install_linux_packages() {
  if need_cmd apt-get; then
    run_root apt-get update
    run_root apt-get install -y curl git unzip tar gzip ripgrep fd-find tmux
    return
  fi
  if need_cmd dnf; then
    run_root dnf install -y curl git unzip tar gzip ripgrep fd-find tmux
    return
  fi
  if need_cmd yum; then
    run_root yum install -y curl git unzip tar gzip ripgrep tmux
    return
  fi
  if need_cmd pacman; then
    run_root pacman -Sy --noconfirm curl git unzip tar gzip ripgrep fd tmux
    return
  fi
  if need_cmd zypper; then
    run_root zypper install -y curl git unzip tar gzip ripgrep fd tmux
    return
  fi
  if need_cmd apk; then
    run_root apk add curl git unzip tar gzip ripgrep fd tmux
    return
  fi
  fail "Unsupported Linux package manager"
}

install_lazygit_linux() {
  if need_cmd lazygit; then
    log "lazygit already installed: $(lazygit --version 2>/dev/null | head -n1)"
    return
  fi

  local arch download_url
  arch="$(uname -m)"
  case "$arch" in
    x86_64)         arch="x86_64" ;;
    arm64|aarch64)  arch="arm64" ;;
    *)              fail "Unsupported Linux architecture: $arch" ;;
  esac

  log "Fetching latest lazygit release version..."
  local version
  version="$(curl -fsSI https://github.com/jesseduffield/lazygit/releases/latest | grep -i "^location:" | sed -nE 's#.*tag/v?([0-9]+\.[0-9]+\.[0-9]+).*#\1#p' | head -n 1)"
  [ -n "$version" ] || fail "Could not determine latest lazygit version"

  local temp_dir
  temp_dir="$(mktemp -d)"

  log "Downloading lazygit v${version}..."
  download_file \
    "https://github.com/jesseduffield/lazygit/releases/download/v${version}/lazygit_${version}_Linux_${arch}.tar.gz" \
    "${temp_dir}/lazygit.tar.gz"

  ensure_local_bin
  tar -xzf "${temp_dir}/lazygit.tar.gz" -C "$temp_dir"
  mv "${temp_dir}"/lazygit "${HOME}/.local/bin/lazygit"
  chmod +x "${HOME}/.local/bin/lazygit"
  rm -rf "$temp_dir"
  log "lazygit v${version} installed to ~/.local/bin/lazygit"
}

install_neovim_linux() {
  local arch archive_name
  arch="$(uname -m)"
  case "$arch" in
    x86_64)         archive_name="nvim-linux-x86_64.tar.gz" ;;
    arm64|aarch64)  archive_name="nvim-linux-arm64.tar.gz" ;;
    *)              fail "Unsupported Linux architecture: $arch" ;;
  esac

  local temp_dir archive_path extract_root extracted_dir
  temp_dir="$(mktemp -d)"
  archive_path="${temp_dir}/${archive_name}"

  log "Downloading Neovim binary..."
  download_file "https://github.com/neovim/neovim/releases/latest/download/${archive_name}" "$archive_path"

  tar -xzf "$archive_path" -C "$temp_dir"
  extract_root="$(tar -tzf "$archive_path" | head -n 1 | cut -d/ -f1)"
  extracted_dir="${temp_dir}/${extract_root}"

  [ -d "$extracted_dir" ] || fail "Failed to extract Neovim archive"

  ensure_local_bin
  rm -rf "${HOME}/.local/nvim"
  mv "$extracted_dir" "${HOME}/.local/nvim"
  ln -sf "${HOME}/.local/nvim/bin/nvim" "${HOME}/.local/bin/nvim"
  ensure_path_contains_local_bin

  rm -rf "$temp_dir"
  log "Neovim installed to ~/.local/nvim"
}

install_deps() {
  case "$(uname -s)" in
    Darwin)
      install_macos_packages
      ;;
    Linux)
      install_linux_packages
      install_lazygit_linux
      install_neovim_linux
      ;;
    *)
      fail "Unsupported operating system: $(uname -s)"
      ;;
  esac
}

# ── fd/fdfind link (Debian/Ubuntu) ──

link_fd_if_needed() {
  ensure_local_bin
  if ! need_cmd fd && need_cmd fdfind; then
    ln -sf "$(command -v fdfind)" "${HOME}/.local/bin/fd"
    log "Linked fdfind -> ~/.local/bin/fd"
  fi
}

# ── zsh ──

install_zsh_plugins() {
  if ! need_cmd zsh; then
    warn "zsh not found, skipping zsh setup"
    return
  fi

  if [ ! -d "${HOME}/.oh-my-zsh" ]; then
    log "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    log "Oh My Zsh installed"
  else
    log "Oh My Zsh already installed"
  fi

  local custom_dir="${HOME}/.oh-my-zsh/custom/plugins"

  if [ ! -d "${custom_dir}/zsh-autosuggestions" ]; then
    log "Installing zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions "${custom_dir}/zsh-autosuggestions"
  else
    log "zsh-autosuggestions already installed"
  fi

  if [ ! -d "${custom_dir}/zsh-syntax-highlighting" ]; then
    log "Installing zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting "${custom_dir}/zsh-syntax-highlighting"
  else
    log "zsh-syntax-highlighting already installed"
  fi
}

# ── tmux ──

install_tmux_plugins() {
  local tpm_dir="${HOME}/.tmux/plugins/tpm"
  if ! need_cmd tmux; then
    warn "tmux not found, skipping plugin install"
    return
  fi

  if [ ! -d "$tpm_dir" ]; then
    log "Cloning TPM..."
    git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
  fi

  if [ -f "${tpm_dir}/bin/install_plugins" ]; then
    log "Installing tmux plugins..."
    "${tpm_dir}/bin/install_plugins"
    log "Tmux plugins installed"
  fi

  if tmux ls >/dev/null 2>&1; then
    tmux source-file "$TARGET_TMUX_CONF" 2>/dev/null || true
    log "Reloaded tmux config"
  fi
}

# ── main ──

main() {
  log "=== dotfiles quick setup ==="
  log "Detected OS: $(uname -s)"

  install_deps
  link_fd_if_needed

  [ -d "$SOURCE_NVIM_DIR" ] || fail "Source nvim config not found: ${SOURCE_NVIM_DIR}"
  backup_if_exists "${HOME}/.local/share/nvim"
  backup_if_exists "${HOME}/.local/state/nvim"
  backup_if_exists "${HOME}/.cache/nvim"
  symlink_config "$SOURCE_NVIM_DIR" "$TARGET_NVIM_DIR"

  [ -f "$SOURCE_TMUX_CONF" ] || fail "Source tmux config not found: ${SOURCE_TMUX_CONF}"
  symlink_config "$SOURCE_TMUX_CONF" "$TARGET_TMUX_CONF"

  install_tmux_plugins

  [ -f "$SOURCE_GHOSTTY_CONF" ] || fail "Source ghostty config not found: ${SOURCE_GHOSTTY_CONF}"
  symlink_config "$SOURCE_GHOSTTY_CONF" "$TARGET_GHOSTTY_CONF"

  if [ -n "$PLATFORM" ]; then
    [ -f "$SOURCE_GHOSTTY_PLATFORM_CONF" ] || fail "Source ghostty platform config not found: ${SOURCE_GHOSTTY_PLATFORM_CONF}"
    symlink_config "$SOURCE_GHOSTTY_PLATFORM_CONF" "$TARGET_GHOSTTY_PLATFORM_CONF"
  else
    warn "Unsupported platform, skipping ghostty platform config"
  fi

  [ -f "$SOURCE_OPencode_CONF" ] || fail "Source opencode config not found: ${SOURCE_OPencode_CONF}"
  symlink_config "$SOURCE_OPencode_CONF" "$TARGET_OPencode_CONF"

  [ -f "$SOURCE_ZSH_CONF" ] || fail "Source zsh config not found: ${SOURCE_ZSH_CONF}"
  symlink_config "$SOURCE_ZSH_CONF" "$TARGET_ZSH_CONF"

  if [ ! -f "$TARGET_ZSH_LOCAL" ]; then
    if [ -f "$SOURCE_ZSH_LOCAL_TEMPLATE" ]; then
      cp "$SOURCE_ZSH_LOCAL_TEMPLATE" "$TARGET_ZSH_LOCAL"
      log "Created ${TARGET_ZSH_LOCAL} from template"
      warn "Edit ${TARGET_ZSH_LOCAL} to set your machine's proxy ports"
    else
      warn "zshrc.local template not found: ${SOURCE_ZSH_LOCAL_TEMPLATE}"
    fi
  else
    log "${TARGET_ZSH_LOCAL} already exists"
  fi

  install_zsh_plugins

  echo ""
  log "=== setup complete ==="
  echo "  Neovim: nvim"
  echo "  Tmux:   tmux"
  echo "  Ghostty:  ${TARGET_GHOSTTY_CONF} (+ config.ghostty.${PLATFORM})"
  echo "  opencode: ${TARGET_OPencode_CONF}"
  echo "  Zsh:      ${TARGET_ZSH_CONF}"
  echo "  Local:    ${TARGET_ZSH_LOCAL}"
}

main "$@"
