#!/bin/sh -e
apt -y update
DEBIAN_FRONTEND=noninteractive apt -y install curl git tar

# nix requires the repo to be considered 'safe'
git config --global --add safe.directory "$(pwd)"

ARCH="$(uname -m)"
if [ "${ARCH}" = "aarch64" ]; then
  ARCH="arm64"
elif [ "${ARCH}" = "x86_64" ]; then
  ARCH="amd64"
fi

AGE_VERSION=1.3.2
curl -fsSL -o /tmp/archive.tar.gz https://github.com/FiloSottile/age/releases/download/v${AGE_VERSION}/age-v${AGE_VERSION}-linux-${ARCH}.tar.gz
tar xvzf /tmp/archive.tar.gz --strip-components 1 -C /usr/local/bin
rm -rf /tmp/archive.tar.gz
