#!/usr/bin/perl -I ./thirds
# author: lilong'en(lilongen@163.com)
# date:   09/22/2012
#

use strict;
use English;
use Data::Dumper;
use Assistor;
use IO::Seekable; 
use File::ReadBackwards;
use CcvUtil;

sub main();
sub getCcvQueriedRevInfo();
sub getSortedRevs($);

my $OUT_LOG_REVS_INFO_JS_WEB_FILE = 'web/queried.revs.info.json';
my $ccvUtil = new CcvUtil();
my $assistor = new Assistor();

exit main();

sub main() {
	my $json = {};
    $json->{revsInfo} = getCcvQueriedRevInfo() || {};
    $json->{revs} = getSortedRevs($json->{revsInfo}) || [];
    $ccvUtil->writeJsonToFile($json, $OUT_LOG_REVS_INFO_JS_WEB_FILE);
    
    return 0;
}

sub getSortedRevs($) {
	my $revsInfo = shift;
	my $revs = [];
	foreach my $rev (sort {$revsInfo->{$b} <=> $revsInfo->{$a}}  keys %{$revsInfo}) {
		push(@{$revs}, $rev)	
	}
	
	return $revs;
}

sub getCcvQueriedRevInfo() {
	my $limitedLinesNum = shift || 9999999;
	my $log_file = $assistor->get_history_reports_log_file();
	my $bw = File::ReadBackwards->new($log_file) or return undef;
	
	my $line_no = 1;
	#Log entry example
	#ecc<|>N/A<|>N/A<|>2007-10-23 05:28:35<|>main<|>http://172.16.251.245:80/cvschangeviewer/reports/2007-10-23/052835/rpt.html
	my $revs = {};
	my $rev = "";
	my $time = "";
	while (defined(my $log_line = $bw->readline()) && $line_no < $limitedLinesNum) {
	    if ($log_line =~ m/<\|>([^ ]+? \d\d:\d\d:\d\d)<\|>([^ ]+)<\|>/) {
	        $time = $1;
	        $rev = $2;

	    	if (!defined($revs->{$rev})) {
	            $revs->{$rev} = 1;
	        } else {
	            $revs->{$rev} ++;
	        }
	    }
	}
	$bw->close();	
	
	return $revs;
}