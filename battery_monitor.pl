#!/usr/bin/perl 

# if you get a segmentation fault at RRD update - try removing rrd file if ther is one...

use RRDs;

my $DEBUG = 0;
my $WEBROOT = "/home/pi";

while (1){
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
	send_commands();
	$dbh->disconnect;
	$counter++;
	$endT = time;
	$duration = $endT - $startT;
	print "\nprogram executed $counter times in ". ($duration) ."secs. Retiring for 1 minute...\n\n" if $DEBUG;
	$sleep_period = 60 - $duration;
	if($sleep_period > 0){sleep($sleep_period)}
}

sub send_commands{
    	# main function loops while there is sites
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
		    "DS:battery:GAUGE:180:0:100",
		# 1 minute max for a year 60 x 24 x 30 x 12 = 518400
		    "RRA:MAX:0.5:1:535680",
		# 12 x 24 x 30 x 12 = 103680
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

