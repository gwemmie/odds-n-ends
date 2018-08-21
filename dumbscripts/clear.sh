#!/bin/bash
# Automatically delete certain files that should probably be deleted

# Don't bother deleting thumbnails that are gonna be reloaded soon anyway
# I give up because it would take 100% of a CPU core for hours
#THUMB_FILES=$(find -L $HOME/.mythtv/* $HOME/Downloads/* $HOME/Pictures/* $HOME/Videos/* | grep -Ei "png|jpg|mp4|mkv|webm")
#THUMB_FILES=${THUMB_FILES// /%20}
#for FILE in $THUMB_FILES; do
#    FILE_MD5=$(printf '%s' "file://$FILE" | md5sum)
#    FILE_THUMB="$HOME/.cache/thumbnails/normal/${FILE_MD5%  -*}.png"
#    touch -c "$FILE_THUMB"
#done

# thumbails > 30 days old
for f in $(find $HOME/.thumbnails/normal/* -mtime +30); do rm "$f"; done
for f in $(find $HOME/.cache/thumbnails/large/* -mtime +30); do rm "$f"; done
for f in $(find $HOME/.cache/thumbnails/normal/* -mtime +30); do rm "$f"; done

# notification history every boot
#rm $HOME/.notifications

# flash cache every boot
rm -rf $HOME/.adobe $HOME/.macromedia

# update Downloads folder
$HOME/.dumbscripts/update-downloads.sh & disown

# trash items > 30 days old
# not implemented
# Hey, I'm lazy. My trash bin has been constantly broken in various ways
# for years, and I never used it anyway.

disown -r && exit
