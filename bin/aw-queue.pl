#!/usr/bin/perl
###########################################################################################################
# This script allows for any application to pass a queue of files to be restored or archived to PresSTORE #
# Written by Mike Szumlinski																			  #
# szumlins@mac.com																						  #
# February 13, 2014 																					  #
#																										  #	
# Special thanks to André Aulich for the paradigm used in this script									  #
###########################################################################################################

################
# Begin Script #
################

#set up to allow basic errors to flow to syslog

use File::Basename qw(dirname);
use File::Spec::Functions qw(rel2abs);
use File::Copy;
use Sys::Syslog;
openlog($0,'','user');

#grab our variables from our conf file;

$platform = $^O;
$path = rel2abs($0);
$directory = dirname($path);

if($platform eq "Win32"){
	require '$directory\..\conf\aw-queue.conf';	
	$platform = "win";	
} else {
	require "$directory/../conf/aw-queue.conf";
	$platform = "mac";	
}

	
#this is the path for the original media queue to be archived/restored
$full_queue_path = $ARGV[0];

#this is the method being used (archive or restore)
$method = $ARGV[1];

#generate a uique session ID based on the date
if($platform eq "win"){
	$sessionid=1234;
} elsif ($platform eq "mac"){
	$sessionid=`date | md5`;
	$sessionid=~s/\n//;
} else {
	syslog('err',"Can't determine platform.  We think you are running on platform: $platform");
}
#this is the path to nsdchat.  You need to change this if you do not have a standard PresSTORE install
if($platform eq "win"){
	$nsdchat = "\"C:\\Program Files (x86)\\ARCHIWARE\\Presstore\\bin\\nsdchat.exe\" -s awsock:/$username:$password:$sessionid\@$hostname:$port -c";
} elsif($platform eq "mac"){
	$nsdchat = "/usr/local/aw/bin/nsdchat -s awsock:/$username:$password:$sessionid\@$hostname:$port -c";
}
#if the filesystem for the archived content lives on a different PresSTORE client than localhost, change that here
$client = "localhost";

#index ID - this is passed as the third argument to the CLI
$index = $ARGV[3];

#log file location.  Change this if you want this going someplace different.  Must change on non-MacOS X systems
if($platform eq "win"){
	$logfile = "$directory\\..\\logs\\aw-queue.log";
} elsif($platform eq "mac"){
	$logfile = "$directory/../logs/aw-queue.log";
} else {
	syslog('err',"Can't determine platform.  We think you are running on platform: $platform");
}

#error log file location.  This simply lists the date stamp, the method, and the files that weren't able to be archived/restored
if($platform eq "win"){
	$errfile = "$directory\\..\\logs\\aw-queue-err.log";
} elsif($platform eq "mac"){
	$errfile = "$directory/../logs/aw-queue-err.log";
} else {
	syslog('err',"Can't determine platform.  We think you are running on platform: $platform");
}

#temp job log file location.  This is csv file that contains the CatDV asset ID, PresSTORE handle, and original file path
if($platform eq "win"){
	$joblogfile = "$directory\\..\\logs\\job_logs\\.thisrunjoblog";
} elsif($platform eq "mac"){
	$joblogfile = "$directory/../logs/job_logs/.thisrunjoblog";
} else {
	syslog('err',"Can't determine platform.  We think you are running on platform: $platform");	
}
#make sure the input is good

#if cli variables are empty, print usage to user/log

if ($ARGV[0] eq '' || $ARGV[1] eq '' || $ARGV[2] eq ''){
	print "\nusage: aw-queue.pl queue_file archive|restore archive_plan archive_index\n\n";
	print "queue_file:      full path to queue file.\n";
	print "archive|restore: select whether to write archive or restore\n";
	print "                 from archive the source_file.\n";
	print "archive_plan:    which archive plan you want PresSTORE to use.\n";
	print "archive_index:   only necessary for restore, this is the\n";
	print "                 PresSTORE index we will look up our files from.\n\n";
	exit
}

#if method is not proper, inform user

if ($ARGV[1] ne 'archive' && $ARGV[1] ne 'restore'){
	print "\nMethod \"$ARGV[1]\" not defined.  Please choose \"archive\" or \"restore\"\n\n";
	syslog('err',"Method \"$ARGV[1]\" not defined.  Please choose \"archive\" or \"restore\"");
	exit
}

