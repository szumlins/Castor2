#!/usr/bin/perl

use File::Basename qw(dirname);
use File::Spec::Functions qw(rel2abs);

$path = rel2abs($0);
$directory = dirname($path);
$ENV{'install_dir'}=$directory;
$platform = $^O;

if($platform eq "darwin"){
	if ($platform eq "darwin"){
		$platform = "Mac OS X";		
	}
	print "Looks like we are on $platform.  Attempting to launch Mac installer script\n\n";	
	system("\"$directory/setup/configure_mac.pl\"");
} elsif ($platform eq "MSWin32"){
	$platform = "Windows";
	print "Looks like we are on $platform.  Attempting to launch Windows installer script\n";	
	system("perl \"$directory\\setup\\configure_win.pl\"");	
} elsif ($platform eq "linux") {
	print "Looks like we are on $platform.  Attempting to launch Linux installer script\n";	
	system("\"$directory/setup/configure_nix.pl\"");
} else {
	print "Can't determine platform.  Manual installation required\n";
}
print "Installer finished\n";	

