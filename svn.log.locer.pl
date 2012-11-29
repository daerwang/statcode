#!/usr/bin/perl -I ./thirds -w
# author: lilong'en(lilongen@163.com)
# date:   10/19/2010
#

use strict;
use English;
use Data::Dumper;
use Assistor;
use CcvUtil;
use URI::Escape;
use Cwd;
use bytes;

sub logInfo($);
sub setGV();
sub main();
sub parse_command_line();
sub generateSvnCmdTasks();
sub getRevsLoc();
sub analyseDfGrepFile($);
sub getCoInitRevLoc();
sub resetFlags($);
sub resetFileRevDfInfo($);
sub resetRevDfInfo($);
sub storeFileRevDfInfo($$);
sub storeRevDfInfo($);
sub detectPaths();
sub setFileLocInfo($$);
sub getMoreUsefulLocInfo();
sub splitSvnCmdTasks();
sub getDfTasksSliceCnt($);
sub getDfTasksSliceInfo();
sub mergeSliceDfCmdsOut();
sub getIfNeedCoFirstVersion();
sub getDfCmdTpl();

my $__DEBUG = 0;

my $T_SNAP	= "";
my $CFG		= "";
my $MID		= "";

parse_command_line();

my $assistor = new Assistor($CFG, $T_SNAP);
$assistor->getModules(); 

my $ccvUtil = new CcvUtil();
my $pms = $ccvUtil->loadFile($assistor->get_specified_operate_file("PMS"));
$assistor->injectRuntimeAccount2Modules($pms->{uid}, $pms->{upw});	

my $GV = {}; setGV();
my $fileCnter = 1;
exit main();

