#!/bin/bash


if ps ax | grep -v grep | grep monitor_battery > /dev/null
then
echo running
else
/home/pi/monitor_battery.py&
fi

if ps ax | grep -v grep | grep thermometer > /dev/null
then
echo running
else
/home/pi/thermometer.py&
fi

if ps ax | grep -v grep | grep cpu_temp > /dev/null
then
echo running
else
/home/pi/cpu_temp.py&
fi
