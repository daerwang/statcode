#!/usr/bin/perl -I ./thirds -w
# author: lilong'en(lilongen@163.com)
# date:   03/08/2010

use strict;
use English;
use Data::Dumper;
use Cwd;
use Assistor;
use CcvUtil;

sub main();
sub formatReportURL();
sub logCcvRunningProgress($$);
sub statAllModules();
sub mergeModulesInfoReports();
sub executeQueue();

my $pl_path = getcwd;

my $T_SNAP = $ARGV[0];
my $assistor = new Assistor(undef, $T_SNAP);
my $ccvUtil = new CcvUtil();

my $tasksInfo = $ccvUtil->loadFile($assistor->get_specified_operate_file("TASK_QUEUE"));
my $pms = $ccvUtil->loadFile($assistor->get_specified_operate_file("PMS"));

my $fromCgi 		= $tasksInfo->{context}->{fromCgi};
my $htmlReportURL 	= $tasksInfo->{context}->{htmlReportURL};
my $plainReportURL 	= $tasksInfo->{context}->{plainReportURL};
my $queryLogEntry 	= $tasksInfo->{context}->{queryLogEntry};

my $H_LOG = undef;

exit main();

sub main() {
	if (!open($H_LOG, ">>", $assistor->get_specified_operate_file("PROGRESS_LOG"))) {
	   return 1;
	}
	
	executeQueue();
	
	my $formatedURL = formatReportURL();
	logCcvRunningProgress($H_LOG, $formatedURL);
	close($H_LOG);
	
	if ($pms->{mode} == 0 || $pms->{mode} == 1) {
		statAllModules();
		mergeModulesInfoReports();
	}
	
	$assistor->logCcvQueryEntry($queryLogEntry);
	
	return 0;
}

sub executeQueue() {
	my $tasksQueue 	= $tasksInfo->{queue};
	my $queueCnt 	= $#{$tasksQueue} + 1;	
	
	for (my $i = 0; $i < $queueCnt; $i++) {
		my $moduleTasks = $tasksQueue->[$i];
		my $moduleTasksCnt = $#{$moduleTasks} + 1;
		
		for (my $j = 0; $j < $moduleTasksCnt; $j++) {
			my $logInfo = "";
			if ($j == 0) {
				$logInfo = $moduleTasks->[$j]->{title};
				
				my $queueProgressInfo = "";
				if ($queueCnt > 1) {
					$queueProgressInfo = "<b>(" . ($i + 1) . "/$queueCnt)</b>";
				}
				
				$logInfo .= " " . $queueProgressInfo . "\n";					
			}
			
			if ($moduleTasks->[$j]->{desc} ne "") {
				$logInfo .= $moduleTasks->[$j]->{desc} . "\n";				
			}
			
			my $moduleProgressInfo = "<span class='itemProgressIndicator'>" . ($j + 1) . "/$moduleTasksCnt ...</span>";
			
			$logInfo .= $moduleTasks->[$j]->{cmd} . " ($moduleProgressInfo)\n";
			
			
			if ($j == $moduleTasksCnt - 1) {
				$logInfo .= "\n";
			}
			
			logCcvRunningProgress($H_LOG, $logInfo);
			
			if ($moduleTasks->[$j]->{workPath} ne "") {
				chdir($moduleTasks->[$j]->{workPath});	
				system($moduleTasks->[$j]->{cmd});
				chdir($pl_path);
			} else {
				system($moduleTasks->[$j]->{cmd});				
			}						
		}
	}	
}

sub logCcvRunningProgress($$) {
	my $H_LOG = $_[0];
	my $logInfo = $_[1];
	
	if (!$logInfo) {
		return;
	}
	
	if (index($logInfo, "cvs") != -1) {
		$logInfo =~ s|(:pserver:[^\s]+:)\w+?(@)|$1\*\*\*$2|; #hide cvs account password
	}
	
	if (index($logInfo, "svn") != -1) {
		$logInfo =~ s|(--password)\s*\"[^\"]*\"|$1 \"\*\*\*\"|; #hide svn account password
	}
	
	print $H_LOG $logInfo;
	
	if ($fromCgi == 0) {
		print $logInfo;
	}
}


