#!/usr/bin/perl -I ./thirds -w
# author: lilong'en(lilongen@163.com)
# date:   05/25/2010
#

use strict;
use Data::Dumper;
use GraphDataer;
use Definition;
use CcvUtil;
use JSON;

sub main();
sub outDataAsJson($$);

sub main() {
	my $dataPath = $ARGV[0];
	my $DEF = new Definition();
	my $GraphDataFile = "$dataPath/$DEF->{MID_DATA_FILE_NAME}->{GRAPH_DATA}";
	my $ccvUtil = new CcvUtil();
	my $pms = $ccvUtil->loadFile("$dataPath/$DEF->{MID_DATA_FILE_NAME}->{LOG_PARSED_INFO}");
	
	
	my $gd = new GraphDataer($dataPath, $pms);
	$gd->constructGraphData();
	outDataAsJson($GraphDataFile, $gd->{GraphData});
}

sub outDataAsJson($$) {
	my $dataFile = shift;
	my $data = shift;
	my $hOut = undef;
	if (!open($hOut, '>', $dataFile)) {
		return;
	}
	
	my $json = new JSON;
	print $hOut $json->pretty->encode($data);
	close($hOut);
}

exit main();