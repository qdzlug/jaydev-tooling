#!/bin/bash

# Define the URL where the SSH public keys are hosted
KEYS_URL="https://jayschmidt.us/qdzlug.keys"

# Define the path to the authorized_keys file for the current user
AUTHORIZED_KEYS="$HOME/.ssh/authorized_keys"

# Define the backup file name
BACKUP_FILE="$HOME/.ssh/authorized_keys.backup"

# Fetch the latest keys from the provided URL
wget -q -O /tmp/updated_keys $KEYS_URL

# Check if the download was successful
if [ $? -ne 0 ]; then
    echo "Failed to download keys from $KEYS_URL"
    exit 1
fi

# Count the number of keys in each file
NUM_KEYS_CURRENT=$(wc -l < $AUTHORIZED_KEYS)
NUM_KEYS_UPDATED=$(wc -l < /tmp/updated_keys)
echo "Number of keys in current authorized_keys: $NUM_KEYS_CURRENT"
echo "Number of keys in updated file: $NUM_KEYS_UPDATED"

# Compare the fetched keys with the current authorized_keys
if cmp -s /tmp/updated_keys $AUTHORIZED_KEYS; then
    echo "No update needed. The authorized keys are up to date."
else
    # Show the differences
    echo "Differences between current and updated keys:"
    diff $AUTHORIZED_KEYS /tmp/updated_keys

    # Backup the current authorized_keys
    cp $AUTHORIZED_KEYS $BACKUP_FILE
    echo "Backed up the existing authorized_keys to $BACKUP_FILE"

    # Replace the authorized_keys with the updated keys
    cp /tmp/updated_keys $AUTHORIZED_KEYS
    echo "Updated the authorized_keys with the latest keys from $KEYS_URL"
fi

# Clean up the temporary file
rm /tmp/updated_keys
