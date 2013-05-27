#!/usr/bin/perl -I ./thirds -w
# author: lilong'en(lilongen@163.com)
# date:   05/27/2013
#

use strict;
use English;
use Data::Dumper;
use Assistor;
use CcvUtil;
use URI::Escape;
use Cwd;
use bytes;

sub setGV();
sub defReportElementEntryTpl();
sub main();
sub parse_command_line();
sub getTemplateParts();
sub replacePart1PMS($);
sub replacePart2PMS($);
sub writeUserViewItems();
sub writeFileViewItems();
sub plusUserBriefInfo($$);
sub generateBriefReportHeader();
sub appendData2AllModulesSumFile();
sub _getFileInUI($);


my $T_SNAP	= "";
my $CFG		= "";
my $MID		= "";

parse_command_line();

my $assistor = new Assistor($CFG, $T_SNAP); $assistor->getModules();
my $ccvUtil = new CcvUtil();
my $pms = $ccvUtil->loadFile($assistor->get_specified_operate_file("PMS"));

my $GV = {}; setGV();
exit main();

sub setGV() {
	$GV->{GitInfo} 				= $assistor->get_module_info_by_module_id($MID);
	$GV->{ViewlizeInfoFile} 	= $assistor->getSvnModuleLogParsedInfoFile($pms, $MID);
	$GV->{ViewlizeInfo} 		= $ccvUtil->loadFile($GV->{ViewlizeInfoFile});
	$GV->{LogFile}              = $assistor->get_repository_log_cmd_output_file($pms->{rev}, $GV->{GitInfo}->{log});
	$GV->{AllDfFile}            = $GV->{LogFile};

	#Module&User LOC persistence data - for final all module sum
    $GV->{ModuleAndUserLocData} = {};
    $GV->{ModuleAndUserLocData}->{$MID} = {};
    $GV->{ModuleAndUserLocData}->{$MID}->{users} = {};
    my $muData = $GV->{ModuleAndUserLocData}->{$MID};
    my $overall = $GV->{ViewlizeInfo};
    $muData->{foc} = $overall->{fileCnt};
    $muData->{loc} = $overall->{addLines} + $overall->{delLines};
    $muData->{loc_added} = $overall->{addLines};
    $muData->{loc_deleted} = $overall->{delLines};    	
    #End		
	
	$GV->{Error} = $GV->{ViewlizeInfo}->{Error};
	
	defReportElementEntryTpl();
}

sub main() {
	my $ret = openReportFiles();
	if ($ret ne '') {
		return 1;
	}
	
	generateBriefReportHeader();
	getTemplateParts();
	writeReports();
	closeReportFiles();
	
	return 0;
}

sub writeReports() {
	my $hUser = $GV->{H_UserReport};
	my $hFile = $GV->{H_FileReport};

	print $hUser $GV->{TplParts}->{userP1};
	writeUserViewItems();
	print $hUser $GV->{TplParts}->{P2};

	print $hFile $GV->{TplParts}->{fileP1};
	writeFileViewItems();
	print $hFile $GV->{TplParts}->{P2};

	
	my $hModuleBrief =  $GV->{H_ModuleBriefReportFile};
	my $hAllBrief =     $GV->{H_AllBriefReportFile};
	print $hModuleBrief $GV->{ModuleBriefInfo};
	print $hAllBrief    $GV->{ModuleBriefInfo};
	print $hAllBrief "\n\n";
	
	appendData2AllModulesSumFile();
}

sub openReportFiles() {
	$GV->{UserReport} = $assistor->get_specified_output_report_file({flag => "LOG_USERS", revs => $pms->{rev}, mid=> $MID});
	$GV->{FileReport} = $assistor->get_specified_output_report_file({flag => "LOG_FILES", revs => $pms->{rev}, mid=> $MID});
	$GV->{AllBriefReportFile} = $assistor->get_brief_report_file();
	$GV->{ModuleBriefReportFile} = $assistor->get_module_brief_report_file($MID);
	
	if (!open($GV->{H_UserReport}, '>', $GV->{UserReport})) {
		print "can not open $GV->{UserReport}\n";
		return $GV->{UserReport};
	}

	if (!open($GV->{H_FileReport}, '>', $GV->{FileReport})) {
		print "can not open $GV->{FileReport}\n";
		return $GV->{FileReport};
	}
	
	if (!open($GV->{H_AllBriefReportFile}, '>>', $GV->{AllBriefReportFile})) {
		print "can not open $GV->{AllBriefReportFile}\n";
		return $GV->{AllBriefReportFile};
	}

	if (!open($GV->{H_ModuleBriefReportFile}, '>', $GV->{ModuleBriefReportFile})) {
		print "can not open $GV->{ModuleBriefReportFile}\n";
		return $GV->{ModuleBriefReportFile};
	}	
	
	return '';
}

