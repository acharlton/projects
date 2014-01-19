#!/usr/bin/python
import os 
import re
import time
import rrdtool
DEBUG = 1

RRD_BASE = '/home/pi'
RRD = '%s/cpu_temp.rrd' % RRD_BASE
if DEBUG:
        print RRD_BASE
        print RRD

if not os.path.exists(RRD):
        print "creating rrd...\n"
        ret = rrdtool.create(RRD, "--step", "5", "--start", '0',
        "DS:cpu_temp:GAUGE:20:0:200",
        "DS:cpu_usage:GAUGE:20:0:100",
        "DS:ram_total:GAUGE:20:0:512",
        "DS:ram_used:GAUGE:20:0:512",
        "DS:ram_free:GAUGE:20:0:512",
        "DS:disk_total:GAUGE:20:0:200",
        "DS:disk_free:GAUGE:20:0:200",
        "DS:disk_perc:GAUGE:20:0:100",
        "RRA:AVERAGE:0.5:1:10080",
        "RRA:AVERAGE:0.5:60:8640")

# Return CPU temperature as a character string                                      
def getCPUtemperature():
    res = os.popen('vcgencmd measure_temp').readline()
    return(str(res.replace("temp=","").replace("'C\n","")))

# Return RAM information (unit=kb) in a list                                                                                                        
def getRAMinfo():
    p = os.popen('free')
    i = 0
    while 1:
        i = i + 1
        line = p.readline()
        if i==2:
            return(line.split()[1:4])

# Return % of CPU used by user as a character string                                
def getCPUuse():
    return(str(os.popen("top -n1 | awk '/Cpu\(s\):/ {print $2}'").readline().strip()))

# Return information about disk space as a list (unit included)                                                                  
def getDiskSpace():
    p = os.popen("df -h /")
    i = 0
    while 1:
        i = i +1
        line = p.readline()
        if i==2:
            return(line.split()[1:5])



while True:
	# CPU informatiom
	CPU_temp = getCPUtemperature()
	CPU_usage = getCPUuse()
	# RAM information
	# Output is in kb, here I convert it in Mb for readability
	RAM_stats = getRAMinfo()
	RAM_total = round(int(RAM_stats[0]) / 1000,1)
	RAM_used = round(int(RAM_stats[1]) / 1000,1)
	RAM_free = round(int(RAM_stats[2]) / 1000,1)
	# Disk information
	DISK_stats = getDiskSpace()
	DISK_total = DISK_stats[0]
	tot = re.sub('[G]','',DISK_total)
	DISK_free = DISK_stats[1]
	free = re.sub('[G]','',DISK_free)
	DISK_perc = DISK_stats[3]
	perc = re.sub('[%]','',DISK_perc)
	rrddata = str(CPU_temp) + ":" + str(CPU_usage) + ":" + str(RAM_total) + ":" + str(RAM_used) + ":" + str(RAM_free) + ":" + str(tot) + ":" + str(free) + ":" + str(perc)
    	cmdstring = '/usr/bin/rrdtool update ' + RRD + ' N:' + str(rrddata)
    	os.system(cmdstring)
    	if DEBUG: print cmdstring;
    	time.sleep(4)


