#!/usr/bin/python
import rrdtool
import os
import serial
import re
DEBUG = 1
BASE = '/home/pi'
RRD = '%s/battery.rrd' % BASE
if DEBUG:
	print BASE
	print RRD

if not os.path.exists(RRD):
	print "creating rrd...\n"
	ret = rrdtool.create(RRD, "--step", "5", "--start", '0',
 	"DS:battery:GAUGE:10:0:10",
 	"RRA:AVERAGE:0.5:1:10080",
 	"RRA:AVERAGE:0.5:60:8640")

'''
ret = rrdtool.graph( "/home/pi/battery.png", "--start", "-%i" % 86400,
         "-w 800",
         "DEF:m1_num=battery.rrd:battery:AVERAGE",
         "LINE3:m1_num#0000FF:battery\\r",
         "GPRINT:m1_num:AVERAGE:Avg m1\: %6.0lf ",
         "GPRINT:m1_num:MAX:Max m1\: %6.0lf \\r")

'''
# for arduino mini ser = serial.Serial(port='/dev/ttyUSB0',
ser = serial.Serial(port='/dev/ttyACM0',
                    baudrate=9600,
                    bytesize=serial.EIGHTBITS,
                    parity=serial.PARITY_NONE,
                    stopbits=serial.STOPBITS_ONE,
                    timeout=3)

if DEBUG: print "Port Opened .... listening";

while 1:
	line = ser.readline().rstrip()
	if DEBUG: print(line); 
	if len(line.split('.')) == 2:
		if DEBUG: print "Battery = " + str(line);
		cmdstring = '/usr/bin/rrdtool update ' + RRD + ' N:' + str(line)
		os.system(cmdstring)
		if DEBUG: print cmdstring;
		#exit()

