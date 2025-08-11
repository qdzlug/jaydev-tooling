#!/bin/bash
set -euxo pipefail

USERNAME="${USERNAME:-jschmidt}"
GITHUB_USER="${GITHUB_USER:-qdzlug}"

# Update base system
sudo apt-get update
sudo apt-get upgrade -y

# Install essential tools
sudo apt-get install -y \
  curl \
  wget \
  git \
  unzip \
  gnupg \
  ca-certificates \
  lsb-release \
  software-properties-common \
  zsh \
  tmux \
  btop \
  build-essential \
  zoxide \
  fzf \
  neovim \
  openssh-client \
  openssh-server

# Install Docker using the official convenience script
curl -fsSL https://get.docker.com | sudo sh

# Create user and set up groups
sudo useradd -m -s /usr/bin/zsh -G sudo,docker "${USERNAME}"
echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/"${USERNAME}"
sudo chmod 0440 /etc/sudoers.d/"${USERNAME}"

# Setup SSH key for user and populate from GitHub
USER_HOME="/home/${USERNAME}"
sudo -u "${USERNAME}" mkdir -p "${USER_HOME}/.ssh"
sudo -u "${USERNAME}" ssh-keygen -t ed25519 -N "" -f "${USER_HOME}/.ssh/id_ed25519"
curl -fsSL "https://github.com/${GITHUB_USER}.keys" | sudo tee "${USER_HOME}/.ssh/authorized_keys" >/dev/null
sudo chown -R "${USERNAME}:${USERNAME}" "${USER_HOME}/.ssh"
sudo chmod 700 "${USER_HOME}/.ssh"
sudo chmod 600 "${USER_HOME}/.ssh/authorized_keys"

# Install chezmoi with sudo to /usr/local/bin
curl -fsLS get.chezmoi.io | sudo sh -s -- -b /usr/local/bin

# Install Tailscale
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/$(lsb_release -cs).noarmor.gpg | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/$(lsb_release -cs).tailscale-keyring.list | \
  sudo tee /etc/apt/sources.list.d/tailscale.list
sudo apt-get update
sudo apt-get install -y tailscale

# Install Starship manually
STARSHIP_VERSION=$(curl -s https://api.github.com/repos/starship/starship/releases/latest | grep tag_name | cut -d '"' -f 4)
curl -Lo starship.tar.gz "https://github.com/starship/starship/releases/download/${STARSHIP_VERSION}/starship-x86_64-unknown-linux-musl.tar.gz"
mkdir -p starship-bin
tar -xzf starship.tar.gz -C starship-bin
sudo mv starship-bin/starship /usr/local/bin/starship
rm -rf starship.tar.gz starship-bin

# Configure starship for all users in zsh
echo 'eval "$(starship init zsh)"' | sudo tee -a /etc/zsh/zshrc

# Install Rust (non-interactive) as the target user
sudo -u "${USERNAME}" bash -c "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y"
echo 'source $HOME/.cargo/env' | sudo tee -a "${USER_HOME}/.zshrc"
sudo chown "${USERNAME}:${USERNAME}" "${USER_HOME}/.zshrc"

# Clean up
sudo apt-get clean
