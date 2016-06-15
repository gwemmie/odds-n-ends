#!/bin/bash
# Switch between landscape and portrait mode. Good for tablet-laptops!
# This version assumes you, like me, are running a 3-column-sized XFCE
# panel on the left side (or bottom, if in portrait mode) of your screen
# Just delete the xfconf-query lines if you aren't.

if [ ! -f $HOME/.dumbscripts/landscape-portrait ]
then echo landscape > $HOME/.dumbscripts/landscape-portrait
fi

if grep -Fxq "landscape" $HOME/.dumbscripts/landscape-portrait
then
  xrandr -o right
  xfconf-query -c xfce4-panel -p /panels/panel-1/mode -s 0
  xfconf-query -c xfce4-panel -p /panels/panel-1/position -s 'p=8;x=540;y=1879'
  echo "portrait" > $HOME/.dumbscripts/landscape-portrait
else
  xrandr -o normal
  xfconf-query -c xfce4-panel -p /panels/panel-1/mode -s 2
  xfconf-query -c xfce4-panel -p /panels/panel-1/position -s 'p=6;x=0;y=0'
  echo "landscape" > $HOME/.dumbscripts/landscape-portrait
fi
