#!/bin/sh -e
env QT_QPA_PLATFORM=offscreen lookandfeeltool -a org.kde.breezedark.desktop
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface gtk-theme 'Breeze-Dark'
gsettings set org.gnome.desktop.interface icon-theme 'breeze-dark'
gsettings set org.gnome.desktop.interface cursor-theme 'breeze_cursors'
gsettings set org.gnome.desktop.interface monospace-font-name 'FiraCode Nerd Font Mono 12'
kwriteconfig6 --file "$HOME/.config/kdeglobals" --group KDE --key SingleClick --type bool false
kwriteconfig6 --file "$HOME/.config/kdeglobals" --group KDE --key ScrollbarLeftClickNavigatesByPage --type bool false
kwriteconfig6 --file "$HOME/.config/kcminputrc" --group Keyboard --key RepeatDelay 200
kwriteconfig6 --file "$HOME/.config/kcminputrc" --group Keyboard --key RepeatRate 40
kwriteconfig6 --file "$HOME/.config/kglobalshortcutsrc" --group org.kde.krunner.desktop --key _launch 'Alt+Space\tSearch\tAlt+F2,Alt+Space\tAlt+F2\tSearch,KRunner'
kwriteconfig6 --file "$HOME/.config/kglobalshortcutsrc" --group kwin --key 'Window Quick Tile Left' 'Meta+Left,Meta+Left,Quick Tile Window to the Left'
kwriteconfig6 --file "$HOME/.config/kglobalshortcutsrc" --group kwin --key 'Window Quick Tile Right' 'Meta+Right,Meta+Right,Quick Tile Window to the Right'
kwriteconfig6 --file "$HOME/.config/kglobalshortcutsrc" --group kwin --key 'Window Quick Tile Top' 'Meta+Up,Meta+Up,Quick Tile Window to the Top'
kwriteconfig6 --file "$HOME/.config/kglobalshortcutsrc" --group kwin --key 'Window Quick Tile Bottom' 'Meta+Down,Meta+Down,Quick Tile Window to the Bottom'
kwriteconfig6 --file "$HOME/.config/kglobalshortcutsrc" --group kwin --key 'Window Maximize' 'Meta+Alt+Return,Meta+PgUp,Maximize Window'
kwriteconfig6 --file "$HOME/.config/krunnerrc" --group General --key FreeFloating --type bool true
kwriteconfig6 --file "$HOME/.config/krunnerrc" --group Plugins --key PowerDevilEnabled --type bool false
kwriteconfig6 --file "$HOME/.config/krunnerrc" --group Plugins --key appstreamEnabled --type bool false
kwriteconfig6 --file "$HOME/.config/krunnerrc" --group Plugins --key baloosearchEnabled --type bool false
kwriteconfig6 --file "$HOME/.config/krunnerrc" --group Plugins --key bookmarksEnabled --type bool false
kwriteconfig6 --file "$HOME/.config/krunnerrc" --group Plugins --key desktopsessionsEnabled --type bool false
kwriteconfig6 --file "$HOME/.config/krunnerrc" --group Plugins --key helprunnerEnabled --type bool false
kwriteconfig6 --file "$HOME/.config/krunnerrc" --group Plugins --key krunner_killEnabled --type bool false
kwriteconfig6 --file "$HOME/.config/krunnerrc" --group Plugins --key kwinEnabled --type bool false
kwriteconfig6 --file "$HOME/.config/krunnerrc" --group Plugins --key org.kde.activities2Enabled --type bool false
kwriteconfig6 --file "$HOME/.config/krunnerrc" --group Plugins --key org.kde.windowedwidgetsEnabled --type bool false
kwriteconfig6 --file "$HOME/.config/krunnerrc" --group Plugins --key placesEnabled --type bool false
kwriteconfig6 --file "$HOME/.config/krunnerrc" --group Plugins --key plasma-desktopEnabled --type bool false
kwriteconfig6 --file "$HOME/.config/krunnerrc" --group Plugins --key recentdocumentsEnabled --type bool false
kwriteconfig6 --file "$HOME/.config/krunnerrc" --group Plugins --key shellEnabled --type bool false
kwriteconfig6 --file "$HOME/.config/krunnerrc" --group Plugins --key windowsEnabled --type bool false

# 'kwriteconfig6' will internally convert '\t' to '\\t' which is incorrect
# the following command reverts this behavior
sed -i 's/\\\\t/\\t/g' ~/.config/kglobalshortcutsrc
