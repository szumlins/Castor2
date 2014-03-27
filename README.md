Release notes

2/14/2014
---------
-Fixed bug in record-update method where lookups failed when multiple files with same naming
 convention are archived in the same batch
 
-Moved field mapping for barcode/label/volume/handle into the catdv.conf file, editing of 
 record-update.pl no longer needed
 
-Changed the way archive queues work when using CatDV.  Unique CatDV ID is now added to archive
 queue by using <<CDVID>> separator in Worker Node
 
-Created rich logs for record updates in addition to jobs to track metadata sendback independent 
 of actual archive task


3/23/2012
---------
-Added release notes to package
-Updated catdv-xml.pl to support Windows paths stored on server in Mac worker node environment.