#!/bin/bash
DIR="/path/to/your/rrd_database/"
 
#set to C if using Celsius
TEMP_SCALE="F"
 
#define the desired colors for the graphs
INTEMP_COLOR="#CC0000"
OUTTEMP_COLOR="#0000FF"
 
#hourly
rrdtool graph $DIR/temp_hourly.png --start -4h \
DEF:temp=$DIR/hometemp.rrd:temp:AVERAGE \
AREA:temp$INTEMP_COLOR:"Inside Temperature [deg $TEMP_SCALE]" \
DEF:outtemp=$DIR/hometemp.rrd:outtemp:AVERAGE \
LINE1:outtemp$OUTTEMP_COLOR:"Outside Temperature [deg $TEMP_SCALE]"
 
#daily
rrdtool graph $DIR/temp_daily.png --start -1d \
DEF:temp=$DIR/hometemp.rrd:temp:AVERAGE \
AREA:temp$INTEMP_COLOR:"Inside Temperature [deg $TEMP_SCALE]" \
DEF:outtemp=$DIR/hometemp.rrd:outtemp:AVERAGE \
LINE1:outtemp$OUTTEMP_COLOR:"Outside Temperature [deg $TEMP_SCALE]"
 
#weekly
rrdtool graph $DIR/temp_weekly.png --start -1w \
DEF:temp=$DIR/hometemp.rrd:temp:AVERAGE \
DEF:outtemp=$DIR/hometemp.rrd:outtemp:AVERAGE \
AREA:temp$INTEMP_COLOR:"Inside Temperature [deg $TEMP_SCALE]" \
LINE1:outtemp$OUTTEMP_COLOR:"Outside Temperature [deg $TEMP_SCALE]"
 
#monthly
rrdtool graph $DIR/temp_monthly.png --start -1m \
DEF:temp=$DIR/hometemp.rrd:temp:AVERAGE \
DEF:outtemp=$DIR/hometemp.rrd:outtemp:AVERAGE \
AREA:temp$INTEMP_COLOR:"Inside Temperature [deg $TEMP_SCALE]" \
LINE1:outtemp$OUTTEMP_COLOR:"Outside Temperature [deg $TEMP_SCALE]"
 
#yearly
rrdtool graph $DIR/temp_yearly.png --start -1y \
DEF:temp=$DIR/hometemp.rrd:temp:AVERAGE \
DEF:outtemp=$DIR/hometemp.rrd:outtemp:AVERAGE \
AREA:temp$INTEMP_COLOR:"Inside Temperature [deg $TEMP_SCALE]" \
LINE1:outtemp$OUTTEMP_COLOR:"Outside Temperature [deg $TEMP_SCALE]"


