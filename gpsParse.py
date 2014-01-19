#!/usr/bin/python

import os
import serial
import time
import crcmod

x_list = []
y_list = []

def send(data):
	NTX2 = serial.Serial('/dev/ttyAMA0', 50, serial.SEVENBITS, serial.PARITY_NONE, serial.STOPBITS_TWO)
	NTX2.flush()
	NTX2.write(data)
	print "sent "+ data
	NTX2.close()


while True:
	gps = serial.Serial('/dev/ttyAMA0',9600, timeout=2)
	line = gps.readline()
	if 'GPGGA' not in line:
		continue
	#gps.flush()
	gps.close()
	time.sleep(0.5)
	print line
	fields = line.split(',')
	utc = fields[1]
	lat = (fields[2])
	N = fields[3]
	lon = fields[4]
	E = fields[5]
	FS = int(fields[6])
	NoSV = fields[7]
	HDOP = fields[8]
	msl = fields[9]
	uMsl = fields[10]
	Altref = fields[11]
	uSep = fields[12]
	DiffAge = fields[13]
	DiffStation = fields[14]

	if FS == 0:
		print "not synched"
		continue

	utc = float(utc)
	t = "%06i" % utc
	h = t[0:2] 
	m = t[2:4]
	s = t[4:6]
	utc = str(str(h) + ":" + str(m) + ":" + str(s)) 

	y = int(lat[:2]) + float(lat[2:]) / 60.
	y = "%02.2f" % y
	if N == 'S':
		y = -y

	x = int(lon[:3]) + float(lon[3:]) / 60.
	x = "%02.2f" % x
	if E == 'W':
		x = -x

	print FS, x, y, NoSV, msl, DiffStation
	string = "DATA " + str(NoSV) + ',' + utc + ',' + str(x) + ',' + str(y) + ',' + str(msl) + "\n"
	send(string)

	#x_list.append(x)
	#y_list.append(y)
	


