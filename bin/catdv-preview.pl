#!/usr/bin/perl

# this script assumes path based previews in CatDV.
# this script also assumes all paths are written into the full path of their source:
# example - preview for /Volumes/XSan/MyMovie.mov would be written to /Path/To/Previews/Volumes/Xsan/MyMovie.previewextension


# set up our perl environment

use File::Basename;
use File::Copy;
use File::Basename qw(dirname);
use File::Spec::Functions qw(rel2abs);
use Sys::Syslog;



openlog($0,'','user');

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

if ($ARGV[0] eq ''){
	print "\nusage: catdv-preview.pl video_file \n\n";
	print "video_file: the full path of the original media location\n\t (ex. \"/path/to/MyVideo.mov\")\n\n";
	exit	
}

# use File::Basename to split up and reformat our string

my $fullpath = $ARGV[0];
my ($name,$path,$suffix) = fileparse($fullpath, qr/\.[^.]*/);

#compile our full path to our proxy

@preview_types = split(",",$previewextension);
$i = 0;
foreach(@preview_types){
	$previewloc = "$previewdir$path$name.$_";

	syslog('err',"Looking for file \@$previewloc");
	if($i==0){
		if(-e $previewloc){
			$i=1;
			syslog('err',"Proxy for $ARGV[0] found at $previewloc");
			# if we have a proxy, move it to our temp location
			
			$awproxyloc = "$awproxypath/$name.$_";
			
			copy($previewloc,$awproxyloc) or die "Copy failed: $!";
			
			if(-e $awproxyloc){
				syslog('err',"$name.$_ copied to $awproxypath successfully");
			} else {
				syslog('err',"$name.$_ did not get copied to $awproxypath");
			}
			
		} else {
			syslog('err',"No proxy found for $ARGV[0].  Skipping.");
			
			# if we can't find the movie, we could generate a proxy or set $awproxyloc to a fixed slate for no preview
			# here we would call our standard proxy generation script - see my qt_tools example for more info	
		}
	}
}

print $awproxyloc;
closelog;
