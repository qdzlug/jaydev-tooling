#!/bin/bash

# Provided as-is without any warranty. Use at your own risk.
# This script replaces Docker Hub image references in Dockerfiles and docker-compose files
# with a local proxy cache (e.g., harbor.virington.com/localhub).

# Usage: ./replace-with-proxy.sh input_file output_file
# Example: ./replace-with-proxy.sh Dockerfile output_Dockerfile
#          ./replace-with-proxy.sh docker-compose.yml output_compose.yml

# Argument validation
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 input_file output_file"
    exit 1
fi

input_file="$1"
output_file="$2"
proxy_cache="harbor.virington.com/localhub"

# Check if input file exists
if [ ! -f "$input_file" ]; then
    echo "Error: Input file '$input_file' does not exist."
    exit 1
fi

# Determine if the file is a Dockerfile or docker-compose file
if [[ "$input_file" == *Dockerfile* ]]; then
    # Replace FROM lines in Dockerfile (handles base images, aliases, and platform specifications)
    sed -E "s|FROM ([a-z0-9\-_/]+)(:[a-zA-Z0-9_\.\-]+)?(.*)|FROM $proxy_cache/\1\2\3|g" "$input_file" > "$output_file"
elif [[ "$input_file" == *compose*.yml || "$input_file" == *compose*.yaml ]]; then
    # Replace image lines in docker-compose files (e.g., image: imagename:tag)
    sed -E "s|image: ([a-z0-9\-_/]+):([a-zA-Z0-9_\.\-]+)|image: $proxy_cache/\1:\2|g" "$input_file" > "$output_file"
else
    echo "Error: Unrecognized file type. The script only supports Dockerfiles and docker-compose YAML files."
    exit 1
fi

echo "Replaced image references in $input_file and saved to $output_file"