#try a simple login to the server to validate nsdchat
$testlogin = `$nsdchat srvinfo hostname`;
$testlogin =~ s/\n//;
if ($testlogin ne $hostname){
	print "\nCould not connect to PresSTORE socket using \"$nsdchat\".  Please verify variables.\n";	
	syslog('err',"Could not connect to PresSTORE socket using \"$nsdchat\".  Please verify variables.");
	exit		
}

#check that the archive plan chosen is valid and enabled

if ($ARGV[2] eq ''){
	print "\narchive_plan not defined\n\n";
} else {
	$plan_check = `$nsdchat ArchivePlan $ARGV[2] enabled`;
	if($plan_check == '0'){
		print "\nArchive plan \"$ARGV[2]\" disabled.  Please enable plan\n\n";
		syslog('err',"Archive plan \"$ARGV[2]\" disabled.  Please enable plan");
		exit
	}
	if($plan_check != '1'){
		print "\nArchive plan \"$ARGV[2]\" not found.\n\n";
		syslog('err',"Archive plan \"$ARGV[2]\" not found.");
		exit
	}
}

#close the syslog, since we have a good working environment we can start logging to our own log

closelog;

# Now that we know we have all the information we need, lets open our log file for writing in case there are errors in the process
# if the log file doesn't exist, we create it, otherwise we append
#
# In MacOS X 10.7, the /Library/Logs directory is now not world writeable as in previous versions of the OS.  This means you will have to
# initialize and allow the user that runs this script access to write to your log file at /Library/Logs/aw-queue.log if you would like to 
# use the default location.

# Initiate our log file
if(-e $logfile){
	open LOGFILE, ">>", $logfile or die $!;
} else {
	open LOGFILE, ">", $logfile or die $!;
}

if(-e $errfile){
	open ERRFILE, ">>", $errfile or die $!;
} else {
	open ERRFILE, ">", $errfile or die $!;
}

#lets build a temp file to track all the assets in this job, their handles, and catdv ids
if(-e $joblogfile){
	open JOBLOG, ">>", $joblogfile or die $1;
} else {
	open JOBLOG, ">", $joblogfile or die $1;
}


#check to see if our queue file is actually there.  if it isn't, print to the log and quit.
if(! -e $full_queue_path){
	print LOGFILE localtime(time)." -- Queue file \"$full_queue_path\" does not exist! Exiting script, please check your queue file.\n";	
	exit
}

if(! -s $full_queue_path){
	print LOGFILE localtime(time)." -- Queue file \"$full_queue_path\" is empty. Nothing to do\n";	
	exit
}

#lets get rid of duplicates in our input file so we don't end up with unecessary tape work or errors

my $stripped = $full_queue_path;
my %seen = ();
{
	local @ARGV = ($stripped);
	local $^I = '.bac';
	while (<>){
		$seen{$_}++;
		next if $seen{$_} > 1;
		print;
	}
}



