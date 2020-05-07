#!/bin/bash
set -e

function usage {
  echo "Usage:  sops.sh  <encrypt|decrypt>"
  exit 1
}

function encrypt {
    # Handle encrypting secrets in environment.
    secrets_files=$(find . -type f -and -name secrets.yaml)

    while IFS= read -r line ; do
        unencrypted_filename=$line
        encrypted_filename=$(echo "$unencrypted_filename" | sed 's/.yaml/.enc.yaml/')

        echo "Encrypting $unencrypted_filename..."
        sops -e $unencrypted_filename > $encrypted_filename
    done <<< "$secrets_files"
}

function decrypt {
    # Handle decrypting secrets in environment.
    secrets_files=$(find . -type f -and -name secrets.enc.yaml)

    while IFS= read -r line ; do
        encrypted_filename=$line
        unencrypted_filename=$(echo "$encrypted_filename" | sed 's/.enc.yaml/.yaml/')

        echo "Decrypting $encrypted_filename..."
        sops -d $encrypted_filename > $unencrypted_filename
    done <<< "$secrets_files"
}

if [ "$#" -ne 1 ]; then
    usage
fi

OPERATION=$1

secrets_files=$()

# Check dependencies
sops_exists=$(command -v sops)
if [ -z "$sops_exists" ]; then
    echo "sops is not installed or not in the PATH. Check out https://github.com/mozilla/sops for installation instructions."
    exit 1;
fi

if [ "$OPERATION" == "encrypt" ]; then
    encrypt
elif [ "$OPERATION" == "decrypt" ]; then
    decrypt
else
    usage
fi





