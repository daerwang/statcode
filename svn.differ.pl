#!/usr/bin/perl -I ./thirds -w
# author: lilong'en(lilongen@163.com)
# date:   12/25/2009
#
use strict;
use English;
use Data::Dumper;
use CGI;
use Assistor;
use CcvUtil;
use UDiffer;

my $RUN_MODE = 1;

my $q;
my $actionType;
if ($RUN_MODE) {
	$q = new CGI;
	$actionType 	= $q->param("AT");	
} else {
	$q = {};
	$actionType 	= 'COVIEW';
}

my $ccvUtil = new CcvUtil();

if ($actionType eq 'DF') {
	my $DfFile 		= '';
	my $OffsetB 	= '';
	my $OffsetE 	= '';
	if ($RUN_MODE) {
		$DfFile 	= $q->param("DF");
		$OffsetB 	= $q->param("OB");
		$OffsetE 	= $q->param("OE");	
	} else {
		$DfFile 	= $q->param("DF");
		$OffsetB 	= $q->param("OB");
		$OffsetE 	= $q->param("OE");
	}	

	
	my $df = $ccvUtil->readFileContent($DfFile, $OffsetB, $OffsetE);
	my $uDiffer = new UDiffer();
	$uDiffer->genDiffHtml(\$df);
	
	print "Content-type: text/html\n\n";
	print $uDiffer->{outHtml};
} else {
	my $T_SNAP = '';
	my $MID = '';
	my $file = '';
	my $rev = '';
	if ($RUN_MODE) {
		$T_SNAP = $q->param("T_SNAP");
		$MID = $q->param("MID");
		$file = $q->param("F");
		$rev = $q->param("R");
	} else {
		#http://10.224.118.245:88/ccv-cgi/svn.differ.pl?AT=CO+VIEW&T_SNAP=2010-11-04+070254&MID=svnXman&F=/svnXman/boxman/UIAssist.cpp&R=3
		$T_SNAP = "2010-11-04+070254";
		$MID = "svnXman";
		$file = "/svnXman/boxman/UIAssist.cpp";
		$rev = "3";
	}	

	my $assistor = new Assistor('', $T_SNAP);
	my $pms = $ccvUtil->loadFile($assistor->get_specified_operate_file("PMS"));
	$assistor->set_config_file($pms->{cfg});
	$assistor->getModules();
	my $mInfo = $assistor->get_module_info_by_module_id($MID);
	my $fileName = substr($file, rindex($file, '/') + 1);
	my $viewedFile = '';
	if ($actionType eq 'COVIEW') {
		my $coOutPath = $assistor->get_operate_revs_location($pms->{rev}) . $MID . "/rev_co";
		my $coOutFileFullPath = "$coOutPath/$rev-$fileName";
		if (!(-e "$coOutFileFullPath")) {
			my $coCmd = $assistor->get_co_svn_file_cmd($mInfo, $file, $rev);
			my $execCmd = "$coCmd > $coOutFileFullPath";
			system($execCmd);
		}
		$viewedFile = $coOutFileFullPath;
	}
	
	if ($actionType eq 'DFDF') {
		my $dfOutPath = $assistor->get_operate_revs_location($pms->{rev}) . $MID . "/rev_df";
		my $dfOutFileFullPath = "$dfOutPath/c$rev-$fileName";
		if (!(-e "$dfOutFileFullPath")) {
			my $dfCmd = $assistor->get_df_svn_file_cmd($mInfo, $file, $rev, $pms->{dfOpts}->{svn});		
			my $execCmd = "$dfCmd > $dfOutFileFullPath";
			system($execCmd);
		}
		$viewedFile = $dfOutFileFullPath;
	}
	
	my $uDiffer = new UDiffer();
	my $df = $ccvUtil->getFileAllContent($viewedFile);
	$actionType eq 'COVIEW' ? $uDiffer->genFileOutHtml(\$df, $file, $rev) : $uDiffer->genDiffHtml(\$df);
	
	print "Content-type: text/html\n\n";
	
	my $unitSize = 2000;
	my $outUnitCnt = length($uDiffer->{outHtml}) / $unitSize;
	
	for (my $i = 0; $i <= $outUnitCnt; $i++) {
		print substr($uDiffer->{outHtml}, $i * $unitSize, $unitSize);	
	}
}
