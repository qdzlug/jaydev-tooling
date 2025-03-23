terraform {
  required_version = ">= 1.0"

  required_providers {
    oxide = {
      source  = "oxidecomputer/oxide"
      version = "0.5.0"
    }
  }
}

provider "oxide" {}

data "oxide_project" "workstation" {
  # Fetch project by name
  name = var.project_name
}

resource "oxide_ssh_key" "workstation" {
  # SSH key for access
  name        = "workstation-sshkey"
  description = "SSH Key for Access"
  public_key  = var.public_ssh_key
}

data "oxide_instance_external_ips" "workstation" {
  for_each    = oxide_instance.workstation
  instance_id = each.value.id
}

resource "oxide_vpc" "workstation" {
  project_id  = data.oxide_project.workstation.id
  description = var.vpc_description
  name        = var.vpc_name
  dns_name    = var.vpc_dns_name
}

data "oxide_vpc_subnet" "workstation" {
  project_name = data.oxide_project.workstation.name
  vpc_name     = oxide_vpc.workstation.name
  name         = "default"
}

resource "oxide_disk" "workstation_disks" {
  for_each = { for i in range(var.instance_count) : i => "disk-${var.instance_prefix}-${i + 1}" }

  project_id      = data.oxide_project.workstation.id
  description     = "Disk for instance ${each.value}"
  name            = each.value
  size            = var.disk_size
  source_image_id = var.boot_image_id
}

resource "oxide_instance" "workstation" {
  for_each = { for i in range(var.instance_count) : i => "${var.instance_prefix}-${i + 1}" }

  project_id       = data.oxide_project.workstation.id
  boot_disk_id     = oxide_disk.workstation_disks[each.key].id
  description      = "Workstation instance ${each.value}"
  name             = each.value
  host_name        = each.value
  memory           = var.memory
  ncpus            = var.ncpus
  start_on_create  = true
  disk_attachments = [oxide_disk.workstation_disks[each.key].id]
  ssh_public_keys  = [oxide_ssh_key.workstation.id]

  # Use a template file for cloud-init, injecting the username variable.
  user_data = base64encode(templatefile("./templates/suse-init.tpl", {
    username       = var.username
    public_ssh_key = var.public_ssh_key
  }))

  external_ips = [
    {
      type = "ephemeral"
    }
  ]
  network_interfaces = [
    {
      subnet_id   = data.oxide_vpc_subnet.workstation.id
      vpc_id      = data.oxide_vpc_subnet.workstation.vpc_id
      description = "A NIC"
      name        = "nic-${each.value}"
    }
  ]
}


resource "local_file" "ansible_inventory" {
  filename = "${path.root}/../ansible/inventory/inventory.ini"
  content = templatefile("${path.root}/templates/inventory.tpl", {
    workstation_ips = [
      for key, instance in data.oxide_instance_external_ips.workstation :
      instance.external_ips[0].ip
    ]
  })
}


output "ansible_inventory_file" {
  value = local_file.ansible_inventory.filename
}

output "workstation_node_ips" {
  value = [for instance in data.oxide_instance_external_ips.workstation : instance.external_ips.0.ip]
}
