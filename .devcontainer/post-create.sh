#!/bin/sh -e
git config set --global safe.directory "$(pwd)"
git clone https://github.com/benfiola/dotfiles ./dotfiles-old
