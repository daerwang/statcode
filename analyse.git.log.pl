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
sub getMoreFromParsedInfo();
sub setMustBeDirPathsFileType();
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
    $GV->{LogFile}      = $assistor->get_repository_log_cmd_output_file($pms->{rev}, $GV->{ModuleInfo}->{log});
	
    $GV->{OverallInfo}  = {
        'usersCnt' => 0,
        'filesCnt' => 0,
        'revsCnt'  => 0   
    };
    $GV->{RevsInfo}     = {}; 
    $GV->{UsersInfo}    = {};
    $GV->{PathsInfo}    = {};
    $GV->{PathPaths}    = {};
    $GV->{Error}		= "";
}

sub main() {
	if (!open(LOG, $GV->{LogFile})) {
		output('Can not open $GV->{LogFile}!\n');
		
		return 1;
	}
	
#git log -v format
#
#commit 9a32f12bdfcc9b7d27cd5907d838c638e5c735f7
#Author: Dave Methvin <dave.methvin@gmail.com>
#Date:   Wed Jan 2 21:32:43 2013 -0500
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
# 
#
#commit cef3450228f53a1facfbed2be77050e61ee6a178
#Author: Dave Methvin <dave.methvin@gmail.com>
#Date:   Wed Jan 2 21:25:49 2013 -0500
#
#    Remove noCloneEvent detects and white-box unit test.
#
#0	12	src/support.js
#0	42	test/unit/manipulation.js
#
#diff --git a/src/support.js b/src/support.js
#index 36b91b5..3c76309 100644
#--- a/src/support.js
#+++ b/src/support.js
#@@ -36,7 +36,6 @@ jQuery.support = (function() {
# 		boxModel: document.compatMode === "CSS1Compat",
# 
# 		// Will be defined later
#-		noCloneEvent: true,
# 		reliableMarginRight: true,
# 		boxSizingReliable: true,
# 		pixelPosition: false
#@@ -71,17 +70,6 @@ jQuery.support = (function() {
# 	// WebKit doesn't clone checked state correctly in fragments
# 	support.checkClone = fragment.cloneNode( true ).cloneNode( true ).lastChild.checked;
# 
#-	// Support: IE<9
#-	// Opera does not clone events (and typeof div.attachEvent === undefined).
#-	// IE9-10 clones events bound via attachEvent, but they don't trigger with .click()
#-	if ( div.attachEvent ) {
#-		div.attachEvent( "onclick", function() {
#-			support.noCloneEvent = false;
#-		});
#-
#-		div.cloneNode( true ).click();
#-	}
#-
# 	// Support: Firefox 17+
# 	// Beware of CSP restrictions (https://developer.mozilla.org/en/Security/CSP), test/csp.php
 	div.setAttribute( "onfocusin", "t" );
    my $lineCnter = 0;
    my $flags = {}; resetFlags($flags);
    my $revInfo;
    my $line;
    my $prevLine;
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

		if ($lineCnter < 2) {
			next;
		}
		
		#r13 | lilongen | 2010-10-11 22:01:14 +0000 (Mon, 11 Oct 2010) | 1 line
		#r23 | lilongen | 2010-10-11 22:01:14 +0000 (Mon, 11 Oct 2010) | 2 lines
		#r35 | lilongen | 2010-10-11 22:01:14 +0000 (Mon, 11 Oct 2010) | 12 lines
		if (!$flags->{revFound} && $line =~ m/^r(\d+) \| ([\w\.\-_\d]+) \| ([\d\-\s:]+) .* \| (\d+) lines?$/) {
			if (!statIt($2)) {
				next;
			}
			
			$flags->{revFound} = 1;
			$revInfo = {};
			$revInfo->{rev} = $1;
			$revInfo->{author} = $2;
			$revInfo->{date} = $3;
			$revInfo->{commentLinesCnt} = $4;
			$revInfo->{paths} = [];
			$revInfo->{hashPaths} = {};
			$revInfo->{comment} = "";
	
			$flags->{revPathsCnter} = 0;
			$flags->{revCommentLinesCnter} = 0;
			
			if (!defined($GV->{UsersInfo}->{$revInfo->{author}})) {
				$GV->{UsersInfo}->{$revInfo->{author}} = {};
				
				$GV->{UsersInfo}->{$revInfo->{author}}->{paths} = {};
				$GV->{UsersInfo}->{$revInfo->{author}}->{info} = {'filesCnt' => 0, 'revsCnt' => 0, 'addLines' => 0, 'delLines' => 0};
			}
			
			next;
		}
		
		#  M /trunk/ccv/ccv1.pl
		if ($flags->{revFound} && $flags->{startComment} == 0 && $line =~ m/^\s+(\w) (.*)$/) {
			my $action 	= $1;
			my $path 	= $2;
			
			if (!defined($GV->{InPathPrefix})) {
				if ($path !~ m|^$GV->{RevFullPathWithoutRepos}| && $path !~ m|^$GV->{RevFullPath}|) {
					next;
				} else {
					if ($path =~ m|^$GV->{RevFullPathWithoutRepos}|) {
						$GV->{InPathPrefix} = $GV->{RevFullPathWithoutRepos};
					} else {
						$GV->{InPathPrefix} = $GV->{RevFullPath};
					}
				}
			} else {
				if ($path !~ m|^$GV->{InPathPrefix}|) {
					next;
				}				
			}
			# A /EIM/src/com/webex/eim/bbui/ui/screen/EmotionDialog.java (from /EIM/src/com/webex/eim/bbui/ui/field/EmotionDialog.java:224)
			#logic for above case
			if ($path =~ m/^(.+) \(from (.+):(\d+)\)/) {
				$path = $1;
				
				$revInfo->{fromPath} = $2;
				$revInfo->{fromPathRev} = $3;						
			}
			#
			
			my $lastBackslashPos = rindex($path, '/'); 
			if ($lastBackslashPos > 0) {
				$GV->{PathPaths}->{substr($path, 0, $lastBackslashPos)} = 1;
			}
			
			my $unexactFileType = 'B';
			if ($path =~ m/(\.[\w\d]+)$/) {
				if ($ccvUtil->isTxtFile(\$GV->{AllExts}, $1)) {
					$unexactFileType = 'T';
				}
			}
			
			if ($pms->{OFilter}->{filterNeeded}) {
				my $isIn = $ccvUtil->filter($path, $pms->{OFilter});
				
				if (!$isIn) {
					next;	
				}				
			}
			
			$flags->{revPathsCnter} ++;
			push(@{$revInfo->{paths}}, {'path' => $path, 'action' => $action});
		    $revInfo->{hashPaths}->{$path} = {'action' => $action, 'type' => $unexactFileType};
			
			next;
		}

		#                    empty line after changed path & before comments
		if ($flags->{revPathsCnter} > 0 && $flags->{startComment} == 0 && $line =~ m/^$/) {
			$flags->{startComment} = 1;
			
			next;
		}

		#check in comments.......
		if ($flags->{startComment} && $flags->{revCommentLinesCnter} < $revInfo->{commentLinesCnt} && $line =~ m/^(.*)$/) {
			$flags->{revCommentLinesCnter}++;
			$revInfo->{comment} .= $1;
			
			next;
		}
		
		#------------------------------------------------------------------------
		if ($flags->{revFound} && $flags->{revCommentLinesCnter} >= $revInfo->{commentLinesCnt} || ($flags->{revPathsCnter} == 0 && $line =~ m/^-+$/)) {
			if ($flags->{revPathsCnter} > 0) {
				$GV->{RevsInfo}->{$revInfo->{rev}} = $revInfo;
				push(@{$GV->{RevsInfo}->{descRevs}}, $revInfo->{rev});
				setUserPathsChangeInfo($flags, $revInfo);
			}
			resetFlags($flags);
			$revInfo = undef;
			
			next;
		}
	}
	close(LOG);
	
	getMoreFromParsedInfo();
	
	if (!defined($GV->{InPathPrefix})) {
		$GV->{OverallInfo}->{InPathPrefix} = $GV->{RevFullPathWithoutRepos};
	} else {
		$GV->{OverallInfo}->{InPathPrefix} = $GV->{InPathPrefix};	
	}
	$GV->{OverallInfo}->{RevFullPathWithoutRepos} = $GV->{RevFullPathWithoutRepos};
	$GV->{OverallInfo}->{RevFullPath} = $GV->{RevFullPath};
	
	$ccvUtil->dumpFile($assistor->getSvnModuleLogParsedInfoFile($pms, $MID), {
	    'OverallInfo' => $GV->{OverallInfo},
		'UsersInfo' => $GV->{UsersInfo},
		'RevsInfo'  => $GV->{RevsInfo},
		'PathsInfo' => $GV->{PathsInfo},
		'PathPaths' => $GV->{PathPaths},
		'Error' 	=> $GV->{Error}
	});

	return 0;
}

