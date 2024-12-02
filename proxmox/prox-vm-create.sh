#!/bin/bash
#
# Copyright 2024 Oxide Computer Company
#
# Description:
# This script automates downloading, verifying, and preparing a Helios image
# for use with Proxmox. It creates a VM, imports a disk image, and sets up a
# metadata volume. The script ensures proper configuration and starts the VM.
#
# Variables:
# - vmid: Unique VM ID (defaults to 600 if not provided).
# - pool: Proxmox storage pool (default: local-zfs).
#

set -o xtrace
set -o pipefail
set -o errexit

TOP=$(cd "$(dirname "$0")" && pwd)

. "$TOP/config/proxmox.sh"
if [[ -n $1 ]]; then
	if ! . "$TOP/config/$1.sh"; then
		echo "failed to source configuration"
		exit 1
	fi
fi

vmid=${VMID:-600}    # VM ID
pool=${POOL:-local-zfs}  # Proxmox storage pool
namebase=helios-qemu-ttya-full
name=$namebase-20231220.raw
namegz=$name.gz
url="https://pkg.oxide.computer/seed/$namegz"
sha256="7ef5ae77bae58d676f2117db2eeff40acbf0b92dfd2513c6198f9fc2c92a193e"
sha256gz="51fc4ead25c1b3ba5d22e79a1cd069ad46b310a084246f612e7ff287085a190f"
sizegz=2944268075
disk="vm-${vmid}-disk-0"

#
# Locate the INPUT_IMAGE and verify existence
#
INPUT_IMAGE_PATH="$TOP/input/$name"
if [[ ! -f "$INPUT_IMAGE_PATH" ]]; then
    echo "Input image $INPUT_IMAGE_PATH not found. Ensure it exists or download it."
fi

#
# Download and validate the image
#
mkdir -p "$TOP/input" "$TOP/tmp"
while :; do
	t="$TOP/input/$name"
	if [[ -f "$t" ]]; then
		echo "Checking hash of existing file $t..."
		if [[ $(shasum -a 256 "$t" | awk '{print $1}') == "$sha256" ]]; then
			echo "Seed image verified."
			break
		fi
		echo "Seed image hash mismatch. Removing and retrying download."
		rm -f "$t"
	fi

	g="$TOP/tmp/$namegz"
	if [[ ! -f "$g" || $(stat -c %s "$g") != "$sizegz" ]]; then
		echo "Downloading $namegz..."
		curl -C - -f -o "$g" "$url" || {
			echo "Download failed. Retrying..."
			sleep 3
			continue
		}
	fi

	echo "Extracting $g..."
	rm -f "$g.extracted"
	if ! gunzip < "$g" > "$g.extracted"; then
		echo "Extraction failed."
		exit 1
	fi

	mv "$g.extracted" "$t"
done

#
# Ensure the VM ID is not in use
#
if qm status "$vmid" >/dev/null 2>&1; then
    echo "VM $vmid already exists. Destroy it before recreating."
    exit 1
fi

#
# Ensure the storage pool exists
#
if ! pvesm status | grep -q "$pool"; then
    echo "Storage pool $pool does not exist. Please configure it."
    exit 1
fi

#
# Resize and convert the image
#
RESIZED_IMAGE="$TOP/tmp/${name%.raw}.qcow2"
qemu-img convert -f raw -O qcow2 "$INPUT_IMAGE_PATH" "$RESIZED_IMAGE"
qemu-img resize "$RESIZED_IMAGE" 20G  # Adjust size as needed

#
# Import the disk into Proxmox
#
# Ensure the VM configuration exists
if ! qm config "$vmid" >/dev/null 2>&1; then
    echo "Creating VM configuration for ID $vmid..."
    qm create "$vmid" --name "$namebase" --memory "$MEM" --net0 virtio,bridge=vmbr0 --cores "$VCPU" --cpu host
fi

echo "Importing the image into $pool"
qm importdisk "$vmid" "$RESIZED_IMAGE" "$pool"

#
# Create the VM in Proxmox
#
echo "Updating VM $vmid..."
##qm create "$vmid" --name "$namebase" --memory 4096 --net0 virtio,bridge=vmbr0 --cores 2
qm set "$vmid" --scsihw virtio-scsi-pci --scsi0 "$pool:$disk" --boot order=scsi0
qm set "$vmid" --agent enabled=1 --serial0 socket --vga serial0


# Define cloud-init metadata file
# (Placeholder for now)
echo "Ensure that you setup the cloudinit drive
#
# Start the VM
#
echo To start VM run qm start "$vmid"
echo To attach to terminal, run exec qm terminal "$vmid"