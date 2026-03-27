#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_CONFIG_DIR="${SCRIPT_DIR}/.config/nvim"
TARGET_CONFIG_DIR="${HOME}/.config/nvim"
TIMESTAMP="$(date +%Y%m%d%H%M%S)"

log() {
  printf '[install_lazyvim] %s\n' "$1"
}

warn() {
  printf '[install_lazyvim] warning: %s\n' "$1" >&2
}

fail() {
  printf '[install_lazyvim] error: %s\n' "$1" >&2
  exit 1
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1
}

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
  local url="$1"
  local output="$2"

  if need_cmd curl; then
    curl -fsSL "$url" -o "$output"
  elif need_cmd wget; then
    wget -qO "$output" "$url"
  else
    fail "curl or wget is required to download files"
  fi
}

ensure_local_bin() {
  mkdir -p "${HOME}/.local/bin"
}

ensure_path_contains_local_bin() {
  case ":${PATH}:" in
    *":${HOME}/.local/bin:"*)
      return
      ;;
  esac

  local export_line='export PATH="$HOME/.local/bin:$PATH"'
  local shell_files=("${HOME}/.profile" "${HOME}/.bashrc" "${HOME}/.zprofile")
  local shell_file

  for shell_file in "${shell_files[@]}"; do
    if [ -f "$shell_file" ] && ! grep -Fq "$export_line" "$shell_file"; then
      printf '\n%s\n' "$export_line" >> "$shell_file"
      log "Added ~/.local/bin to PATH in ${shell_file}"
    fi
  done

  if [ ! -f "${HOME}/.profile" ]; then
    printf '%s\n' "$export_line" >> "${HOME}/.profile"
    log "Added ~/.local/bin to PATH in ${HOME}/.profile"
  fi
}

backup_if_exists() {
  local path="$1"
  if [ -e "$path" ]; then
    local backup_path="${path}.bak.${TIMESTAMP}"
    mv "$path" "$backup_path"
    log "Backed up ${path} to ${backup_path}"
  fi
}

link_fd_if_needed() {
  ensure_local_bin

  if ! need_cmd fd && need_cmd fdfind; then
    ln -sf "$(command -v fdfind)" "${HOME}/.local/bin/fd"
    log "Linked fdfind to ~/.local/bin/fd"
  fi
}

install_macos_packages() {
  need_cmd brew || fail "Homebrew is required on macOS. Install it first from https://brew.sh/"
  brew install neovim git curl unzip ripgrep fd
}

install_linux_packages() {
  if need_cmd apt-get; then
    run_root apt-get update
    run_root apt-get install -y curl git unzip tar gzip ripgrep fd-find
    return
  fi

  if need_cmd dnf; then
    run_root dnf install -y curl git unzip tar gzip ripgrep fd-find
    return
  fi

  if need_cmd yum; then
    run_root yum install -y curl git unzip tar gzip ripgrep
    return
  fi

  if need_cmd pacman; then
    run_root pacman -Sy --noconfirm curl git unzip tar gzip ripgrep fd
    return
  fi

  if need_cmd zypper; then
    run_root zypper install -y curl git unzip tar gzip ripgrep fd
    return
  fi

  if need_cmd apk; then
    run_root apk add curl git unzip tar gzip ripgrep fd
    return
  fi

  fail "unsupported Linux package manager"
}

install_neovim_linux() {
  local arch
  local archive_name
  local temp_dir
  local archive_path
  local extract_root
  local extracted_dir

  arch="$(uname -m)"
  case "$arch" in
    x86_64)
      archive_name="nvim-linux-x86_64.tar.gz"
      ;;
    arm64|aarch64)
      archive_name="nvim-linux-arm64.tar.gz"
      ;;
    *)
      fail "unsupported Linux architecture: ${arch}"
      ;;
  esac

  temp_dir="$(mktemp -d)"
  archive_path="${temp_dir}/${archive_name}"

  log "Downloading Neovim ${archive_name}"
  download_file "https://github.com/neovim/neovim/releases/latest/download/${archive_name}" "$archive_path"

  tar -xzf "$archive_path" -C "$temp_dir"
  extract_root="$(tar -tzf "$archive_path" | head -n 1 | cut -d/ -f1)"
  extracted_dir="${temp_dir}/${extract_root}"

  [ -d "$extracted_dir" ] || fail "failed to extract Neovim archive"

  ensure_local_bin
  rm -rf "${HOME}/.local/nvim"
  mv "$extracted_dir" "${HOME}/.local/nvim"
  ln -sf "${HOME}/.local/nvim/bin/nvim" "${HOME}/.local/bin/nvim"
  ensure_path_contains_local_bin

  rm -rf "$temp_dir"
}

install_neovim() {
  case "$(uname -s)" in
    Darwin)
      log "Installing Neovim with Homebrew"
      install_macos_packages
      ;;
    Linux)
      log "Installing Linux dependencies"
      install_linux_packages
      install_neovim_linux
      ;;
    *)
      fail "unsupported operating system: $(uname -s)"
      ;;
  esac
}

install_config() {
  [ -d "$SOURCE_CONFIG_DIR" ] || fail "source config directory not found: ${SOURCE_CONFIG_DIR}"

  backup_if_exists "$TARGET_CONFIG_DIR"
  backup_if_exists "${HOME}/.local/share/nvim"
  backup_if_exists "${HOME}/.local/state/nvim"
  backup_if_exists "${HOME}/.cache/nvim"

  mkdir -p "${HOME}/.config"
  cp -R "$SOURCE_CONFIG_DIR" "$TARGET_CONFIG_DIR"
  log "Installed config to ${TARGET_CONFIG_DIR}"
}

main() {
  log "Installing LazyVim prerequisites and config"
  install_neovim
  link_fd_if_needed
  install_config
  log "Done. Start Neovim with: nvim"
}

main "$@"
