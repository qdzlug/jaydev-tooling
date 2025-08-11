FROM ubuntu:22.04

SHELL ["/bin/bash", "-c"]
ENV DEBIAN_FRONTEND=noninteractive

# Install the Docker apt repository
RUN apt-get update && \
    apt-get upgrade --yes && \
    apt-get install --yes \
    ca-certificates \
    curl \
    gnupg && \
    install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    chmod a+r /etc/apt/keyrings/docker.gpg && \
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install baseline packages including Docker
RUN apt-get update && \
    apt-get install --yes \
    bash \
    build-essential \
    containerd.io \
    docker-ce \
    docker-ce-cli \
    docker-buildx-plugin \
    docker-compose-plugin \
    htop \
    jq \
    locales \
    man \
    python3 \
    python3-pip \
    software-properties-common \
    sudo \
    systemd \
    systemd-sysv \
    unzip \
    vim \
    wget \
	  htop \
    rsync && \
    rm -rf /var/lib/apt/lists/*

# Install latest Git using their official PPA
RUN add-apt-repository ppa:git-core/ppa && \
    apt-get update && \
    apt-get install --yes git && \
    rm -rf /var/lib/apt/lists/*

# Enable Docker to start with systemd
RUN systemctl enable docker

# Create a symlink for standalone docker-compose usage
RUN ln -s /usr/libexec/docker/cli-plugins/docker-compose /usr/bin/docker-compose

# Set up locale for Unicode
ENV LANG=en_US.UTF-8

# Add a user `coder` so that you're not developing as the `root` user
RUN useradd coder \
    --create-home \
    --shell=/bin/bash \
    --groups docker \
    --uid 1000 \
    --user-group && \
    echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/nopasswd

USER coder