sub setMustBeDirPathsFileType() {
	for my $key (keys %{$GV->{PathPaths}}) {
		if (defined($GV->{PathsInfo}->{$key})) {
			$GV->{PathsInfo}->{$key}->{info}->{type} = 'D';
		}
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

sub setUserPathsChangeInfo($$) {
	my $flags = $_[0];
	my $revInfo = $_[1];
	
	for (my $i = 0; $i < $flags->{revPathsCnter}; $i++) {
		my $path = $revInfo->{paths}->[$i]->{path};
		
		if (!defined($GV->{UsersInfo}->{$revInfo->{author}}->{paths}->{$path})) {
			$GV->{UsersInfo}->{$revInfo->{author}}->{paths}->{$path} = {
			    'revs' => [], 
			    'info' => {'revsCnt' => 0, 'addLines' => 0, 'delLines' => 0}
		    };
		    
		    $GV->{UsersInfo}->{$revInfo->{author}}->{info}->{filesCnt}++;
		}
		push(@{$GV->{UsersInfo}->{$revInfo->{author}}->{paths}->{$path}->{revs}}, $revInfo->{rev});
		$GV->{UsersInfo}->{$revInfo->{author}}->{paths}->{$path}->{info}->{revsCnt}++;
		
		if (!defined($GV->{PathsInfo}->{$path})) {
			$GV->{PathsInfo}->{$path} = {
			    'revs' => [], 
			    'info' => {'revsCnt' => 0, 'addLines' => 0, 'delLines' => 0}
			};
			
			if ($revInfo->{fromPath}) {
				$GV->{PathsInfo}->{$path}->{info}->{fromPath} = $revInfo->{fromPath};
				$GV->{PathsInfo}->{$path}->{info}->{fromPathRev} = $revInfo->{fromPathRev};
			}
			
			$GV->{OverallInfo}->{filesCnt}++;
		}
		push(@{$GV->{PathsInfo}->{$path}->{revs}}, $revInfo->{rev});
		$GV->{PathsInfo}->{$path}->{info}->{revsCnt}++;
	}
}

sub getMoreFromParsedInfo() {
    $GV->{OverallInfo}->{usersCnt} = keys(%{$GV->{UsersInfo}});
    $GV->{OverallInfo}->{revsCnt} = $#{$GV->{RevsInfo}->{descRevs}} + 1;
    
    for (my $i = 0; $i < $GV->{OverallInfo}->{revsCnt}; $i++) {
        my $rev = $GV->{RevsInfo}->{descRevs}->[$i];
        my $revAuthor = $GV->{RevsInfo}->{$rev}->{author};
        $GV->{UsersInfo}->{$revAuthor}->{info}->{revsCnt}++;
    }
    
    setMustBeDirPathsFileType();
}

sub resetFlags($) {
	my $flags = $_[0];
	$flags->{revFound} = 0;
	$flags->{startComment} = 0;
	$flags->{revEnd} = 0;
	$flags->{revPathsCnter} = 0;
	$flags->{revCommentLinesCnter} = 0;	
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
