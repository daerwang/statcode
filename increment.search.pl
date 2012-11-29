#!/usr/bin/perl -I ./thirds -w
# author: lilong'en(lilongen@163.com)
# date:   10/26/2007
#
use strict;
use English;
use IO::Seekable; 
use CGI;
use Assistor;
use File::ReadBackwards;
use Cwd;
use Data::Dumper;

my $q = new CGI;
my $bra = $q->param('q');
print "Content-type: text/html\n\n";

my $assistor    = new Assistor();
my $log_file    = $assistor->get_history_reports_log_file();
my $bw = File::ReadBackwards->new($log_file) 
                                or die "can't open $log_file!" ;

my $line_no = 1;

#Log entry example
#ecc<|>N/A<|>N/A<|>2007-10-23 05:28:35<|>main<|>http://172.16.251.245:80/cvschangeviewer/reports/2007-10-23/052835/rpt.html
my $branchs = {};
my $branch = "";
my $time = "";
while (defined(my $log_line = $bw->readline()) && $line_no <= 500) {
    if ($log_line =~ m/<\|>([^ ]+? \d\d:\d\d:\d\d)<\|>([^ ]+)<\|>/) {
        $time = $1;
        $branch = $2;
        if ($branch !~ m/$bra/i) {
            next;   
        } 
    	if (!defined($branchs->{$branch})) {
            $branchs->{$branch} = 1;
        } else {
            $branchs->{$branch} ++;
        }
    }
}

$bw->close();

my $branchItems = "";
my @keys = keys %{$branchs};

foreach $branch (sort {$branchs->{$b} <=> $branchs->{$a}}  keys %{$branchs}) {
    #$branchItems .= $branch . "|" .$branchs->{$branch} ."\n";       
    $branchItems .= $branch . "|" .$branchs->{$branch} . "|" . $bra ."\n";       
}

print $branchItems;
