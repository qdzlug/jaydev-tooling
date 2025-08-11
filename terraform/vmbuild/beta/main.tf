terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "2.9.10"
    }
  }
}

variable "pm_api_url" {
  description = "The API URL for the Proxmox provider."
  type        = string
}

variable "pm_user" {
  description = "The user for the Proxmox provider."
  type        = string
}

variable "pm_password" {
  description = "The password for the Proxmox provider."
  type        = string
  sensitive   = true
}

variable "pm_tls_insecure" {
  description = "Whether to disable TLS verification for the Proxmox provider."
  type        = string
}

provider "proxmox" {
  pm_api_url      = var.pm_api_url
  pm_user         = var.pm_user
  pm_password     = var.pm_password
  pm_tls_insecure = var.pm_tls_insecure
}

variable "storage" {
  description = "The storage to use for the VMs."
  type        = string
}

variable "name_prefix" {
  description = "The prefix for the name of the VMs."
  type        = string
}

variable "node" {
  description = "The node where you want the VMs to be created at."
  type        = list(string)
}

variable "vm_count" {
  description = "The number of VMs to create."
  type        = number
}

variable "template" {
  description = "The template to use for creating the VMs."
  type        = string
}

variable "ssh_keys" {
  description = "The SSH keys to use for the VMs."
  type        = string
}


resource "proxmox_vm_qemu" "proxmox_vm" {
  count       = var.vm_count
  name        = "${var.name_prefix}${count.index}"
  clone       = var.template
  full_clone  = true
  os_type     = "cloud-init"
  target_node = var.node[count.index % length(var.node)]
  cores       = "4"
  sockets     = "1"
  cpu         = "host"
  memory      = 8192
  scsihw      = "virtio-scsi-pci"
  bootdisk    = "scsi0"
  agent       = 1

  disk {
    size     = "200G"
    type     = "scsi"
    storage  = var.storage
    iothread = 0
  }

  network {
    model  = "virtio"
    bridge = "vmbr0"
  }

  lifecycle {
    ignore_changes = [
      network,
    ]
  }

  sshkeys = var.ssh_keys
}

output "name" {
  description = "Names of the created VMs"
  value       = [for i in proxmox_vm_qemu.proxmox_vm : i.name]
}

output "ssh_host" {
  description = "SSH host of the created VMs"
  value       = [for i in proxmox_vm_qemu.proxmox_vm : i.ssh_host]
}

output "cores" {
  description = "Number of cores of the created VMs"
  value       = [for i in proxmox_vm_qemu.proxmox_vm : i.cores]
}

output "memory" {
  description = "Memory sizes of the created VMs"
  value       = [for i in proxmox_vm_qemu.proxmox_vm : i.memory]
}

output "disk_size" {
  description = "Disk sizes of the created VMs"
  value       = [for i in proxmox_vm_qemu.proxmox_vm : i.disk[0].size]
}
