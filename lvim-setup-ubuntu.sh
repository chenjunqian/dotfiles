apt-get update
apt-get upgrade

apt-get install -y curl
apt-get install -y wget
apt-get install -y unzip
# install lunarvim dependencies
apt-get install -y sudo 
apt-get install -y nodejs
apt-get install -y npm
apt-get install -y pip
apt-get install -y cargo

# install neovim
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
chmod u+x nvim.appimage

./nvim.appimage --appimage-extract
./squashfs-root/AppRun --version

# Optional: exposing nvim globally.
sudo mv squashfs-root /
sudo ln -s /squashfs-root/AppRun /usr/bin/nvim


bash <(curl -s https://raw.githubusercontent.com/lunarvim/lunarvim/master/utils/installer/install.sh)
