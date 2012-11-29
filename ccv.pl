#!/usr/bin/perl -I ./thirds -w
# author: lilong'en(lilongen@163.com)
# date:   03/08/2010
#

use strict;
use English;
use Data::Dumper;
use Cwd;
use Assistor;
use CcvUtil;
use ApiInnerParamUtil;

sub main();

sub gen_report_file($$);
sub get_rdiff_log_revs_dates();
sub generateTasksQueue();
sub generateCvsModuleTasks($);
sub generateSvnModuleTasks($);
sub construct_rlog_analyse_cmd($);
sub construct_cvs_rdiff_analyse_cmd($);
sub construct_svn_diff_analyse_cmd($);
sub constructCCVQueueEntry($);
sub addTasksInfoContext($);
sub constructAndPersistenceTasksInfo();
sub persistencePMS();
sub constructSvnDiffCmd($$);


my $scriptName = $0;
my $cmdLine = join (" ", @ARGV);
my $paramUtil = new ApiInnerParamUtil("inner", $cmdLine);
my $pms = $paramUtil->constructPmsObjectFromInnerCmdLine();

my $assistor = new Assistor($pms->{cfg}, $pms->{T_SNAP});
my $ccvUtil = new CcvUtil();

if (!$pms->{T_SNAP}) {
	$pms->{T_SNAP} = $assistor->{tsnap};
}

$assistor->set_diff_revs_dates($pms);#pay attention to this
my $pl_path = getcwd;
my $modulesInfo = $assistor->getModules();
$assistor->injectRuntimeAccount2Modules($pms->{uid}, $pms->{upw});

my $moudlesCnt = $#{$modulesInfo};
my $_H_XLOG_ = undef;
my $_X_CCV_LOG_ = $assistor->get_specified_operate_file("PROGRESS_LOG");
my $revsDirUnderT_SNAP = $assistor->get_operate_revs_dates_dir_name($pms);

exit main();

