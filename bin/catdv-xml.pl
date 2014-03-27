#!/usr/bin/perl

# set up environment
# if you do not have XML::Simple installed, use CPAN to install
#
# shell> perl -MCPAN -e shell
# cpan> install XML::Simple
#
# last edited 2/13/14


use XML::Simple;
use Data::Dumper;
use File::Basename;
use File::Basename qw(dirname);
use File::Spec::Functions qw(rel2abs);

our %metadata = ();

$platform = $^O;
$path = rel2abs($0);
$directory = dirname($path);

if($platform eq "Win32"){
	require '$directory\..\conf\catdv.conf';
	require '$directory\..\conf\aw-queue.conf';	
	$platform = "win";	
} else {
	require "$directory/../conf/catdv.conf";
	require "$directory/../conf/aw-queue.conf";
	$platform = "mac";	
}

#if(-e "C:\\Program Files (x86)\\ARCHIWARE\\Castor\\conf\\metadata.conf"){
#	require "C:\\Program Files (x86)\\ARCHIWARE\\Castor\\conf\\metadata.conf";
#} elsif(-e "/usr/local/Castor/conf/metadata.conf") {
#	require "/usr/local/Castor/conf/metadata.conf";
#}

#if(-e "C:\\Program Files (x86)\\ARCHIWARE\\Castor\\conf\\catdv.conf"){
#	require "C:\\Program Files (x86)\\ARCHIWARE\\Castor\\conf\\catdv.conf";
#} elsif(-e "/usr/local/Castor/conf/catdv.conf") {
#	require "/usr/local/Castor/conf/catdv.conf";
#}

#if(-e "C:\\Program Files (x86)\\ARCHIWARE\\Castor\\conf\\aw-queue.conf"){
#	require "C:\\Program Files (x86)\\ARCHIWARE\\Castor\\conf\\aw-queue.conf";
#} elsif(-e "/usr/local/Castor/conf/aw-queue.conf") {
#	require "/usr/local/Castor/conf/aw-queue.conf";
#}


if ($ARGV[0] eq '' && $ARGV[1] eq ''){
	print "\nusage: catdv-xml.pl debug|id|media_file xml_file \n\n";
	print "debug: enables direct analysis of CatDV XML file\n";
	print "id: returns just the catdv asset ID of this file\n";
	print "video_file: the full path of the original media location (ex. \"MyVideo.mov\")\n";
	print "xml_file: an exported xml file from CatDV worker node\n\n";
	print "example id usage:     catdv-xml.pl id /path/to/catdv.xml\n";	
	print "example debug usage:  catdv-xml.pl debug /path/to/catdv.xml\n\n";
	exit	
}

if ($ARGV[0] eq 'debug' && $ARGV[1] eq ''){
	print "error: no XML file given\n\n";
	print "usage: catdv-xml.pl debug|id|media_file xml_file \n\n";
	print "debug: enables direct analysis of CatDV XML file\n";
	print "id: returns just the catdv asset ID of this file\n";
	print "video_file: the full path of the original media location (ex. \"MyVideo.mov\")\n";
	print "xml_file: an exported xml file from CatDV worker node\n\n";
	print "example debug usage:  catdv-xml.pl debug /path/to/catdv.xml\n\n";
	exit	
}

if ($ARGV[0] eq 'id' && $ARGV[1] eq ''){
	print "error: no XML file given\n\n";
	print "usage: catdv-xml.pl debug|id|media_file xml_file \n\n";
	print "debug: enables direct analysis of CatDV XML file\n";
	print "id: returns just the catdv asset ID of this file\n";
	print "video_file: the full path of the original media location (ex. \"MyVideo.mov\")\n";
	print "xml_file: an exported xml file from CatDV worker node\n\n";
	print "example id usage:  	 catdv-xml.pl id /path/to/catdv.xml\n\n";
	exit	
}

if ($ARGV[0] eq '-strip' && $ARGV[1] eq ''){
	print "error: no XML file given\n\n";
	print "usage: catdv-xml.pl debug|id|media_file xml_file \n\n";
	print "debug: enables direct analysis of CatDV XML file\n";
	print "id: returns just the catdv asset ID of this file\n";
	print "video_file: the full path of the original media location (ex. \"MyVideo.mov\")\n";
	print "xml_file: an exported xml file from CatDV worker node\n\n";
	print "example debug usage:  catdv-xml.pl debug /path/to/catdv.xml\n\n";
	exit	
}

$xml = new XML::Simple;

# get the base filename (similar to $f in CatDV)
$xmlfile = basename($ARGV[0]);

# add .xml to the end of filename to reference exported xml from CatDV
if($ARGV[0] eq "debug"){
	$xmltarget = $ARGV[1];
} elsif ($ARGV[0] eq "id") {
	$xmlfile = basename($ARGV[1]);
	if($platform eq "win"){
		$xmltarget = "$xmldir\\$ARGV[0].xml";
	} elsif($platform eq "mac"){
		$xmltarget = "$xmldir/$ARGV[0].xml";
	}
} elsif($ARGV[0] eq "-strip"){
	#currently only works for windows paths in mac WN environments.
	$xmlfile = basename($ARGV[1]);
	opendir(TMP,"$xmldir");
	@xmls = readdir(TMP);
	
	foreach $file(@xmls){
		@breakdown = split(/\\/,$file);
		$compare = $breakdown[-1];
		if($compare eq "$xmlfile.xml"){
			$xmltarget = "$xmldir/$file";
		}
	}
} else {
	if($platform eq "win"){
		$xmltarget = "$xmldir\\$ARGV[0].xml";
	} elsif($platform eq "mac"){
		$xmltarget = "$xmldir/$ARGV[0].xml";
	}
}

#read in CatDV xml file from command line
$data = $xml->XMLin($xmltarget);

#our %metadata = ();

if($platform eq "Win32"){
	require '$directory\..\conf\metadata.conf';
	$platform = "win";	
} else {
	require "$directory/../conf/metadata.conf";		
	$platform = "mac";	
}


# echo output back to PresSTORE.  Simply add each of your key/value pairs to the next line.
# Don't forget to escape the curly braces for the values.
if($ARGV[2] eq 'dump'){
	print Dumper($data);
} elsif($ARGV[0] eq 'id'){
	$cdvid = $data->{CLIP}->{REMOTEID};
	$cdvid =~ s/\..*//;
	print $cdvid;
} else {
    while ( my ($key, $value) = each(%metadata) ) {
        print "$key \{$value\} ";
    }
    print "\n";
}
