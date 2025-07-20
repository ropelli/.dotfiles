#!/usr/bin/env bash
set -e

install_ubuntu() {
    apt update && apt install wget curl tar ripgrep fzf stow xclip tmux -y
    cp -a . ~/.dotfiles
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
    sudo ln -s ~/nvim/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
}

install_fedora() {
    dnf install wget curl tar ripgrep fzf stow tmux -y

    adduser testuser
    usermod -aG wheel testuser
    
    cp -a . /home/testuser/.dotfiles
    cd /home/testuser/.dotfiles
    git submodule update --init --recursive
    git submodule update --recursive --remote
    chown -R testuser:testuser /home/testuser/.dotfiles
    su testuser -c "bash -c 'cd /home/testuser/.dotfiles && ./deps.sh'"
}

if [[ "$1" == "ubuntu" ]]; then
    install_ubuntu
elif [[ "$1" == "fedora" ]]; then
    install_fedora
else
    echo "Unsupported distro '$1'" >&2
    exit 1
fi
