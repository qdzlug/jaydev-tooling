# ☁️ Terraform Image Import for Oxide

This module (or script) automates the process of importing a Linux cloud image (Debian, Ubuntu, RHEL, SUSE) into an [Oxide Computer](https://oxide.computer) project.

## 📋 What It Does

- Downloads a NoCloud-compatible cloud image
- Converts it to a raw disk image using `qemu-img`
- Imports the image into Oxide via `oxide disk import`

## 🚀 Workflow

1. **Fetch** an image from a known cloud image source
2. **Convert** QCOW2/IMG to RAW using `qemu-img`
3. **Import** into Oxide:

```bash
oxide disk import \
  --project omni \
  --path /tmp/ubuntu-2204.raw \
  --disk ubuntu-2204 \
  --disk-block-size 512 \
  --description "Ubuntu 22.04 NoCloud Image" \
  --snapshot ubuntu-2204 \
  --image ubuntu-2204 \
  --image-description "Ubuntu 22.04" \
  --image-os ubuntu \
  --image-version 22.04
```

## 🧱 Requirements

- Terraform (if using a TF wrapper)
- `qemu-img` installed
- `oxide` CLI installed and authenticated
- Internet access to fetch the image

## 📁 Project Structure (if using Ansible)

```
oxide_image_import/
├── playbook.yml
└── roles/
    └── oxide_image/
        └── tasks/main.yml
```

## ✍️ Notes

- This is meant to be automated but safe — no destructive actions
- Versioning and naming logic are based on image filename patterns
- Can be adapted to loop over multiple distros or versions
