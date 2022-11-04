apt-get install -y sudo 
sudo apt-get update
sudo apt-get upgrade

sudo apt-get install -y curl
sudo apt-get install -y wget
sudo apt-get install -y unzip
sudo apt-get install tmux
# install lunarvim dependencies
sudo apt-get install -y nodejs
sudo apt-get install -y npm
sudo apt-get install -y pip
sudo apt-get install -y cargo

# install neovim
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
chmod u+x nvim.appimage

./nvim.appimage --appimage-extract
./squashfs-root/AppRun --version

# Optional: exposing nvim globally.
sudo mv squashfs-root /
sudo ln -s /squashfs-root/AppRun /usr/bin/nvim


bash <(curl -s https://raw.githubusercontent.com/lunarvim/lunarvim/master/utils/installer/install.sh)
