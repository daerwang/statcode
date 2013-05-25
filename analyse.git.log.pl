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
sub statIt($);
sub storeCmtInfo($);
sub setCmtFileDiffOffset($);
sub generateMoreInfos($);
sub viewlizeInfo();
sub viewlizeAuthorsInfo();
sub viewlizeCommitsInfo();
sub viewlizeFilesInfo();
sub getViewlizeFileInfo($$);
sub add2TotalLoc($);
sub persistPhasedViewlizeInfo();


my $CFG;
my $T_SNAP;
my $MID;
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
    $GV->{LogFile}      = $assistor->get_repository_log_cmd_output_file($pms->{rev}, $GV->{ModuleInfo}->{log});
	
	$GV->{Cmts} = [];
    $GV->{CmtsInfo}     = {}; 
    $GV->{AuthorsInfo}    = {};
    $GV->{FilesInfo}    = {};
    $GV->{Error}		= "";
}

sub main() {
	my $LOG = undef;
print "$GV->{LogFile}\n\n";
	if (!open($LOG, $GV->{LogFile})) {
		print "Can not open $GV->{LogFile}!\n";
		
		return 1;
	}

    my $lineCnter = 0;
	my $cmtCnter = 0;
    my $flags = {}; resetFlags($flags);
	
    my $cmtInfo;
	my $cmtFileInfo;
    my $line;
    my $prevLine;
	while (!eof($LOG)) {
		$line = <$LOG>;
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

#commit => m/^commit ([\d\w]+)$/,
#author => m/^Author (.+) <(.*)>$/,
#date => m/^Date:\s+([\d\-]+) ([\d:]+) \-(\d+)$/,
#comment => m/^(\s){4}(.+)$/,
#fileLOC => m/^([\d\-]+) ([\d\-]+) (.+)$/,
#fileDiffHeader => m/^diff --git a\/(.+) b\/(.+)$/,
#changeMode => m/^(old mode|new mode|deleted file mode|new file mode|copy from|copy to|rename from|rename to) (.+)$/,
#similarity => m/^(similarity index) (.+)$/,
#dissimilarity => m/^(dissimilarity index) (.+)$/,
#changeIndexAndMode => m/^index (\w+)\.\.(\w+) (.+)$/,
#oldMode => m/^old mode(.+)$/,
#newMode => m/^new mode(.+)$/

		#print Dumper($line);

		if ($flags->{doCmtReTest}) {
			#commit 9a32f12bdfcc9b7d27cd5907d838c638e5c735f7
			if ($line =~ m/^commit ([\d\w]+)$/) {
print "cmtFound: $1 -- lineCnter: $lineCnter\n";
				$cmtCnter++;
				if ($cmtCnter > 1) {
					setCmtFileDiffOffset({
						flags => $flags,
						LOG => $LOG,
						line => $line,
						cmtInfo => $cmtInfo
					});
					
					storeCmtInfo($cmtInfo);
					resetFlags($flags);
				}
				
				$flags->{doCmtReTest} = 0;
				$flags->{cmtFound} = 1;
				
				$cmtInfo = {};
				$cmtInfo->{cmt} = $1;
				next;
			}
		}
		
		#Author: lilongen <lilongen@163.com>
		if ($flags->{cmtFound} && $line =~  m/^Author: (.+) <(.*)>$/) {
print "authorFound: $1 -- lineCnter: $lineCnter \n";		
			$flags->{authorFound} = 1;
			$flags->{cmtFound} = 0;
			$cmtInfo->{author} = $1;
			$cmtInfo->{email} = $2;
			next;
		}
		
		#Date:   2013-04-14 23:21:59 -0700
		#Date:   2013-04-14 23:21:59 +0800
		if ($flags->{authorFound} && $line =~ m/^Date:\s+(\d\d\d\d-\d\d-\d\d) (\d\d:\d\d:\d\d) [\+\-](\d+)$/) {
print "dateFound: $1  -- lineCnter: $lineCnter -> $line\n";		
			$flags->{dateFound} = 1;
			$flags->{authorFound} = 0;
			$cmtInfo->{date} = $1;
			$cmtInfo->{time} = $2;
			$cmtInfo->{timeZone} = $3;
			next;
		}
		
		if ($flags->{dateFound} && $line =~ m/^$/) {
print "commentBeginFound:\n";		
			$flags->{commentBeginFound} = 1;
			$flags->{dateFound} = 0;
			$cmtInfo->{comment} = '';
			next;
		}

		if ($flags->{commentBeginFound}) {
			if ($line =~ m/^$/) {
print "cmtFilesBeginFound: \n";			
				$flags->{cmtFilesBeginFound} = 1;
				$flags->{commentBeginFound} = 0;
				$cmtInfo->{arrayFiles} = [];
				$cmtInfo->{hashFiles} = {};
			} else {
				# m/^(\s){4}(.+)$/
print "comment: $line\n";		
				$cmtInfo->{comment} .= substr($line, 4);
			}
			next;
		}
		
		if ($flags->{cmtFilesBeginFound}) {
			if ($line =~ m/^([\d\-]+)\t([\d\-]+)\t(.+)$/) {
				$cmtFileInfo = {};
				$cmtFileInfo->{file} = $3;
print "cmt changed file:  $3\n";
				my $isBinary = $1 eq '-' && $2 eq '-';
				$cmtFileInfo->{addLines} = $isBinary ? 0 : $1;
				$cmtFileInfo->{delLines} = $isBinary ? 0 : $2;
				$cmtFileInfo->{binary} = $isBinary ? 1 : 0;
				$cmtFileInfo->{cmt} = $cmtInfo->{cmt};
				push(@{$cmtInfo->{arrayFiles}}, $cmtFileInfo->{file});
				$cmtInfo->{hashFiles}->{$cmtFileInfo->{file}} = $cmtFileInfo;
			} else {
				$flags->{filesDiffBegin} = 1;
print "filesDiffBegin:  \n";				
				$flags->{cmtFilesBeginFound} = 0;
			}
			next;
		}
		
		if ($flags->{filesDiffBegin}) {
			if ($line =~ m/^diff --git a\/(.+) b\/(.+)$/) {
print "diff --git:  \n";			
				 setCmtFileDiffOffset({
					file => $1,
					flags => $flags,
					LOG => $LOG,
					line => $line,
					cmtInfo => $cmtInfo
				});
				$flags->{prevDiffFile} = $1;
				$flags->{doCmtReTest} = 1;
				$flags->{doFileChangeModeTest} = 1;
			} else {
				if ($flags->{doFileChangeModeTest}) {
					my $changeMode = 'normal';
					if ($line =~ m/^(deleted|new) file mode \d+$/) { #this will closely follow "$line =~ m/^diff --git a\/(.+) b\/(.+)$/"
						$changeMode = $1;
					}
					$cmtInfo->{hashFiles}->{$flags->{prevDiffFile}}->{changeMode} = $changeMode;
					$flags->{doFileChangeModeTest} = 0;
				}
			}
			next;
		}
	}
	
	if ($flags->{prevDiffFile}) {
		setCmtFileDiffOffset({
			flags => $flags,
			LOG => $LOG,
			line => undef,
			cmtInfo => $cmtInfo
		});
		storeCmtInfo($cmtInfo);
		resetFlags($flags);
	}

	close($LOG);
	
	if ($lineCnter == 1) {
		$GV->{Error} = $prevLine;
	}
	
	viewlizeInfo();
	persistPhasedViewlizeInfo();
	
	return 0;
}

