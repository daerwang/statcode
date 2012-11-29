#!/usr/bin/perl -I ./thirds -w
# author: lilong'en(lilongen@163.com)
# date:   10/20/2007
#
use strict;
use English;
use IO::Seekable; 
use CGI;
use Assistor;
use File::ReadBackwards;
use Cwd;

my $q = new CGI;
print "Content-type: text/html\n\n";

my $assistor    = new Assistor();
my $log_file    = $assistor->get_history_reports_log_file();

my $bw = File::ReadBackwards->new($log_file);
if (!$bw) {
	print "No History Item!";
	exit 0;
}

my $history = "";
my $line_no = 1;
my $MAX_SHOWN_ENTRYS = 200;
#Log entry example
#0<|>ecc<|>N/A<|>N/A<|>2007-10-23 05:28:35<|>main<|>http://172.16.251.245:80/cvschangeviewer/reports/2007-10-23/052835/rpt.html
#1<|>ecc<|><|><|>2007-10-23 05:28:35<|>Rev1: rev1 Rev2: rev2<|>http://172.16.251.245:80/cvschangeviewer/reports/2007-10-23/052835/rpt.html

while (defined(my $log_line = $bw->readline()) && $line_no <= $MAX_SHOWN_ENTRYS) {
    my @items = split(/<\|>/, $log_line);
    
    #$items[4] =~ s/(\d{4})([\-\/\\])([^\s]+)/$3/;
    $items[4] =~ s/(\d{4})([\-\/\\])([^\s]+)/$3$2$1/;  #Keep year field
    $items[4] =~ s/ (\d\d:\d\d):\d\d/&nbsp;$1/;
    $items[4] =~ s/\-/\//g;
    $line_no ++;
    
    my $tips = ""; 
    my $shown_modules = $items[1];
    my $shown_revs_dates = $items[5];
    
    my $TRIP_LEN = 45;
    my $VALID_LEN = $TRIP_LEN - 3;
    if (length($shown_modules) > $TRIP_LEN) {
    	$shown_modules = substr($shown_modules, 0, $VALID_LEN) . "...";	
    }
    
    if (length($shown_revs_dates) > $TRIP_LEN) {
    	my $len = $VALID_LEN;
    	if (length($shown_modules) <= $TRIP_LEN) {
    		$len = $VALID_LEN + ($TRIP_LEN - length($shown_modules));
    	}
    	
		$shown_revs_dates = substr($shown_revs_dates, 0, $len) . "...";	
	} 
 
     
	if ($items[0] eq "0") {
		$tips = sprintf("Modules: %s  Branch/Revision(s): %s", 
		                    $items[1],
		                    $items[5]);
		                     			
	    $history .= sprintf("<div class='historyEntry ellipsis'><a href='%s' title='%s' target='_blank'>%s - <span class='entryVers'>%s</span></a><br/><span class='historyDate'>%s - Date scope: %s&nbsp;&nbsp;By: %s</span></div>\n",
	                    $items[6],
	                    $tips,
	                    $shown_modules,
	                    $shown_revs_dates,
	                    $items[4],
	                    $items[2],
	                    $items[3]);
	} else {
		$tips = sprintf("Modules: %s  %s", 
		                    $items[1],
		                    $items[5]); 
		                    		
	    $history .= sprintf("<div class='historyEntry ellipsis'><a href='%s' title='%s' target='_blank'>%s - <span class='entryVers'>%s</span></a><br/><span class='historyDate'>%s</span></div>\n",
	                    $items[6],
	                    $tips,
	                    $shown_modules,
	                    $shown_revs_dates,
	                    $items[4]);		
		
	}
}

if ($line_no > $MAX_SHOWN_ENTRYS) {
	$history .= "<tr><td class='historyEntry'>... ... ... </td></tr>";
}

$bw->close();

print <<HTML;
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
<title>CCV Query History</title>
<link rel="stylesheet" type="text/css" href="/ccv/css/ccv.css" />

</head>
<body class="ccvHistory">
<div class="list">
  $history 
</div>

</body>
</html>

HTML

exit 0;
