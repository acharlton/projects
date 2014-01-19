#!/bin/bash

timelapseName=`date +\%Y-\%m-\%d-\%H-\%M-%S`
mkdir -p /mnt/lapse/$timelapseName
jpegfilename=/mnt/lapse/$timelapseName/img-%07d.jpg
#/usr/bin/raspistill -o $jpegfilename -t 108000000 -tl 2400
/usr/bin/raspistill -o $jpegfilename -t 108000000 -tl 60000 -n 
