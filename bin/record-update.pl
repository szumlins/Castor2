#!/usr/bin/perl

#updated 2/1/14

use FindBin;
use lib "$FindBin::Bin/../lib";
use File::Basename;
use Sys::Syslog;
use File::Basename qw(dirname);
use File::Spec::Functions qw(rel2abs);
use File::Copy;

#openlog($0,'','user');
#syslog('err',"Starting catdv update script");

$platform = $^O;
$path = rel2abs($0);
$directory = dirname($path);


if($platform eq "Win32"){
	require '$directory\..\conf\aw-queue.conf';
	require '$directory\..\conf\catdv.conf';

	$platform = "win";	
	use lib "$FindBin::Bin\..\lib\win\lib";
	$rulog = "$directory\..\logs\record-update.log";
} else {
	require "$directory/../conf/aw-queue.conf";
	require "$directory/../conf/catdv.conf";	
	$platform = "mac";	
	use lib "$FindBin::Bin/../lib/mac/lib";	
	$rulogfile = "$directory/../logs/record-update.log"	
}

if(-e $rulogfile){
	open LOGFILE, ">>", $rulogfile or die $!;
} else {
	open LOGFILE, ">", $rulogfile or die $!;
}

use Text::CSV;

print LOGFILE localtime(time)." Starting catdv update script\n";	



unless($ENV{'AWPST_SRV_JOB'}){
	if ($ARGV[0] eq ''){
		print "\nusage: record-update.pl job_log \n\n";
		print "job_log: the full path of the csv file created by aw-queue.pl on run\n\n";
		exit	
	}
	$csvfile = $ARGV[0];
	$job = basename($csvfile);
	$job =~ s/.csv//;
	unless(-e $ARGV[0]){
	print "\nusage: record-update.pl logfile\n\n";
	print "logfile:      Full path to an aw-queue.pl generated job_log file\n";
	print "              By default these live in /Castor/logs/job_logs/\n\n";
	exit;
	}
} else {
	if($platform eq "win"){
		$csvfile = "$directory\\..\\logs\\job_logs\\".$ENV{'AWPST_SRV_JOB'}.".csv";
	} elsif ($platform eq "mac"){
		$csvfile = "$directory/../logs/job_logs/".$ENV{'AWPST_SRV_JOB'}.".csv";
	}		
	#syslog('err',"Trying to open $csvfile");
	$job = $ENV{'AWPST_SRV_JOB'};
	print LOGFILE localtime(time)." Trying to open $csvfile\n";	
}

#generate a uique session ID based on the date
if($platform eq "win"){
	$sessionid=1234;
} elsif ($platform eq "mac"){
	$sessionid=`date | md5`;
	$sessionid=~s/\n//;
} else {
	#syslog('err',"Can't determine platform.  We think you are running on platform: $platform");
	print LOGFILE localtime(time)." Can't determine platform.  We think you are running on platform: $platform\n";	
}

#this is the path to nsdchat.  You need to change this if you do not have a standard PresSTORE install
if($platform eq "win"){
	$nsdchat = "\"C:\\Program Files (x86)\\ARCHIWARE\\Presstore\\bin\\nsdchat.exe\" -s awsock:/$username:$password:$sessionid\@$hostname:$port -c";
} elsif($platform eq "mac"){
	$nsdchat = "/usr/local/aw/bin/nsdchat -s awsock:/$username:$password:$sessionid\@$hostname:$port -c";
} else {
	#syslog('err',"Can't determine platfrom.  We think you are running on platform :$platform");
	print LOGFILE localtime(time)." Can't determine platfrom.  We think you are running on platform :$platform\n";	
}
#if the filesystem for the archived content lives on a different PresSTORE client than localhost, change that here
$client = "localhost";


#try a simple login to the server to validate nsdchat
$testlogin = `$nsdchat srvinfo hostname`;
$testlogin =~ s/\n//;
if ($testlogin ne $hostname){
	print "\nCould not connect to PresSTORE socket using \"$nsdchat\".  Please verify variables.\n";	
	#syslog('err',"Could not connect to PresSTORE socket using \"$nsdchat\".  Please verify variables.");
	print LOGFILE localtime(time)." Could not connect to PresSTORE socket using \"$nsdchat\".  Please verify variables.\n";	
	exit		
}

sub uniq{
    my %seen = ();
    my @r = ();
    foreach my $a (@_) {
        unless ($seen{$a}) {
            push @r, $a;
            $seen{$a} = 1;
        }
    }
    return @r;
}

sub get_volumes{
	$handle = $_[0];
	#print LOGFILE localtime(time)." $nsdchat ArchiveEntry $handle volume\n";				
	$tape = `$nsdchat ArchiveEntry $handle volume`;
	$tape =~ s//\n/;
	split(" ",$tape);
	return $tape;
}

sub get_label{
	@volumes = @_;
	@labels = shift;
	$i = 0;
	foreach(@volumes){
		#print LOGFILE localtime(time)." $nsdchat Volume $_ label\n";					
		@labels[$i] = `$nsdchat Volume $_ label`;
		chomp(@labels[$i]);
		$i++;
	}
	$i=0;
	return @labels;
}

