#!/usr/bin/perl

$root = $ENV{'install_dir'};
$cdbin = "$root/setup/CocoaDialog.app/Contents/MacOS/CocoaDialog";
$pbin = "$root/setup/Pashua.app/Contents/MacOS/Pashua";
$pconf = "$root/setup/cp.conf";

sub isint{
	my $val = shift;
	return ($val =~ m/^\d+$/);
}
sub check_restore {
	$restorefrequency = `"$cdbin" standard-inputbox --text "10" --informative-text "Enter (in minutes) how often you want to run restore batches" --no-cancel --float`; 	
	@restorefreq = split("\n",$restorefrequency);
	$restorefrequency = @restorefreq[1];	
    if (isint($restorefrequency)) {
        return $restorefrequency;
    } else {
        return check_restore();
    }
}
sub check_environment{
	unless(-e "/usr/local/aw/bin/nsdchat"){
		print "It appears that you don't have PresSTORE installed on this system.  Cannot continue";
		exit;
	}
	
	$plans = `/usr/local/aw/bin/nsdchat -c ArchivePlan names`;
	$indexes = `/usr/local/aw/bin/nsdchat -c ArchiveIndex names`;
	@available_plans = split(" ",$plans);
	@available_indexes = split(" ",$indexes);
	$gui_plans = shift;
	$gui_indexes = shift;
	
	foreach(@available_plans){
			$gui_plans = $gui_plans." \"$_\"";
	}
	
	foreach(@available_indexes){
			$gui_indexes = $gui_indexes." \"$_\"";
	}
}
sub summary{
	$summ = shift;
	$summ = "Config Summary\n".
		    "----------------------------------\n".
			"Hostname: $result{'hostname'}\n".
			"Username: $result{'username'}\n".
			"Password: $result{'password'}\n".
			"PresSTORE Socket Port: $result{'port'}\n".
			"XML location: $result{'xmldir'}\n".
			"CatDV Preview Root: $result{'proxypath'}\n".
			"Preview Type: $result{'previewextension'}\n".
			"Temp Proxy Storage Location: $result{'awproxypath'}\n".
			"Archive Plan: $result{'archiveplan'}\n".
			"Archive Index: $result{'archiveindex'}\n".
			"Archive Schedule: $result{'archivetime'}:00\n".
			"Restore Frequency: ".($result{'restorefrequency'}/60)." minutes\n\n";


	$go = `"$cdbin" textbox --informative-text "Warning: Selecting (Write Config) will overwrite your existing configuration!" --title "Configuration Summary" --text "$summ" --button1 "Write Config" --button2 "Cancel"`;
}
sub generate_conf{
	open(PCONF,">","$root/setup/cp.conf") or die localtime(time)." -- $!";
	print PCONF "# Set transparency: 0 is transparent, 1 is opaque\n";
	print PCONF "*.transparency=0.95\n";
	print PCONF "\n";
	print PCONF "# Set window title\n";
	print PCONF "*.title = Castor Configuration for Mac\n";
	print PCONF "\n";
	print PCONF "# Introductory text\n";
	print PCONF "txt.type = text\n";
	print PCONF "txt.default = Welcome to the Castor Configuration tool\n";
	print PCONF "txt.x = 18\n";
	print PCONF "txt.y = 529\n";
	print PCONF "\n";
	
	print PCONF "# Hostname\n";
	print PCONF "hostname.type = textfield\n";
	print PCONF "hostname.label = PresSTORE Server Hostname\n";
	$hn = `hostname`;
	$hn =~ s/\n//;
	print PCONF "hostname.default = $hn\n";
	print PCONF "hostname.width = 310\n";
	print PCONF "hostname.x = 18\n";
	print PCONF "hostname.y = 468\n";	
	print PCONF "\n";

	print PCONF "# Username\n";
	print PCONF "username.type = textfield\n";
	print PCONF "username.label = PresSTORE Username\n";
	$uname = `whoami`;
	$uname =~ s/\n//;
	print PCONF "username.default = $uname\n";
	print PCONF "username.width = 310\n";
	print PCONF "username.x = 18\n";
	print PCONF "username.y = 413\n";	
	print PCONF "\n";
	print PCONF "password.type = password\n";
	print PCONF "password.label = PresSTORE Password\n";
	print PCONF "password.default = password\n";
	print PCONF "password.width = 310\n";
	print PCONF "password.x = 18\n";
	print PCONF "password.y = 358\n";	
	print PCONF "\n";
	print PCONF "port.type = textfield\n";
	print PCONF "port.label = PresSTORE Socket Port\n";
	print PCONF "port.default = 9001\n";
	print PCONF "port.width = 310\n";
	print PCONF "port.x = 18\n";
	print PCONF "port.y = 303\n";	
	print PCONF "\n";		
	print PCONF "# Proxies\n";
	print PCONF "proxypath.type = openbrowser\n";
	print PCONF "proxypath.label = CatDV Proxy Root\n";
	print PCONF "proxypath.width = 400\n";
	print PCONF "proxypath.x = 365\n";	
	print PCONF "proxypath.y = 468\n";		
	print PCONF "proxypath.default = /Users/Shared/CatDV/Proxies\n";
	print PCONF "proxypath.filetype = directory\n";			
	print PCONF "proxypath.tooltip = Browse to the location of your CatDV Path Based Proxy root directory\n";
	print PCONF "\n";
	print PCONF "# Temp Files\n";
	print PCONF "xmldir.type = openbrowser\n";
	print PCONF "xmldir.label = CatDV Temp File Root\n";
	print PCONF "xmldir.width = 400\n";
	print PCONF "xmldir.x = 365\n";
	print PCONF "xmldir.y = 413\n";	
	print PCONF "xmldir.default = $root/tmp\n";	
	print PCONF "xmldir.filetype = directory\n";		
	print PCONF "xmldir.tooltip = Browse to the location of your CatDV Temp root (we recommend keeping it in Castor/tmp)\n";
	print PCONF "\n";
	print PCONF "\n";
	print PCONF "# Temp Proxy copy\n";
	print PCONF "awproxypath.type = openbrowser\n";
	print PCONF "awproxypath.label = Archiware Proxy Cache Directory\n";
	print PCONF "awproxypath.width = 400\n";
	print PCONF "awproxypath.x = 365\n";
	print PCONF "awproxypath.y = 303\n";		
	print PCONF "awproxypath.default = /tmp\n";	
	print PCONF "awproxypath.filetype = directory\n";		
	print PCONF "awproxypath.tooltip = PresSTORE will make a copy of any proxy file being moved into its index here.  We recommend you put this on the same filesystem as your Archiware proxy directory\n";
	print PCONF "\n";	
	$worker_dir = `ls /Applications | grep "CatDV Worker"`;
	$worker_dir =~ s/\n//;
	if(-e "/Applications/$worker_dir/catdv"){
		$cdvbin = "/Applications/$worker_dir/catdv"
	} else {
		$cdvbin = "/Applications/";
	}	
	print PCONF "# CatDV Worker Binary\n";
	print PCONF "catdvbin.type = openbrowser\n";
	print PCONF "catdvbin.label = CatDV Worker CLI Binary\n";
	print PCONF "catdvbin.width=400\n";
	print PCONF "catdvbin.x=365\n";
	print PCONF "catdvbin.y=358\n";
	print PCONF "catdvbin.default = $cdvbin\n";	
	print PCONF "catdvbin.tooltip = Locate the Worker Node CLI Binary (normally called catdv in the Worker Node folder)\n";
	print PCONF "\n";	
	print PCONF "\n";
	print PCONF "# Archive Plans\n";
	print PCONF "archiveplan.type = popup\n";
	print PCONF "archiveplan.label = Archive Plan\n";
	print PCONF "archiveplan.width = 310\n";
	print PCONF "archiveplan.x = 18\n";
	print PCONF "archiveplan.y = 248\n";	
	foreach(@available_plans){
		print PCONF "archiveplan.option = $_\n";
	}
	print PCONF "\n";
	print PCONF "\n";
	print PCONF "# Archive indexes\n";
	print PCONF "archiveindex.type = popup\n";
	print PCONF "archiveindex.label = Archive Index\n";
	print PCONF "archiveindex.width = 310\n";
	print PCONF "archiveindex.x = 18\n";
	print PCONF "archiveindex.y = 182\n";	
	foreach(@available_indexes){
		print PCONF "archiveindex.option = $_\n";
	}
	print PCONF "\n";
	print PCONF "\n";
	print PCONF "# Archive time\n";
	print PCONF "archivetime.type = popup\n";
	print PCONF "archivetime.label = Time of day to run batch archive (once per day)\n";
	print PCONF "archivetime.width = 310\n";
	print PCONF "archivetime.x = 18\n";
	print PCONF "archivetime.y = 116\n";	
	print PCONF "archivetime.option = 12:00am\n";
	for($i=1;$i<12;$i++){
		print PCONF "archivetime.option = $i:00am\n";
	}
	print PCONF "archivetime.option = 12:00pm\n";
	for($i=1;$i<12;$i++){
		print PCONF "archivetime.option = $i:00pm\n";
	}	
	foreach(@available_indexes){
		print PCONF "archiveindex.option = $_\n";
	}
	print PCONF "\n";
	print PCONF "\n";	
	print PCONF "\n";
	print PCONF "\n";
	print PCONF "# Restore Interval\n";
	print PCONF "restorefrequency.type = popup\n";
	print PCONF "restorefrequency.label = How frequently do you want to run restore batches?\n";
	print PCONF "restorefrequency.width = 310\n";
	print PCONF "restorefrequency.x = 18\n";
	print PCONF "restorefrequency.y = 50\n";	
	for($i=15;$i<=90;$i+=15){
		print PCONF "restorefrequency.option = $i minutes\n";
	}

	print PCONF "\n";
	print PCONF "\n";	

	print PCONF "# Archive Status Field\n";
	print PCONF "cdv_arch_sts.type = textfield\n";
	print PCONF "cdv_arch_sts.default = STS\n";
	print PCONF "cdv_arch_sts.width = 30\n";
	print PCONF "cdv_arch_sts.x = 367\n";
	print PCONF "cdv_arch_sts.y = 251\n";	
	print PCONF "\n";
	print PCONF "# Barcode Field\n";
	print PCONF "cdv_barcode.type = textfield\n";
	print PCONF "cdv_barcode.width = 30\n";
	print PCONF "cdv_barcode.x = 367\n";
	print PCONF "cdv_barcode.y = 224\n";	
	print PCONF "\n";
	print PCONF "# Label Field\n";
	print PCONF "cdv_label.type = textfield\n";
	print PCONF "cdv_label.width = 30\n";
	print PCONF "cdv_label.x = 367\n";
	print PCONF "cdv_label.y = 197\n";	
	print PCONF "\n";
	print PCONF "# Volume Field\n";
	print PCONF "cdv_volume.type = textfield\n";
	print PCONF "cdv_volume.width = 30\n";
	print PCONF "cdv_volume.x = 367\n";
	print PCONF "cdv_volume.y = 170\n";	
	print PCONF "\n";	
	print PCONF "# Handle Field\n";
	print PCONF "cdv_handle.type = textfield\n";
	print PCONF "cdv_handle.width = 30\n";
	print PCONF "cdv_handle.x = 367\n";	
	print PCONF "cdv_handle.y = 143\n";		
	print PCONF "\n";		

	print PCONF "# Archive Status Field_label\n";
	print PCONF "cdv_arch_sts_label.type = text\n";
	print PCONF "cdv_arch_sts_label.default = CatDV Archive Status Field\n";			
	print PCONF "cdv_arch_sts_label.x = 400\n";
	print PCONF "cdv_arch_sts_label.y = 254\n";	
	print PCONF "\n";
	print PCONF "# Barcode Field_label\n";
	print PCONF "cdv_barcode_label.type = text\n";
	print PCONF "cdv_barcode_label.default = Archiware Barcode Field\n";	
	print PCONF "cdv_barcode_label.x = 400\n";
	print PCONF "cdv_barcode_label.y = 227\n";	
	print PCONF "\n";
	print PCONF "# Label Field_label\n";
	print PCONF "cdv_label_label.type = text\n";
	print PCONF "cdv_label_label.default = Archiware Label Field\n";	
	print PCONF "cdv_label_label.x = 400\n";
	print PCONF "cdv_label_label.y = 200\n";	
	print PCONF "\n";
	print PCONF "# Volume Field_label\n";
	print PCONF "cdv_volume_label.type = text\n";
	print PCONF "cdv_volume_label.default = Archiware Volume Field\n";	
	print PCONF "cdv_volume_label.x = 400\n";
	print PCONF "cdv_volume_label.y = 173\n";	
	print PCONF "\n";	
	print PCONF "# Handle Field_label\n";
	print PCONF "cdv_handle_label.type = text\n";
	print PCONF "cdv_handle_label.default = Archiware Handle Field\n";	
	print PCONF "cdv_handle_label.x = 400\n";	
	print PCONF "cdv_handle_label.y = 146\n";		
	print PCONF "\n";		


	print PCONF "logo.type = image\n";
	print PCONF "logo.path = $root/setup/castor-icon.png\n";
	print PCONF "logo.x = 550\n";	
	print PCONF "logo.y = 60\n";	
			
	print PCONF "# Add a cancel button with default label\n";
	print PCONF "cb.type=cancelbutton\n";
	close PCONF;
}
sub get_config{
	#make the pashua config file
	generate_conf();	
	
	#run pashua and get user input
	$result = `"$pbin" "$pconf"`;

	#parse returned input
	%result = ();
	foreach (split/\n/, $result) {
		/^(\w+)=(.*)$/;
		next unless defined $1;
		$result{$1} = $2;
	}
	
	#format time for use
	@hours = split(":",$result{'archivetime'});
	$ampm = substr(@hours[1],2);
	if(@hours[0] != 12 && $ampm eq "am"){
		$result{'archivetime'} = @hours[0];
	} elsif (@hours[0] != 12 && $ampm eq "pm"){
		$result{'archivetime'} = @hours[0] + 12;
	} else {
		$result{'archivetime'} = 0;
	}
	
	#get restore Interval
	if($result{'restorefrequency'} eq "Other"){
		$restorefrequency = check_restore();
	} else {
		$rf = substr($result{'restorefrequency'},0,2);		
	}

	$result{'restorefrequency'} = $rf * 60;
	
	
	#get all proxy extensions
	$previewextension = `find "$result{'proxypath'}" -type f | perl -ne 'print \$1 if m/\\.([^.\\/]+)\$/' | sort -u`;
	@exts = split("\n",$previewextension);
	foreach(@exts){
		if(length($_)<=4){
			push(@exts_clean,$_);
		}
	}
	$previewextension = join(",",@exts_clean);	

	$result{'previewextension'}=$previewextension;
	$result{'tmpdir'}="/tmp";

	#print "  Pashua returned the following hash keys and values:\n";
	#while (my($k, $v) = each(%result)) {
	#	print "    $k = $v\n";
	#}
}
sub write_awconf{
	open AWCONF, ">", "$root/conf/aw-queue.conf" or die $!;

	print AWCONF "##################\n";
	print AWCONF "# User variables #\n";
	print AWCONF "##################\n";
	print AWCONF "\n";
	print AWCONF "# Hostname of the PresSTORE server.  Find out by running \"/usr/local/aw/bin/nsdchat -c srvinfo hostname\" on the server\n";
	print AWCONF "\n";
	print AWCONF "\$hostname = \"$result{'hostname'}\"\;\n";	
	print AWCONF "\n";
	print AWCONF "# Username of a user on the PresSTORE server with permissions to archive and restore.\n";
	print AWCONF "\n";
	print AWCONF "\$username = \"$result{'username'}\"\;\n";
	print AWCONF "\n";
	print AWCONF "# Password of a user on the PresSTORE server with permissions to archive and restore.\n";
	print AWCONF "\n";	
	print AWCONF "\$password = \"$result{'password'}\"\;\n";
	print AWCONF "\n";	
	print AWCONF "# Default nsdchat port is 9001.  Do not change unless you specifically changed this in your PresSTORE server config\n";
	print AWCONF "\n";
	print AWCONF "\$port = \"$result{'port'}\"\;\n";
	print AWCONF "\n";	
	print AWCONF "# Are we using aw-queue for CatDV or in standalone mode? \"yes\" for CatDV, \"no\" for standalone\n";
	print AWCONF "\n";
	print AWCONF "\$usecatdv = \"yes\"\;\n";
	print AWCONF "\n";		
	print AWCONF "# Where is the catdv CLI application (can be left blank if $usecatdv is set to \"no\")\n";
	print AWCONF "\n";
	print AWCONF "\$catdv = \"$result{'catdvbin'}\"\;\n";	
	print AWCONF "\n";
	print AWCONF "# Maps to user fields in CatDV.  Should be standard CatDV field names or \"Ux\"\n";
	print AWCONF "\n";	
	print AWCONF "\$cdv_handle_map = \"$result{'cdv_handle'}\"\;\n";		
	print AWCONF "\$cdv_label_map = \"$result{'cdv_label'}\"\;\n";	
	print AWCONF "\$cdv_volume_map = \"$result{'cdv_volume'}\"\;\n";
	print AWCONF "\$cdv_barcode_map = \"$result{'cdv_barcode'}\"\;\n";						
	print AWCONF "\$cdv_arch_status_map = \"$result{'cdv_arch_sts'}\"\;\n";							


	close AWCONF;
}
sub write_catdvconf{
	open CDVCONF, ">", "$root/conf/catdv.conf" or die $!;

	print CDVCONF "###################\n";
	print CDVCONF "# User Variables  #\n";
	print CDVCONF "###################\n";
	print CDVCONF "\n";
	print CDVCONF "# Location of xml files being written by worker node.  Default is /usr/local/Castor/tmp\n";
	print CDVCONF "\n";
	print CDVCONF "\$xmldir = \"$result{'xmldir'}\"\;\n";
	print CDVCONF "\n";
	print CDVCONF "# Location of CatDV Preview Files root\n";
	print CDVCONF "\n";
	print CDVCONF "\$previewdir = \"$result{'proxypath'}\"\;\n";
	print CDVCONF "\n";
	print CDVCONF "# Type of previews being generated in CatDV (mov, mp4, m4v, mpg, etc)\n";
	print CDVCONF "\n";
	print CDVCONF "\$previewextension = \"$result{'previewextension'}\"\;\n";
	print CDVCONF "\n";
	print CDVCONF "# Temporary preview location\n";		
	print CDVCONF "\n";
	print CDVCONF "\$awproxypath = \"$result{'awproxypath'}\"\;\n";	

	close CDVCONF;
}
sub write_launchd{
	#make sure they aren't running already
	unless(-e "$ENV{'HOME'}/Library/LaunchDaemons"){
		`"$cdbin" bubble --timeout 1 --title "Castor Info" --x-placement center --y-placement center --text "$ENV{'HOME'}/Library/LauncDaemons doesn't exist yet, creating"`;			
		`mkdir -p $ENV{'HOME'}/Library/LaunchDaemons`;
	}	
	
	if(-e "/Library/LaunchDaemons/org.provideotech.aw-queue-archive.plist" && -e "/Library/LaunchDaemons/org.provideotech.aw-queue-archive.plist"){
		`"$cdbin" bubble --timeout 1 --title "Castor Info" --x-placement center --y-placement center --text "Trying to stop LaunchDaemons"`;			
		`/bin/launchctl unload -w /Library/LaunchDaemons/org.provideotech.aw-queue-archive.plist`;
		`/bin/launchctl unload -w /Library/LaunchDaemons/org.provideotech.aw-queue-restore.plist`;	
	} elsif (-e "$ENV{'HOME'}/Library/LaunchDaemons/org.provideotech.aw-queue-archive.plist" && -e "$ENV{'HOME'}/Library/LaunchDaemons/org.provideotech.aw-queue-restore.plist"){
		`"$cdbin" bubble --timeout 1 --title "Castor Info" --x-placement center --y-placement center --text "Trying to stop LaunchDaemons"`;				
		`/bin/launchctl unload -w $ENV{'HOME'}/Library/LaunchDaemons/org.provideotech.aw-queue-archive.plist`;
		`/bin/launchctl unload -w $ENV{'HOME'}/Library/LaunchDaemons/org.provideotech.aw-queue-restore.plist`;		
	} else {
		`"$cdbin" bubble --timeout 1 --title "Castor Info" --x-placement center --y-placement center --text "Launchd plist files don't exist yet, no need to stop"`;				
	}

	#open the files for writing
	`"$cdbin" bubble --timeout 1 --title "Castor Info" --x-placement center --y-placement center --text "Trying to open plist files"`;				
	

	open ALD, ">", "$ENV{'HOME'}/Library/LaunchDaemons/org.provideotech.aw-queue-archive.plist" or die $!;
	open RLD, ">", "$ENV{'HOME'}/Library/LaunchDaemons/org.provideotech.aw-queue-restore.plist" or die $!;

	#first do the archive plist

	print "Writing Archive plist\n";

	print ALD "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
	print ALD "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n";
	print ALD "<plist version=\"1.0\">\n";
	print ALD "<dict>\n";
	print ALD "	<key>Disabled</key>\n";
	print ALD "	<false/>\n";
	print ALD "	<key>Label</key>\n";
	print ALD "	<string>org.provideotech.aw-queue-archive</string>\n";
	print ALD "	<key>ProgramArguments</key>\n";
	print ALD "	<array>\n";
	print ALD "		<string>$root/bin/aw-queue.pl</string>\n";
	print ALD "		<string>$root/queues/archive-queue.txt</string>\n";
	print ALD "		<string>archive</string>\n";
	print ALD "		<string>$result{'archiveplan'}</string>\n";
	print ALD "	</array>\n";
	print ALD "	<key>StartCalendarInterval</key>\n";
	print ALD "	<dict>\n";
	print ALD "		<key>Hour</key>\n";
	print ALD "		<integer>$result{'archivetime'}</integer>\n";
	print ALD "		<key>Minute</key>\n";
	print ALD "		<integer>0</integer>\n";	
	print ALD "	</dict>\n";
	print ALD "</dict>\n";
	print ALD "</plist>\n";

	#next do the restore plist

	print "Writing Restore plist\n";	

	print RLD "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
	print RLD "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n";
	print RLD "<plist version=\"1.0\">\n";
	print RLD "<dict>\n";
	print RLD "	<key>Disabled</key>\n";
	print RLD "	<false/>\n";
	print RLD "	<key>Label</key>\n";
	print RLD "	<string>org.provideotech.aw-queue-restore</string>\n";
	print RLD "	<key>ProgramArguments</key>\n";
	print RLD "	<array>\n";
	print RLD "		<string>$root/bin/aw-queue.pl</string>\n";
	print RLD "		<string>$root/queues/restore-queue.txt</string>\n";
	print RLD "		<string>restore</string>\n";
	print RLD "		<string>$result{'archiveplan'}</string>\n";
	print RLD "		<string>$result{'archiveindex'}</string>\n";	
	print RLD "	</array>\n";
	print RLD "	<key>StartInterval</key>\n";
	print RLD "	<integer>$result{'restorefrequency'}</integer>\n";
	print RLD "</dict>\n";
	print RLD "</plist>\n";

	#close the files

	close ALD;
	close RLD;

	#set up proper permissions

	`"$cdbin" bubble --timeout 1 --title "Castor Info" --x-placement center --y-placement center --text "Setting proper launchd permissions"`;				

	if(-e "$ENV{'HOME'}/Library/LaunchDaemons/org.provideotech.aw-queue-archive.plist" && -e "$ENV{'HOME'}/Library/LaunchDaemons/org.provideotech.aw-queue-archive.plist"){
		$u = `whoami`;
		$u =~ s/\n//;
		$g = `groups $user | awk {\'print \$1\'}`;
		$g =~ s/\n//;
		`/usr/sbin/chown $u:$g $ENV{'HOME'}/Library/LaunchDaemons/org.provideotech.aw-queue*`;
		`/bin/chmod 644 $ENV{'HOME'}/Library/LaunchDaemons/org.provideotech.aw-queue*`;
	} else {
		`"$cdbin" bubble --timeout 1 --title "Castor Info" --x-placement center --y-placement center --text "Error- Could not locate launchd plists.  Please verify by hand"`;					
	}

	#start up
	`"$cdbin" bubble --timeout 1 --title "Castor Info" --x-placement center --y-placement center --text "Trying to start newly created LaunchDaemons"`;				

	`/bin/launchctl load -wF ~/Library/LaunchDaemons/org.provideotech.aw-queue-archive.plist`;
	`/bin/launchctl load -wF ~/Library/LaunchDaemons/org.provideotech.aw-queue-restore.plist`;	
	$started = `/bin/launchctl list | grep org.provideotech | wc -l`;
	if($started == 2){
		`"$cdbin" bubble --timeout 1 --title "Castor Info" --x-placement center --y-placement center --text "LaunchDaemons Started"`;				
	} else {
		`"$cdbin" bubble --timeout 1 --title "Castor Info" --x-placement center --y-placement center --text "Error- Check that LaunchDaemons are running"`;				
	}	
}
sub validate{

	if($_[0] eq "y"){
		`"$cdbin" bubble --timeout 1 --title "Castor Info" --x-placement center --y-placement center --text "Writing aw-queue.conf file"`;
		write_awconf();
		`"$cdbin" bubble --timeout 1 --title "Castor Info" --x-placement center --y-placement center --text "Writing catdv.conf file"`;		
		write_catdvconf();
		`"$cdbin" bubble --timeout 1 --title "Castor Info" --x-placement center --y-placement center --text "Creating LaunchDaemon plists"`;		
		write_launchd();
		`"$cdbin" bubble --timeout 1 --title "Castor Info" --x-placement center --y-placement center --text "Setting up queue files and permissions"`;		
		`/bin/mkdir -p "$root/queues"`;
		`/bin/mkdir -p "$root/conf"`;		
		`/bin/mkdir -p "$root/tmp"`;
		`/bin/mkdir -p "$root/logs/job_logs"`;		
		`/bin/mkdir -p "$root/logs/update_logs"`;				
		`/usr/bin/touch "$root/queues/archive-queue.txt"`;
		`/usr/bin/touch "$root/queues/restore-queue.txt"`;
		`/usr/bin/touch "$root/logs/aw-queue.log"`;
		`/usr/bin/touch "$root/logs/aw-queue-err.log"`;
		`/bin/chmod 777 "$root/queues/archive-queue.txt"`;
		`/bin/chmod 777 "$root/queues/restore-queue.txt"`;
		`/bin/chmod 775 "$root/logs/aw-queue.log"`;
		`/bin/chmod 775 "$root/logs/aw-queue-err.log"`;		
		if(-ne "$root/lib"){
			`/usr/bin/unzip/ "$root/lib.zip"`;
		}
		$finish = "You will now need to edit $root/conf/metadata.conf by hand to complete the install\n\n";
		$finish .= "Copy and paste the following command to edit\n\n";
		$finish .= "open -a TextEdit $root/conf/metadata.conf\n\n";
		$finish .= "Configuration Script Complete!\n";
		#print $finish;
		
		$editmd=`"$cdbin" textbox --title "Core Configuration Complete!" --text "$finish" --informative‑text "Edit the metadata.conf file" --button1 "Edit metadata.conf" --button2 "I'll do it later"`;		
		if($editmd==1){
			`open -a TextEdit "$root/conf/metadata.conf"`;
		}
	} elsif($_[0] eq "n"){
		print "Aborting config. Nothing has been written to disk.\n";
	} else {
		print "\nI don't understand $submit";
		undef($_[0]);
		summary();
	}	

}

check_environment();
get_config();
if($result{'cb'}==0){
	summary();
	if($go==1){
		validate("y");
		
	}
} else {
	exit;
}