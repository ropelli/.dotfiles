#!/bin/bash

dnf_or_apt() {
    if [ $OUR_DISTRO = fedora ]; then
        sudo dnf "$@"
    elif [ $OUR_DISTRO = debian ]; then
        sudo apt-get "$@"
    fi
}

install_homebrew() {
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
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
    dnf_or_apt install -y ruby-full
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
    if [ $OUR_DISTRO = fedora ]; then
        sudo dnf install make automake gcc gcc-c++ kernel-devel
    elif [ $OUR_DISTRO = debian ]; then
        sudo apt-get install -y build-essential
    else
        echo "Unsupported DISTRO" >&2
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
    export PATH="/usr/local/go/bin:$PATH"
    go version
}

install_git() {
    dnf_or_apt install -y git git-lfs
    go install github.com/jesseduffield/lazygit@latest
    lazygit --version
    wget https://github.com/nektos/act/releases/download/v0.2.71/act_Linux_x86_64.tar.gz -O /tmp/act.tar.gz
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
    go install github.com/derailed/k9s@v0.32.7
    k9s version
    wget https://github.com/helmfile/helmfile/releases/download/v1.0.0-rc.8/helmfile_1.0.0-rc.8_linux_amd64.tar.gz -O /tmp/helmfile.tar.gz
    tar -C ~/.local/bin -xzf /tmp/helmfile.tar.gz
    helmfile version
}

install_docker() {
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
    sudo docker run hello-world

    # Add user to docker group
    sudo groupadd docker -f
    sudo usermod -aG docker "$USER"
    newgrp docker
    sudo chown "$USER":"$USER" /home/"$USER"/.docker -R
    sudo chmod g+rwx "$HOME/.docker" -R
    docker run hello-world
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


if which dnf >/dev/null 2>&1; then
    OUR_DISTRO=fedora
elif which apt-get >/dev/ull 2>&1; then
    OUR_DISTRO=debian
else
    OUR_DISTRO=unsupported
    echo "Unsupported DISTRO!" >&2
fi
export OUR_DISTRO


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    set -e
    if [ $OUR_DISTRO = unspported ]; then
        exit 1
    fi
    install_all
fi
