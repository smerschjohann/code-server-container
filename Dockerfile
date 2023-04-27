FROM codercom/code-server:4.12.0-bullseye

RUN sudo groupadd -g 998 docker && \
    sudo usermod -a -G docker coder && \
    curl -sL https://download.docker.com/linux/static/stable/aarch64/docker-23.0.4.tgz | sudo tar --strip-components 1 -xzf - -C /usr/local/bin && \
    sudo mkdir -p /usr/libexec/docker/cli-plugins/ && \
    curl -sL https://go.dev/dl/go1.20.3.linux-arm64.tar.gz | sudo tar xzf - -C /usr/local && \
    sudo ln -s /usr/local/go/bin/go /usr/local/bin/

COPY --from=docker/buildx-bin:latest /buildx /usr/libexec/docker/cli-plugins/docker-buildx

RUN  sudo sed -i 's/bullseye main/bullseye main contrib non-free/g' /etc/apt/sources.list && \
     sudo apt-get update && \
     sudo apt-get install -y jq python3 vim fzf bash-completion python3-pip tmux zstd zip p7zip-rar && \
     sudo apt-get clean

ENV SHELL=/bin/zsh