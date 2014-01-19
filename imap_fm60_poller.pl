#!/usr/bin/perl 

# if you get a segmentation fault at RRD update - try removing rrd file if ther is one...

use RRDs;
use Sys::Syslog;
use DBI;
use Net::Telnet;

$message = "$0 LOADING";
#syslogit('debug',$message,'local0');

my $DEBUG = 0;
my $WEBROOT = "/home/monitor_data/solar";
my $counter = 0; 
my $type = "SOLAR";
my %seen;
my $DIRATTR = "48";
my @sentIps;
my %location;
my %hostname;
my %monitored;
my %alarm_level;
my %lat;
my %lng;
my %solar_config_id;
my %ip;
my %alm_count;

syslogit('err',"$0 LOADING Poller for FM60 Battery Charger Graphing and Alarms",'local0');

while (1){
   	%solar_config_id = ();
	%location = ();
	%hostname = ();
	%monitored = ();
	%alarm_level = ();
	%lat = ();
	%lng = ();
	%resources = ();
	%ip = ();
	%port = ();
	%state = ();
	%fault = ();
   	my $startT = time;
	
   	print "time registered as: $startT \n" if $DEBUG;
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	$year += 1900;
	$mon++;
	my $d = sprintf("%02d",$mday);
	my $m = sprintf("%02d",$mon);
	my $y = sprintf("%04d",$year);
	my $hr = sprintf("%02d",$hour);
	my $mi = sprintf("%02d",$min);
	my $sysTime = "$hr:$mi $d\-$m\-$y";
	print "$sysTime\n" if $DEBUG;
	my $dbuser = "webscript";
	my $dbpass = "andro!d";
	my $dbh = DBI->connect("dbi:mysql:imap", $dbuser,$dbpass);
	get_config_table($dbh);
	send_commands();
	$dbh->disconnect;
	$counter++;
	$endT = time;
	$duration = $endT - $startT;
	print "\nprogram executed $counter times in ". ($duration) ."secs. Retiring for 1 minute...\n\n" if $DEBUG;
	$sleep_period = 60 - $duration;
	if($sleep_period > 0){sleep($sleep_period)}
}

