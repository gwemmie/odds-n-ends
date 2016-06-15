#!/bin/bash
# Automatically delete certain files that should probably be deleted

# thumbails > 30 days old
cd $HOME/.thumbnails/normal/
for f in $(find -mtime +30); do rm "$f"; done
cd $HOME/.cache/thumbnails/large/
for f in $(find -mtime +30); do rm "$f"; done
cd $HOME/.cache/thumbnails/normal/
for f in $(find -mtime +30); do rm "$f"; done

# flash cache every boot
rm -rf $HOME/.adobe $HOME/.macromedia

# trash items > 30 days old
# not implemented
# Hey, I'm lazy. My trash bin has been constantly broken in various ways
# for years, and I never used it anyway.
