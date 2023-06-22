#!/bin/bash

# Author: Jason Schmidt
# License: Apache 2.0

# This script downloads Ubuntu cloud images and creates corresponding
# Proxmox VMs with cloud-init enabled. It sets up DHCP for all network
# interfaces and sets a username, password, and SSH key for each VM.

# Array of Ubuntu versions
versions=("bionic" "jammy" "kinetic" "lunar" "focal")

# Base URL for Ubuntu cloud images
base_url="https://cloud-images.ubuntu.com"

# VMID start value
vmid=9100

# Where do we store our volumes?
storage="ceph01"

# Parse command-line arguments for username, password, and SSH key path
while getopts u:p:k: flag; do
  case "${flag}" in
  u) username=${OPTARG} ;;
  p) password=${OPTARG} ;;
  k) sshkey=${OPTARG} ;;
  *) echo "Invalid flag passed" ;;
  esac
done

# If variables are not provided as command-line arguments, prompt the user for them
if [[ -z "$username" ]]; then
  read -r -p "Enter your username: " username
fi
if [[ -z "$password" ]]; then
  read -r -s -p "Enter your password: " password
  echo
fi
if [[ -z "$sshkey" ]]; then
  read -r -p "Enter the path to your SSH public key: " sshkey
fi

# Check if all required variables are provided
if [[ -z "$username" || -z "$password" || -z "$sshkey" ]]; then
  echo "Error: You must provide a username, password, and SSH key path."
  exit 1
fi

# Check if the SSH key file exists
if [[ ! -f "$sshkey" ]]; then
  echo "Error: The SSH key file does not exist."
  exit 1
fi

# VM specifications
memory=8196 # Memory in MB
cores=4     # Number of CPUs

# Loop over each Ubuntu version
for version in "${versions[@]}"; do
  # Check if a template with the VMID already exists and delete it if it does
  if qm status $vmid >/dev/null 2>&1; then
    qm stop $vmid
    qm destroy $vmid
  fi

  # Download the cloud image for the current Ubuntu version
  url="${base_url}/${version}/current/${version}-server-cloudimg-amd64.img"
  curl "{$url}" -O

  image="${version}-server-cloudimg-amd64.img"

  # Edit the image to autoinstall some packages for us.
  # Check if virt-customize is installed
  if ! command -v virt-customize &>/dev/null; then
    echo "virt-customize is not installed."
    echo "You can install it on Debian-based systems with the following command:"
    echo "sudo apt-get install libguestfs-tools"
  else
    virt-customize -a "$image" --firstboot-install build-essential,curl,jq,libbz2-dev,libffi-dev,liblzma-dev,libncursesw5-dev,libreadline-dev,libsqlite3-dev,libssl-dev,libxml2-dev,libxmlsec1-dev,llvm,make,tk-dev,wget,xz-utils,zlib1g-dev,unzip,qemu-guest-agent --firstboot-command 'systemctl enable qemu-guest-agent'
  fi

  # Create a new VM for the current Ubuntu version
  name="${version}-template"
  qm create $vmid --name "$name" --memory "$memory" --cores "$cores" --net0 virtio,bridge=vmbr0 --cipassword "$password" --sshkeys "$sshkey" --ipconfig0 ip=dhcp --agent enabled=1
  qm importdisk "$vmid" "$image" "$storage"
  qm set $vmid --scsihw virtio-scsi-pci --scsi0 "$storage":vm-${vmid}-disk-0
  qm set $vmid --ide2 "$storage":cloudinit
  qm set $vmid --boot c --bootdisk scsi0
  qm set $vmid --serial0 socket --vga serial0
  qm resize "$vmid" scsi0 +126G
  qm template "$vmid"

  # Remvove the intermediate file
  rm -f "$image"

  # Increment VMID for the next iteration
  ((vmid++))
done
