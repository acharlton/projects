#!/usr/bin/python
import os
import glob
import time
import rrdtool
DEBUG = 1
 
os.system('modprobe w1-gpio')
os.system('modprobe w1-therm')
 
base_dir = '/sys/bus/w1/devices/'
device_folder = glob.glob(base_dir + '10*')[0]
device_file = device_folder + '/w1_slave'

RRD_BASE = '/home/pi'
RRD = '%s/ambient_temp.rrd' % RRD_BASE
if DEBUG:
        print RRD_BASE
        print RRD

if not os.path.exists(RRD):
        print "creating rrd...\n"
        ret = rrdtool.create(RRD, "--step", "5", "--start", '0',
        "DS:battery:GAUGE:20:-20:200",
        "RRA:AVERAGE:0.5:1:10080",
        "RRA:AVERAGE:0.5:60:8640")

def read_temp_raw():
    f = open(device_file, 'r')
    lines = f.readlines()
    f.close()
    return lines
 
def read_temp():
    lines = read_temp_raw()
    while lines[0].strip()[-3:] != 'YES':
        time.sleep(0.2)
        lines = read_temp_raw()
    equals_pos = lines[1].find('t=')
    if equals_pos != -1:
        temp_string = lines[1][equals_pos+2:]
        temp_c = float(temp_string) / 1000.0
        temp_f = temp_c * 9.0 / 5.0 + 32.0
        #return temp_c, temp_f
        return temp_c
	
while True:
	#print read_temp()
	line = read_temp()
	time.sleep(4)
        cmdstring = '/usr/bin/rrdtool update ' + RRD + ' N:' + str(line)
        os.system(cmdstring)
        if DEBUG: print cmdstring;
