#!/bin/zsh -e
directory="$(dirname "$(realpath "${(%):-%x}")")"
defaults write com.googlecode.iterm2 PrefsCustomFolder -string "$directory"
defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true