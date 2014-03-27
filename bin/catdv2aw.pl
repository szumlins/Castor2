#!/usr/bin/perl
###########################################################################################################
# This script writes file paths into a temp queue file for aw-queue.pl to poll for archive/restore        #
# Written by Mike Szumlinski																			  #
# szumlins@mac.com																						  #
# February 14, 2014																						  #
#																										  #	
# Special thanks to André Aulich for the paradigm used in this script									  #
###########################################################################################################

#############################
# Known Issues/Future Plans #
#############################
# Does not validate entry into queue file.  This requires knowing method as restore file paths are
# not online and cannot be verified.  Plans to include this in the future that will require an additional
# variable.

use File::Basename;
use File::Basename qw(dirname);
use File::Spec::Functions qw(rel2abs);
use File::Path qw( mkpath );


# are we writing to the archive or restore path?
$queue_file = $ARGV[0];

# the full file path to archive/restore
$file = $ARGV[1];

#validate input from the cli

if ($ARGV[0] eq '' || $ARGV[1] eq ''){
	print "\nusage: catdv2aw.pl queue_file file_path\n\n";
	print "queue_file: full path to queue file\n";
	print "file_path: path of file getting added to PresSTORE Archive or Restore queue\n\n";
	exit
}

$platform = $^O;
$path = rel2abs($0);
$directory = dirname($path);

if($platform eq "Win32"){
	require '$directory\..\conf\catdv.conf';	
	$platform = "win";	
} else {
	require "$directory/../conf/catdv.conf";
	$platform = "mac";	
}


#if(-e "C:\\Program Files (x86)\\ARCHIWARE\\Castor\\conf\\aw-queue.conf"){
#	require "C:\\Program Files (x86)\\ARCHIWARE\\Castor\\conf\\aw-queue.conf";
#} elsif(-e "/usr/local/Castor/conf/aw-queue.conf") {
#	require "/usr/local/Castor/conf/aw-queue.conf";
#} else {
#	print "Can't determine platform";
#}

#does our queue file exist?

if(-e $queue_file){
	open QUEUE, ">>", $queue_file or die $!; 
} else {
	print "Cannot find queue file $queue_file";
}
if($platform eq "win"){
	$file =~ s/\\/\//g;
}

($name,$path,$suffix) = fileparse($file,@suffixlist);
mkpath("$xmldir$path", 0, 0777 );

print QUEUE "$file\n";