sub get_config_table{
	$db_handle = shift;	
	my $sql = "	SELECT
					type,
					serial_config.id as id,
					ip_addresses.hostname,
					serial_config.alarm_level,
					ip_addresses.ip_address as ip_address,
					port,
					resources,
					mission_locations.location,
					monitored,
					equipment_name,
					mission_locations.lat,
					mission_locations.lng,
					alarmid,
					state,
					address,
					fault 
				FROM (((((serial_config 
					left join ip_addresses on ip_addresses.id=ip_address_id)
					left join mission_locations on location_id=mission_locations.id)
					left join equipment on equipment_id=equipment.id) 
					left join eq_group on equipment.group_id=eq_group.id)
					left join alarms on (alarms.config_id=serial_config.id and type = 'SOLAR')) 
				WHERE equipment_name = 'fm60' and monitored > '0';";
				
	my $sth = $db_handle->prepare($sql);
	my $rows = $sth->execute();
	print "\nAlarm and config records:\n" if $DEBUG;
	while ($ref = $sth->fetchrow_hashref()){
		unless ($seen{$ref->{ip_address}}) {$seen{$ref->{ip_address}} = 1;push (@sentIps, $ref->{ip_address});} 
		unless ($solar_config_id{$ref->{ip_address}} ){$solar_config_id{$ref->{ip_address}} = $ref->{id};}
		unless ($location{$ref->{ip_address}}){$location{$ref->{ip_address}} = $ref->{location};}
		unless ($hostname{$ref->{ip_address}}){$hostname{$ref->{ip_address}} = $ref->{hostname};}
		unless ($monitored{$ref->{ip_address}}){$monitored{$ref->{ip_address}} = $ref->{monitored};} 
		unless ($equipment_name{$ref->{ip_address}}){$equipment_name{$ref->{ip_address}} = $ref->{equipment_name};}
		unless ($alarm_level{$ref->{ip_address}}){$alarm_level{$ref->{ip_address}} = $ref->{alarm_level};}
		unless ($lat{$ref->{ip_address}}){$lat{$ref->{ip_address}} = $ref->{lat};}
		unless ($lng{$ref->{ip_address}}){$lng{$ref->{ip_address}} = $ref->{lng};}
		unless ($ip{$ref->{id}}){$ip{$ref->{id}} = $ref->{ip_address};}
		unless ($host_add{$ref->{id}}){$host_add{$ref->{id}} = $ref->{hostname}."_".$ref->{address};}
		unless ($resources{$ref->{id}}){$resources{$ref->{id}} = $ref->{resources};}
		unless ($address{$ref->{id}}){$address{$ref->{id}} = $ref->{address};}
		unless ($port{$ref->{id}}){$port{$ref->{id}} = $ref->{port};}
		if (defined($ref->{state})){
			#t this needs to be changed to uniquely identify each type of alarm tha can exist on each ip address.....
			$state{$ref->{alarmid}}{$ref->{ip_address}} = $ref->{state};
		}
		if (defined($ref->{fault})){
			$fault{$ref->{alarmid}}{$ref->{ip_address}} = $ref->{fault};
			print "id:$ref->{id} hostname:$ref->{hostname} location:$ref->{location} monitored:$ref->{monitored} ip_address:$ref->{ip_address} port:$ref->{port} eq_name:$ref->{equipment_name} alarm_level:$ref->{alarm_level} lat:$ref->{lat} lng:$ref->{lng} state:$state{$ref->{alarmid}}{$ref->{ip_address}} fault:$fault{$ref->{alarmid}}{$ref->{ip_address}} \n" if $DEBUG; 
		}else{
			print "id:$ref->{id} hostname:$ref->{hostname} location:$ref->{location} monitored:$ref->{monitored} ip_address:$ref->{ip_address} port:$ref->{port} eq_name:$ref->{equipment_name} alarm_level:$ref->{alarm_level} lat:$ref->{lat} lng:$ref->{lng} \n" if $DEBUG;
		}
	}
}
sub get_site_resources{
        my($hostname) = shift;
        my $sql = "SELECT distinct resources FROM serial_config left join ip_addresses on ip_addresses.id=ip_address_id WHERE hostname = \'$hostname\';";
        my $sth = $dbh->prepare($sql);
        my $rows = $sth->execute();
        while (my $ref = $sth->fetchrow_hashref()){
                $res =  $ref->{resources};
        }
        return $res;
}