#run archive method
if($method eq 'archive'){
	#create job
	$archive_selection = `$nsdchat ArchiveSelection create $client $ARGV[2]`;
	$archive_selection =~ s/\n//;		
	if($archive_selection eq ''){

		#find out why we failed
		$geterr = `$nsdchat geterror`;
		$geterr =~ s/\n//;

		#print it to the log
		print LOGFILE localtime(time)." -- Archive Selection not created.  PresSTORE returned error \"$geterr\". Exiting.\n\n";
		exit;		
	}

	print LOGFILE localtime(time)." -- Archive selection $archive_selection created successfully\n";
	
	#open queue file, add each file to archive queue
	open FILE, "<",$full_queue_path or die $!;

	print LOGFILE localtime(time)." -- Archive queue file $full_queue_path successfully opened\n";

	$i = 0;
	$j = 0;
	if($usecatdv eq "yes"){
		print LOGFILE localtime(time)." -- Attempting to load CatDV post-run script\n";
		if($platform eq "win"){
			$recordupdate = "$directory\\record-update.pl";
		} elsif($platform eq "mac"){
			$recordupdate = "$directory/record-update.pl";
		} else {
			syslog('err',"Can't determine platform.  We think you are running on platform: $platform");
		}
		$register_script = `$nsdchat ArchiveSelection $archive_selection onjobcompletion \"localhost:$recordupdate\"`;
		$register_script =~ s/\n//;
		
		if($register_script ne "localhost:$recordupdate"){
			$geterr = `$nsdchat geterror`;
			$geterr =~ s/\n//;
			print LOGFILE localtime(time)." -- Post action script didn't register.  PresSTORE returned \"$geterr\"\n";
		} else {
			$geterr = `$nsdchat geterror`;
			$geterr =~ s/\n//;
			print LOGFILE localtime(time)." -- Post action script registered.  PresSTORE returned \"$geterr\"\n";			
		}
	}
	while (<FILE>){
		@this_file = split("<<CDVID>>",$_);
		$this_file[0] =~ s/\n//;
		$this_file[1] =~ s/\n//;		
		#$raw = $_;
		$this_file[0] =~ s/'/\'/g;
		$this_file[0] =~ s/\#/\\#/g;
		$this_file[0] =~ s/\(/\\(/g;
		$this_file[0] =~ s/\)/\\)/g;
		$this_file[0] =~ s/"/\"/g;
		$this_file[0] =~ s/\&/\\&/g;
		$this_file[0] =~ s/\,/\\,/g;
		$this_file[0] =~ s/\;/\\;/g;		
		@handles[$i] = `$nsdchat ArchiveSelection $archive_selection addentry {$this_file[0]}`;		
		if (length(@handles[$i])<2){
			$geterr = `$nsdchat geterror`;
			$geterr =~ s/\n//;		

			print LOGFILE localtime(time)." -- File $this_file[0] did not generate archive handle and will not be archived.  PresSTORE returned \"$geterr\".\n";	
			
			print ERRFILE localtime(time)." -- {$method} - $this_file[0]\n";
			
			$j++;
		} else {

			print LOGFILE localtime(time)." -- File $this_file[0] generated archive handle @handles[$i]";	
			$thishandle = @handles[$i];
			$thishandle =~ s/\n//;
			#this block of code writes a logical lookup for CatDV by writing the original file path, CatDV ID, and PresSTORE Archive Handle to a csv file
			if($usecatdv eq "yes"){
				#if($platform eq "win"){
				#	$catdvid = `\"$directory\\..\\catdv-xml.pl\" id \"$raw\"` or die $!;
				#} elsif($platform eq "mac"){
				#	$catdvid = `$directory/catdv-xml.pl id \"$raw\"` or die $!;
				#}
				print JOBLOG "\"$this_file[0]\",\"$thishandle\",\"$this_file[1]\"\n";
			}
		}
		
		$i++;
	}
		
	$filescount = $i-$j;
	print LOGFILE localtime(time)." -- Preparing $filescount files for archive\n";		
	
	if($filescount<=0){
		#don't submit a 0 job file

		print LOGFILE localtime(time)." -- 0 valid archive handles generated. Exiting.\n\n";		
	} else {
		#submit archive job to run
		$job_id = `$nsdchat ArchiveSelection $archive_selection submit yes`;
		$job_id =~ s/\n//;		
		
		if($job_id eq ''){
			$geterr = `$nsdchat geterror`;
			$geterr =~ s/\n//;		

			print LOGFILE localtime(time)." -- Job not submitted. PresSTORE returned error \"$geterr\". Exiting.\n\n";		
			exit;
		}
	}

	print LOGFILE localtime(time)." -- Archive job $job_id successfully submitted\n";
	close JOBLOG;
	$job_id =~ s/\n//;
	if($usecatdv eq "yes"){
		if($platform eq "win"){
			move($joblogfile,"$directory\\..\\logs\\job_logs\\job_logs\\$job_id.csv");
		} elsif($platform eq "mac"){
			move($joblogfile,"$directory/../logs/job_logs/$job_id.csv");
		}  else {
			syslog('err',"Can't determine platform.  We think you are running on platform: $platform");
		}
	}
	#if job finished cleanly, lets clean out that file
	
	open FILE,">",$full_queue_path;
	close FILE;

	print LOGFILE localtime(time)." -- Archive queue emptied\n";

}

