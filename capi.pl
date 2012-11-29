#!/usr/bin/perl -I ./thirds -w
# author: lilong'en(lilongen@163.com)
# date:   02/17/2012
#

use strict;
use English;
use Data::Dumper;
use ApiInnerParamUtil;
use Assistor;

sub main();
sub help();

my $CmdLine = join (" ", @ARGV);

sub help() {
	print <<'CAPI_EXAMPLE';
CodeChangeViewer Command Line API examples:
	
1. Command Line API to Generate Report Base on cvs/svn Repository Module Log
perl capi.pl --mode="log" --cfg="config.xml" --mids="cvsModuleId1,svnModuleId1" --rev="B28"

API Command with more options
perl capi.pl \
	--T_SNAP="2011-01-01+123456 " \
	--mode="log" \
	--cfg="config.xml" \
	--mids="cvsModuleId1,svnModuleId1" \
	--rev="B28" \
	--date="1/1/2011<=12/31/2011" \
	--wids="user1,user2,user3" 

	
2. Command Line API to Generate Report Base on cvs/svn Repository Module Diff
cvs modules diff between two branches
perl capi.pl \
	--mode="diff" --cfg="config.xml" --mids="cvsModuleId1,cvsModuleId1" \
	--dfAgainst="revs" --r1="B27" --r2="B28"

cvs modules diff between two dates
perl capi.pl \
	--mode="diff" --cfg="config.xml" --mids="cvsModuleId1,cvsModuleId1" \
	--dfAgainst="dates" --d1="02/08/2011" --d2="08/18/2011"

svn modules diff between two branches
perl capi.pl \
	--mode="diff" --cfg="config.xml" --mids="cvsModuleId1,cvsModuleId1" \
	--dfAgainst="revs" --r1="B27" --r2="B28" --rd1b="branch" --rd2b="branch" --bb=""
	
perl capi.pl \
	--mode="diff" --cfg="config.xml" --mids="cvsModuleId1,cvsModuleId1" \
	--dfAgainst="revs" --r1="B27" --r2="" --rd1b="branch" --rd2b="trunk" --bb=""	
	
perl capi.pl \
	--mode="diff" --cfg="config.xml" --mids="cvsModuleId1,cvsModuleId1" \
	--dfAgainst="revs" --r1="" --r2="B28" --rd1b="trunk" --rd2b="branch" --bb=""	

svn modules diff between two dates
perl capi.pl \
	--mode="diff" --cfg="config.xml" --mids="cvsModuleId1,cvsModuleId1" \
	--dfAgainst="dates" --d1="02/08/2011" --d2="08/18/2011" --rd1b="OnBranch" --rd2b="OnBranch" --bb="B28"
	
perl capi.pl \
	--mode="diff" --cfg="config.xml" --mids="cvsModuleId1,cvsModuleId1" \
	--dfAgainst="dates" --d1="02/08/2011" --d2="08/18/2011" --rd1b="OnTrunk" --rd2b="OnTrunk" --bb=""

    
3. Command Line API to Generate Report Base on cvs/svn Repository Module Source Files
perl capi.pl --mode="file" --cfg="config.xml" --mids="cvsModuleId1,svnModuleId1" --rev="B28"

CAPI_EXAMPLE

}

sub main() {
	if ($CmdLine =~ m/^(\-\-help|\s*)$/) {
		help();
		return 1;
	}

	my $paramUtil = new ApiInnerParamUtil("capi", $CmdLine);
	my $cfg = $paramUtil->getParamOuterVal("cfg");
	my $T_SNAP = $paramUtil->getParamOuterVal("T_SNAP") || "";
	my $assistor = new Assistor($cfg, $T_SNAP);	
	$paramUtil->setParamInnerVal("T_SNAP", $T_SNAP);
	my $innerCmd = $paramUtil->convertApi2InnerCmd();
	
	print "\n$innerCmd\n\n";
	system($innerCmd);
	
	return 0;	
}

exit main();