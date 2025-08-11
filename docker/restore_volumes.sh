#!/bin/bash
set -euo pipefail

if [[ $# -eq 0 ]]; then
  echo "Usage: $0 volume1 [volume2 ...]"
  exit 1
fi

BACKUP_DIR="./docker_volume_backups"
mkdir -p "$BACKUP_DIR"

for VOLUME in "$@"; do
  BACKUP_FILE="${BACKUP_DIR}/${VOLUME}.tar.gz"
  echo "Backing up volume: $VOLUME -> $BACKUP_FILE"
  docker run --rm \
    -v "${VOLUME}":/volume \
    -v "${PWD}/${BACKUP_DIR}":/backup \
    alpine \
    sh -c "cd /volume && tar czf /backup/${VOLUME}.tar.gz ."
done

echo "Backup complete: files stored in ${BACKUP_DIR}"