#!/bin/bash

# Usage: This script installs NGINX on various Linux distributions
# Run it as root or with sudo privileges
# Usage: sudo ./install_nginx.sh

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

# Prompt the user to continue
read -p "This script will install NGINX on your system. Do you wish to continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit 1
fi

# Function to install NGINX on CentOS/RHEL/Oracle Linux/AlmaLinux/Rocky Linux
install_nginx_centos() {
    # Install necessary utilities
    yum install yum-utils -y || { echo 'Installing yum-utils failed' ; exit 1; }

    # Install EPEL repository
    yum install epel-release -y || { echo 'Installing EPEL repository failed' ; exit 1; }

    # Update the repository
    yum update -y || { echo 'Updating repository failed' ; exit 1; }

    # Install NGINX
    yum install nginx -y || { echo 'Installing NGINX failed' ; exit 1; }

    # Start NGINX
    systemctl start nginx || { echo 'Starting NGINX failed' ; exit 1; }

    # Enable NGINX to start on boot
    systemctl enable nginx || { echo 'Enabling NGINX to start on boot failed' ; exit 1; }
}

# Function to install NGINX on Debian
install_nginx_debian() {
    # Update the Debian repository information
    apt-get update -y || { echo 'Updating repository information failed' ; exit 1; }

    # Install prerequisites
    apt-get install curl gnupg2 ca-certificates lsb-release debian-archive-keyring -y || { echo 'Installing prerequisites failed' ; exit 1; }

    # Import an official NGINX signing key
    curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor | tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null || { echo 'Importing NGINX signing key failed' ; exit 1; }

    # Set up the apt repository for stable NGINX packages
    echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/debian `lsb_release -cs` nginx" | tee /etc/apt/sources.list.d/nginx.list || { echo 'Setting up the apt repository failed' ; exit 1; }

    # Set up repository pinning
    echo -e "Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900\n" | tee /etc/apt/preferences.d/99nginx || { echo 'Setting up repository pinning failed' ; exit 1; }

    # Install the NGINX package
    apt update || { echo 'Updating repository information failed' ; exit 1; }
    apt install nginx -y || { echo 'Installing NGINX failed' ; exit 1; }

    # Start NGINX
    systemctl start nginx || { echo 'Starting NGINX failed' ; exit 1; }

    # Enable NGINX to start on boot
    systemctl enable nginx || { echo 'Enabling NGINX to start on boot failed' ; exit 1; }
}

# Function to install NGINX on Ubuntu
install_nginx_ubuntu() {
    # Update the Ubuntu repository information
    apt-get update -y || { echo 'Updating repository information failed' ; exit 1; }

    # Install NGINX
    apt-get install nginx -y || { echo 'Installing NGINX failed' ; exit 1; }

    # Start NGINX
    systemctl start nginx || { echo 'Starting NGINX failed' ; exit 1; }

    # Enable NGINX to start on boot
    systemctl enable nginx || { echo 'Enabling NGINX to start on boot failed' ; exit 1; }
}

# Check the Linux distribution and call the appropriate function
if [ -f /etc/os-release ]; then
    . /etc/os-release
    case $ID in
        centos|rhel|oraclelinux|almalinux|rocky)
            install_nginx_centos
            ;;
        debian)
            install_nginx_debian
            ;;
        ubuntu)
            install_nginx_ubuntu
            ;;
        *)
            echo "Unsupported Linux distribution"
            exit 1
            ;;
    esac
else
    echo "Not a Linux system or Linux distribution not supported"
    exit 1
fi

# Test if NGINX is running
if systemctl status nginx >/dev/null 2>&1; then
    echo "NGINX is running successfully"
else
    echo "NGINX is not running. Please check the installation"
    exit 1
fi
