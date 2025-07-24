#!/bin/bash

dnf_or_apt() {
    if [ $PKG_MNGR = dnf ]; then
        sudo dnf "$@"
    elif [ $PKG_MNGR = apt-get ]; then
        sudo apt-get "$@"
    else
        echo "Unsupported package manager" >&2
        return 1
    fi
}

setup_local_bin() {
    mkdir $HOME/.local/bin
    export PATH="$HOME/.local/bin:$PATH"
}

install_homebrew() {
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/708c94ee69fafa67c1e475783d3ed36706062743/install.sh)"
    echo >> "$HOME/.bashrc"
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> "$HOME/.bashrc"
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
}

install_fzf() {
    brew install fzf
}

install_ripgrep() {
    brew install ripgrep
}

install_tpm() {
    rm -fr ~/.tmux/plugins/tpm
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
}

install_ruby() {
    if [ $PKG_MNGR = dnf ]; then
        dnf_or_apt install -y ruby
    elif [ $PKG_MNGR = apt-get ]; then
        dnf_or_apt install -y ruby-full
    else
        echo "Unsupported package manager" >&2
        return 1
    fi
}

install_tmux() {
    dnf_or_apt install -y tmux
    install_tpm
    sudo gem install tmuxinator
}

install_fd() {
    dnf_or_apt install -y fd-find
}

install_compilers() {
    if [ $PKG_MNGR = dnf ]; then
        dnf_or_apt install -y make automake gcc gcc-c++ kernel-devel
    elif [ $PKG_MNGR = apt-get ]; then
        dnf_or_apt install -y build-essential
    else
        echo "Unsupported package manager" >&2
        return 1
    fi
}

install_networking_tools() {
    dnf_or_apt install -y net-tools
}

install_go() {
    sudo rm -rf /usr/local/go
    wget https://go.dev/dl/go1.23.4.linux-amd64.tar.gz -O /tmp/go.tar.gz
    sudo tar -C /usr/local -xzf /tmp/go.tar.gz
    export PATH="$HOME/go/bin:/usr/local/go/bin:$PATH"
    go version
}

install_git() {
    dnf_or_apt install -y git git-lfs
    go install github.com/jesseduffield/lazygit@latest
    lazygit --version
    wget https://github.com/nektos/act/releases/download/v0.2.79/act_Linux_x86_64.tar.gz -O /tmp/act.tar.gz
    tar -C ~/.local/bin -xzf /tmp/act.tar.gz
    act --version
}

install_subversion() {
    dnf_or_apt install -y subversion
    go install github.com/YoshihideShirai/tuisvn@latest
}

install_go_tools() {
    go install github.com/air-verse/air@latest
    air -v
}

install_podman() {
    dnf_or_apt -y install podman -y
    podman version
}

install_k8s_tools() {
    go install sigs.k8s.io/kind@v0.26.0
    kind version
    go install github.com/derailed/k9s@v0.50.9
    k9s version
    wget https://github.com/helmfile/helmfile/releases/download/v1.1.3/helmfile_1.1.3_linux_amd64.tar.gz -O /tmp/helmfile.tar.gz
    tar -C ~/.local/bin -xzf /tmp/helmfile.tar.gz
    helmfile version
}

install_docker() {
    if [ $PKG_MNGR = dnf ]; then
        sudo dnf install -y dnf-plugins-core
        sudo dnf-3 config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
        sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        sudo systemctl enable --now docker
        sudo docker run --rm hello-world
    elif [ $PKG_MNGR = apt-get ]; then
        # Add Docker's official GPG key:
        sudo apt-get update
        sudo apt-get install ca-certificates curl
        sudo install -m 0755 -d /etc/apt/keyrings
        sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
        sudo chmod a+r /etc/apt/keyrings/docker.asc
    
        # Add the repository to Apt sources:
        echo \
            "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
            $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
            sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt-get update
    
        # Install latest
        sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
        sudo docker run --rm hello-world
    else
        echo "Unsupported package manager" >&2
        return 1
    fi
    # Add user to docker group
    sudo groupadd docker -f
    sudo usermod -aG docker "$USER"
    newgrp docker
    sudo chown "$USER":"$USER" "$HOME"/.docker -R
    sudo chmod g+rwx "$HOME/.docker" -R
    docker run --rm hello-world
}

install_nodejs() {
    brew install node@22
    source ~/.profile
    source ~/.bashrc
    node -v
    npm -v
}

install_wsl_tools() {
    if ! [ -z $WSL_DISTRO_NAME ]; then
        dnf_or_apt update
        sudo apt install wslu -y
    fi
}

install_markup_tools() {
    dnf_or_apt update
    dnf_or_apt install -y yq jq
    yq --version
    jq --version
}

install_all() {
    dnf_or_apt update
    install_compilers
    setup_local_bin
    install_networking_tools
    install_homebrew
    install_fzf
    install_ripgrep
    install_fd
    install_ruby # needed for tmuxinator
    install_tmux
    install_go
    install_git
    install_go_tools
    install_k8s_tools
    install_docker
    install_podman
    install_nodejs
    install_wsl_tools
    install_markup_tools
    install_subversion
}

set -x

if command -v dnf >/dev/null; then
    PKG_MNGR=dnf
elif command -v apt-get >/dev/null; then
    PKG_MNGR=apt-get
else
    PKG_MNGR=unsupported
    echo "Unsupported package manager" >&2
fi
export OUR_DISTRO


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    set -e
    if [ $PKG_MNGR = unsupported ]; then
        exit 1
    fi
    install_all
fi
