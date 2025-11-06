apt-get install -y sudo 
sudo apt-get update
sudo apt-get upgrade

sudo apt-get install -y curl
sudo apt-get install -y wget
sudo apt-get install -y unzip
sudo apt-get install tmux

# install neovim
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
sudo rm -rf /opt/nvim-linux-x86_64
sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz

# Add neovim to PATH
if ! grep -q "/opt/nvim-linux-x86_64/bin" ~/.bashrc; then
    echo 'export PATH="/opt/nvim-linux-x86_64/bin:$PATH"' >> ~/.bashrc
fi


# Install Lazyvim

# required
mv ~/.config/nvim{,.bak}

# optional but recommended
mv ~/.local/share/nvim{,.bak}
mv ~/.local/state/nvim{,.bak}
mv ~/.cache/nvim{,.bak}

cp -r .config/nvim ~/.config/nvim


# Setup tmux
cp .tmux.conf ~/.tmux.conf

# Install TPM (Tmux Plugin Manager)
if [ ! -d "~/.tmux/plugins/tpm" ]; then
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

# Reload tmux configuration
tmux source-file ~/.tmux.conf 2>/dev/null || echo "Tmux configuration reloaded (run 'tmux source-file ~/.tmux.conf' after starting tmux)"

echo "To install tmux plugins, press prefix+I after starting tmux (prefix is usually Ctrl+B)"