sub formatReportURL() {
    my $out .= "\n<b><font color='#000000'>Generated reports: </font></b>";
   
    $out .= sprintf("\nDetailed report(html):\n<a href=\"%s\" target='_blank'><font style='color: #0000ff;'>%s</font></a>",
                    $htmlReportURL,
                    $htmlReportURL);
    if ($pms->{mode} != 2) {
    	$out .= sprintf("\n\nBrief report(plain):\n<a href=\"%s\" target='_blank'><font style='color: #0000ff;'>%s</font></a>\n\n",
                    $plainReportURL,
                    $plainReportURL);                    
	}
    
    $out .= "<DONE></DONE>\n"; 
       
    return $out;
}

sub statAllModules() {
	my $all_modules_info = $ccvUtil->loadFile($assistor->get_all_modules_sum_info_data_file());
	my $out_info = {};
	$out_info->{foc} = 0;
	$out_info->{loc} = 0;
	$out_info->{loc_added} = 0;
	$out_info->{loc_deleted} = 0;
	$out_info->{users} = {};
	
	for my $mid (keys %{$all_modules_info}) {
		$out_info->{foc} += $all_modules_info->{$mid}->{foc};
		$out_info->{loc} += $all_modules_info->{$mid}->{loc};
		$out_info->{loc_added} += $all_modules_info->{$mid}->{loc_added} || 0;
		$out_info->{loc_deleted} += $all_modules_info->{$mid}->{loc_deleted} || 0;
		
		for my $user (keys %{$all_modules_info->{$mid}->{users}}) {
			if (!defined($out_info->{users}->{$user})) {
				$out_info->{users}->{$user} = {foc => 0, loc => 0, loc_added => 0, loc_deleted => 0};
			}
			
			$out_info->{users}->{$user}->{foc} += $all_modules_info->{$mid}->{users}->{$user}->{foc};
			$out_info->{users}->{$user}->{loc} += $all_modules_info->{$mid}->{users}->{$user}->{loc};			
			$out_info->{users}->{$user}->{loc_added} += $all_modules_info->{$mid}->{users}->{$user}->{loc_added};
			$out_info->{users}->{$user}->{loc_deleted} += $all_modules_info->{$mid}->{users}->{$user}->{loc_deleted};
		}
	}
	
	my @sorted_users = sort {
	        	lc($a) cmp lc($b)     # compare with key
	    		}  keys %{$out_info->{users}};
	
	my $csv_out = "";
	$csv_out .= "Author, LOC, +, -, FOC \n";
	$csv_out .= "All, $out_info->{loc}, $out_info->{loc_added}, $out_info->{loc_deleted}, $out_info->{foc} \n\n";
	
	for (my $index = 0; $index <= $#sorted_users; $index++) {
		my $user = $sorted_users[$index];
		
		$csv_out .= "$user, $out_info->{users}->{$user}->{loc}, $out_info->{users}->{$user}->{loc_added}, $out_info->{users}->{$user}->{loc_deleted}, $out_info->{users}->{$user}->{foc} \n";
	}
	
	$csv_out .= "\n\n";

	$assistor->write_file($assistor->get_all_modules_sum_header_file(), $csv_out);
}

sub mergeModulesInfoReports() {
	my $allModlesBriefFile = $assistor->get_brief_report_file();
	my $allModulesUserSumFile = $assistor->get_all_modules_sum_header_file();	
	
	my $tmpFile = $assistor->reportLocalPath() . "__CCV_TMP4MERGE__";
	system("cat \"$allModulesUserSumFile\" \"$allModlesBriefFile\" > \"$tmpFile\"; mv -f \"$allModlesBriefFile\" \"$allModlesBriefFile.o\"; mv -f \"$tmpFile\" \"$allModlesBriefFile\"");
}