#run restore method
if($method eq 'restore'){
	#verify we have a good index
	if($platform eq "win"){
		$goodindex = `$nsdchat ArchiveIndex names | find /C \"$index\"`;
	} elsif ($platform eq "mac"){
		$goodindex = `$nsdchat ArchiveIndex names | grep $index`;
	}  else {
		syslog('err',"Can't determine platform.  We think you are running on platform: $platform");
	}
	$goodindex =~ s/\n//;
	
	if($platform eq "win"){
		if($goodindex eq '1'){
			print LOGFILE localtime(time)." -- Could not find Archive Index \"$index\", exiting.  Please check the \$index variable in aw-queue.pl\n\n";
			exit;
		}
	} elsif ($platform eq "mac"){
		if($goodindex eq ''){
			print LOGFILE localtime(time)." -- Could not find Archive Index \"$index\", exiting.  Please check the \$index variable in aw-queue.pl\n\n";
			exit;
		}
	}  else {
		syslog('err',"Can't determine platform.  We think you are running on platform: $platform");
	}

	

	
	#create job
	$restore_selection = `$nsdchat RestoreSelection create $client`;
	$restore_selection =~ s/\n//;
	if($restore_selection eq ''){

		#find out why we failed
		$geterr = `$nsdchat geterror`;
		$geterr =~ s/\n//;

		#print it to the log

		print LOGFILE localtime(time)." -- Restore Selection not created.  PresSTORE returned error \"$geterr\". Exiting.\n\n";
		exit;		
	}


	print LOGFILE localtime(time)." -- Restore selection \"$restore_selection\" created successfully\n";

	
	#open queue file, add each file to restore queue
	open FILE, "<",$full_queue_path or die $!;

	$i = 0;
	$j = 0;
	
	while (<FILE>){	
		$_ =~ s/\n//;
		$_ =~ s/'/\'/g;
		$_ =~ s/\#/\\#/g;
		$_ =~ s/\(/\\(/g;
		$_ =~ s/\)/\\)/g;
		$_ =~ s/"/\"/g;
		$_ =~ s/\&/\\&/g;
		$_ =~ s/\,/\\,/g;
		$_ =~ s/\;/\\;/g;		
				
		if (defined($_)){

			print LOGFILE localtime(time)." -- Looking up archive handle for file \"$_\" in index \"$index\"\n";
			@archive_handles[$i] = `$nsdchat ArchiveEntry handle $client {$_} $index`;	
			chomp(@archive_handles[$i]);
			
			if (length(@archive_handles[$i])<2){
				$geterr = `$nsdchat geterror`;
				$geterr =~ s/\n//;
			
				print LOGFILE localtime(time)." -- Archive handle could not be looked up.  PresSTORE returned error \"$geterr\".\n";
				print ERRFILE localtime(time)." -- {$method} - $_\n";	
				push(@restore_handles,"err");
				$j++;
			} else {
				@restore_handles[$i] = `$nsdchat RestoreSelection $restore_selection addentry {@archive_handles[$i]}`;
				chomp(@restore_handles[$i]);
				
				if (length(@restore_handles[$i])<2){
					$geterr = `$nsdchat geterror`;
					$geterr =~ s/\n//;
					
					print LOGFILE localtime(time)." -- Restore handle could not be looked up.  PresSTORE returned error \"$geterr\". Exiting.\n\n";
					print ERRFILE localtime(time)." -- {$method} - $_\n";	
					
					$j++;				
				} else {			

					print LOGFILE localtime(time)." -- Archive Handle @archive_handles[$i] generated restore handle \"@restore_handles[$i]\" successfully\n";
				}
			}		
		$i++;
		}
	}
	
	$filecount = $i-$j;
	print LOGFILE localtime(time)." -- Preparing $filecount files for restore\n";		

	if($filecount<=0){
		open FILE,">",$full_queue_path;
		close FILE;		

		print LOGFILE localtime(time)." -- Restore queue emptied\n";
		
		#don't submit a 0 job file

		print LOGFILE localtime(time)." -- 0 valid restore handles generated. Exiting.\n\n";
	
		exit;
	} else {
		#submit restore job to run
		$job_id = `$nsdchat RestoreSelection $restore_selection submit 0`;
		$job_id =~ s/\n//;		
		
		if($job_id eq ''){
			$geterr = `$nsdchat geterror`;
			$geterr =~ s/\n//;		

			print LOGFILE localtime(time)." -- Job not submitted. PresSTORE returned error \"$geterr\". Exiting\n\n";		
			exit;
		} else {	

			print LOGFILE localtime(time)." -- Restore job $job_id successfully submitted\n";	
		}
	}
	
	open FILE,">",$full_queue_path;
	close FILE;

	print LOGFILE localtime(time)." -- Restore queue emptied\n";
	
}

print LOGFILE localtime(time)." -- Script Finished Cleanly\n\n";

close LOGFILE;
close ERRFILE;