sub closeReportFiles() {
	close($GV->{H_UserReport});
	close($GV->{H_FileReport});
	close($GV->{H_AllBriefReportFile});
	close($GV->{H_ModuleBriefReportFile});	
}

sub appendData2AllModulesSumFile() {
	my $allModulesSumInfo = $assistor->get_all_modules_sum_info_data_file();
	my $tmp;
	
	if (-e $allModulesSumInfo) {
		$tmp = $ccvUtil->loadFile($allModulesSumInfo);
		$tmp->{$MID} = $GV->{ModuleAndUserLocData}->{$MID};
	} else {
		$tmp = $GV->{ModuleAndUserLocData};
	}
	
	$ccvUtil->dumpFile($allModulesSumInfo, $tmp);		
}

sub getTemplateParts() {
	my $tplFile = $assistor->get_report_template_file('LOG');
    my $separator = "#NODE#";
    my $tplContent = $assistor->read_whole_file($tplFile);
    my $sepPos = index($tplContent, $separator);
    my $part1 = substr($tplContent, 0, $sepPos);
    my $part2 = substr($tplContent, $sepPos + length($separator));
	
    $GV->{TplParts} = {'userP1' => $part1, 'fileP1' => $part1, 'P2' => $part2};
    
	replacePart1PMS('user');
	replacePart1PMS('file');    

	replacePart2PMS(1);    
}

sub replacePart1PMS($){
	#PLAIN_REPORT#
	#MODULE#
	#MODULE_URI#
	#REVS_DATES#
	#DATE_SCOPE#
	#ACCOUNT#
	#FILTER_INFO#
	#ERROR#
	#FOC#
	#LOC#
	#LOG_FILE#
	#DF_FILE#
	#MODULE_PLAIN_REPORT#
	#GRPAH_ENTRY_PARAMS#
	#MFI_URL#
	#OTHER_NAME#
	my $viewType = $_[0];	
	my $part = $viewType eq 'user' ? \$GV->{TplParts}->{userP1} : \$GV->{TplParts}->{fileP1};
	my $date = $pms->{date} ? $pms->{date} : 'N/A';
	my $wids = $pms->{wids} ? $pms->{wids} : 'N/A';
	my $loc = $ccvUtil->formatLoc4UI($GV->{ViewlizeInfo}, $GV->{WithLoc});
	my $foc = $GV->{ViewlizeInfo}->{fileCnt};
	my $allPlainReportUrl = $assistor->transReportLocalPath2WebPath($GV->{AllBriefReportFile});
	my $modulePlainReportUrl = $assistor->transReportLocalPath2WebPath($GV->{ModuleBriefReportFile});
    my $gitLogFileUrl = $assistor->transOperateLocalPath2WebPath($GV->{LogFile});
    my $gitAllDfFileUrl = $assistor->transOperateLocalPath2WebPath($GV->{AllDfFile});
    my $graphDataFile = $assistor->transOperateLocalPath2WebPath($assistor->getSvnMoudleGraphDataFile($pms, $MID));
    my $mfi_file = $assistor->transOperateLocalPath2WebPath($assistor->getSvnMoudleFilesInfoDataFile($pms, $MID));
    
    $$part =~ s/#BODY_CLS#/svnLogReport/;
	$$part =~ s/#MODULE#/$GV->{GitInfo}->{id}/;
	$$part =~ s/#MODULE_URI#/$GV->{GitInfo}->{url}/;
	$$part =~ s/#REVS_DATES#/$pms->{rev}/;
	$$part =~ s/#DATE_SCOPE#/$date/;
	$$part =~ s/#ACCOUNT#/$wids/g;
	$$part =~ s/#FOC#/$foc/;
	$$part =~ s/#LOC#/$loc/;
	$$part =~ s/#PLAIN_REPORT#/$allPlainReportUrl/;
	$$part =~ s/#MODULE_PLAIN_REPORT#/$modulePlainReportUrl/;
	$$part =~ s/#LOG_FILE#/$gitLogFileUrl/;
	$$part =~ s/#DF_FILE#/$gitAllDfFileUrl/;
	$$part =~ s/#GRPAH_ENTRY_PARAMS#/$graphDataFile/;
	$$part =~ s/#MFI_URL#/$mfi_file/;
	$$part =~ s/#ERROR#/$GV->{Error}/;
	$$part =~ s/#GRAPH_HTML#/g.html/;
	
	my $filterInfo = $ccvUtil->getShownFilterInfo($pms->{OFilter});
    $$part =~ s/#FILTER_INFO#/$filterInfo/;
	
	my $urlToView;
	my $nameToView;
	if ($viewType eq 'user') {
		$urlToView = $assistor->transReportLocalPath2WebPath($GV->{FileReport});
		$nameToView = 'File';
	} else {
		$urlToView = $assistor->transReportLocalPath2WebPath($GV->{UserReport});
		$nameToView = 'User';		
	}
	$$part =~ s/#OTHER_URL#/$urlToView/;
	$$part =~ s/#OTHER_NAME#/$nameToView/;	
}

