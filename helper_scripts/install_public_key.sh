#!/bin/bash
set -e 

PUBLIC_KEY_DATA="${PUBLIC_KEY_DATA:-}"

if [ "$PUBLIC_KEY_DATA" = "" ]; then
    2>&1 echo "error: must provide a public key"
    exit 1
fi

SSH_PATH="$HOME/.ssh"
if [ ! -e "$SSH_PATH" ]; then
    echo "creating directory: $SSH_PATH"
    mkdir "$SSH_PATH"
fi

AUTHORIZED_KEYS_PATH="$SSH_PATH/authorized_keys"
if [ ! -e "$AUTHORIZED_KEYS_PATH" ]; then
    echo "creating file: $AUTHORIZED_KEYS_PATH"
    touch "$AUTHORIZED_KEYS_PATH"
fi

set +e
cat "$AUTHORIZED_KEYS_PATH" | grep -q "$PUBLIC_KEY_DATA" 
KEY_EXISTS="$?"
set -e

if [ ! "$KEY_EXISTS" = "0" ]; then
    echo "adding public key to authorized_keys: $PUBLIC_KEY_DATA"
    echo "$PUBLIC_KEY_DATA" >> "$AUTHORIZED_KEYS_PATH"
fi

exit 0