sub get_barcode{
	@volumes = @_;
	@barcodes = shift;
	$i = 0;
	foreach(@volumes){
		#print LOGFILE localtime(time)." $nsdchat Volume $_ barcode\n";						
		@barcodes[$i] = `$nsdchat Volume $_ barcode`;
		chomp(@barcodes[$i]);
		$i++;
	}
	$i=0;
	return @barcodes;
}

unless(-e $csvfile){
	syslog('err',"Job log file $csvfile doesn't exist");
	exit;
}

unless(-e $catdv){
	syslog('err',"Can't find catdv cli tool at path $catdv");
	print "Can't find catdv cli\n";
	exit;
}
print LOGFILE localtime(time)." Successfully found $csvfile, starting updates.\n";
#syslog('err'," Successfully found $csvfile, starting updates.");

$parse = Text::CSV->new();
open (CSV, "<", $csvfile) or die $!;
$c=1;
while (<CSV>){
	if($parse->parse($_)){
		@columns = $parse->fields();
		print LOGFILE localtime(time)." -----\n";
		print LOGFILE localtime(time)." Processing file $c.\n";
		#syslog('err',"Processing file $c.");		
		print LOGFILE localtime(time)." Full path: $columns[0].\n";		
		#syslog('err',"Full Path: $columns[0]");
		print LOGFILE localtime(time)." P5 Handle: $columns[1].\n";				
		#syslog('err',"PresSTORE Handle: $columns[1]");
		print LOGFILE localtime(time)." CDV ID: $columns[2].\n";				
		#syslog('err',"CatDV Unique ID: $columns[2]");
		@tapes = uniq(split(" ",get_volumes($columns[1])));
		print LOGFILE localtime(time)." File is on ".scalar(@tapes)." tapes\n";				
		#syslog('err',"File is on ".scalar(@tapes)." tapes\n");

		@labels = get_label(@tapes);
		@barcodes = get_barcode(@tapes);

		$tapecdv = join(",",@tapes);
		print LOGFILE localtime(time)." Volumes(s): $tapecdv\n";
		#syslog('err',"Volume(s): $tapecdv");		
		$result = `su $username -c "\\\"$catdv\\\" -clipid $columns[2] -set $cdv_volume_map=\\\"$tapecdv\\\""`;
		$result =~ s/\n//g;				
		print LOGFILE localtime(time)." CatDV output: $result\n";		
		#syslog('err',"$result");
		
		$labelcdv = join(",",@labels);
		print LOGFILE localtime(time)." Sending Label(s): $labelcdv\n";					
		#syslog('err',"Label(s): $labelcdv");				
		$result = `su $username -c "\\\"$catdv\\\" -clipid $columns[2] -set $cdv_label_map=\\\"$labelcdv\\\""`;
		$result =~ s/\n//g;		
		print LOGFILE localtime(time)." CatDV output: $result\n";				
		#syslog('err',"$result");
		
		$barcodecdv = join(",",@barcodes);
		print LOGFILE localtime(time)." Sending Barcode(s): $barcodecdv\n";			
		#syslog('err',"Barcode(s): $barcodecdv");
		$result = `su $username -c "\\\"$catdv\\\" -clipid $columns[2] -set $cdv_barcode_map=\\\"$barcodecdv\\\""`;				
		$result =~ s/\n//g;		
		print LOGFILE localtime(time)." CatDV output: $result\n";			
		#syslog('err',"$result");
	
		print LOGFILE localtime(time)." Sending P5 Handle\n";	
		#syslog('err',"PresSTORE Handle(s): $columns[1]");	
		$result = `su $username -c "\\\"$catdv\\\" -clipid $columns[2] -set $cdv_handle_map=\\\"$columns[1]\\\""`;	
		$result =~ s/\n//g;			
		print LOGFILE localtime(time)." CatDV output: $result\n";						
		#syslog('err',"$result");

		print LOGFILE localtime(time)." Setting CatDV Status field to \"Archived\"\n";	
		#syslog('err',"PresSTORE Handle(s): $columns[1]");	
		$result = `su $username -c "\\\"$catdv\\\" -clipid $columns[2] -set $cdv_arch_status_map=\\\"Archived\\\""`;			
		$result =~ s/\n//g;		
		print LOGFILE localtime(time)." CatDV output: $result\n";				
		#syslog('err',"$result");
		
		$c++;
	} else {
		$err = $parse->error_input;
		syslog('err',"Failed to parse line: $err");		
		$i++;
	}
}
close CSV;

print LOGFILE localtime(time)." -----\n";
print LOGFILE localtime(time)." Exiting CatDV return script\n";	
close LOGFILE;

$mvlog = "$directory/../logs/update_logs/$job.record-update.log";

move($rulogfile,$mvlog);

#syslog('err',"Exiting CatDV return script");
	
