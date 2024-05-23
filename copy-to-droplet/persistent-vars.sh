#!/bin/bash

ENV_FILE_PATH="./.env"
TARGET_PROFILE="$HOME/.bash_profile"

# Read each line from .env
while IFS= read -r line || [[ -n "$line" ]]; do
    # Skip empty lines and lines starting with #
    if [[ -n "$line" && ! "$line" =~ ^# ]]; then
        # Check if the line already exists in the target profile
        if ! grep -qF -- "$line" "$TARGET_PROFILE"; then
            # It's new, so append it (as an exported variable) to the profile
            echo "export $line" >> "$TARGET_PROFILE"
        fi
    fi
done < "$ENV_FILE_PATH"

echo "Environment variables from $ENV_FILE_PATH have been made persistent in $TARGET_PROFILE."

