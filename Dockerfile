FROM codercom/code-server:4.16.0-bullseye

ARG TARGETARCH

ENV SHELL=/bin/zsh
SHELL [ "/bin/zsh", "-c" ]

ADD dotfiles /home/coder/

RUN if [[ "$TARGETARCH" == "arm64" ]]; then DOCKERARCH="aarch64"; GOARCH="arm64"; else DOCKERARCH="x86_64"; GOARCH="amd64"; fi; \
    # docker static binary, to allow DIND or remote docker
    sudo groupadd -g 998 docker && \
    sudo usermod -a -G docker coder && \
    curl -sL https://download.docker.com/linux/static/stable/${DOCKERARCH}/docker-23.0.5.tgz | sudo tar --strip-components 1 -xzf - -C /usr/local/bin && \
    sudo mkdir -p /usr/libexec/docker/cli-plugins/ && \
    # go binaries
    curl -sL https://go.dev/dl/$(curl 'https://go.dev/VERSION?m=text').linux-${GOARCH}.tar.gz | sudo tar xzf - -C /usr/local && \
    sudo ln -s /usr/local/go/bin/go /usr/local/bin/ && \
    # nvm to allow easily installing node, if required
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash && \
    # install kubectl and krew including ctx and ns extensions
    sudo curl -L -o /usr/local/bin/kubectl "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${GOARCH}/kubectl" && \
    sudo chown -R coder:coder /home/coder && chmod +x /home/coder/.local/bin/* && sudo chmod +x /usr/local/bin/* && mkdir -p /home/coder/.ssh && \
    set -x; cd "$(mktemp -d)" && \
        OS="$(uname | tr '[:upper:]' '[:lower:]')" && \
        ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" && \
        KREW="krew-${OS}_${ARCH}" && \
        curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" && \
        tar zxvf "${KREW}.tar.gz" && \
        ./"${KREW}" install krew && \
        CUR=$PWD; cd /home/coder; rm -r $CUR && \
    export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH" && kubectl krew install ctx ns

COPY --from=docker/buildx-bin:latest /buildx /usr/libexec/docker/cli-plugins/docker-buildx

RUN  sudo sed -i 's/bullseye main/bullseye main contrib non-free/g' /etc/apt/sources.list && \
     sudo apt-get update && \
     sudo apt-get install -y jq python3 vim fzf bash-completion python3-pip tmux zstd zip p7zip-rar quilt \
            build-essential g++ libx11-dev libxkbfile-dev libsecret-1-dev python-is-python3 acl && \
     sudo apt-get clean

RUN sudo chown -R coder:coder /home/coder && chmod +x /home/coder/.local/bin/* && sudo chmod +x /usr/local/bin/* && mkdir -p /home/coder/.ssh
