#!/usr/bin/perl -I ./thirds -w
# author: lilong'en(lilongen@163.com)
# date:   01/06/2013
#

use strict;
use English;
use Data::Dumper;
use Assistor;
use CcvUtil;
use bytes;

sub setGV();
sub main();
sub parse_command_line();
sub setUserPathsChangeInfo($$);
sub statIt($);

my $T_SNAP		= "";
my $CFG			= "";
my $MID			= "";
parse_command_line();

my $assistor	= new Assistor($CFG, $T_SNAP); $assistor->getModules();
my $ccvUtil 	= new CcvUtil();
my $pms 		= $ccvUtil->loadFile($assistor->get_specified_operate_file("PMS"));

my $GV = {}; setGV();
exit main();

sub setGV() {
    $GV->{ModuleInfo}   = $assistor->get_module_info_by_module_id($MID);
    $GV->{LangInfo}     = $assistor->get_program_langs_ext();
    $GV->{AllExts} 	    = $GV->{LangInfo}->{ext};
    $GV->{AllExts} 		=~ s/(^|\s)/ \./g;
    $GV->{FileFilter}   = $GV->{ModuleInfo}->{file_filter};
    $GV->{ModuleName}   = $GV->{ModuleInfo}->{module};
    $GV->{LogFile}      = $assistor->get_repository_log_cmd_output_file($pms->{cmt}, $GV->{ModuleInfo}->{log});
	
    $GV->{OverallInfo}  = {
        'authorsCnt' => 0,
        'filesCnt' => 0,
        'cmtsCnt'  => 0   
    };
    $GV->{CmtsInfo}     = {}; 
    $GV->{AuthorsInfo}    = {};
    $GV->{FilesInfo}    = {};
    $GV->{Error}		= "";
}

