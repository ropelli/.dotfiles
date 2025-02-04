#!/usr/bin/env bash
set -e

install_ubuntu() {
    apt update && apt install wget curl tar ripgrep fzf stow -y
    git clone https://github.com/ropelli/.dotfiles ~/.dotfiles
    rm -f ~/.bashrc ~/.profile
    cd ~/.dotfiles
    git submodule update --init --recursive
    git submodule update --recursive --remote
    ./install

    cd ~
    wget https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
    mkdir -p ~/nvim
    cd ~/nvim
    tar -xzf ~/nvim-linux-x86_64.tar.gz
    ln -s ~/nvim/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
}

if [[ "$1" == "ubuntu" ]]; then
    install_ubuntu
fi
