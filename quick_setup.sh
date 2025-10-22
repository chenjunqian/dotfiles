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


# Install Lazyvim

# required
mv ~/.config/nvim{,.bak}

# optional but recommended
mv ~/.local/share/nvim{,.bak}
mv ~/.local/state/nvim{,.bak}
mv ~/.cache/nvim{,.bak}

cp .config/nvim ~/.config/nvim


# Setup tmux
cp .tmux.conf ~/.tmux.conf