sub main() {
    #class ConfigAssistor method get_config return value is reference to hash
    my $R_TEMPLATE      = $assistor->get_report_template_file("FRAME");            
    my $R_TOP_TEMPLATE  = $assistor->get_report_template_file("TOP");
    
    my $REPORT          = $assistor->read_whole_file($R_TEMPLATE);
    my $REPORT_TOP      = $assistor->read_whole_file($R_TOP_TEMPLATE);

    my $date            = $assistor->get_time_date();
    my $serial          = $assistor->get_time_serial();
    
    my $old_mask = umask(0);
    mkdir("web/reports/$date");
    mkdir("web/reports/$date/$serial");
        
    mkdir("operate/$date");
    mkdir("operate/$date/$serial");

    if (!open($_H_XLOG_, ">>", $_X_CCV_LOG_)) {
		print $_H_XLOG_ "Err: Can not create/open $_X_CCV_LOG_!\n";
	}
	my $shownCmdLine = $cmdLine;
	$shownCmdLine =~ s/-upw[^\s]+//g;
	$shownCmdLine =~ s/-uid[^\s]+//g;
    print $_H_XLOG_ "perl -w $scriptName $shownCmdLine\n\n";
    chdir("operate/$date/$serial");
     
    my $operate_path         = getcwd;
  
    mkdir($revsDirUnderT_SNAP);
    chdir($revsDirUnderT_SNAP);
  
    my $ld_entry 	= getcwd;
    
    my $report      = $REPORT;
    my $report_top  = $REPORT_TOP;
    my $counter     = 0;
    my $top_url     = "";
    
    $top_url = $assistor->transReportLocalPath2WebPath($assistor->get_specified_output_report_file({flag => "TOP", revs => $revsDirUnderT_SNAP}));

    my $main_url    = "";
    
    $report =~ s/#TOP#/$top_url/;
  
    for (my $j = 0; $j <= $moudlesCnt; $j++) {
    	my $moduleInfo 	= $modulesInfo->[$j];
        my $moudleId 	= $moduleInfo->{id};
        
        if ($pms->{mids} eq "*" || index(",$pms->{mids},", ",$moudleId,") != -1) {
			$counter ++;            
        } else {
        	next;
        }        
        
        mkdir($moudleId);

        if ($pms->{mode} == 0) {
        	if ($moduleInfo->{type} eq 'cvs') {
		        mkdir($moudleId . "/rev_files");
		        mkdir($moudleId . "/1.1");
		        mkdir($moudleId . "/head");
        	} else {
        		mkdir($moudleId . "/rev_df");
        		mkdir($moudleId . "/rev_co");
		        mkdir($moudleId . "/rev_src");
		        mkdir($moudleId . "/rev_src/init");
		        mkdir($moudleId . "/rev_src/head");
        	}
			if ($moduleInfo->{type} eq 'cvs') {
				$main_url = $assistor->transReportLocalPath2WebPath($assistor->get_specified_output_report_file({flag => "LOG_USERS", revs => $revsDirUnderT_SNAP, mid=> $moudleId}));	
			} else {
				$main_url = $assistor->transReportLocalPath2WebPath($assistor->get_specified_output_report_file({flag => "LOG_USERS", revs => $revsDirUnderT_SNAP, mid=> $moudleId}));	
			}
        	
        } elsif ($pms->{mode} == 1){
	        $main_url = $assistor->transReportLocalPath2WebPath($assistor->get_specified_output_report_file({flag => "DIFF_GROUP", revs => $revsDirUnderT_SNAP, mid=> $moudleId}));
	    } elsif ($pms->{mode} == 2){
        	if ($moduleInfo->{type} eq 'cvs') {
		        mkdir($moudleId . "/rev_files");
		        mkdir($moudleId . "/1.1");
		        mkdir($moudleId . "/head");
        	} else {
        		mkdir($moudleId . "/rev_df");
        		mkdir($moudleId . "/rev_co");
		        mkdir($moudleId . "/rev_src");
		        mkdir($moudleId . "/rev_src/init");
		        mkdir($moudleId . "/rev_src/head");
        	}
        	
        	my $df = "";
        	my $moduleURI = "";
	        if ($moduleInfo->{type} eq 'cvs') {
	        	$df = $assistor->transOperateLocalPath2WebPath($assistor->get_cvs_module_files_info_file($revsDirUnderT_SNAP, $moudleId));
	        	$moduleURI = $assistor->get_module_cvsroot_without_uid($moduleInfo) . "/" . $moduleInfo->{module};
			} else {
				$df = $assistor->transOperateLocalPath2WebPath($assistor->getSvnMoudleFilesInfoDataFile($pms, $moudleId));
				$moduleURI = $assistor->get_svn_module_url($moduleInfo, $pms->{rev});
			}
			
			$main_url = sprintf("/ccv/fsi.html?df=%s&moduleURI=%s",
							$df,
							$moduleURI
			);			
	    }
	    
        if ($counter == 1) {
            $report =~ s/#MAIN#/$main_url/;
        }
        
        #$report_top =~ s/((<div class="tabbertab" title=")#TITLE(" id=")#URL#("><\/div>))/$2$module_id$3$main_url$4\n$1/;
        $report_top =~ s/((<li><a id=")#URL#(" href="#tab-c">)#TITLE#(<\/a><\/li>))/$2$main_url$3$moudleId$4\n$1/;
    }
    #Add to adjust top height according to modules amount
    my $top_height = 40;
    if ($counter > 20) {
    	$top_height = 100;	
    } elsif ($counter > 10) {
    	$top_height = 70;	
    }
    $report =~ s/#HEIGHT#/$top_height/;    
    #End
    
    $report_top =~ s/((<li><a id=")#URL#(" href="#tab-c">)#TITLE#(<\/a><\/li>))//;
    chdir($pl_path);
    
    my $reportFrames 	= $assistor->get_specified_output_report_file({flag => "FRAME", revs => $revsDirUnderT_SNAP});
    my $reportTop 		= $assistor->get_specified_output_report_file({flag => "TOP", revs => $revsDirUnderT_SNAP});
     
    gen_report_file($reportFrames, \$report);
    gen_report_file($reportTop, \$report_top);
    
    chdir($operate_path);
    chdir($pl_path);
    
    if (defined($_H_XLOG_)) {
        close($_H_XLOG_);
    }
    umask($old_mask);
	
	persistencePMS();
	
	constructAndPersistenceTasksInfo();
	
	my $flagInBG = $pms->{fromCgi} == 1 ? "&" : "";
	my $runTaskManager = "perl -w task.manager.pl \"$pms->{T_SNAP}\" $flagInBG";
    system($runTaskManager);
    
    return 0;
}

sub persistencePMS() {
	$ccvUtil->dumpFile($assistor->get_specified_operate_file("PMS"), $pms);
}

sub constructAndPersistenceTasksInfo() {
    my $tasksQueue = generateTasksQueue();
	my $tasksInfo = {};
	$tasksInfo->{queue} = $tasksQueue;
	addTasksInfoContext($tasksInfo);

	my $queueFile = $assistor->get_specified_operate_file("TASK_QUEUE");	
    $ccvUtil->dumpFile($queueFile, $tasksInfo);	
}

sub addTasksInfoContext($) {
	my $tasksInfo = $_[0];
    my $htmlReportURL  = $assistor->transReportLocalPath2WebPath($assistor->get_specified_output_report_file({flag => "FRAME", revs => $revsDirUnderT_SNAP}));
    my $plainReportURL = $assistor->transReportLocalPath2WebPath($assistor->get_brief_report_file());
	my $log_entry = constructCCVQueueEntry($htmlReportURL);

	$tasksInfo->{context} = {};
	$tasksInfo->{context}->{fromCgi} 			= $pms->{fromCgi};

	$tasksInfo->{context}->{reportMode}			= $pms->{mode};
	$tasksInfo->{context}->{revsDirUnderT_SNAP}	= $revsDirUnderT_SNAP;

	$tasksInfo->{context}->{htmlReportURL} 		= $htmlReportURL;
	$tasksInfo->{context}->{plainReportURL} 	= $plainReportURL;
	$tasksInfo->{context}->{queryLogEntry} 		= $log_entry;	
}

sub constructCCVQueueEntry($) {
	my $htmlReportURL = $_[0];
    #Log entry example
    #ecc<|>N/A<|>N/A<|>2007-10-23 05:28:35<|>main<|>http://172.16.251.245:80/ccv/reports/2007-10-23/052835/rpt.html
	
    my $history = "";
    my $dt = $assistor->get_friendly_time();
    my $LOG_SP = "<|>";
    my $modules = $pms->{mids};

    $modules =~ s/^,//;
    $modules =~ s/,{2,}$//g;
	
	if ($pms->{mode} == 0) {#log
	    $history = sprintf("%s$LOG_SP%s$LOG_SP%s$LOG_SP%s", 
	                        $modules,
	                        ($pms->{date} eq "" ? "N/A" : $pms->{date}), 
	                        ($pms->{wids} eq "" ? "N/A" : $pms->{wids}),
	                        $dt);
    } elsif ($pms->{mode} == 1) {#diff
	    $history = sprintf("%s$LOG_SP%s$LOG_SP%s$LOG_SP%s", 
                    $modules,
                    "", 
                    "",
                    $dt);
    } elsif ($pms->{mode} == 2) {#file
	    $history = sprintf("%s$LOG_SP%s$LOG_SP%s$LOG_SP%s", 
                    $modules,
                    "", 
                    "",
                    $dt);
    }
    
    my $revs_dates  = (($pms->{mode} == 0 ||  $pms->{mode} == 2) ? $revsDirUnderT_SNAP : get_rdiff_log_revs_dates());
    my $log_entry = sprintf("%s$LOG_SP%s$LOG_SP%s$LOG_SP%s\n",
                              $pms->{mode},
                              $history,
							  $revs_dates,                            
                              $htmlReportURL);
                              
	return $log_entry;
}

sub gen_report_file($$) {
    my $file_name = $_[0];
    my $file_content = $_[1];
    my $h_file;
    
    if (!open($h_file, ">>", $file_name)) {
		print $_H_XLOG_ "Err: Can not create/open $file_name!\n";
		
		return 1;
	}         
    
    print $h_file $$file_content;
    close($h_file);
    
    return 0;
}

sub get_rdiff_log_revs_dates() {
	my $revs_dates_log = "";
	if ($pms->{dfDates} ne "") {
		if ($pms->{d1} eq "" || $pms->{d2} eq "") {
			$revs_dates_log = "Date1: ";
			$revs_dates_log .= ($pms->{d1} eq "" ? $pms->{d2} : $pms->{d1});
			$revs_dates_log .= " Date2: HEAD(MAIN)"
		} else {
			$revs_dates_log = "Date1: $pms->{d1} Date2: $pms->{d2}";
			
		}
	} 
	
	if ($pms->{dfRevs} ne "") {
		if ($pms->{r1} eq "" || $pms->{r2} eq "") {
			$revs_dates_log = "Rev1: ";
			$revs_dates_log .= ($pms->{r1} eq "" ? $pms->{r2} : $pms->{r1});
			$revs_dates_log .= " Rev2: HEAD(MAIN)"
		} else {
			$revs_dates_log = "Rev1: $pms->{r1} Rev2: $pms->{r2}";
			
		}
	} 	   	

	return 	$revs_dates_log;
}

sub generateCvsModuleTasks($) {
	my $moduleInfo = $_[0];
	
    my $moduleName = $moduleInfo->{module};
    my $logFile    = $moduleInfo->{log};
    my $diffFile   = $moduleInfo->{diff};
    my $moudleId   = $moduleInfo->{id};
    my $cvsroot = $assistor->get_module_cvsroot($moduleInfo);
    my $cvsrootNoUID = $assistor->get_module_cvsroot_without_uid($moduleInfo);
    my $operatePath = $assistor->get_operate_revs_location($assistor->get_operate_revs_dates_dir_name($pms));
	
	my $moduleTasks = [];
	if ($pms->{mode} == 0) { #rlog
	    my $revRestrict = (uc($pms->{rev}) eq "MAIN") ? "" : "-r$pms->{rev}";
	    my $dateRestrict = ($pms->{date} eq "") ? "" : "-d\"$pms->{date}\"";
	    
	    #get rlog
	    my $taskrLog = {};
    	$taskrLog->{cmd} = "cvs -Q -d $cvsroot rlog -N $revRestrict $dateRestrict \"$moduleName\" > $logFile 2>&1";
    	$taskrLog->{type} = "cvs";
    	$taskrLog->{mode} = $moduleInfo->{mode};#pserver, ext
		$taskrLog->{workPath} = $operatePath;
		$taskrLog->{title} = "<b>$moudleId</b>";
		$taskrLog->{desc} = "$moduleName - $cvsrootNoUID";
		push(@{$moduleTasks}, $taskrLog);
    	#End
		
		#check out 1.1 version, can not use cvs export , cvs can not export r1.1
	    if ($pms->{rev} eq "MAIN") {
	    	my $taskCO11 = {};
	    	
	    	$taskCO11->{cmd} = "cvs -Q -d $cvsroot co -r1.1 \"$moduleName\" 2>&1";
	    	$taskCO11->{type} = "cvs";
	    	$taskCO11->{mode} = $moduleInfo->{mode};
			$taskCO11->{workPath} = $operatePath . $moudleId . "/1.1";
			$taskCO11->{title} = "";
			$taskCO11->{desc} = "";
			push(@{$moduleTasks}, $taskCO11);		    	
	    }
	    #End
	    
	    #check out latest, can not use cvs export , cvs can not export r1.1
	    if ($pms->{gopt}->{graph}) {
	    	my $taskCO = {};
	    	
	    	$taskCO->{cmd} = "cvs -Q -d $cvsroot co $revRestrict \"$moduleName\" 2>&1";
	    	$taskCO->{type} = "cvs";
	    	$taskCO->{mode} = $moduleInfo->{mode};
			$taskCO->{workPath} = $operatePath . $moudleId . "/head";
			$taskCO->{title} = "";
			$taskCO->{desc} = "";
			push(@{$moduleTasks}, $taskCO);	
	    }
	    #End
	    
		my $taskAnalyse = {};
		$taskAnalyse->{cmd} = construct_rlog_analyse_cmd($moudleId);		
		$taskAnalyse->{workPath} = "";
		$taskAnalyse->{title} = "";
		$taskAnalyse->{desc} = "";
		push(@{$moduleTasks}, $taskAnalyse);
		
	    #stat. module files when need graph
	    if ($pms->{gopt}->{graph}) {
	    	my $modulePath = $assistor->get_module_co_head_path($revsDirUnderT_SNAP, $moudleId);
	    	my $statDirectory = $moduleName;
	    	if ($moduleName =~ m|^([^/]+)/.*$|) {#cvs module
	    		$statDirectory = $1;
	    	}

	    	my $taskStatFiles = {};
	    	$taskStatFiles->{cmd} = "perl -w stat.files.pl \"$pms->{T_SNAP}\" \"$modulePath\" \"$statDirectory\"";
			$taskStatFiles->{workPath} = "";
			$taskStatFiles->{title} = "";
			$taskStatFiles->{desc} = "";
			push(@{$moduleTasks}, $taskStatFiles);
			
	    	my $taskDrawGraph = {};
	    	$taskDrawGraph->{cmd} = "perl -w draw.graph.pl \"$modulePath\"";
			$taskDrawGraph->{workPath} = "";
			$taskDrawGraph->{title} = "";
			$taskDrawGraph->{desc} = "";
			push(@{$moduleTasks}, $taskDrawGraph);				
	    }
	    #End			
	    
	} elsif($pms->{mode} == 1) {#rdiff
		my $revs = "";
		my $dates = "";
		if ($pms->{r1} ne "" || $pms->{r2} ne "") {
			$revs = (($pms->{r1} ne "") ? "-r$pms->{r1}" : "") . (($pms->{r2} ne "") ? " -r$pms->{r2}" : "");
		} else {
			$dates = (($pms->{d1} ne "") ? "-D$pms->{d1}" : "") . (($pms->{d2} ne "") ? " -D$pms->{d2}" : "");
		}
		my $taskrDiff = {};
    	$taskrDiff->{cmd} = "cvs -Q -d $cvsroot rdiff -u $revs $dates \"$moduleName\" > $diffFile 2>&1";
    	$taskrDiff->{type} = "cvs";
    	$taskrDiff->{mode} = $moduleInfo->{mode};
		$taskrDiff->{workPath} = $operatePath;
		$taskrDiff->{title} = "<b>$moudleId</b>";
		$taskrDiff->{desc} = "$moduleName - $cvsrootNoUID";
		push(@{$moduleTasks}, $taskrDiff);
		
		my $taskAnalyse = {};
		$taskAnalyse->{cmd} = construct_cvs_rdiff_analyse_cmd($moudleId);		
		$taskAnalyse->{workPath} = "";
		$taskAnalyse->{title} = "";
		$taskAnalyse->{desc} = "";
		push(@{$moduleTasks}, $taskAnalyse);
	} elsif($pms->{mode} == 2) {#file
	    my $revRestrict = (uc($pms->{rev}) eq "MAIN") ? "" : "-r$pms->{rev}";
	    #check out latest, can not use cvs export , cvs can not export r1.1
    	my $taskCO = {};
    	$taskCO->{cmd} = "cvs -Q -d $cvsroot co $revRestrict \"$moduleName\" 2>&1";
    	$taskCO->{type} = "cvs";
    	$taskCO->{mode} = $moduleInfo->{mode};
		$taskCO->{workPath} = $operatePath . $moudleId . "/head";
		$taskCO->{title} = "<b>$moudleId</b>";
		$taskCO->{desc} = "$moduleName - $cvsrootNoUID";
		push(@{$moduleTasks}, $taskCO);	
	    #End
	    		
    	my $modulePath = $assistor->get_module_co_head_path($revsDirUnderT_SNAP, $moudleId);
    	my $statDirectory = $moduleName;
    	if ($moduleName =~ m|^([^/]+)/.*$|) {#cvs Module
    		$statDirectory = $1;
    	}
    	
    	my $taskStatFiles = {};
    	$taskStatFiles->{cmd} = "perl -w stat.files.pl \"$pms->{T_SNAP}\" \"$modulePath\" \"$statDirectory\"";
		$taskStatFiles->{workPath} = "";
		$taskStatFiles->{title} = "";
		$taskStatFiles->{desc} = "";
		push(@{$moduleTasks}, $taskStatFiles);
	}
	
	return $moduleTasks;
}


sub generateSvnModuleTasks($) {
	my $moduleInfo = $_[0];
	
    my $moduleName = $moduleInfo->{module};
    my $logFile    = $moduleInfo->{log};
    my $diffFile   = $moduleInfo->{diff};
    my $moudleId   = $moduleInfo->{id};
    my $svnModuleUrl= "";
    my $operatePath = $assistor->get_operate_revs_location($assistor->get_operate_revs_dates_dir_name($pms));
	
	my $moduleTasks = [];
	if ($pms->{mode} == 0) { # log
		$svnModuleUrl = $assistor->get_svn_module_url($moduleInfo, $pms->{rev});
	    #get svn log
	    my $taskrLog = {};
	    
	    my $dateScale = length($pms->{date}) > 0 ? "-r\"" . $ccvUtil->convertDateLogic2SvnNeeded($pms->{date}) . "\"" : "";
	    my $revsInfo = $assistor->getSvnLogRevsInfo($pms->{rev});
	    if (0) {
	    	
	    }
	    if ($ccvUtil->isAnonymousAccessSVN($moduleInfo)) {
	        $taskrLog->{cmd} = "svn log --no-auth-cache --non-interactive --trust-server-cert -v $dateScale \"$svnModuleUrl\" > $logFile 2>&1";
	    } else {
    	    $taskrLog->{cmd} = "svn log --no-auth-cache --non-interactive --trust-server-cert --username \"$moduleInfo->{account_id}\" --password \"$moduleInfo->{account_pw}\" -v $dateScale \"$svnModuleUrl\" > $logFile 2>&1";
    	}
    	$taskrLog->{type} = "svn";
    	$taskrLog->{mode} = $moduleInfo->{mode};#file, svn, svn+ssh, http, https
		$taskrLog->{workPath} = $operatePath;
		$taskrLog->{title} = "<b>$moudleId</b>";
		$taskrLog->{desc} = "$moduleName - $svnModuleUrl";
		push(@{$moduleTasks}, $taskrLog);
		#End
		
		#svn log analyse
	    my $taskAnalyse = {};
    	$taskAnalyse->{cmd} = "perl -w analyse.svn.log.pl -f\"$pms->{cfg}\" -t\"$pms->{T_SNAP}\" -m\"$moudleId\"";
    	$taskAnalyse->{type} 	= "svn";
    	$taskAnalyse->{mode} 	= $moduleInfo->{mode};#file, svn, svn+ssh, http, https
		$taskAnalyse->{workPath}= "";
		$taskAnalyse->{title} 	= "<b>$moudleId</b>";
		$taskAnalyse->{desc} 	= "$moduleName - $svnModuleUrl";
		push(@{$moduleTasks}, $taskAnalyse);
		#End
		if ($pms->{gopt}->{OSvnWithLoc}) {
			#processor base on svn module log parsed info
		    my $taskParsedInfoMgr = {};
	    	$taskParsedInfoMgr->{cmd} = "perl -w svn.log.locer.pl -f\"$pms->{cfg}\" -t\"$pms->{T_SNAP}\" -m\"$moudleId\"";
	    	$taskParsedInfoMgr->{type} = "svn";
	    	$taskParsedInfoMgr->{mode} = $moduleInfo->{mode};#file, svn, svn+ssh, http, https
			$taskParsedInfoMgr->{workPath} = '';
			$taskParsedInfoMgr->{title} = "<b>$moudleId</b>";
			$taskParsedInfoMgr->{desc} = "$moduleName - $svnModuleUrl";
			push(@{$moduleTasks}, $taskParsedInfoMgr);
			#End			
		}
		
	    #stat files & generate, output graph json data
	    if ($pms->{gopt}->{graph}) {
	    	my $modulePath = "$operatePath$moudleId";
	    	my $statDirectory = $moduleName;
	    	if ($moduleName =~ m|^.*/([^/]+)$|) {#svn module
	    		$statDirectory = $1;
	    	}
	    	my $srcHeadLocation = "$modulePath/rev_src/head";
			
			my $taskCoHead = {};
		    if ($ccvUtil->isAnonymousAccessSVN($moduleInfo)) {
		        $taskCoHead->{cmd} = "svn export --no-auth-cache --non-interactive --trust-server-cert \"$svnModuleUrl\"";
		    } else {
	    	    $taskCoHead->{cmd} = "svn export --no-auth-cache --non-interactive --trust-server-cert --username \"$moduleInfo->{account_id}\" --password \"$moduleInfo->{account_pw}\" \"$svnModuleUrl\"";
	    	}
	    	$taskCoHead->{type} = "svn";
	    	$taskCoHead->{mode} = $moduleInfo->{mode};#file, svn, svn+ssh, http, https
			$taskCoHead->{workPath} = $srcHeadLocation;
			$taskCoHead->{title} = "<b>$moudleId</b>";
			$taskCoHead->{desc} = "$moduleName - $svnModuleUrl";
			push(@{$moduleTasks}, $taskCoHead);

	    	my $taskStatFiles = {};
	    	$taskStatFiles->{cmd} = "perl -w stat.files.pl \"$pms->{T_SNAP}\" \"$srcHeadLocation\" \"$statDirectory\"";
			$taskStatFiles->{workPath} = "";
			$taskStatFiles->{title} = "";
			$taskStatFiles->{desc} = "";
			push(@{$moduleTasks}, $taskStatFiles);
			
	    	my $taskGenGraphData = {};
	    	$taskGenGraphData->{cmd} = "perl -w gen.graph.data.pl \"$modulePath\"";
			$taskGenGraphData->{workPath} = "";
			$taskGenGraphData->{title} = "";
			$taskGenGraphData->{desc} = "";
			push(@{$moduleTasks}, $taskGenGraphData);				
	    }
	    #End
	    		
		#generate report base on log & diff parsed data
	    my $taskGenReport = {};
    	$taskGenReport->{cmd} = "perl -w gen.svn.log.report.pl -f\"$pms->{cfg}\" -t\"$pms->{T_SNAP}\" -m\"$moudleId\"";
    	$taskGenReport->{type} = "svn";
    	$taskGenReport->{mode} = $moduleInfo->{mode};#file, svn, svn+ssh, http, https
		$taskGenReport->{workPath} = '';
		$taskGenReport->{title} = "<b>$moudleId</b>";
		$taskGenReport->{desc} = "$moduleName - $svnModuleUrl";
		push(@{$moduleTasks}, $taskGenReport);
		#End
	} elsif ($pms->{mode} == 1) {# diff
		$svnModuleUrl = $assistor->get_svn_module_url($moduleInfo, "", "trunk");
		my $dfOutFile = $operatePath . $moduleInfo->{diff};
		my $taskrDiff = {};
    	$taskrDiff->{cmd} = constructSvnDiffCmd($moduleInfo, $dfOutFile);
    	$taskrDiff->{type} = "svn";
    	$taskrDiff->{mode} = $moduleInfo->{mode};
		$taskrDiff->{workPath} = '';
		$taskrDiff->{title} = "<b>$moudleId</b>";
		$taskrDiff->{desc} = "$moduleName - $svnModuleUrl";
		push(@{$moduleTasks}, $taskrDiff);
		
		my $taskAnalyse = {};
		$taskAnalyse->{cmd} = construct_svn_diff_analyse_cmd($moudleId);		
		$taskAnalyse->{workPath} = "";
		$taskAnalyse->{title} = "";
		$taskAnalyse->{desc} = "";
		push(@{$moduleTasks}, $taskAnalyse);		
	} elsif ($pms->{mode} == 2) {# file
		$svnModuleUrl = $assistor->get_svn_module_url($moduleInfo, $pms->{rev});
    	my $modulePath = "$operatePath$moudleId";
    	my $statDirectory = $moduleName;
    	if ($moduleName =~ m|^.*/([^/]+)$|) {#svn module
    		$statDirectory = $1;
    	}
    	my $srcHeadLocation = "$modulePath/rev_src/head";
		
		my $taskCoHead = {};
	    if ($ccvUtil->isAnonymousAccessSVN($moduleInfo)) {
	        $taskCoHead->{cmd} = "svn export --no-auth-cache --non-interactive --trust-server-cert \"$svnModuleUrl\"";
	    } else {
    	    $taskCoHead->{cmd} = "svn export --no-auth-cache --non-interactive --trust-server-cert --username \"$moduleInfo->{account_id}\" --password \"$moduleInfo->{account_pw}\" \"$svnModuleUrl\"";
    	}
    	$taskCoHead->{type} = "svn";
    	$taskCoHead->{mode} = $moduleInfo->{mode};#file, svn, svn+ssh, http, https
		$taskCoHead->{workPath} = $srcHeadLocation;
		$taskCoHead->{title} = "<b>$moudleId</b>";
		$taskCoHead->{desc} = "$moduleName - $svnModuleUrl";
		push(@{$moduleTasks}, $taskCoHead);

    	my $taskStatFiles = {};
    	$taskStatFiles->{cmd} = "perl -w stat.files.pl \"$pms->{T_SNAP}\" \"$srcHeadLocation\" \"$statDirectory\"";
		$taskStatFiles->{workPath} = "";
		$taskStatFiles->{title} = "";
		$taskStatFiles->{desc} = "";
		push(@{$moduleTasks}, $taskStatFiles);	
	}
	
	return $moduleTasks;
}

sub constructSvnDiffCmd($$) {
	my $moduleInfo = $_[0];
	my $dfOutFile = $_[1];
	
	my $url1 = '';
	my $url2 = '';
	my $svnDfCmd = '';
	
	if ($pms->{dfAgainst} eq "revs") { #revs diff
		if ($pms->{rd1b} eq "OnTrunk" || $pms->{rd1b} eq "OnBranch") {
			$url1 = ($pms->{rd1b} eq "OnTrunk") ? $assistor->get_svn_module_url($moduleInfo, "", "trunk") : $assistor->get_svn_module_url($moduleInfo, $pms->{bb}, "branch");
			#-r%r1:%r2
			$svnDfCmd = sprintf("svn diff %s --no-auth-cache --non-interactive --trust-server-cert --username \"%s\" --password \"%s\" -r \"%s:%s\" \"%s\" > \"%s\" 2>&1",
				$pms->{dfOpts}->{svn},
				$moduleInfo->{account_id},
				$moduleInfo->{account_pw},
				$pms->{r1},
				$pms->{r2},
				$url1,
				$dfOutFile
			);				
		} else {
			if ($pms->{rd1b} eq "trunk") {
				$url1 = $assistor->get_svn_module_url($moduleInfo, "", "trunk");
			} elsif ($pms->{rd1b} eq "branch") {
				$url1 = $assistor->get_svn_module_url($moduleInfo, $pms->{r1}, "branch");
			} else {#tag
				$url1 = $assistor->get_svn_module_url($moduleInfo, $pms->{r1}, "tag");
			}
			
			if ($pms->{rd2b} eq "trunk") {
				$url2 = $assistor->get_svn_module_url($moduleInfo, "", "trunk");
			} elsif ($pms->{rd2b} eq "branch") {
				$url2 = $assistor->get_svn_module_url($moduleInfo, $pms->{r2}, "branch");
			} else {#tag
				$url2 = $assistor->get_svn_module_url($moduleInfo, $pms->{r2}, "tag");
			}
			
			$svnDfCmd = sprintf("svn diff %s --no-auth-cache --non-interactive --trust-server-cert --username \"%s\" --password \"%s\" \"%s\" \"%s\"> \"%s\" 2>&1",
				$pms->{dfOpts}->{svn},
				$moduleInfo->{account_id},
				$moduleInfo->{account_pw},
				$url1,
				$url2,
				$dfOutFile
			);				
		}
	} else {
		if ($pms->{rd1b} eq "OnTrunk") {
			$url1 = $assistor->get_svn_module_url($moduleInfo, "", "trunk");
		} elsif ($pms->{rd1b} eq "OnBranch") {
			$url1 = $assistor->get_svn_module_url($moduleInfo, $pms->{bb}, "branch");
		}
		
		#-r{2010-12-1}:{2010-10-1}
		$svnDfCmd = sprintf("svn diff %s --no-auth-cache --non-interactive --trust-server-cert --username \"%s\" --password \"%s\" -r \"{%s}:{%s}\" \"%s\" > \"%s\" 2>&1",
			$pms->{dfOpts}->{svn},
			$moduleInfo->{account_id},
			$moduleInfo->{account_pw},
			$ccvUtil->convertDate2SvnFormat($pms->{d1}),
			$ccvUtil->convertDate2SvnFormat($pms->{d2}),
			$url1,
			$dfOutFile
		);	
	}
	
	return $svnDfCmd;
}

sub generateTasksQueue() {
	my $tasksQueue = [];
	
    for (my $j = 0; $j <= $moudlesCnt; $j++) {
    	my $moduleInfo = $modulesInfo->[$j];
        my $moudleId = $moduleInfo->{id};
        
		if (!($pms->{mids} eq "*" || index(",$pms->{mids},", ",$moudleId,") != -1)) {
			next;	
		}
		
		my $moduleTasks = (uc($moduleInfo->{type}) eq "CVS") ? generateCvsModuleTasks($moduleInfo) : generateSvnModuleTasks($moduleInfo);
		
		push(@{$tasksQueue}, $moduleTasks);
    }
    
    return $tasksQueue;
}

sub construct_rlog_analyse_cmd($){
    my $mid = $_[0];

    my $cmd = sprintf("perl -w \"%s\" \"%s\" \"%s\" \"%s\" \"%s\" \"%s\" \"%s\" \"%s\" \"%s\" \"%s\" \"%s\" \"%s\"", 
                        "analyse.cvs.log.pl",
                        "-f" . $pms->{cfg},
                        "-t" . $pms->{T_SNAP},
                        "-r" . $pms->{rev},
                        "-m" . $mid,
                        "-d" . $pms->{date},
                        "-w" . $pms->{wids},
                        "-gm".  $pms->{gopt}->{graph},
                        "-arm". $pms->{gopt}->{allRevs},
                        "-sbm". $pms->{gopt}->{statBin},
                        "-sbl". $pms->{gopt}->{statBinLines},
                        "-nsd". $pms->{gopt}->{notStatDeleted});
    
    return $cmd;
}

sub construct_cvs_rdiff_analyse_cmd($) {
	my $mid = $_[0];
    return sprintf("perl -w \"%s\" \"%s\" \"%s\" \"%s\" \"%s\" \"%s\" \"%s\" \"%s\"", 
                        "analyse.cvs.rdiff.pl",
                        "-f"  . $pms->{cfg},
                        "-t"  . $pms->{T_SNAP},
                        "-r1" . $pms->{r1},
                        "-r2" . $pms->{r2},
                        "-D1" . $pms->{d1},
                        "-D2" . $pms->{d2},
                        "-m"  . $mid);
}

sub construct_svn_diff_analyse_cmd($) {
	my $mid = $_[0];
    return sprintf("perl -w \"%s\" \"%s\" \"%s\" \"%s\"", 
                        "analyse.svn.diff.pl",
                        "-f"  . $pms->{cfg},
                        "-t"  . $pms->{T_SNAP},
                        "-m"  . $mid);
}
