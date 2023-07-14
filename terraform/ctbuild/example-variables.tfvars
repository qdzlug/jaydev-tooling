# Proxmox API configuration
proxmox_api_url      = "https://<proxmox-api-url>"
proxmox_username     = "<username>@<auth-realm>"
proxmox_password     = "<password>"
proxmox_tls_insecure = "<true-or-false>"

# Container configuration
container_count = <number-of-containers>
name_prefix = "<container-name-prefix>"
template = "<template-location>"
storage = "<storage-location>"
user_password = "<user-password>"
ssh_keys = "<sshkeys-in-heredoc-form"

# Resource allocation
cores = <number-of-cores>
disk_size = "<disk-size>"
memory = <memory-size>

# Network configuration
network_model = "<network-model>"
network_bridge = "<network-bridge>"
network_ipv4 = "<network-ipv4>"

# Node configuration
node = [
"<node1>", "<node2>", "<node3>"
]
