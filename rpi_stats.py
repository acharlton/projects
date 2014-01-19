#!/usr/bin/python
# script to log cpu_temp, RAM info, Disk info to a rrd database
import os 
import re
import time
import rrdtool
import spidev


DEBUG = 1

RRD_BASE = '/home/pi'
RRD = '%s/rpi_stats.rrd' % RRD_BASE
if DEBUG:
        print RRD_BASE
        print RRD

if not os.path.exists(RRD):
        print "creating rrd...\n"
        ret = rrdtool.create(RRD, "--step", "10", "--start", '0',
        "DS:battery:GAUGE:300:0:200",
        "DS:cpu_temp:GAUGE:300:0:200",
        "DS:ram_total:GAUGE:300:0:512",
        "DS:ram_used:GAUGE:300:0:512",
        "DS:ram_free:GAUGE:300:0:512",
        "DS:disk_total:GAUGE:300:0:200",
        "DS:disk_free:GAUGE:300:0:200",
        "DS:disk_perc:GAUGE:300:0:100",
        "RRA:AVERAGE:0.5:1:10080")

# get battery from spi
spi = spidev.SpiDev()
spi.open(0, 0)

def readadc(adcnum):
# read SPI data from MCP3008 chip, 8 possible adc's (0 thru 7)
    if adcnum > 7 or adcnum < 0:
        return -1
    r = spi.xfer2([1, 8 + adcnum << 4, 0])
    adcout = ((r[1] & 3) << 8) + r[2]
    return adcout

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
    #return(str(os.popen("top -n1 | awk '/Cpu\(s\):/ {print $2}'").readline().strip()))
    return(str(99))

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
        #battery info
        value = readadc(0)
        volts = (value * 3.3) / 1024
        battv = volts * 1.5
        #print ("%4d/1023 => %5.3f V => %4.1f V" % (value, volts, battv))
        #cmdstring = '/usr/bin/rrdtool update ' + RRD + ' N:' + str(round(battv,4))

        # CPU informatiom
        CPU_temp = getCPUtemperature()
        #CPU_usage = getCPUuse()
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
        #rrddata = str(CPU_temp) + ":" + str(CPU_usage) + ":" + str(RAM_total) + ":" + str(RAM_used) + ":" + str(RAM_free) + ":" + str(tot) + ":" + str(free) + ":" + str(perc)
        rrddata = str(round(battv,4)) + ":" + str(CPU_temp) + ":" + str(RAM_total) + ":" + str(RAM_used) + ":" + str(RAM_free) + ":" + str(tot) + ":" + str(free) + ":" + str(perc)
        cmdstring = '/usr/bin/rrdtool update ' + RRD + ' N:' + str(rrddata)
        os.system(cmdstring)
        if DEBUG: print cmdstring;
      	time.sleep(10)

