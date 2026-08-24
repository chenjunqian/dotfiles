export PATH="$HOME/.local/bin:$PATH"

# Drop stale proxy inherited from parent processes (e.g. old tmux panes);
# proxy-on is the single source of truth for proxy config.
unset http_proxy https_proxy all_proxy no_proxy

# Machine-local overrides (e.g. proxy ports, per-machine paths).
# Not part of the dotfiles repo; see templates/zshrc.local.example.
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="amuse"

# ── proxy ──
# Proxy is on by default; disable it with proxy-off.
# Ports come from ~/.zshrc.local (PROXY_HTTP_PORT / PROXY_SOCKS_PORT), default
# 7890. On macOS, proxy-on reads the system proxy settings (System Settings >
# Network > Proxies) when they are enabled.

PROXY_HOST="${PROXY_HOST:-127.0.0.1}"
PROXY_HTTP_PORT="${PROXY_HTTP_PORT:-7890}"
PROXY_SOCKS_PORT="${PROXY_SOCKS_PORT:-7890}"

proxy-off() {
  unset http_proxy https_proxy all_proxy no_proxy
  echo "Proxy disabled"
}

proxy-on() {
  if [ "$(uname -s)" = "Darwin" ] && [ "$(scutil --proxy | awk '/HTTPEnable/{print $3}')" = "1" ]; then
    local host port_http port_socks
    host="$(scutil --proxy | awk '/HTTPProxy/{print $3}')"
    port_http="$(scutil --proxy | awk '/HTTPPort/{print $3}')"
    [ -n "$host" ] && [ -n "$port_http" ] || {
      echo "Proxy: system proxy not fully configured" >&2
      return 1
    }
    port_socks=""
    if [ "$(scutil --proxy | awk '/SOCKSEnable/{print $3}')" = "1" ]; then
      port_socks="$(scutil --proxy | awk '/SOCKSPort/{print $3}')"
      export all_proxy="socks5://${host}:${port_socks}"
    fi
    export http_proxy="http://${host}:${port_http}"
    export https_proxy="http://${host}:${port_http}"
    export no_proxy=localhost,127.0.0.1,::1
    echo "Proxy enabled (system: ${host}:${port_http})"
    return
  fi

  export http_proxy="http://${PROXY_HOST}:${PROXY_HTTP_PORT}"
  export https_proxy="http://${PROXY_HOST}:${PROXY_HTTP_PORT}"
  export all_proxy="socks5://${PROXY_HOST}:${PROXY_SOCKS_PORT}"
  export no_proxy=localhost,127.0.0.1,::1
  echo "Proxy enabled (${PROXY_HOST}:${PROXY_HTTP_PORT})"
}

proxy-on

plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

# opencode
export PATH="$HOME/.opencode/bin:$PATH"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Go
export GOROOT=$HOME/go
export GOPATH=$HOME/go-workspace
export PATH=$HOME/go/bin:$HOME/go-workspace/bin:$PATH
export PATH="$HOME/.bun/bin:$PATH"
