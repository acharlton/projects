#!/usr/bin/python
import paramiko
from commands import getstatusoutput
 
DIR = '/path/to/your/temperature/scripts'
 
#generate graphs
getstatusoutput(DIR + '/create_graph.sh')
 
ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('your_sftp_server', port=your_sftp_port, username='your_username', password='your_password')
 
sftp = ssh.open_sftp();
sftp.put(DIR + '/temp_hourly.png', 'rpi_temp/temp_hourly.png')
sftp.put(DIR + '/temp_daily.png', 'rpi_temp/temp_daily.png')
sftp.put(DIR + '/temp_weekly.png', 'rpi_temp/temp_weekly.png')
sftp.put(DIR + '/temp_monthly.png', 'rpi_temp/temp_monthly.png')
sftp.put(DIR + '/temp_yearly.png', 'rpi_temp/temp_yearly.png')
sftp.close()
