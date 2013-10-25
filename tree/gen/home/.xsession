#!/bin/sh

# hack but doesn't persist?
sudo rfkill block bluetooth

xrdb -load ~/.Xresources

SCRS_MODE=h
export TMUX=''

# shift+caps does bksp w/o this..
asdf

ibus-daemon -drx

# make hold-key typing repeat a bit fasterxrdb -load ~/.Xresources &
xset r rate 200 50

notifier

gnome-panel &
#workrave &
caffeine &

ff &

tmux-multi-group-prune &

remacs

# scrs sometimes fails w/o this..
sleep 4

#scrs -m "$SCRS_MODE" -- -z &
scrs -m "$SCRS_MODE" &

nm-applet &

gnome-settings-daemon &
gnome-volume-manager &
conky &

# why doesn't something else start this?
#dropbox start &

startfluxbox