sub replacePart2PMS($) {
	my $part = \$GV->{TplParts}->{P2};
	
	my $ShowGraphEntry = $pms->{gopt}->{graph};	
	my $ShowSrcDetails = 0;
	my $error = $GV->{Error} eq "" ? 0 : 1;
	my $showBin = 1;
	my $showDir = 1;
    
    my $GV_IN_JS =<<GV_IN_JS;
{
	T_SNAP: "$T_SNAP",
	MID: "$MID",
	WithLoc: "$GV->{WithLoc}",
	ShowGraphEntry: "$ShowGraphEntry",
	ShowSrcDetails: "$ShowSrcDetails",
	Error: "$error",
	ShowBin: "$showBin",
	ShowDir: "$showDir",
	DF: "$GV->{AllDfFile}",	
	ReportType: "GIT_LOG"
}
GV_IN_JS
    
	$$part =~ s/#GV#/$GV_IN_JS/;
}

sub defReportElementEntryTpl() {
	$GV->{EntryTpl} = {};
	# . FOC, 
	# . LOC
	
	#
	# concern performace when huge amount plus/minus dom 
	# do not use later-event-bind, but use static in html
	#
	#
	my $plusMinusEvtDef = "onclick=\"showChildren(this);\"";
	
	$GV->{EntryTpl}->{UserEntryTpl} = "<li><span class=\"plus\" $plusMinusEvtDef></span><span class=\"userChangeinfo\">FOC: %04d LOC: %s</span> <span class=\"userName\">%s</span>\n<ul>\n";
	
	# . FILE_TYPE_CLZ
	# . REVS_CNT, 
	# . FILE_DIFF_PARAMS,
	# . CI_COMMENT,
	# . LOC, 
	# . FILE_LAST_REV_ACTION_TYPE_CLZ, 
	# . FILE, 
	# . FILE_TYPE(D, B)
	$GV->{EntryTpl}->{UserFileEntryTpl} = "<li class=\"%s\"><span class=\"plus\" $plusMinusEvtDef></span>CIS %03d - <a href=\"javascript: showDiff(%s);\"><span class=\"locInfo\" onmouseover=\"showTip('%s')\">%s</span> <span class=\"%s\">%s</span>%s</a>\n<ul>\n"; 
	# for binary or directory
	# . FILE_TYPE_CLZ
	# . REVS_CNT,
	# . CI_COMMENT,
	# . LOC, 
	# . FILE_LAST_REV_ACTION_TYPE_CLZ, 
	# . FILE, 
	# . FILE_TYPE(D/B)
	$GV->{EntryTpl}->{UserFileEntryTpl4BD} = "<li class=\"%s\"><span class=\"plus\" $plusMinusEvtDef></span>CIS %03d - <span class=\"locInfo\" onmouseover=\"showTip('%s')\">%s</span> <span class=\"%s\">%s</span>%s\n<ul>\n"; 
	
	# . TIME, 
	# . FILE_DIFF_PARAMS,
	# . CI_COMMENT,
	# . LOC,
	# . REV_ACTION_TYPE_CLZ,
	# . REV
	$GV->{EntryTpl}->{UserFileCiEntryTpl} = "<li><span class=\"ci\"></span><span class=\"revTime\">%s</span> <a href=\"javascript: showDiff(%s);\"><span class=\"locInfo\" onmouseover=\"showTip('%s')\">%s</span> <span class=\"%s\">r%s</span></a>\n";
	# for binary or directory
	# . TIME, 
	# . CI_COMMENT,
	# . LOC,
	# . REV_ACTION_TYPE_CLZ
	# . REV
	$GV->{EntryTpl}->{UserFileCiEntryTpl4BD} = "<li><span class=\"ci\"></span><span class=\"revTime\">%s</span> <span class=\"locInfo\" onmouseover=\"showTip('%s')\">%s</span> <span class=\"%s\">r%s</span>\n";

	
	# . FILE_TYPE_CLZ
	# . REVS_CNT, 
	# . FILE_DIFF_PARAMS,
	# . CI_COMMENT,
	# . LOC, 
	# . FILE_LAST_REV_ACTION_TYPE_CLZ, 
	# . FILE, 
	# . FILE_TYPE(D/B)
	$GV->{EntryTpl}->{FileEntryTpl} = "<li class=\"%s\"><span class=\"plus\" $plusMinusEvtDef></span>CIS %03d - <a href=\"javascript: showDiff(%s);\"><span class=\"locInfo\" onmouseover=\"showTip('%s')\">%s</span> <span class=\"%s\">%s</span></a>%s\n<ul>\n"; 
	# for binary or directory
	# . FILE_TYPE_CLZ
	# . REVS_CNT,
	# . CI_COMMENT,
	# . LOC,
	# . FILE_LAST_REV_ACTION_TYPE_CLZ,
	# . FILE,
	# . FILE_TYPE(D/B)
	$GV->{EntryTpl}->{FileEntryTpl4BD} = "<li class=\"%s\"><span class=\"plus\" $plusMinusEvtDef></span>CIS %03d - <span class=\"locInfo\" onmouseover=\"showTip('%s')\">%s</span> <span class=\"%s\">%s</span>%s\n<ul>\n"; 
	
	# . TIME, 
	# . FILE_DIFF_PARAMS, 
	# . CI_COMMENT,
	# . LOC,
	# . REV_ACTION_TYPE_CLZ
	# . REV,
	# . USER
	$GV->{EntryTpl}->{FileCiEntryTpl} = "<li><span class=\"ci\"></span><span class=\"revTime\">%s</span> <a href=\"javascript: showDiff(%s);\"><span class=\"locInfo\" onmouseover=\"showTip('%s')\">%s</span> <span class=\"%s\">r%s</span> <span class=\"ciRevUser\">%s</span></a>\n";
	# for binary or directory
	# . TIME, 
	# . CI_COMMENT,
	# . LOC,
	# . REV_ACTION_TYPE_CLZ
	# . REV,
	# . USER
	$GV->{EntryTpl}->{FileCiEntryTpl4BD} = "<li><span class=\"ci\"></span><span class=\"revTime\">%s</span> <span class=\"locInfo\" onmouseover=\"showTip('%s')\">%s</span> <span class=\"%s\">r%s</span> <span class=\"ciRevUser\">%s</span>\n";
}

