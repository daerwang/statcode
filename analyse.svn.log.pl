#!/usr/bin/perl -I ./thirds -w
# author: lilong'en(lilongen@163.com)
# date:   10/12/2010
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
	$GV->{RevFullPath}  = $assistor->getSvnModuleRevFullPath($GV->{ModuleInfo}, $pms);
	$GV->{RevFullPathWithoutRepos}  = substr($GV->{RevFullPath}, length($GV->{ModuleInfo}->{repository}));
	$GV->{InPathPrefix} = undef;
	
    $GV->{OverallInfo}  = {
        'usersCnt' => 0,
        'filesCnt' => 0,
        'revsCnt'  => 0   
    };
    $GV->{RevsInfo}     = {}; 
    $GV->{UsersInfo}    = {};
    $GV->{PathsInfo}    = {};
    $GV->{PathPaths}    = {};
    $GV->{RevsInfo}->{descRevs} = [];
    $GV->{Error}		= "";
}

sub main() {
	if (!open(LOG, $GV->{LogFile})) {
		output('Can not open $GV->{LogFile}!\n');
		
		return 1;
	}
	
	#svn log -v format
	#
	#------------------------------------------------------------------------
	#r20 | lilongen | 2010-10-11 22:09:16 +0000 (Mon, 11 Oct 2010) | 1 line
	#Changed paths:
	#   M /trunk/ccv/T.CMD
	#
	#change T.CMD
	#------------------------------------------------------------------------
	#r19 | lilongen | 2010-10-11 22:08:23 +0000 (Mon, 11 Oct 2010) | 1 line
	#Changed paths:
	#   A /trunk/ccv/T.CMD (from /trunk/ccv/TEST.CMD:15)
	#   D /trunk/ccv/TEST.CMD
	#
	#rename TEST.CMD to T.CMD
	#------------------------------------------------------------------------
	#r18 | lilongen | 2010-10-11 22:07:12 +0000 (Mon, 11 Oct 2010) | 1 line
	#Changed paths:
	#   M /trunk/ccv/UPDATE.sh
	#
	#
	#------------------------------------------------------------------------
	#r17 | lilongen | 2010-10-11 22:05:42 +0000 (Mon, 11 Oct 2010) | 1 line
	#Changed paths:
	#   D /trunk/ccv/tt.pl
	#
	#delete tt.pl
	#------------------------------------------------------------------------
	#r16 | lilongen | 2010-10-11 22:03:57 +0000 (Mon, 11 Oct 2010) | 1 line
	#Changed paths:
	#   M /trunk/ccv/ccv1.pl
	#
	#sdfsdhfjsdkaf
	#------------------------------------------------------------------------
	#r13 | lilongen | 2010-10-11 22:01:14 +0000 (Mon, 11 Oct 2010) | 1 line
	#Changed paths:
	#   A /trunk/ccv
	#   A /trunk/ccv/.update
	#   A /trunk/ccv/.update/CVS
	#   A /trunk/ccv/.update/CVS/Entries
	#   A /trunk/ccv/.update/CVS/Entries.Static
	#   A /trunk/ccv/.update/CVS/Repository
	#   A /trunk/ccv/.update/CVS/Root
	#   A /trunk/ccv/.update/INSTALL.pl
	#   A /trunk/ccv/.update/README
	#   A /trunk/ccv/.update/VERSION
	#   A /trunk/ccv/.update/ccv.tar.gz
	#
	#import
	#------------------------------------------------------------------------
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
