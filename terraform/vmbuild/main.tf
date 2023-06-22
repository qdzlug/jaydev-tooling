terraform {
  required_providers {
    proxmox = {
      source = "Telmate/proxmox"
      version = "2.9.10"
    }
  }
}

provider "proxmox" {
  pm_api_url = "https://192.168.212.101:8006/api2/json"
  pm_user = "root@pam"
  pm_password = var.pm_password
  pm_tls_insecure = "true"
}

variable "node" {
  description = "The node where you want the VMs to be created at."
  type = list(string)
}

variable "vm_count" {
  description = "The number of VMs to create."
  type = number
}

variable "template" {
  description = "The template to use for creating the VMs."
  type = string
}

variable "pm_password" {
  description = "The password for the Proxmox API."
  type = string
  sensitive = true
}

resource "proxmox_vm_qemu" "proxmox_vm" {
  count = var.vm_count
  name = "tf-vm-${count.index}"
  clone = var.template
  os_type = "cloud-init"
  target_node = var.node[count.index % length(var.node)]
  cores = "4"
  sockets = "1"
  cpu = "host"
  memory = 8096
  scsihw = "virtio-scsi-pci"
  bootdisk = "scsi0"
  agent = 0

  disk {
    size = "128G"
    type = "scsi"
    storage = "ceph01"
    iothread = 0
  }

  network {
    model = "virtio"
    bridge = "vmbr0"
  }

  lifecycle {
    ignore_changes = [
      network,
    ]
  }

  sshkeys = <<EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDh6ROxdnUrSAmjyqzlpvcSFlXcSwD7VMp7PvCTzAtDePSluBiQq3njWW88Pcxgmhsqhsm/ZjRKTdFO5RWRt2YM3BsZQqIMlsulIKK426RavgtnMYpJuUhTkyVm1QQAaoOH4NvkBOk35VOWylzxSZFa2v+LExjOQzQM5CfXB2GX7KerNNvEMNuTnFQ5upuV8YOEeeeomfLmt/I8VMxFJiSQWlELkS2NBVbhWKHcRaE2T2X2eASaruqlDhSMgeE0K/8bRuLquvv5j0F3rQ6slbVi0zjdIMRUlwD4gsZOQaSiFrQceItR+slp3/2FT/o6uxW/lJu3sW5RkHNHMxubSFpl jschmidt@jack.virington.com
EOF
}