sub send_commands{
    	# main function loops while there is sites
	my %alarmMessage = (); 
	my %rrdVals = ();
	my %rrdFilename = ();
	my %rrdPath = ();
	my %MX_charger_mode = ('00' => 'Silent','01' => 'Float', '02' => 'Bulk', '03' => 'Absorb', '04' => 'EQ');
	print "\nRetrieving Data:\n" if $DEBUG;
	foreach my $id(keys %host_add){
		my($batt_current,$pv_current,$pv_volts,$daily_accum_kwh,$tenths_batt_current,$batt_volts,$daily_accum_ah) = "U";		
		my @rrdvals;
		$message = "FlexMax 60 Status for $host_add{$id}: ";
		$rrdFilename{$id} = "fm60-$host_add{$id}.rrd";
		$rrdPath{$id} = "/home/monitor_data/solar/$host_add{$id}/";	    
		print "\nstarting $message (using rrd file: $rrdPath{$id}$rrdFilename{$id})\n" if $DEBUG;
		my $t = new Net::Telnet(Timeout=>6,Errmode=>'return',Port=>"$port{$id}",Binmode=>'1');
		if($t->open("$ip{$id}")){
			print "opened tcp connection to $ip{$id} BF451\n" if $DEBUG;
			sleep 2;
			my $read = $t->get;
			print "get[$read]\n" if $DEBUG;
			my $data;
			print "using data which matches address: $address{$id}\n" if $DEBUG;
			if($read =~ /($address{$id},\d{2},\d{2},\d{2},\d{3},\d{3},\d{2},\d{2},\d{3},\d{2},\d{3},\d{3,4},\d{2,3},\d{3})/){
				$line = $1;
				if($line){
					print "length:" . length($line) . "\n" if $DEBUG;
				}
				$data = $line;
				$data =~ s/\s+//;
				print "data: {$data}\n" if $DEBUG;
				#A,00,10,07,076,027,02,03,000,03,576,0050,00,078 (47 chars)
				#($add,$u0,$batt_current,$pv_current,$pv_volts,$daily_accum_kwh,$tenths_batt_current,$aux,$err_mode,$ch_mode,$batt_volts,$daily_accum_ah,$u1,$chksum) = split(',',$data);
				($add,$u0,$batt_current,$pv_current,$pv_volts,$daily_accum_kwh,$tenths_batt_current,$aux,$err_mode,$ch_mode,$batt_volts,$daily_accum_ah,$u1,$chksum) = split(',',$data);
			}else{
				open(RS, '>>errored.txt') or warn "cant open file";
				print RS $read;
				close (RS);
			}
			$t->close();			
		}else{
			print "$host_add{$id} not open $ip{$id} : $port{$id}\n" if $DEBUG;
			my $msg = $t->errmsg;
			print "[$msg]\n" if $DEBUG; 
		}
		# do post facto calculations to scale and ready for storage
		$daily_accum_kwh = $daily_accum_kwh / 10; # provided by outback, provides latest value 
		$daily_accum_ah = $daily_accum_ah * 1; # provided by outback , provides latest value
		
		# OUT 
		$batt_current = $batt_current + ($tenths_batt_current/10);
		$batt_volts = $batt_volts / 10;
		$batt_power = sprintf "%2.2f",($batt_volts * $batt_current);


		# IN 
		$pv_current = $pv_current * 1; # current supplied from panels 
		$pv_volts = $pv_volts * 1; # voltage supplied from panels 
		$pv_power = sprintf "%2.2f", ($pv_volts * $pv_current); # power suuplied by panels
		
		# ratio of out power to in power ????? what is this???? load(batt)/supply(pv) ??
		$ratio = 0;
		if($pv_power > 0){
			#$ratio=$batt_power/$pv_power;
			$ratio=$pv_power/$batt_power;
		}
		$ioratio = sprintf "%2.2f",($ratio*100); # power ratio between offered and used 
		
		$ch_mode = $ch_mode * 10;
		my $site_res = $resources{$id}*1;
		my $yield = 0;
		if($site_res > 0){
			$yield = sprintf "%2.2f",$daily_accum_kwh/($site_res/1000); # energy provided to batteries / capacity available
		}

		push (@rrdvals,$pv_current,$pv_volts,$pv_power,$ioratio,$daily_accum_kwh,$yield,$batt_current,$batt_volts,$batt_power,$daily_accum_ah,$ch_mode,$site_res);
		my $rrdVals = join ":", ("N",@rrdvals);
		print "data prepared for RRD: $rrdVals\n" if $DEBUG;
		$rrdVals{$id} = $rrdVals;
		if ($DEBUG){
		print <<EOD;

						MX Address:\t\t\t$add
						Charger Current(A):\t\t$batt_current(A)
						Daily accum energy(KWh):\t$daily_accum_kwh(kWh)
						Battery Voltage(V):\t\t$batt_volts(V)
						Production Energy (W):\t\t$batt_power(W)
						PV Current(A):\t\t\t$pv_current(A)
						PV Voltage(V):\t\t\t$pv_volts(V)
						Power from PV(W):\t\t$pv_power(W)
						Ratio between in and out(%):\t$ioratio(%)
						Daily accum AH(Ah):\t\t$daily_accum_ah(Ah)
						MX Charger Mode:\t\t$ch_mode(x10)
						Resources(Wp):\t\t\t$site_res(Wp)
						Yield(KWh/KWp):\t\t\t$yield(kWh/kWp)
EOD
}
		# start alarm procedure here
		my $parameter = "DCVolts";
		unless (defined $batt_volts){
			my $fault = "no batt_voltsery volt reading from solar device";
			$alarmMessage{$ip{$id}}{$parameter} = "ATTENTION WARNING U $alarm_level{$ip{$id}} $type $solar_config_id{$ip{$id}} $host_add{$id} $location{$ip{$id}} $lat{$ip{$id}} $lng{$ip{$id}} $fault" if $alarm_level{$ip{$id}};
		}
		# only worry about 48V supplies not 12V
		if (defined($batt_volts) && $batt_volts < 48 && $batt_volts > 30){
			# set the alarmmessage string 
			my $fault = "Battery level below 48V (reading: $batt_volts)";
			$alarmMessage{$ip{$id}}{$parameter} = "ATTENTION WARNING U $alarm_level{$ip{$id}} $type $solar_config_id{$ip{$id}} $host_add{$id} \"$location{$ip{$id}}\" $lat{$ip{$id}} $lng{$ip{$id}} $fault" if $alarm_level{$ip{$id}};
			# we only enter the next section if there is alarms of some state in the alarms table
			foreach my $almkey(keys %state){ # this section handles alarm messaging so we go thru each alarm id from the alarms table and collect which ids need alarm message updates
				if (defined($state{$almkey}{$ip{$id}}) && ($state{$almkey}{$ip{$id}} =~ /WARNING/)){
					print "found WARNING($state{$almkey}{$ip{$id}}) in alarms table.... clearing alarm buffer for $ip{$id}...\n" if $DEBUG;
					# note here we are simply emptying the hash - the value is not defined
					$alarmMessage{$ip{$id}}{$parameter} = ();
					# buffer for 10 polls
					print "incrementing alarm poll count $alm_count{$almkey}{$ip{$id}}\n" if $DEBUG;
					$alm_count{$almkey}{$ip{$id}}++;
					print "alm count: $alm_count{$almkey}{$ip{$id}} alamid: $almkey\n";
					if ($alm_count{$almkey}{$ip{$id}} > 10){ # only works as long as the program has been running before this is a local reference
						$alarmMessage{$ip{$id}}{$parameter} = "ATTENTION ACTIVE $almkey $alarm_level{$ip{$id}} $type $solar_config_id{$ip{$id}} $host_add{$id} \"$location{$ip{$id}}\" $lat{$ip{$id}} $lng{$ip{$id}} $fault{$almkey}{$ip{$id}}" if $alarm_level{$ip{$id}};
						$alm_count{$almkey}{$ip{$id}} = 0;
						print "message $alarmMessage{$ip{$id}}{$parameter}\n";
					}
				}elsif(defined($state{$almkey}{$ip{$id}}) && ($state{$almkey}{$ip{$id}} =~ /CLEARED/)){
					# the same as no alarm found - so leave the WARNING message in tact
					$alm_count{$almkey}{$ip{$id}} = 0;
					print "$ip{$id} alm count: $alm_count{$almkey}{$ip{$id}} key:$almkey\n" if $DEBUG;
				}elsif(defined($state{$almkey}{$ip{$id}}) && ($state{$almkey}{$ip{$id}} =~ /ACTIVE/ )){
					# remove the WARNING status.
					$alarmMessage{$ip{$id}}{$parameter} = ();
					$alm_count{$almkey}{$ip{$id}} = 0;
					print "$ip{$id} alm count: $alm_count{$almkey}{$ip{$id}} key:$almkey\n" if $DEBUG;
				}
			}
		}else{ # if the value is ok we still need to check if any alarms are active or in warning state
			foreach my $almkey(keys %state){ 
				foreach my $ip(keys %{$state{$almkey}}){
					if (defined($state{$almkey}{$ip{$id}}) && (($state{$almkey}{$ip{$id}} =~ /WARNING/)||($state{$almkey}{$ip{$id}}=~ /ACTIVE/))){
						$alm_count{$almkey}{$ip{$id}} = 0;
						$alarmMessage{$ip{$id}}{$parameter} = "ATTENTION CLEARED $almkey $alarm_level{$ip{$id}} $type $solar_config_id{$ip{$id}} $host_add{$id} \"$location{$ip{$id}}\" $lat{$ip{$id}} $lng{$ip{$id}} $fault{$almkey}{$ip{$id}}"if $alarm_level{$ip{$id}};
					}elsif(defined($state{$almkey}{$ip{$id}}) && ($state{$almkey}{$ip{$id}} =~ /CLEARED/ )){
						$alm_count{$almkey}{$ip{$id}} = 0;
					}else{
					}
				}
			}
		}
		# end alarm procedure
	}
	print "\n\nUpdating RRDS:\n" if $DEBUG;
	foreach my $id(keys %ip){
		if (UpdateRRD($rrdFilename{$id},$rrdPath{$id},$rrdVals{$id})){
			print "$rrdFilename{$id} RRD update SUCCESSFUL \n" if $DEBUG;
		}else{
			print "RRD update FAILED readings: [$rrdFilename{$id} $rrdPath{$id} $rrdVals{$id}]\n\n" if $DEBUG;
		}
	}
	print "\nChecking Alarms to send to Syslog....." if $DEBUG;
	my $haveAlarms = 0;
	foreach my $ip(keys %alarmMessage){
		$haveAlarms = 1;
		foreach my $param(keys %{$alarmMessage{$ip}}){
			if (defined($alarmMessage{$ip}{$param})){
				print "\nsending alarm:  $alarmMessage{$ip}{$param}\n" if $DEBUG;
				Alarm($alarmMessage{$ip}{$param}) if $alarm_level{$ip};
			}else{   
				print "\nNo alarm messages for $ip $param [$alarmMessage{$ip}{$param}] on this run...\n" if $DEBUG;
			}	
		}
	}
	unless($haveAlarms){print "Alarms: none found\n" if $DEBUG;}
	%alarmMessage = ();
}

