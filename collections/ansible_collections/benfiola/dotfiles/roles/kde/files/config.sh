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
kwriteconfig5 --file "$HOME/.config/kglobalshortcutsrc" --group org.kde.krunner.desktop --key _launch 'Alt+Space\tAlt+F2\tSearch\tCtrl+Space,Alt+Space\tAlt+F2\tSearch,KRunner'

# 'kwriteconfig5' will internally convert '\t' to '\\t' which is incorrect
# the following command reverts this behavior
sed -i 's/\\\\t/\\t/g' ~/.config/kglobalshortcutsrc
