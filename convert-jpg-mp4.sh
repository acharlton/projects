#!/bin/bash

# this works well
# x=1;for i in *JPG; do counter=$(printf %04d $x); ln "$i" img_in_order/img"$counter".jpg; x=$(($x+1)); done
# ffmpeg -i img%04d.jpg -r 6 -an -vcodec copy lapse.avi
