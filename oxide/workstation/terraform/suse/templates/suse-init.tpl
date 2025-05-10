#cloud-config
users:
  - name: ${username}
    groups: sudo
    shell: /bin/zsh
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    lock_passwd: true
    ssh_authorized_keys:
      - ${public_ssh_key}