sub main() {
	if (!open(LOG, $GV->{LogFile})) {
		output('Can not open $GV->{LogFile}!\n');
		
		return 1;
	}

	my $RE = {
		#It is followed by one or more extended header lines:
		
		#old mode <mode>
		#new mode <mode>
		#deleted file mode <mode>
		#new file mode <mode>
		#copy from <path>
		#copy to <path>
		#rename from <path>
		#rename to <path>
		#similarity index <number>
		#dissimilarity index <number>
		#index <hash>..<hash> <mode>	
		
		
		#commit 9a32f12bdfcc9b7d27cd5907d838c638e5c735f7
		#Author: Dave Methvin <dave.methvin@gmail.com>
		#Date:   2013-01-08 01:14:01 -0800
		#
		#    Remove oldIE styleFloat detect.
		#
		#1	1	src/css.js
		#0	4	src/support.js
		#
		#diff --git a/src/css.js b/src/css.js
		#index a29356e..6b800d6 100644
		#--- a/src/css.js
		#+++ b/src/css.js	
		commit => m/^commit ([\d\w]+)$/,
		author => m/^Author (.+) <(.*)>$/,
		date => m/^Date:\s+([\d\-]+) ([\d:]+) \-(\d+))$/,
		comment => m/^(\s){4}(.+)$/,
		fileLOC => m/^([\d\-]+) ([\d\-]+) (.+)$/,
		fileDiffHeader => m/^diff --git a\/(.+) b\/(.+)$/,
		changeMode => m/^(old mode|new mode|deleted file mode|new file mode|copy from|copy to|rename from|rename to) (.+)$/,
		similarity => m/^(similarity index) (.+)$/,
		dissimilarity => m/^(dissimilarity index) (.+)$/,
		changeIndexAndMode => m/^index (\w+)\.\.(\w+) (.+)$/,
		oldMode => m/^old mode(.+)$/,
		newMode => m/^new mode(.+)$/
	};

    my $lineCnter = 0;
	my $doCmtTest = 1;
	my $cmtCnter = 0;
    my $flags = {}; resetFlags($flags);
	
    my $cmtInfo;
	my $fileInfo;
	my $authorInfo;
	
    my $line;
    my $prevLine;
	my $diffingFile;
	while (1) {
		$line = <LOG>;
		if (!defined($line)) {
			if ($lineCnter == 1) {
				$GV->{Error} = $prevLine;
			}
			
			last;
		}
		
		$lineCnter++;
		$prevLine = $line;
		#print $line;
#git log -u --date=iso --numstat
#
#commit 9a32f12bdfcc9b7d27cd5907d838c638e5c735f7
#Author: Dave Methvin <dave.methvin@gmail.com>
#Date:   2013-01-08 01:14:01 -0800
#
#    Remove oldIE styleFloat detect.
#
#1	1	src/css.js
#0	4	src/support.js
#-	-	docs/ins.vsd
#
#diff --git a/src/css.js b/src/css.js
#index a29356e..6b800d6 100644
#--- a/src/css.js
#+++ b/src/css.js
#@@ -172,7 +172,7 @@ jQuery.extend({
# 	// setting or getting the value
# 	cssProps: {
# 		// normalize float css property
#-		"float": jQuery.support.cssFloat ? "cssFloat" : "styleFloat"
#+		"float": "cssFloat"
# 	},
# 
# 	// Get and set the style property on a DOM Node
#diff --git a/src/support.js b/src/support.js
#index 3c76309..25b2fd8 100644
#--- a/src/support.js
#+++ b/src/support.js
#@@ -21,10 +21,6 @@ jQuery.support = (function() {
# 
# 	a.style.cssText = "float:left;opacity:.5";
# 	support = {
#-		// Verify style float existence
#-		// (IE uses styleFloat instead of cssFloat)
#-		cssFloat: !!a.style.cssFloat,
#-
# 		// Check the default checkbox/radio value ("" on WebKit; "on" elsewhere)
# 		checkOn: !!input.value,
#diff --git a/docs/ins.vsd b/docs/ins.vsd
#new file mode 100755
#index 0000000..b68ad1d
#Binary files /dev/null and b/docs/ins.vsd differ
#diff --git a/draw.graph.pl b/draw.graph.pl
#new file mode 100755
#index 0000000..756ea35
#--- /dev/null
#+++ b/draw.graph.pl
#@@ -0,0 +1,57 @@
#+#!/usr/bin/perl -I ./thirds -w
#+# author: lilong'en(lilongen@163.com)
#+# date:   04/05/2010

		if ($flags->{doCmtReTest}) {
			if ($line =~ $RE->{commit}) {
				$flags->{cmtFound} = 1;

				$cmtCnter++;
				$cmtInfo = {};
				$cmtInfo->{cmt} = $1;
			}
			next;
		}
		
		if ($line =~ $RE->{author}) {
			$flags->{doCmtReTest} = 0;
			$flags->{authorFound} = 1;
			$cmtInfo->{authorName} = $1;
			$cmtInfo->{authorEmail} = $2;
			next;
		}
		
		if ($flags->{authorFound} && $line =~ $RE->{date}) {
			$flags->{dateFound} = 1;
			$cmtInfo->{date} = $1;
			$cmtInfo->{time} = $2;
			$cmtInfo->{timeZone} = $3;
			next;
		}
		
		if ($flags->{dateFound} && $line =~ m/^$/) {
			$flags->{commentBeginFound} = 1;
			$cmtInfo->{comment} = '';
			next;
		}
		
		if ($cmtInfo->{commentBeginFound}) {
			if ($line =~ m/^$/) {
				$flags->{cmtFilesBeginFound} = 1;
				$flags->{commentBeginFound} = 0;
				$cmtInfo->{arrayFiles} = [];
				$cmtInfo->{hashFiles} = {};
			} else {
				$cmtInfo->{comment} .= $line;
			}
			next;
		}
		
		if ($flags->{cmtFilesBeginFound}) {
			if ($line =~ $RE->{fileLOC}) {
				$cmtFileInfo = {};
				$cmtFileInfo->{file} = $3;
				$cmtFileInfo->{addLines} = $1;
				$cmtFileInfo->{delLines} = $2;
				$cmtFileInfo->{cmt} = $cmtInfo->{cmt};
				push(@{$cmtInfo->{arrayFiles}}, $cmtFileInfo->{file});
				$cmtInfo->{hashFiles}->{$cmtFileInfo->{file}} = $cmtFileInfo;
			} else {
				$flags->{filesDiffBegin} = 1;
				$flags->{cmtFilesBeginFound} = 0;
			}
			next;
		}
		
		if ($flags->{filesDiffBegin}) {
			if ($line =~ $RE->{fileDiffHeader}) {
				my $aFile = $1;
				my $bFile = $2;
				my $changeInfo = getCmtFileChangeInfo($aFile, $bFile);
				$cmtInfo->{hashFiles}->{$changeInfo->{file}}->{mode} = $changeInfo->{mode};
				$flags->{doCmtReTest} = 1;
			}
		}
	}
	
	close(LOG);

	$ccvUtil->dumpFile($assistor->getSvnModuleLogParsedInfoFile($pms, $MID), {
	    'OverallInfo' => $GV->{OverallInfo},
		'AuthorsInfo' => $GV->{AuthorsInfo},
		'CmtsInfo'  => $GV->{CmtsInfo},
		'PathsInfo' => $GV->{PathsInfo},
		'PathPaths' => $GV->{PathPaths},
		'Error' 	=> $GV->{Error}
	});

	return 0;
}

sub getCmtFileChangeInfo(my $aFile, $bFile) {
	my $mode = 'normal';
	my $file = $aFile;
	if ($aFile eq '/dev/null') {
		$mode = 'new';
		$file = $bFile;
	}
	if ($bFile eq '/dev/null') {
		$mode = 'deleted';
	}
	return {
		mode: $mode,
		file: $file
	};
}

sub statIt($) {
	my $user = $_[0];
	if (length($pms->{wids}) > 0) {
		return index(",$pms->{wids},", ",$user,") != -1;
	} else {
		return 1;	
	}
}

sub resetFlags($) {
	my $flags = $_[0];
	$flags->{doCmtReTest} = 1;
	$flags->{cmtFound} = 0;
	$flags->{authorFound} = 0;
	$flags->{dateFound} = 0;
	$flags->{commentBeginFound} = 0;
	$flags->{cmtFilesBeginFound} = 0;
	$flags->{filesDiffBegin} = 0;	
}

sub parse_command_line() {
    my $cmd_line = join (" ", @ARGV);

    if ($cmd_line =~ m/\s-t([^\s]+)/) {
        $T_SNAP = $1; 
    }

    if ($cmd_line =~ m/(^|\s)-f([^\s]+)/) {
        $CFG = $2;
    }

    if ($cmd_line =~ m/\s-m([^\s]+)/) {
        $MID = $1;
    }
}