sub _getFileInUI($) {
	my $file = $_[0];
	my $filesInfo = $GV->{ViewlizeInfo}->{FilesInfo};
	my $fileInUI = $file;
	my $fromPathSufixTpl = " <span class=\"fromPath\">(from %s : %s)</span>";
	if ($pathsInfo->{$file}->{info}->{fromPath}) {
		$fileInUI .= sprintf($fromPathSufixTpl, 
			$pathsInfo->{$file}->{info}->{fromPath},
			$pathsInfo->{$file}->{info}->{fromPathRev} || ''
		);
	}
	
	return $fileInUI;
}

sub writeUserViewItems() {
	my $usersInfo = $GV->{ViewlizeInfo}->{UsersInfo};
	my $revsInfo = $GV->{ViewlizeInfo}->{RevsInfo};
	my $pathsInfo = $GV->{ViewlizeInfo}->{PathsInfo};
	my @sortedKeys = sort { lc($a) cmp lc($b) } keys %{$usersInfo};
	my $cnt = $#sortedKeys + 1;
	my $usersOut = '';

	for (my $i = 0; $i < $cnt; $i++) {
		my $user = $sortedKeys[$i];
		my $userInfo = $usersInfo->{$user};
		if ($userInfo->{info}->{fileCnt} == 0) {
			next;
		}		
		
		my @sortedPaths = sort { lc($a) cmp lc($b) } keys %{$userInfo->{paths}};
		my $pathsCnt = $#sortedPaths + 1;
		$usersOut .= sprintf($GV->{EntryTpl}->{UserEntryTpl}, 
			$userInfo->{info}->{fileCnt},
			$ccvUtil->formatLoc4UI($userInfo->{info}, $GV->{WithLoc}),
			$user
		);
		plusUserBriefInfo($user, $userInfo->{info});
		
		for (my $j = 0; $j < $pathsCnt; $j++) {
			my $file = $sortedPaths[$j];
			my $fileInfo = $userInfo->{paths}->{$file};
			my $fileLastRev = $fileInfo->{revs}->[0];
			my $latestRevFileInfo = $revsInfo->{$fileLastRev}->{hashPaths}->{$file};
			my $fileType = $pathsInfo->{$file}->{info}->{type} || $latestRevFileInfo->{type} || 'B';
			my $fileInUI = _getFileInUI($file);
			if ($fileType eq 'T') {#text file
				$usersOut .= sprintf($GV->{EntryTpl}->{UserFileEntryTpl},
					$fileType,	
					$fileInfo->{info}->{revsCnt},
					$ccvUtil->getFileDiffParams($file, $fileLastRev, $latestRevFileInfo),
					$ccvUtil->replaceCharInComment($revsInfo->{$fileLastRev}->{comment}),
					$ccvUtil->formatLoc4UI($fileInfo->{info}, $GV->{WithLoc}),
					$ccvUtil->getFileUIClz($latestRevFileInfo->{action}),
					$fileInUI,
					$ccvUtil->getFileTypeIndicatorHtml($fileType)
				);				
			} else {#binary file, directory
				$usersOut .= sprintf($GV->{EntryTpl}->{UserFileEntryTpl4BD}, 
					$fileType,
					$fileInfo->{info}->{revsCnt},
					$ccvUtil->replaceCharInComment($revsInfo->{$fileLastRev}->{comment}),
					$ccvUtil->formatLoc4UI($fileInfo->{info}, $GV->{WithLoc}),
					$ccvUtil->getFileUIClz($latestRevFileInfo->{action}),
					$fileInUI,
					$ccvUtil->getFileTypeIndicatorHtml($fileType)
				);					
			}
			
			my $userFileRevsCnt = $#{$fileInfo->{revs}} + 1;
			for (my $k = 0; $k < $userFileRevsCnt; $k++) {
				my $rev = $fileInfo->{revs}->[$k];
				my $revFileInfo = $revsInfo->{$rev}->{hashPaths}->{$file};
				if ($fileType eq 'T') {#text file
					$usersOut .= sprintf($GV->{EntryTpl}->{UserFileCiEntryTpl}, 
						$revsInfo->{$rev}->{date},
						$ccvUtil->getFileDiffParams($file, $rev, $revFileInfo),
						$ccvUtil->replaceCharInComment($revsInfo->{$rev}->{comment}),
						$ccvUtil->formatLoc4UI($revFileInfo, $GV->{WithLoc}),
						$ccvUtil->getRevActionUIClz($revFileInfo->{action}),
						$rev
					);
				} else {#binary file, directory
					$usersOut .= sprintf($GV->{EntryTpl}->{UserFileCiEntryTpl4BD}, 
						$revsInfo->{$rev}->{date},
						$ccvUtil->replaceCharInComment($revsInfo->{$rev}->{comment}),
						$ccvUtil->formatLoc4UI($revFileInfo, $GV->{WithLoc}),
						$ccvUtil->getRevActionUIClz($revFileInfo->{action}),
						$rev
					);
				}
			}
			$usersOut .= "</ul>\n</li>\n";
		}
		
		$usersOut .= "</ul>\n</li>\n";
	}
	
	my $hUser = $GV->{H_UserReport};
	print $hUser $usersOut;
}

