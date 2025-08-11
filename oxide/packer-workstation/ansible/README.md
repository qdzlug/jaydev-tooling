# 🛠️ Ansible Automation for Workstation + Oxide Setup

This directory contains a modular Ansible setup to configure Linux systems and integrate with [Oxide Computer Company](https://oxide.computer) infrastructure.

## 📋 What It Does

- Adds a system user and configures SSH access (via GitHub)
- Installs a full developer environment (tmux, zsh, chezmoi, starship, rust, neovim, etc.)
- Bootstraps dotfiles via [chezmoi](https://www.chezmoi.io/)
- Installs Tailscale VPN
- Supports multiple Linux distros: Ubuntu/Debian, RHEL, SUSE

## 📦 Getting Started

```bash
make install           # Create virtual environment + install Ansible
source .venv/bin/activate
ansible-playbook playbook.yml -i inventory/hosts.ini
```

## 📁 Project Structure

```
ansible/
├── playbook.yml         # Main playbook
├── vars.yml             # Central variable definitions
├── ansible.cfg          # Config file pointing to hosts
├── inventory/
│   └── hosts.ini        # Static inventory
├── roles/
│   ├── user_add/        # Adds a system user + SSH keys
│   ├── common/          # Base package installation
│   ├── tools/           # Developer tools and CLI utils
│   ├── chezmoi/         # Dotfile setup
│   └── tailscale/       # VPN setup
└── Makefile             # venv management
```

## 🧪 Example: Override Vars

```bash
ansible-playbook playbook.yml \
  -e new_user=myuser \
  -e github_user=mygithubname
```

## 🔐 Requirements

- Python 3.7+
- Access to GitHub (for SSH keys)
- SSH access to remote machines

