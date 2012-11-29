#!/usr/bin/perl -I ./thirds -w
# author: lilong'en(lilongen@163.com)
# date:   04/05/2010
#

use strict;
use English;
use Data::Dumper;
use ccvGraph;
use CGI;
use Assistor;
use Cwd;
use JSON;

sub main();
sub parseParams();

my $pms = {};
parseParams();

exit main();

sub main() {
	my $ccvGraph = new ccvGraph($pms->{G_PATH});
	if (!$pms->{fromCgi}) {
		$ccvGraph->drawUserLOC();
		$ccvGraph->drawUserAverLOC();
		$ccvGraph->drawUserDateLOC();
		$ccvGraph->drawUserDateAccuLOC();
		$ccvGraph->drawModuleDateLOC();
		$ccvGraph->drawModuleDateAccuLOC();		
	} else {
	    my $ret = {};
	    $ccvGraph->constructUserDateLOCs4Graph($pms->{users});
     	$ret->{userDateLOCImage} = $ccvGraph->drawUserDateLOC();
    	$ret->{userDateAccuLOCImage} = $ccvGraph->drawUserDateAccuLOC();		    
		
		my $json = new JSON;
		print $json->pretty->encode($ret);		
	}
	
	return 0;
}

sub parseParams() {
	if (defined($ARGV[0])) {
		$pms->{fromCgi} = 0;
		$pms->{G_PATH} = $ARGV[0];
	} else {
		$pms->{fromCgi} = 1;
		my $q = new CGI;
		print "Content-type: application/json\n\n";
		
		$pms->{G_PATH} = $q->param("G_PATH");
		$pms->{users} = $q->param("users");
	}
}
