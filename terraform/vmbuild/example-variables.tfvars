# Proxmox API configuration
pm_api_url      = "https://<proxmox-api-url>"
pm_user         = "<username>@<auth-realm>"
pm_password     = "<password>"
pm_tls_insecure = "<true-or-false>"

# VM configuration
vm_count    = <number-of-vms>
name_prefix = "<vm-name-prefix>"
template    = "<template-location>"
storage     = "<storage-location>"
ssh_keys    = "<ssh-public-key>"

# Node configuration
node = ["<node1>", "<node2>", "<node3>"]
