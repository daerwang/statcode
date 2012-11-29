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
my $wid = $q->param('q');
print "Content-type: text/html\n\n";

my $assistor    = new Assistor();
my $wids_file    = $assistor->get_wids_file();

my $bw = File::ReadBackwards->new($wids_file) 
                                or die "can't open $wids_file!" ;

my $wids = [];
while (defined(my $wid_line = $bw->readline())) {
    if ($wid_line =~ m/\w*$wid\w*/i) {
		push(@{$wids}, $wid_line); 
    }
}
$bw->close();

my $matchCnt = $#{$wids};
my $widsOut= "";
for (my $i = 0; $i <= $matchCnt; $i++) {
	$widsOut .= $wids->[$i] ."\n";
}

print $widsOut;

