
packer {
  required_plugins {
    oxide = {
      source  = "github.com/oxidecomputer/oxide"
      version = ">= 0.3.0"
    }
  }
}

variable "project" {
  type    = string
  default = "jay"
}

variable "vpc_name" {
  type    = string
  default = "default"
}

variable "image_id" {
  type    = string
  default = "b5a6a687-4c85-45e8-a348-b1162ed85543"
}

source "oxide-instance" "ubuntu" {
  project            = var.project
  boot_disk_image_id = var.image_id
  vpc                = var.vpc_name
  cpus               = 4
  memory             = 17179869184

  ssh_username       = "ubuntu"
}

build {
  name    = "build-workstation"
  sources = ["source.oxide-instance.ubuntu"]

  provisioner "shell" {
    script = "build.sh"
  }

  provisioner "shell" {
    expect_disconnect = true
    inline = [
      "sync;sync;sync;sudo reboot",
    ]
  }

  /*
  provisioner "ansible" {
    playbook_file   = "ansible/playbook.yml"
    extra_arguments = ["-e", "@ansible/vars.yml"]
    user            = "ubuntu"
    use_sudo        = true
  }
  */
}
