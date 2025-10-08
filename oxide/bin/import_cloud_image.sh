#!/usr/bin/env bash
set -euo pipefail

# import_cloud_image.sh
# Download a cloud image, convert to RAW, and import it into an Oxide rack.

prompt_if_empty() {
  local var_name="$1"
  local prompt="$2"
  local current_val="${!var_name:-}"
  if [[ -z "$current_val" ]]; then
    read -rp "$prompt: " current_val
    eval "$var_name=\"\$current_val\""
  fi
}

usage() {
  cat <<'USAGE'
Usage:
  import_cloud_image.sh \
    [--url <image_url>] \
    [--project <oxide_project>] \
    [--name <oxide_image_name>] \
    [--description "<image_description>"] \
    [--os <image_os>] \
    [--version <image_version>] \
    [--disk-block-size 512]

If a value is not passed, you will be prompted for it.

Example:
  ./import_cloud_image.sh \
    --url https://example.com/image.qcow2 \
    --project demo \
    --name ubuntu-2404 \
    --description "Ubuntu 24.04 LTS" \
    --os ubuntu \
    --version 24.04
USAGE
}

# -------- arg parsing --------
URL=""
PROJECT=""
NAME=""
DESC=""
OS_NAME=""
VERSION=""
DISK_BLOCK_SIZE="512"

while [[ $# -gt 0 ]]; do
  case "$1" in
  --url)
    URL="${2:-}"
    shift 2
    ;;
  --project)
    PROJECT="${2:-}"
    shift 2
    ;;
  --name)
    NAME="${2:-}"
    shift 2
    ;;
  --description)
    DESC="${2:-}"
    shift 2
    ;;
  --os)
    OS_NAME="${2:-}"
    shift 2
    ;;
  --version)
    VERSION="${2:-}"
    shift 2
    ;;
  --disk-block-size)
    DISK_BLOCK_SIZE="${2:-}"
    shift 2
    ;;
  -h | --help)
    usage
    exit 0
    ;;
  *)
    echo "Unknown arg: $1"
    usage
    exit 2
    ;;
  esac
done

# -------- prompt for missing --------
prompt_if_empty URL "Enter image URL"
prompt_if_empty PROJECT "Enter Oxide project name"
prompt_if_empty NAME "Enter Oxide image/disk name"
prompt_if_empty DESC "Enter image description"
prompt_if_empty OS_NAME "Enter image OS"
prompt_if_empty VERSION "Enter image version"
prompt_if_empty DISK_BLOCK_SIZE "Enter disk block size (default 512)"

# -------- validation --------
command -v curl >/dev/null || {
  echo "ERROR: curl not found"
  exit 1
}
command -v qemu-img >/dev/null || {
  echo "ERROR: qemu-img not found (install qemu)"
  exit 1
}
command -v oxide >/dev/null || {
  echo "ERROR: oxide CLI not found"
  exit 1
}

# -------- workspace --------
WORKDIR="$(mktemp -d -t oxide-import-XXXXXX)"
trap 'rm -rf "$WORKDIR"' EXIT
cd "$WORKDIR"

# -------- download --------
FILENAME="$(basename "${URL%%\?*}")"
echo "Downloading: $URL"
curl -fsSL --retry 5 --retry-delay 2 -o "$FILENAME" "$URL"

# -------- decompress if needed --------
INPUT_PATH="$FILENAME"
case "$FILENAME" in
*.xz)
  echo "Decompressing .xz..."
  xz -T0 -d "$FILENAME"
  INPUT_PATH="${FILENAME%.xz}"
  ;;
*.gz)
  echo "Decompressing .gz..."
  gunzip "$FILENAME"
  INPUT_PATH="${FILENAME%.gz}"
  ;;
esac

# -------- determine format --------
RAW_OUT="_out/${NAME}.raw"
mkdir -p _out
EXT="${INPUT_PATH##*.}"
convert_needed="yes"

case "${EXT,,}" in
raw | qcow2 | img)
  if qemu-img info "$INPUT_PATH" | grep -qi 'file format: *raw'; then
    echo "Input is RAW; copying..."
    cp -f "$INPUT_PATH" "$RAW_OUT"
    convert_needed="no"
  fi
  ;;
iso)
  echo "Input is ISO; copying..."
  cp -f "$INPUT_PATH" "$RAW_OUT"
  convert_needed="no"
  ;;
esac

if [[ "$convert_needed" == "yes" ]]; then
  echo "Converting '${INPUT_PATH}' -> RAW (${RAW_OUT})..."
  qemu-img convert -p -O raw "$INPUT_PATH" "$RAW_OUT"
fi

# -------- info --------
echo "Final image info:"
qemu-img info "$RAW_OUT" || true

# -------- import --------
echo "Importing to Oxide..."
oxide disk import \
  --project "$PROJECT" \
  --path "$RAW_OUT" \
  --disk "$NAME" \
  --disk-block-size "$DISK_BLOCK_SIZE" \
  --description "$DESC" \
  --snapshot "$NAME" \
  --image "$NAME" \
  --image-description "$DESC" \
  --image-os "$OS_NAME" \
  --image-version "$VERSION"

echo "Import complete."