sub writeFileViewItems() {
	my $filesInfo = $GV->{ViewlizeInfo}->{PathsInfo};
	my $revsInfo = $GV->{ViewlizeInfo}->{RevsInfo};
	my $pathsInfo = $GV->{ViewlizeInfo}->{PathsInfo};
	my @sortedKeys = sort { lc($a) cmp lc($b) } keys %{$filesInfo};
	my $cnt = $#sortedKeys + 1;
	my $filesOut = '';	
	for (my $i = 0; $i < $cnt; $i++) {
		my $file = $sortedKeys[$i];
		my $fileInfo = $filesInfo->{$file};
		my $fileLastRev = $fileInfo->{revs}->[0];
		my $latestRevFileInfo = $revsInfo->{$fileLastRev}->{hashPaths}->{$file};
		my $fileType = $pathsInfo->{$file}->{info}->{type} || $latestRevFileInfo->{type} || 'B';
		my $fileInUI = _getFileInUI($file);
		if ($fileType eq 'T') {#text file
			$filesOut .= sprintf($GV->{EntryTpl}->{FileEntryTpl},
				$fileType,
				$fileInfo->{info}->{revsCnt},
				$ccvUtil->getFileDiffParams($file, $fileLastRev, $latestRevFileInfo),
				$ccvUtil->replaceCharInComment($revsInfo->{$fileLastRev}->{comment}),
				$ccvUtil->formatLoc4UI($fileInfo->{info}, $GV->{WithLoc}),
				$ccvUtil->getFileUIClz($latestRevFileInfo->{action}),
				$fileInUI,
				$ccvUtil->getFileTypeIndicatorHtml($fileType)
			);
		} else {#binary file, directory
			$filesOut .= sprintf($GV->{EntryTpl}->{FileEntryTpl4BD}, 
				$fileType,
				$fileInfo->{info}->{revsCnt},
				$ccvUtil->replaceCharInComment($revsInfo->{$fileLastRev}->{comment}),
				$ccvUtil->formatLoc4UI($fileInfo->{info}, $GV->{WithLoc}),
				$ccvUtil->getFileUIClz($latestRevFileInfo->{action}),
				$fileInUI,
				$ccvUtil->getFileTypeIndicatorHtml($fileType)
			);
		}		
		
		my $fileRevsCnt = $#{$fileInfo->{revs}} + 1;
		for (my $k = 0; $k < $fileRevsCnt; $k++) {
			my $rev = $fileInfo->{revs}->[$k];
			my $revFileInfo = $revsInfo->{$rev}->{hashPaths}->{$file};
			if ($fileType eq 'T') {#text file
				$filesOut .= sprintf($GV->{EntryTpl}->{FileCiEntryTpl}, 
					$revsInfo->{$rev}->{date},
					$ccvUtil->getFileDiffParams($file, $rev, $revFileInfo),
					$ccvUtil->replaceCharInComment($revsInfo->{$rev}->{comment}),
					$ccvUtil->formatLoc4UI($revFileInfo, $GV->{WithLoc}),
					$ccvUtil->getRevActionUIClz($revFileInfo->{action}),
					$rev,
					$revsInfo->{$rev}->{author}
				);
			} else {#binary file, directory
				$filesOut .= sprintf($GV->{EntryTpl}->{FileCiEntryTpl4BD}, 
					$revsInfo->{$rev}->{date},
					$ccvUtil->replaceCharInComment($revsInfo->{$rev}->{comment}),
					$ccvUtil->formatLoc4UI($revFileInfo, $GV->{WithLoc}),
					$ccvUtil->getRevActionUIClz($revFileInfo->{action}),
					$rev,
					$revsInfo->{$rev}->{author}
				);
			}			
		}
		$filesOut .= "</ul>\n</li>\n";
	}
	
	my $hFile = $GV->{H_FileReport};
	print $hFile $filesOut;	
}

