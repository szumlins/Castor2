#!/usr/bin/perl

$root = $ENV{'install_dir'};

$cdbin = "$root/setup/CocoaDialog.app/Contents/MacOS/CocoaDialog";

$mydir = `"$cdbin" fileselect --text "Choose the source file for the main controller" --select-only-directories`;


#setup conf files
#