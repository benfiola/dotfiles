#!/bin/sh -e
git config set --global safe.directory "$(pwd)"

rm -rf ./dotfiles-old
git clone https://github.com/benfiola/dotfiles ./dotfiles-old