sub persistPhasedViewlizeInfo() {
	my $file = $assistor->getGitLogParsedInfoFile($pms, $MID);
	$ccvUtil->dumpFile($file, $GV->{ViewlizeInfo});
	$ccvUtil->writeJsonToFile($GV, "$file.gv.json");
	$ccvUtil->writeJsonToFile($GV->{ViewlizeInfo}, "$file.json");
}

sub storeCmtInfo($) {
	my $cmtInfo = $_[0];
	$GV->{CmtsInfo}->{$cmtInfo->{cmt}} = $cmtInfo;
	generateMoreInfos($cmtInfo);
}

sub generateMoreInfos($) {
	my $cmtInfo = $_[0];
	
	push(@{$GV->{Cmts}}, $cmtInfo->{cmt});
	
	if (!defined($GV->{AuthorsInfo}->{$cmtInfo->{author}})) {
		$GV->{AuthorsInfo}->{$cmtInfo->{author}} = {
			cmtsArray => [],
			hashFiles => {}
		};
	}
	
	my $authorInfo = $GV->{AuthorsInfo}->{$cmtInfo->{author}};
	push(@{$authorInfo->{cmtsArray}}, $cmtInfo->{cmt});
	
	for my $file (keys %{$cmtInfo->{hashFiles}}) {
		if (!defined($authorInfo->{hashFiles}->{$file})) {
			$authorInfo->{hashFiles}->{$file} = [];
		}
		push(@{$authorInfo->{hashFiles}->{$file}}, $cmtInfo->{cmt});

		if (!defined($GV->{FilesInfo}->{$file})) {
			$GV->{FilesInfo}->{$file} = [];
		}
		push(@{$GV->{FilesInfo}->{$file}}, $cmtInfo->{cmt});
	}
}

sub setCmtFileDiffOffset($) {
	my $po = $_[0];
	my $file 	= $po->{file};
	my $flags 	= $po->{flags};
	my $LOG 	= $po->{LOG};
	my $line 	= $po->{line};
	my $cmtInfo = $po->{cmtInfo};
	
	if (defined($flags->{prevDiffFile})) {
		if (!defined($line)) {
			$cmtInfo->{hashFiles}->{$flags->{prevDiffFile}}->{offsetE} = tell($LOG);
		} else {
			$cmtInfo->{hashFiles}->{$flags->{prevDiffFile}}->{offsetE} = tell($LOG) - length($line) - 1;
		}
	}

	if (defined($file)) {
		$cmtInfo->{hashFiles}->{$file}->{offsetB} = tell($LOG) - length($line);
	}
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
	$flags->{prevDiffFile} = undef;
	$flags->{doFileChangeModeTest} = 0;
}

