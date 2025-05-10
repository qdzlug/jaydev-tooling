#!/usr/bin/env python3

from collections import defaultdict
import re
import sys

# Parse the input data from stdin
input_data = sys.stdin.read()

# Parse the input data
plugins = defaultdict(list)
current_plugin = None

for line in input_data.strip().split('\n'):
    if line.strip():
        if not line.startswith(' '):
            current_plugin = line.strip()
        else:
            version = line.strip()
            plugins[current_plugin].append(version)

# Helper function to sort versions
def sort_versions(versions):
    def version_key(version):
        # Split version into components and convert to tuples for sorting
        return tuple(int(part) if part.isdigit() else part for part in re.split(r'(\d+)', version) if part)
    return sorted(versions, key=version_key)

# Generate uninstall commands
commands = []
for plugin, versions in plugins.items():
    sorted_versions = sort_versions(versions)
    for version in sorted_versions[:-1]:
        commands.append(f"asdf uninstall {plugin} {version}")

# Print the commands
for command in commands:
    print(command)
