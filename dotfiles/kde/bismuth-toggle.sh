#!/bin/zsh -ex
file="$HOME/.config/kwinrc"
group="Plugins"
key="bismuthEnabled"
default="false"

message="bismuth enabled"
value="true"
if kreadconfig5 --file "$file" --group "$group" --key "$key" --default false --type bool; then
    value="false"
    message="bismuth disabled"
fi

kwriteconfig5 --file "$file" --group "$group" --key "$key" --type bool "$value"
dbus-send --type=signal --dest=org.kde.KWin /KWin org.kde.KWin.reloadConfig
notify-send -e "$message"