sub viewlizeInfo() {
	my @authors = keys %{$GV->{AuthorsInfo}};
	my @files = keys %{$GV->{FilesInfo}};
	$GV->{ViewlizeInfo} = {
		AuthorsInfo => {},
		CmtsInfo => {},
		FilesInfo => {},
		addLines => 0,
		delLines => 0,
		cmtCnt => $#{$GV->{Cmts}} + 1,
		authorCnt => $#authors + 1,
		foc => $#files + 1
	};
	
	viewlizeAuthorsInfo();
	viewlizeCommitsInfo();
	viewlizeFilesInfo();
}

sub viewlizeAuthorsInfo() {
	my $info = $GV->{AuthorsInfo};
	my $viewInfo = $GV->{ViewlizeInfo}->{AuthorsInfo};
	foreach my $author (sort keys %{$info}) {
		my $authorInfo = $info->{$author};
		$viewInfo->{$author} = {
			foc => 0,
			addLines => 0,
			delLines => 0,
			hashFiles => {}
		};
		
		foreach my $file (sort keys %{$authorInfo->{hashFiles}}) {
			my $viewlizeFileInfo = getViewlizeFileInfo($file, $authorInfo->{hashFiles}->{$file});
			$viewInfo->{$author}->{foc} += 1;
			$viewInfo->{$author}->{addLines} += $viewlizeFileInfo->{addLines};
			$viewInfo->{$author}->{delLines} += $viewlizeFileInfo->{delLines};
			$viewInfo->{$author}->{hashFiles}->{$file} = $viewlizeFileInfo;
			
			add2TotalLoc($viewlizeFileInfo);
		}
	}	
}

sub add2TotalLoc($) {
	my $info = shift;
	$GV->{ViewlizeInfo}->{addLines} += $info->{addLines};		
	$GV->{ViewlizeInfo}->{delLines} += $info->{delLines};	
}

sub viewlizeCommitsInfo() {
	$GV->{ViewlizeInfo}->{CmtsInfo} = {
		Cmts => $GV->{Cmts},
		hashCmts => $GV->{CmtsInfo}
	};
	
	foreach my $cmt (keys %{$GV->{CmtsInfo}}) {
		$GV->{CmtsInfo}->{$cmt}->{addLines} = 0;
		$GV->{CmtsInfo}->{$cmt}->{delLines} = 0;
		foreach my $file (keys %{$GV->{CmtsInfo}->{$cmt}->{hashFiles}}) {
			my $cmtFileInfo = $GV->{CmtsInfo}->{$cmt}->{hashFiles}->{$file};
			$GV->{CmtsInfo}->{$cmt}->{addLines} += $cmtFileInfo->{addLines};
			$GV->{CmtsInfo}->{$cmt}->{delLines} += $cmtFileInfo->{delLines};
		}
	}
}

sub viewlizeFilesInfo() {
	foreach my $file (sort keys %{$GV->{FilesInfo}}) {
		$GV->{ViewlizeInfo}->{FilesInfo}->{$file} = getViewlizeFileInfo($file, $GV->{FilesInfo}->{$file});
	}
}

sub getViewlizeFileInfo($$) {
	my $file = shift;
	my $cmtsOnFile = shift;
	
	my $viewlizeFileInfo = {
		addLines => 0,
		delLines => 0,
		binary => 0,
		cmts => []
	};
	
	for (my $i = 0; $i <= $#{$cmtsOnFile}; $i++) {
		my $cmt = $cmtsOnFile->[$i];
		my $cmtInfo = $GV->{CmtsInfo}->{$cmt};
		my $fileCmtInfo = $cmtInfo->{hashFiles}->{$file};
		
		my $viewlizeFileCmtInfo = {
			date => $cmtInfo->{date},
			time => $cmtInfo->{time},
			comment => $cmtInfo->{comment},
			timeZone => $cmtInfo->{timeZone},
			binary => $fileCmtInfo->{binary},
			addLines => $fileCmtInfo->{addLines},
			delLines => $fileCmtInfo->{delLines},
			offsetB => $fileCmtInfo->{offsetB},
			offsetE => $fileCmtInfo->{offsetE},
			changeMode => $fileCmtInfo->{changeMode}
		};
		$viewlizeFileInfo->{addLines} += $viewlizeFileCmtInfo->{addLines};
		$viewlizeFileInfo->{delLines} += $viewlizeFileCmtInfo->{delLines};
		$viewlizeFileInfo->{binary} += $viewlizeFileCmtInfo->{binary};
		push(@{$viewlizeFileInfo->{cmts}}, $viewlizeFileCmtInfo);
	}
	
	return $viewlizeFileInfo;
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
