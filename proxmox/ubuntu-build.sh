#!/bin/bash

# Author: Jason Schmidt
# License: Apache 2.0

# This script downloads Ubuntu cloud images and creates corresponding
# Proxmox VMs with cloud-init enabled. It sets up DHCP for all network
# interfaces and sets a username, password, and SSH key for each VM.

# Display usage information
usage() {
    echo "Usage: $0 [-u username] [-p password] [-k sshkey]"
    echo
    echo "Options:"
    echo "  -u  Specify the username for the VM."
    echo "  -p  Specify the password for the VM."
    echo "  -k  Specify the path to the SSH public key."
    echo "  -h  Display this help message."
    exit 1
}

# Array of Ubuntu versions
versions=("bionic" "focal" "jammy" "mantic" "noble")

# Base URL for Ubuntu cloud images
base_url="https://cloud-images.ubuntu.com"

# VMID start value
vmid=9100

# Where do we store our volumes?
storage="iris-nfs"

# Parse command-line arguments for username, password, and SSH key path
while getopts u:p:k:h flag; do
    case "${flag}" in
        u) username=${OPTARG} ;;
        p) password=${OPTARG} ;;
        k) sshkey=${OPTARG} ;;
        h) usage ;;
        *) usage ;;
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

retry() {
    local n=1
    local max=5
    local delay=10
    while true; do
        "$@" && break || {
            if [[ $n -lt $max ]]; then
                ((n++))
                echo "Command failed. Attempt $n/$max:"
                sleep $delay;
            else
                echo "The command has failed after $n attempts."
                return 1
            fi
        }
    done
}

# Loop over each Ubuntu version
for version in "${versions[@]}"; do
  # Check if a template with the VMID already exists and delete it if it does
  if qm status $vmid >/dev/null 2>&1; then
    retry qm stop $vmid
    retry qm destroy $vmid
  fi

  # Download the cloud image for the current Ubuntu version
  url="${base_url}/${version}/current/${version}-server-cloudimg-amd64.img"
  retry curl -O "${url}"

  image="${version}-server-cloudimg-amd64.img"

  # Resize the image file
  qemu-img resize "$image" 5G

  # Edit the image to autoinstall some packages for us.
  # Check if virt-customize is installed
  if ! command -v virt-customize &>/dev/null; then
    echo "virt-customize is not installed."
    echo "You can install it on Debian-based systems with the following command:"
    echo "sudo apt-get install libguestfs-tools"
  else
    if ! virt-customize -a "$image" --install "build-essential,curl,jq,make,wget,xz-utils,zip,unzip,qemu-guest-agent" --firstboot-command 'systemctl enable qemu-guest-agent' --firstboot-command 'service qemu-guest-agent start' --firstboot-command 'dpkg --configure -a'; then
      echo "Warning: virt-customize failed for $version. Skipping this version."
      continue
    fi
  fi

  # Create a new VM for the current Ubuntu version
  name="${version}-template"
  retry qm create $vmid --name "$name" --memory "$memory" --cores "$cores" --net0 virtio,bridge=vmbr0 --cipassword "$password" --sshkeys "$sshkey" --ipconfig0 ip=dhcp --agent enabled=1

  # Import the disk image
  retry qm importdisk $vmid "$image" "$storage"

  # Get the correct disk ID for the imported disk
  diskid=$(qm config $vmid | grep unused | cut -d ' ' -f 2 | cut -d ':' -f 2)

  # Attach the imported disk to the VM
  retry qm set $vmid --scsihw virtio-scsi-pci --scsi0 "$storage:$diskid"

  # Configure the VM
  retry qm set $vmid --ide2 "$storage:cloudinit"
  retry qm set $vmid --boot order=scsi0
  retry qm set $vmid --serial0 socket --vga serial0
  retry qm resize "$vmid" scsi0 +126G
  retry qm template "$vmid"

  # Remove the intermediate file
  rm -f "$image"

  # Increment VMID for the next iteration
  ((vmid++))
done

# Set immutable flag on disk files if supported
for file in /mnt/pve/iris-nfs/images/*/vm-*-disk-*.raw; do
  if [[ -f "$file" ]]; then
    chattr +i "$file" 2>/dev/null || echo "Warning: Could not set immutable flag on $file. Operation not supported."
  fi
done