sub UpdateRRD{
    	my ($rrdFilename,$rrdPath,$feed) = @_;
    	my $success = 1;
    	unless(-d "$rrdPath"){
		print "creating directory...$rrdPath$rrdFilename\n" if $DEBUG;
		system("mkdir -p $rrdPath");
		system("chown -R apache $WEBROOT");
    	}
    	unless(-e "$rrdPath$rrdFilename"){
		print "didnt find rrd file creating...\n" if $DEBUG;
		my @rrdDS = (
		# DS:ds_name : ds_type : acceptable step size in seconds : min : max values ignored if outside min-max
		    "DS:pv_current:GAUGE:180:0:100",
		    "DS:pv_volts:GAUGE:180:0:200",
		    "DS:pv_power:GAUGE:180:0:10000",
		    "DS:ioratio:GAUGE:180:0:200",
		    "DS:accum_kwh:GAUGE:180:0:200",
		    "DS:yield:GAUGE:180:0:200",
		    "DS:batt_current:GAUGE:180:0:100",
		    "DS:batt_volts:GAUGE:180:0:100",
		    "DS:batt_power:GAUGE:180:0:10000",
		    "DS:accum_ah:GAUGE:180:0:200",
		    "DS:ch_mode:GAUGE:180:0:40",
		    "DS:site_res:GAUGE:180:0:10000",
		# once full move values to RRA archive, averaging if 1:1 mapping not used
		# RRA : storage_type : % of errors acceptable : no of values to consider for archiving : size of storage
		# 1 minute max for a year 60 x 24 x 30 x 12 = 518400
		    "RRA:MAX:0.5:1:535680",
		# 12 x 24 x 30 x 12 = 103680
		# daily max for 5 years 1440 = each sample is taken each minute x 60 x 24 - need to take max as data cycles from 0 to mx over 24 hrs - i.e. result would be halved - need to store highest value for the day
		    "RRA:MAX:0.5:5:103680",
		# 24 x 30 x 12 = 8640
		    "RRA:MAX:0.5:60:8640"
		);
		if(RRDs::create("$rrdPath$rrdFilename", "--step=60",@rrdDS)){
			print "successfully built rrd...$rrdPath$rrdFilename @rrdDS\n" if $DEBUG;
		}else{
			if($ERR=RRDs::error){
				print "failed to create rrd due to this error: $ERR!\n" if $DEBUG;
				next;
			}
		}
    	}
	RRDs::update("$rrdPath$rrdFilename","$feed");
	if($ERR = RRDs::error){
	    $success = 0;
	    print "rrd update failing due to ...$ERR with: $rrdPath$rrdFilename $feed\n" if $DEBUG;	    
	}else{$success = 1;}
	return $success;
}

sub Alarm{ # sent here because alarm is enabled
    my ($myAlarm) = shift;
    syslogit('debug',$myAlarm,'local0'); # syslog-daemon.pl  will update alarms file
}

sub syslogit {
        my ($priority, $msg, $facility) = @_; 
        return 0 unless ($priority =~ /info|err|debug/);
        openlog($0, 'pid,cons', $facility);
        syslog($priority, $msg);
        closelog();
        return 1;
}
