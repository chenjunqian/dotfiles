export PATH="$HOME/.local/bin:$PATH"

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="amuse"

# Proxy config for Clash Verge
export http_proxy=http://127.0.0.1:7897
export https_proxy=http://127.0.0.1:7897
export all_proxy=socks5://127.0.0.1:7897
export no_proxy=localhost,127.0.0.1,::1

proxy-off() {
  unset http_proxy https_proxy all_proxy no_proxy
  echo "Proxy disabled"
}

proxy-on() {
  export http_proxy=http://127.0.0.1:7897
  export https_proxy=http://127.0.0.1:7897
  export all_proxy=socks5://127.0.0.1:7897
  export no_proxy=localhost,127.0.0.1,::1
  echo "Proxy enabled (Clash Verge :7897)"
}

plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

# opencode
export PATH="$HOME/.opencode/bin:$PATH"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# bun completions
[ -s "/home/junqianchen/.bun/_bun" ] && source "/home/junqianchen/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Go
export GOROOT=$HOME/go
export GOPATH=$HOME/go-workspace
export PATH=$HOME/go/bin:$HOME/go-workspace/bin:$PATH
