#!/bin/bash
#
# update .rrd database with CPU temperature
#
# $Id: update_cputemp 275 2013-05-16 05:20:56Z lenik $
cd /home/pi
# create database if not exists
[ -f cputemp.rrd ] || {
/usr/bin/rrdtool create /home/pi/cputemp.rrd --step 300 \
DS:cputemp:GAUGE:1200:U:U \
RRA:AVERAGE:0.5:1:3200 \
RRA:AVERAGE:0.5:6:3200 \
RRA:AVERAGE:0.5:36:3200 \
RRA:AVERAGE:0.5:144:3200 \
RRA:AVERAGE:0.5:1008:3200 \
RRA:AVERAGE:0.5:4320:3200 \
RRA:AVERAGE:0.5:52560:3200 \
RRA:AVERAGE:0.5:525600:3200
}
# read the temperature and convert “59234″ into “59.234″ (degrees celsius)
TEMPERATURE=`cat /sys/class/thermal/thermal_zone0/temp`
TEMPERATURE=`echo -n ${TEMPERATURE:0:2};`
echo "test"
TEMPERATURE=`echo -n ${TEMPERATURE:0:2}; echo -n .; echo -n ${TEMPERATURE:2}`
/usr/bin/rrdtool update /home/pi/cputemp.rrd `date +”%s”`:$TEMPERATURE
/usr/bin/rrdtool graph /home/pi/cputemp.png DEF:temp=/home/pi/cputemp.rrd:cputemp:AVERAGE LINE2:temp#00FF00 --width 800
