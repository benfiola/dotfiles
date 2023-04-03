#!/bin/zsh -e
secret_file="${ZSHRC_PROFILED_PATH}/pulumi-secret"
if [ ! -f "${secret_file}" ]; then
    debug_msg "generating pulumi secret"
    echo "export PULUMI_CONFIG_PASSPHRASE=$(head -c 24 /dev/urandom | base64)" > "${secret_file}"
fi
source "${secret_file}"