sub plusUserBriefInfo($$) {
    my $user = $_[0];
    my $userInfo = $_[1];
 	
    $GV->{ModuleBriefInfo} .= sprintf("%s, %d, %d, %d, %d\n",
        $user, 
        $userInfo->{addLines} + $userInfo->{delLines},
		$userInfo->{addLines},
		$userInfo->{delLines},                  
        $userInfo->{fileCnt}
    );
    
    #followings for all modules's info sum
    $GV->{ModuleAndUserLocData}->{$MID}->{users}->{$user} = {};
    my $uData = $GV->{ModuleAndUserLocData}->{$MID}->{users}->{$user};
    $uData->{foc} = $userInfo->{fileCnt};
    $uData->{loc} = $userInfo->{addLines} + $userInfo->{delLines};
    $uData->{loc_added} = $userInfo->{addLines};
    $uData->{loc_deleted} = $userInfo->{delLines};
    #End     
}

sub generateBriefReportHeader() {
    $GV->{ModuleBriefInfo} = sprintf("Git Repository: %s (%s)\n; Branch/Revisions: %s; DateScope: %s; By: %s,,\n",
        $MID, 
        $GV->{GitInfo}->{url},
        $pms->{rev}, 
        $pms->{date},
        $pms->{wids}
    );
    
    my $overall = $GV->{ViewlizeInfo};
    $GV->{ModuleBriefInfo} .= sprintf("Author, LOC, +, -, FOC\nAll users, %d, %d, %d, %d\n\n", 
        $overall->{addLines} + $overall->{delLines},
		$overall->{addLines},
		$overall->{delLines},                  
        $overall->{fileCnt}
    );    
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
