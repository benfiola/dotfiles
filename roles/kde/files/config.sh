#!/bin/sh -e
env QT_QPA_PLATFORM=offscreen lookandfeeltool -a org.kde.breezedark.desktop
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface gtk-theme 'Breeze-Dark'
gsettings set org.gnome.desktop.interface icon-theme 'breeze-dark'
gsettings set org.gnome.desktop.interface cursor-theme 'breeze_cursors'
gsettings set org.gnome.desktop.interface monospace-font-name 'FiraCode Nerd Font Mono 12'
kwriteconfig5 --file "$HOME/.config/kdeglobals" --group KDE --key SingleClick --type bool false
kwriteconfig5 --file "$HOME/.config/kdeglobals" --group KDE --key ScrollbarLeftClickNavigatesByPage --type bool false
kwriteconfig5 --file "$HOME/.config/kcminputrc" --group Keyboard --key RepeatDelay 200
kwriteconfig5 --file "$HOME/.config/kcminputrc" --group Keyboard --key RepeatRate 40
