#!/bin/sh -e
kwriteconfig5 --file "$HOME/.config/kwinrc" --group Plugins --key bismuthEnabled --type bool true
kwriteconfig5 --file "$HOME/.config/kwinrc" --group Windows --key ElectricBorderMaximize --type bool false
kwriteconfig5 --file "$HOME/.config/kwinrc" --group Windows --key ElectricBorderTiling --type bool false
kwriteconfig5 --file "$HOME/.config/kwinrc" --group Windows --key FocusPolicy FocusFollowsMouse
kwriteconfig5 --file "$HOME/.config/kwinrc" --group Windows --key NextFocusPrefersMouse --type bool true
kwriteconfig5 --file "$HOME/.config/kwinrc" --group Script-bismuth --key screenGapBottom 20
kwriteconfig5 --file "$HOME/.config/kwinrc" --group Script-bismuth --key screenGapLeft 20
kwriteconfig5 --file "$HOME/.config/kwinrc" --group Script-bismuth --key screenGapRight 20
kwriteconfig5 --file "$HOME/.config/kwinrc" --group Script-bismuth --key screenGapTop 20
kwriteconfig5 --file "$HOME/.config/kwinrc" --group Script-bismuth --key tileLayoutGap 20
kwriteconfig5 --file "$HOME/.config/kwinrulesrc" --group General --key count 1
kwriteconfig5 --file "$HOME/.config/kwinrulesrc" --group General --key rules fca92cf7-673b-4e39-abb7-aae2aa4cb538
kwriteconfig5 --file "$HOME/.config/kwinrulesrc" --group fca92cf7-673b-4e39-abb7-aae2aa4cb538 --key Description "Minimum Window Size"
kwriteconfig5 --file "$HOME/.config/kwinrulesrc" --group fca92cf7-673b-4e39-abb7-aae2aa4cb538 --key minsizerule 2
kwriteconfig5 --file "$HOME/.config/kwinrulesrc" --group fca92cf7-673b-4e39-abb7-aae2aa4cb538 --key minsize 0,0
kwriteconfig5 --file "$HOME/.config/kwinrulesrc" --group fca92cf7-673b-4e39-abb7-aae2aa4cb538 --key types 1
kwriteconfig5 --file "$HOME/.config/kglobalshortcutsrc" --group bismuth --key decrease_window_width "Meta+Ctrl+H,Meta+Ctrl+H,Increase Window Width"
kwriteconfig5 --file "$HOME/.config/kglobalshortcutsrc" --group bismuth --key increase_window_height "Meta+Ctrl+J,Meta+Ctrl+J,Increase Window Height"
kwriteconfig5 --file "$HOME/.config/kglobalshortcutsrc" --group bismuth --key decrease_window_height "Meta+Ctrl+K,Meta+Ctrl+K,Decrease Window Height"
kwriteconfig5 --file "$HOME/.config/kglobalshortcutsrc" --group bismuth --key increase_window_width "Meta+Ctrl+L,Meta+Ctrl+L,Increase Window Width"
kwriteconfig5 --file "$HOME/.config/kglobalshortcutsrc" --group bismuth --key move_window_to_left_pos "Meta+Shift+H,Meta+Shift+H,Move Window Left"
kwriteconfig5 --file "$HOME/.config/kglobalshortcutsrc" --group bismuth --key move_window_to_bottom_pos "Meta+Shift+J,Meta+Shift+J,Move Window Down"
kwriteconfig5 --file "$HOME/.config/kglobalshortcutsrc" --group bismuth --key move_window_to_upper_pos "Meta+Shift+K,Meta+Shift+K,Move Window Up"
kwriteconfig5 --file "$HOME/.config/kglobalshortcutsrc" --group bismuth --key move_window_to_right_pos "Meta+Shift+L,Meta+Shift+L,Move Window Right"
kwriteconfig5 --file "$HOME/.config/kglobalshortcutsrc" --group bismuth --key rotate "Meta+R,Meta+R,Rotate"
kwriteconfig5 --file "$HOME/.config/kglobalshortcutsrc" --group bismuth --key next_layout "Meta+\\\\,Meta+\\\\,Switch to the Next Layout"
kwriteconfig5 --file "$HOME/.config/kglobalshortcutsrc" --group bismuth --key prev_layout "Meta+|,Meta+|,Switch to the Previous Layout"
kwriteconfig5 --file "$HOME/.config/kglobalshortcutsrc" --group bismuth --key toggle_window_floating "Meta+F,Meta+F,Toggle Active Window Floating"
kwriteconfig5 --file "$HOME/.config/kglobalshortcutsrc" --group bismuth-toggle.desktop --key _launch "Ctrl+Meta+|,none,bismuth-toggle"
kwriteconfig5 --file "$HOME/.config/kglobalshortcutsrc" --group bismuth-toggle.desktop --key _k_friendly_name "bismuth-toggle"