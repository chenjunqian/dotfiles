#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_NVIM_DIR="${SCRIPT_DIR}/.config/nvim"
TARGET_NVIM_DIR="${HOME}/.config/nvim"
SOURCE_TMUX_CONF="${SCRIPT_DIR}/.tmux.conf"
TARGET_TMUX_CONF="${HOME}/.tmux.conf"
TIMESTAMP="$(date +%Y%m%d%H%M%S)"

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
  local shell_files=("${HOME}/.profile" "${HOME}/.bashrc" "${HOME}/.zprofile")
  for f in "${shell_files[@]}"; do
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
  brew install neovim tmux git curl ripgrep fd
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

  echo ""
  log "=== setup complete ==="
  echo "  Neovim: nvim"
  echo "  Tmux:   tmux"
  echo ""
}

main "$@"
