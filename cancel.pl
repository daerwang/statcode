#!/usr/bin/perl -I ./thirds -w
# author: lilong'en(lilongen@163.com)
# date:   03/21/2010
#

use strict;
use English;
use Data::Dumper;
use CGI;

sub main();

my $q = new CGI;	
my $T_SNAP = $q->param("T_SNAP");
$T_SNAP =~ s|\+|\\+|;

print "Content-type: text/html\n\n";

exit main();

sub main() {
	my $cmdGetMasterPid = "ps -eo '%p %P %a' | grep -P 'perl -w task\\.manager\\.pl \\d $T_SNAP' | awk '{print \$1}'";
	print "cmdGetMasterPid: $cmdGetMasterPid<br/>";
	my $ccvMasterPid = `$cmdGetMasterPid`;
	
	$ccvMasterPid =~ s|[\n\s]||;
	if (!$ccvMasterPid) {
		return 1;
	}
	print " ccvMasterPid: $ccvMasterPid<br/>";
	
	my $cmdGetSHCvsProcessPid = "ps -eo '%p %P %a' | grep -P '\\d+\\s+$ccvMasterPid \.*cvs' | awk '{print \$1}'";
	print "cmdGetSHCvsProcessPid: $cmdGetSHCvsProcessPid<br/>";
	my $shCvsProcessPid = `$cmdGetSHCvsProcessPid`;
	$shCvsProcessPid =~ s|[\n\s]||;
	if (!$shCvsProcessPid) {
		return 2;
	}
	print " shCvsProcessPid: $shCvsProcessPid<br/>";
	
	my $cmdGetCvsProcessPid = "ps -eo '%p %P %a' | grep -P '\\d+\\s+$shCvsProcessPid \.*cvs' | awk '{print \$1}'";
	print "cmdGetCvsProcessPid: $cmdGetCvsProcessPid<br/>";
	my $cvsProcessPid = `$cmdGetCvsProcessPid`;
	$cvsProcessPid =~ s|[\n\s]||;
	if (!$cvsProcessPid) {
		return 3;
	}
	print " cvsProcessPid: $cvsProcessPid<br/>";
	
	my $cmdKill = "kill -9 $ccvMasterPid $shCvsProcessPid $cvsProcessPid";
	print "cmdKill: $cmdKill<br/>";
	
	`$cmdKill`;
	
	return 0;
}
