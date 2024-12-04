#!/bin/bash

# Author: Jason Schmidt (modified)
# License: Apache 2.0

# This script creates a Proxmox template VM using a provided media file, name, and VM ID.
# It supports cloud-init configuration and optional resizing of the root disk.

# Display usage information
usage() {
    echo "Usage: $0 -m <media-file> -n <vm-name> -i <vmid> [-s <storage>] [-u <username>] [-p <password>] [-k <sshkey>] [-d <disk-size>]"
    echo
    echo "Options:"
    echo "  -m  Path to the media file (required)"
    echo "  -n  Name of the template (required)"
    echo "  -i  VM ID for the template (required)"
    echo "  -s  Proxmox storage pool (default: local-lvm)"
    echo "  -u  Username for the VM"
    echo "  -p  Password for the VM"
    echo "  -k  Path to the SSH public key"
    echo "  -d  Additional disk size to allocate (default: +126G)"
    echo "  -h  Display this help message."
    exit 1
}

# Default values
storage="local-lvm"
disk_size="+126G"
username="ubuntu"
password="ubuntu"

# Parse command-line arguments
while getopts "m:n:i:s:u:p:k:d:h" flag; do
    case "${flag}" in
        m) media_file=${OPTARG} ;;
        n) vm_name=${OPTARG} ;;
        i) vmid=${OPTARG} ;;
        s) storage=${OPTARG} ;;
        u) username=${OPTARG} ;;
        p) password=${OPTARG} ;;
        k) sshkey=${OPTARG} ;;
        d) disk_size=${OPTARG} ;;
        h) usage ;;
        *) usage ;;
    esac
done

# Check required arguments
if [[ -z "$media_file" || -z "$vm_name" || -z "$vmid" ]]; then
    echo "Error: Media file, VM name, and VM ID are required."
    usage
fi

# Check if the media file exists
if [[ ! -f "$media_file" ]]; then
    echo "Error: Media file does not exist: $media_file"
    exit 1
fi

# Check if the SSH key file exists, if provided
if [[ -n "$sshkey" && ! -f "$sshkey" ]]; then
    echo "Error: The SSH key file does not exist: $sshkey"
    exit 1
fi

# VM specifications
memory=8192 # Memory in MB
cores=4     # Number of CPUs

# Helper function for retries
retry() {
    local n=1
    local max=5
    local delay=10
    while true; do
        "$@" && break || {
            if [[ $n -lt $max ]]; then
                ((n++))
                echo "Command failed. Attempt $n/$max:"
                sleep $delay
            else
                echo "The command has failed after $n attempts."
                return 1
            fi
        }
    done
}

# Create or overwrite the VM configuration
if qm status $vmid >/dev/null 2>&1; then
    echo "VM ID $vmid already exists. Deleting it..."
    retry qm stop $vmid
    retry qm destroy -destroy-unreferenced-disks 1 -purge 1 -skiplock 1 $vmid
fi

echo "Creating VM $vm_name with ID $vmid..."

retry qm create $vmid \
    --name "$vm_name" \
    --memory "$memory" \
    --cores "$cores" \
    --net0 virtio,bridge=vmbr0 \
    --cipassword "$password" \
    --sshkeys "$sshkey" \
    --ipconfig0 ip=dhcp \
    --agent enabled=1

# Import the media file into Proxmox
echo "Importing media file into Proxmox storage ($storage)..."
retry qm importdisk $vmid "$media_file" "$storage"

# Get the correct disk ID for the imported disk
diskid=$(qm config $vmid | grep unused | cut -d ' ' -f 2 | cut -d ':' -f 2)

# Attach the imported disk to the VM
echo "Attaching disk to VM..."
retry qm set $vmid --scsihw virtio-scsi-pci --scsi0 "$storage:$diskid"

# Attach the cloud-init disk
echo "Attaching cloud-init disk..."
retry qm set $vmid --ide2 "$storage:cloudinit"

# Configure boot order and serial console
echo "Configuring VM..."
retry qm set $vmid --boot order=scsi0
retry qm set $vmid --serial0 socket --vga serial0

# Resize the disk if requested
if [[ -n "$disk_size" ]]; then
    echo "Resizing disk by $disk_size..."
    retry qm resize "$vmid" scsi0 "$disk_size"
fi

# Convert the VM into a template
echo "Converting VM to template..."
retry qm template $vmid

echo "Template $vm_name with ID $vmid successfully created!"
