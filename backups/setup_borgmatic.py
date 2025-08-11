#!/usr/bin/env python3

import os
import subprocess
import shutil
import sys
from pathlib import Path
from datetime import datetime
import yaml

# === CONFIGURATION ===
SSH_CONFIG_PATH = Path.home() / ".ssh" / "config"
BORG_CONFIG_PATH = Path("/etc/borgmatic/config.yaml")
REQUIRED_TOOLS = ["borgmatic", "yq", "ssh", "systemctl"]
SYSTEMD_TIMER = "borgmatic.timer"
BORG_HOST_ALIAS = "borg-backup"
BORG_HOST = "100.107.227.16"
BORG_PORT = 2222
BORG_USER = "borgwarehouse"
BORG_KEY_PATH = Path.home() / ".ssh" / "id_ed25519"


def check_dependencies():
    print("[1/6] Checking required tools...")
    missing = [tool for tool in REQUIRED_TOOLS if shutil.which(tool) is None]
    if missing:
        print(f"❌ Missing required tools: {', '.join(missing)}")
        sys.exit(1)
    print("✅ All required tools are installed.")


def ensure_ssh_config():
    print("[2/6] Ensuring SSH config entry...")
    entry = f"Host {BORG_HOST_ALIAS}\n" \
            f"    HostName {BORG_HOST}\n" \
            f"    Port {BORG_PORT}\n" \
            f"    User {BORG_USER}\n" \
            f"    IdentityFile {BORG_KEY_PATH}\n" \
            f"    IdentitiesOnly yes\n"

    SSH_CONFIG_PATH.parent.mkdir(parents=True, exist_ok=True)
    if SSH_CONFIG_PATH.exists() and entry.splitlines()[0] in SSH_CONFIG_PATH.read_text():
        print("✅ SSH config entry already exists.")
        return

    with SSH_CONFIG_PATH.open("a") as f:
        f.write(f"\n{entry}")
    print("✅ SSH config entry added.")

def normalize_borgmatic_config():
    print("[2b] Ensuring borgmatic config uses correct SSH alias and ssh_command...")
    updated = False

    with open(BORG_CONFIG_PATH, "r") as f:
        config = yaml.safe_load(f)

    location = config.setdefault("location", {})
    repositories = location.get("repositories", [])
    if repositories:
        current = repositories[0]

        # Extract path part from ssh:// form or fix formatting
        if current.startswith("ssh://"):
            # ssh://borgwarehouse@host:port/./repo-id
            path_part = current.split("/", 3)[-1]
        else:
            path_part = current.split(":", 1)[-1]

        if not path_part.startswith("./"):
            path_part = f"./{path_part.lstrip('/')}"

        fixed = f"{BORG_HOST_ALIAS}:{path_part}"
        if current != fixed:
            print(f"🔧 Updating repository: {current} → {fixed}")
            config["location"]["repositories"][0] = fixed
            updated = True

    # Ensure correct ssh_command
    storage = config.setdefault("storage", {})
    expected_ssh_cmd = f"ssh -i {BORG_KEY_PATH} -o IdentitiesOnly=yes -p {BORG_PORT}"
    if storage.get("ssh_command") != expected_ssh_cmd:
        print(f"🔧 Setting ssh_command: {expected_ssh_cmd}")
        storage["ssh_command"] = expected_ssh_cmd
        updated = True

    # Quote passphrase if missing
    passphrase = storage.get("encryption_passphrase")
    if passphrase and not isinstance(passphrase, str):
        print("🔧 Quoting encryption_passphrase for YAML safety")
        storage["encryption_passphrase"] = str(passphrase)
        updated = True

    if updated:
        backup_path = BORG_CONFIG_PATH.with_suffix(
            f".bak.{datetime.now().strftime('%Y%m%d%H%M%S')}"
        )
        shutil.copy2(BORG_CONFIG_PATH, backup_path)
        print(f"📦 Backed up original config to: {backup_path}")

        with open(BORG_CONFIG_PATH, "w") as f:
            yaml.safe_dump(config, f, sort_keys=False, default_flow_style=False)

        print("✅ Config updated and saved.")
    else:
        print("✅ No changes needed to config.")


def validate_borgmatic_config():
    print("[3/6] Validating borgmatic config syntax...")
    try:
        subprocess.run(
            ["borgmatic", "--verbosity", "0", "--dry-run", "--config", str(BORG_CONFIG_PATH)],
            check=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        print("✅ Borgmatic config is valid.")
    except subprocess.CalledProcessError:
        print("❌ Borgmatic config is invalid.\n")
        print("🔍 Trying to show syntax errors...")
        try:
            with open(BORG_CONFIG_PATH, "r") as f:
                yaml.safe_load(f)
            print("✅ YAML parsed successfully, but Borgmatic still rejected the config.")
        except yaml.YAMLError as e:
            print("❌ YAML parsing error:")
            print(e)
        print("\n🚨 Fix required:")
        print(f" - File path: {BORG_CONFIG_PATH}")
        print(" - Run this to validate YAML manually:")
        print(f"     yq . {BORG_CONFIG_PATH}")
        print(" - Or debug borgmatic directly:")
        print(f"     borgmatic --verbosity 2 --dry-run --config {BORG_CONFIG_PATH}")
        print(" - Docs: https://torsion.org/borgmatic/docs/reference/configuration/")
        sys.exit(1)


def ensure_timer():
    print("[4/6] Ensuring borgmatic.timer is enabled...")
    try:
        subprocess.run(["systemctl", "enable", "--now", SYSTEMD_TIMER], check=True)
        print("✅ Timer enabled and started.")
    except subprocess.CalledProcessError:
        print("❌ Failed to enable/start borgmatic.timer")
        sys.exit(1)


def extract_config_details():
    print("[5/6] Reading config details...")
    with open(BORG_CONFIG_PATH) as f:
        config = yaml.safe_load(f)

    location = config.get("location", {})
    storage = config.get("storage", {})
    repo = location.get("repositories", ["(none)"])[0]
    sources = location.get("source_directories", [])
    ssh_cmd = storage.get("ssh_command", "ssh")
    passphrase = storage.get("encryption_passphrase", "none")

    print("\n📋 Borgmatic Configuration Summary:")
    print("----------------------------------------")
    print(f"Repository:     {repo}")
    print(f"SSH Command:    {ssh_cmd}")
    print(f"Source Paths:   {', '.join(sources)}")
    print(f"Passphrase:     {passphrase}")
    print(f"SSH Config:     {BORG_HOST_ALIAS} → {BORG_USER}@{BORG_HOST}:{BORG_PORT}")
    print()


def show_timer_status():
    print("[6/6] Fetching next scheduled run...")
    try:
        output = subprocess.check_output(
            ["systemctl", "list-timers", "--all"], text=True
        )
        for line in output.splitlines():
            if SYSTEMD_TIMER in line:
                print(f"Next Run:       {line.strip()}")
                return
        print("❌ borgmatic.timer is not scheduled.")
    except subprocess.CalledProcessError:
        print("❌ Unable to fetch timer status.")


def main():
    check_dependencies()
    ensure_ssh_config()
    normalize_borgmatic_config()
    validate_borgmatic_config()
    ensure_timer()
    extract_config_details()
    show_timer_status()


if __name__ == "__main__":
    main()