sub setGV() {
	$GV->{ModuleInfo} 			= $assistor->get_module_info_by_module_id($MID);
	$GV->{LogParsedInfoFile} 	= $assistor->getSvnModuleLogParsedInfoFile($pms, $MID);
	$GV->{LogParsedInfo} 		= $ccvUtil->loadFile($GV->{LogParsedInfoFile});
	$GV->{ModuleUrl} 			= $assistor->get_svn_module_url($GV->{ModuleInfo}, $pms->{rev});
	$GV->{InPathPrefix} 		= $GV->{LogParsedInfo}->{OverallInfo}->{InPathPrefix};
	$GV->{InPathPrefix4CoPaths} = substr($GV->{InPathPrefix}, 0, rindex($GV->{InPathPrefix}, '/') + 1);
	
	my $descRevs = $GV->{LogParsedInfo}->{RevsInfo}->{descRevs};
	$GV->{InitRev} = $descRevs->[$#{$descRevs}];
	$GV->{LastRev} = $descRevs->[0];
	
	$GV->{DF_OUT_PLACEHOLDER} = "#__CCV_DF__#";
	$GV->{DfCmdsShTpl} 	= "__ccv_df_slice_%d_%d.sh";
	$GV->{DfSliceOutTpl} = "__ccv_df_slice_out_%d_%d";
	
	$GV->{DfCmdsOuts} = "";#for merge df out to one file
	$GV->{AllRevsDfOut} = $assistor->{DEF}->{MID_OUT_FILE_NAME}->{SVN_ALL_REVS_DF};
	$GV->{NeedCoFirstVer} = 0;
}

sub main() {
	my $plPath = getcwd;
	my $moduleOperatePath = $assistor->get_operate_revs_location($assistor->get_operate_revs_dates_dir_name($pms)) . $MID;

	chdir($moduleOperatePath);
	generateSvnCmdTasks();
	splitSvnCmdTasks();
	
	#
	# !! Important
	# for fork will copy current process, 
	# so use a more simple new process as the fork parent to make sure use more-less memory
	#
	chdir($plPath);
    my $cmd = sprintf("perl -w svn.cmds.parent.pl \"%s\" \"%s\" \"%s\" \"%s\" \"%s\" \"%s\"",
    	$moduleOperatePath,
    	$GV->{DfSliceInfo}->{DfCmdsCnt},
    	$GV->{DfSliceInfo}->{DfCmdsSliceCnt},
    	$GV->{DfSliceInfo}->{SliceCmdsCnt},
		$GV->{ModuleInfo}->{account_id},
		$GV->{ModuleInfo}->{account_pw}
    );	
	
	system($cmd);
	chdir($moduleOperatePath);
	getIfNeedCoFirstVersion();
	if ($GV->{NeedCoFirstVer}) {
		chdir('rev_src/init');
		system($GV->{SvnCmds}->{coCmd});
		chdir('../..');		
	}
	
	mergeSliceDfCmdsOut();
	getRevsLoc();

	if ($GV->{NeedCoFirstVer}) {
		getCoInitRevLoc();	
	}
	
	chdir($plPath);

    getMoreUsefulLocInfo();
    system("mv $GV->{LogParsedInfoFile} $GV->{LogParsedInfoFile}.o");
    
    $GV->{LogParsedInfo}->{NeedCoFirstVer} = $GV->{NeedCoFirstVer};
    $ccvUtil->dumpFile($GV->{LogParsedInfoFile}, $GV->{LogParsedInfo});
		
    return 0;
}

sub getDfTasksSliceInfo() {
	my $dfCmdsCnt = $#{$GV->{SvnCmds}->{dfCmds}} + 1;
	my $dfCmdsSliceCnt = getDfTasksSliceCnt($dfCmdsCnt);
    my $sliceCmdsCnt = int($dfCmdsCnt / $dfCmdsSliceCnt);
    if ($dfCmdsCnt % $dfCmdsSliceCnt != 0) {
       $sliceCmdsCnt ++; 
    }
    
    $GV->{DfSliceInfo} = {};
    $GV->{DfSliceInfo}->{DfCmdsCnt} = $dfCmdsCnt;
    $GV->{DfSliceInfo}->{DfCmdsSliceCnt} = $dfCmdsSliceCnt;
    $GV->{DfSliceInfo}->{SliceCmdsCnt} = $sliceCmdsCnt;	
}

sub splitSvnCmdTasks() {
	getDfTasksSliceInfo();
	for (my $i = 0; $i < $GV->{DfSliceInfo}->{DfCmdsSliceCnt}; $i++) {
        my $dfCmdSh = sprintf($GV->{DfCmdsShTpl}, $GV->{DfSliceInfo}->{DfCmdsSliceCnt}, $i);
        
        my $sliceCmds = "";
        if (!open(H_SH, '>', $dfCmdSh)) {
            print "Err: can not open $dfCmdSh";
            next;
        }
		
		my $dfOut = sprintf($GV->{DfSliceOutTpl}, $GV->{DfSliceInfo}->{DfCmdsSliceCnt}, $i);
		$GV->{DfCmdsOuts} .= $dfOut . ' ';
        for (my $j = 0; $j < $GV->{DfSliceInfo}->{SliceCmdsCnt}; $j++) {
            my $idx = $GV->{DfSliceInfo}->{SliceCmdsCnt} * $i + $j;
            if ($idx >= $GV->{DfSliceInfo}->{DfCmdsCnt}) {
            	last;
            }
            
            $GV->{SvnCmds}->{dfCmds}->[$idx] =~ s/$GV->{DF_OUT_PLACEHOLDER}/$dfOut/g;
            $sliceCmds .= $GV->{SvnCmds}->{dfCmds}->[$idx] . "\n";
            
            if ($j % 100 == 0) {
                print H_SH $sliceCmds;
                $sliceCmds = "";
            }
        }
        print H_SH $sliceCmds;
        close H_SH;
	}
}

sub getDfTasksSliceCnt($) {
    my $dfCmdsCnt = $_[0];
    
    if ($dfCmdsCnt > 10000) {
    	return 30;
    } elsif ($dfCmdsCnt > 2000) {
    	return 30;
    } elsif ($dfCmdsCnt > 200) {
    	return 20;
    } elsif ($dfCmdsCnt > 50) {
    	return 10;
    } else {
    	return 1;	
    }
}

sub mergeSliceDfCmdsOut() {
	system("cat $GV->{DfCmdsOuts} > $GV->{AllRevsDfOut}");
}

sub getIfNeedCoFirstVersion() {
	my $descRevs = $GV->{LogParsedInfo}->{RevsInfo}->{descRevs};
	
	if ($#{$descRevs} < 0) {
		$GV->{NeedCoFirstVer} = 0;
		
		return 0;
	}
	my $firstVer = $descRevs->[$#{$descRevs}];
	#(revision xxx)
	#grep -P "^\+\+\+ .*\(revision xx\)$" __ccv_df_slice_out_20_19
	
	my $outFile = sprintf($GV->{DfSliceOutTpl}, $GV->{DfSliceInfo}->{DfCmdsSliceCnt}, $GV->{DfSliceInfo}->{DfCmdsSliceCnt} - 1);
	my $grepOut = "_ccv_if_need_co_first_ver_out";
	my $cmd = "grep -P \"^\\+\\+\\+ .*\\(revision $firstVer\\)\" $outFile > $grepOut";
	system($cmd);
	my $content = $assistor->read_whole_file($grepOut);
	
	if (length($content) > 10) {
		$GV->{NeedCoFirstVer} = 0;
		return 1;
	} else {
		$GV->{NeedCoFirstVer} = 1;
		return 0;	
	}
}

sub getDfCmdTpl() {
	return $ccvUtil->isAnonymousAccessSVN($GV->{ModuleInfo}) ?
        sprintf('echo __ccv_svn_df_c_#REV# >> %s;svn diff %s --non-interactive --trust-server-cert -c "#REV#" "%s" >> %s',
    		$GV->{DF_OUT_PLACEHOLDER},
    		$pms->{dfOpts}->{svn},
    		$GV->{ModuleUrl},
    		$GV->{DF_OUT_PLACEHOLDER}
    	) 
    	: 
        sprintf('echo __ccv_svn_df_c_#REV# >> %s;svn diff %s --non-interactive --trust-server-cert --username "$1" --password "$2" -c "#REV#" "%s" >> %s', 
        	$GV->{DF_OUT_PLACEHOLDER},
        	$pms->{dfOpts}->{svn},
    		$GV->{ModuleUrl},
    		$GV->{DF_OUT_PLACEHOLDER}
    	);
}

sub generateSvnCmdTasks() {
	my $descRevs = $GV->{LogParsedInfo}->{RevsInfo}->{descRevs};
	my $svnDfCmdTasks = [];
	
	my $versCnt = $#{$descRevs} + 1;
	if ($versCnt > 0) {
		my $diffCmdTemplate = getDfCmdTpl();
		
		for (my $i = 0; $i < $versCnt ; $i++) {
			my $cmd = $diffCmdTemplate;
			$cmd =~ s/#REV#/$descRevs->[$i]/g;		
			push(@{$svnDfCmdTasks}, $cmd);
		}
	}
		
	
	my $coCmd = $ccvUtil->isAnonymousAccessSVN($GV->{ModuleInfo}) ? 
    	sprintf('svn export --non-interactive --trust-server-cert -r "%s" "%s"', 
    		$descRevs->[$#{$descRevs}],
    		$GV->{ModuleUrl}
    	)
    	: 
    	sprintf('svn export --non-interactive --trust-server-cert --username "%s" --password "%s" -r "%s" "%s"', 
    		$GV->{ModuleInfo}->{account_id},
    		$GV->{ModuleInfo}->{account_pw},
    		$descRevs->[$#{$descRevs}],
    		$GV->{ModuleUrl}
    	);
    		
	
	$GV->{SvnCmds} = {
		'dfCmds' => $svnDfCmdTasks,
		'coCmd' => $coCmd
	};
}


sub getRevsLoc() {
	my $H_RDF;	
	if (!open($H_RDF, $GV->{AllRevsDfOut})) {
		print "Can not open svn module revision diff out file $GV->{AllRevsDfOut}!\n";
	} else {
	    analyseDfGrepFile($H_RDF);
	    close($H_RDF);
	}
}

#Index: themes/default/tokenfield.css
#===================================================================
#--- themes/default/tokenfield.css	(revision 791)
#+++ themes/default/tokenfield.css	(revision 792)
#@@ -1 +1 @@
#Index: tokenfield.htm
#===================================================================
#--- tokenfield.htm	(revision 791)
#+++ tokenfield.htm	(revision 792)
#@@ -1,69 +1,69 @@
#Index: themes/default/images/widget.profile.png
#===================================================================
#Cannot display: file marked as a binary type.
#svn:mime-type = application/octet-stream
#Index: widget.profile.js
#===================================================================
#--- widget.profile.js	(revision 0)
#+++ widget.profile.js	(revision 627)
#@@ -0,0 +1 @@
sub analyseDfGrepFile($) {
	my $H_RDF = $_[0];
    my $lineCnter = 0;
    my $flags = {}; resetFlags($flags);
    my $fileRevDfInfo = undef;
    my $revDfInfo = undef;

	while(1) {
		my $line = <$H_RDF>;	
		if (!defined($line)) {
		    if (defined($fileRevDfInfo)) {
		    	$fileRevDfInfo->{offsetE} = tell($H_RDF);
		        storeFileRevDfInfo($flags, $fileRevDfInfo);
		    }
		    if (defined($revDfInfo)) {
		    	$revDfInfo->{offsetE} = tell($H_RDF);
		    	storeRevDfInfo($revDfInfo);
		    }		    
			last;
		}
		
		if ($flags->{fileFound}) {
		    $flags->{linesAfterFileFoundCnter}++;
		}
		if ($flags->{linesAfterFileFoundCnter} == 1) {#===================================================================
		    next;
		}
		if ($flags->{linesAfterFileFoundCnter} == 2 && $line !~ m/^\-/) {#Cannot display: file marked as a binary type.
	        $flags->{isBinary} = 1;
	        #for binary file diff part does not include revsion, so need to get it from whole rev df incdicator
	        $fileRevDfInfo->{r1} = $revDfInfo->{rev};
	        next;		    
		}
		
		#cat __ccv_svn_df_c_#REV# >> %s
		if ($line =~ m/^__ccv_svn_df_c_(\d+)$/) {
		    if (defined($revDfInfo)) {
		    	$revDfInfo->{offsetE} = tell($H_RDF) - length($line);
		    	storeRevDfInfo($revDfInfo);
		    }
		    $revDfInfo = {}; resetRevDfInfo($revDfInfo);
            $revDfInfo->{rev} = $1;	    
		    $revDfInfo->{offsetB} = tell($H_RDF);
		    next;
		}
		
		#Index: themes/default/tokenfield.css
		if ($line =~ m/^Index: (.+)$/) {
		    if (defined($fileRevDfInfo)) {
		    	$fileRevDfInfo->{offsetE} = tell($H_RDF) - length($line) - 1;
		    	storeFileRevDfInfo($flags, $fileRevDfInfo);
		    }
		    
		    $fileRevDfInfo = {}; resetFileRevDfInfo($fileRevDfInfo); resetFlags($flags);
		    $fileRevDfInfo->{file} = $1;
		    $fileRevDfInfo->{offsetB} = tell($H_RDF) - length($line);
		    $flags->{fileFound} = 1;
		    
		    next;
	    }
	    
	    if ($flags->{fileFound} && !$flags->{isBinary}) {
	    	if ($line =~ m/^\s/) {#lines before/after "-/+" indicator character
	    		next;
	    	}
	    	
	        #--- themes/default/tokenfield.css	(revision 791)
	        if ($line =~ m/^\-\-\- .+\s+\(revision (\d+)\)$/) {
    	        $fileRevDfInfo->{r0} = $1;
    	        next;
    	    }
	    
            #+++ tokenfield.htm	(revision 792)
    	    if ($line =~ m/^\+\+\+ .+\s+\(revision (\d+)\)$/) {
    	        $fileRevDfInfo->{r1} = $1;
    	        next;
    	    }
    	    
    	    if ($line =~ m/^\-/) {
    	        $fileRevDfInfo->{delLines}++;
    	        next;
    	    }
    	    
    	    if ($line =~ m/^\+/) {
    	        $fileRevDfInfo->{addLines}++;
    	        next;
    	    }    	    
	    }
	    		    	    	    
	}
}

#wc: widget: Is a directory
#      0 widget
#      0 widget/TokenField.js
#     22 widget/pandora.js
#     55 widget/profile.htm
#wc: widget/themes/default/images: Is a directory
#      0 widget/themes/default/images
#      6 widget/themes/default/images/Button_Dropdown.gif
#      7 widget/themes/default/images/Button_Dropdown.png
#    169 widget/themes/default/images/CountryFlag.gif
sub getCoInitRevLoc() {
	chdir('rev_src/init');
	
	detectPaths();
	filterPaths();
	
	system("cat src.paths.txt | xargs wc -l > src.paths.txt.wc 2>/dev/null");

	my $hFWC;
	if (!open($hFWC, 'src.paths.txt.wc')) {
		print "Error: Can not open file src.paths.txt.wc\n";
		return;
	}
	while(1) {
		my $line = <$hFWC>;	
		if (!defined($line)) {
			last;
		}

		if ($line =~ m/^\s*(\d+) (.+)$/) {
			setFileLocInfo($2, $1);
			next;
		}
	}
	close($hFWC);

	chdir('../..');
}

sub detectPaths() {
	my $paths = $GV->{LogParsedInfo}->{RevsInfo}->{$GV->{InitRev}}->{paths};
	my $cnt = $#{$paths};
	my $strPaths = '';
	my $startOffset = length($GV->{InPathPrefix4CoPaths});
	for (my $i = 0; $i <= $cnt; $i++  ) {
		$strPaths .= substr($paths->[$i]->{path}, $startOffset);
		if ($i < $cnt) {
			$strPaths .= "\n";
		}
	}

	system("echo \"$strPaths\" > src.paths");
	system("file -f src.paths > src.paths.file 2>&1");
}

sub setFileLocInfo($$) {
	my $file = $_[0];
	my $loc = $_[1];

	my $fileInfo = $GV->{LogParsedInfo}->{RevsInfo}->{$GV->{InitRev}}->{hashPaths}->{"$GV->{InPathPrefix4CoPaths}$file"};
	if (defined($fileInfo)) {
		$fileInfo->{addLines} = $loc; 
		$fileInfo->{delLines} = 0;
		$fileInfo->{isNew} = 1;
		
	}
}

sub setFileTypeInfo($$) {
	my $file = $_[0];
	my $fileType = $_[1];
	
	my $fileInfo = $GV->{LogParsedInfo}->{RevsInfo}->{$GV->{InitRev}}->{hashPaths}->{"$GV->{InPathPrefix4CoPaths}$file"};
	$fileInfo->{type} = $fileType;
}

#widget/nls/zh-tw/resource_zh-tw.js:                         UTF-8 Unicode English text, with very long lines, with no line terminators
#widget/pandora.js:                                          ASCII C program text, with very long lines
#widget/themes/default:                                      directory
#widget/themes/default/blank.gif:                            GIF image data, version 89a, 1 x 1
#widget/themes/default/ellipsis.xml:                         XML document text
#widget/themes/default/iepngfix.htc:                         ASCII C++ program text, with CRLF line terminators
#widget/themes/default/images:                               directory
#widget/themes/default/images/Button_Dropdown.gif:           GIF image data, version 89a, 85 x 17
#widget/themes/default/images/Button_Dropdown.png:           PNG image data, 85 x 17, 8-bit/color RGBA, non-interlaced
sub filterPaths() {
	my $hF;
	if (!open($hF, 'src.paths.file')) {
		print "Error: Can not open file src.paths.file\n";
		return;
	}
	
	my $txtFiles = '';
	while(1) {
		my $line = <$hF>;	
		if (!defined($line)) {
			last;
		}
			
		if ($line =~ m/^(.+):\s+(.+)$/) {
			my $file = $1;
			my $fileInfo = $2;
			
			my $fileType = 'T';		
			if ($fileInfo eq 'directory') {
				$fileType = 'D';
			} elsif (index($fileInfo, 'text') != -1) {
				$fileType = 'T';
				$txtFiles .= $file . "\n";
			} else {
				$fileType = 'B';
			}
			
			setFileTypeInfo($file, $fileType);
		}
	}
	close($hF);
	
	$txtFiles = substr($txtFiles, 0, -1);
	system("echo \"$txtFiles\" > src.paths.txt");
}

sub getMoreUsefulLocInfo() {
    my $revsInfo = $GV->{LogParsedInfo}->{RevsInfo};
    my $pathsInfo = $GV->{LogParsedInfo}->{PathsInfo};
    my $overallInfo = $GV->{LogParsedInfo}->{OverallInfo};

    $overallInfo->{addLines} = 0;
    $overallInfo->{delLines} = 0;
    
    my $revsCnt = $#{$revsInfo->{descRevs}} + 1;
    for (my $i = 0; $i < $revsCnt; $i++) {
        my $rev = $revsInfo->{descRevs}->[$i];
        my $user = $revsInfo->{$rev}->{author};
        my $userData = $GV->{LogParsedInfo}->{UsersInfo}->{$user};
		    	    
        while ( my ($path, $info) = each( %{$revsInfo->{$rev}->{hashPaths}} ) ) {
            if ($info->{type} && $info->{type} eq 'T') {
            	if (!defined($info->{addLines})) {
            		$info->{addLines} = 0;
            	}
            	if (!defined($info->{delLines})) {
            		$info->{delLines} = 0;
            	}
            	
                $overallInfo->{addLines} += $info->{addLines};
                $overallInfo->{delLines} += $info->{delLines};
				
                $userData->{info}->{addLines} += $info->{addLines};
                $userData->{info}->{delLines} += $info->{delLines};
                
                my $userFileInfo =  $userData->{paths}->{$path}->{info};
               	$userFileInfo->{addLines} += $info->{addLines};	
                $userFileInfo->{delLines} += $info->{delLines};	
                
                
                my $fileInfo = $pathsInfo->{$path}->{info};
                $fileInfo->{addLines} += $info->{addLines};	
                $fileInfo->{delLines} += $info->{delLines};	
            }        
        }
    }
}

sub storeFileRevDfInfo($$) {
    my $flags = $_[0];
    my $fileRevDfInfo = $_[1];
    
    my $fileInfo = $GV->{LogParsedInfo}->{RevsInfo}->{$fileRevDfInfo->{r1}}->{hashPaths}->{$GV->{InPathPrefix} . '/' . $fileRevDfInfo->{file}};
	if ($flags->{isBinary}) {
	    $fileInfo->{type} = 'B';
	} else {
	    $fileInfo->{type} = 'T';
	    $fileInfo->{delLines} 	= $fileRevDfInfo->{delLines};
	    $fileInfo->{addLines} 	= $fileRevDfInfo->{addLines};
	    $fileInfo->{isNew} 		= ($fileRevDfInfo->{r0} == 0 ? 1 : 0);
	    $fileInfo->{offsetB} 	= $fileRevDfInfo->{offsetB};
	    $fileInfo->{offsetE} 	= $fileRevDfInfo->{offsetE};
	}
    $fileCnter++;
    
    resetFlags($flags);
}

sub storeRevDfInfo($) {
    my $revDfInfo = $_[0];
    my $revInfo = $GV->{LogParsedInfo}->{RevsInfo}->{$revDfInfo->{rev}};
    $revInfo->{offsetB} = $revDfInfo->{offsetB};
    $revInfo->{offsetE} = $revDfInfo->{offsetE};
}

sub resetFlags($) {
	my $flags = $_[0];
	$flags->{fileFound} = 0;
	$flags->{isBinary} = 0;
	$flags->{linesAfterFileFoundCnter} = 0;
}

sub resetFileRevDfInfo($) {
    my $fileRevDfInfo = $_[0];
    $fileRevDfInfo->{file} = '';
    $fileRevDfInfo->{offsetB} = -1;
    $fileRevDfInfo->{offsetE} = -1;
    $fileRevDfInfo->{r0} = 0;
    $fileRevDfInfo->{r1} = 0;
    $fileRevDfInfo->{delLines} = 0;
    $fileRevDfInfo->{addLines} = 0;
}

sub resetRevDfInfo($) {
    my $revDfInfo = $_[0];
    $revDfInfo->{rev} = 0;	    
    $revDfInfo->{offsetB} = -1;
    $revDfInfo->{offsetE} = -1;
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

sub logInfo($) {
	if ($__DEBUG) {
		print $_[0] . "\n";
	}	
}
