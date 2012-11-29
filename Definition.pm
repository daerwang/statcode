#!/usr/bin/perl -I ./thirds
# author: lilong'en(lilongen@163.com)
# date: 11/07/2011
# 
package Definition;

use strict;
use English;
use Data::Dumper;
use Storable;


sub new() {
	my $pkg = shift;
    my $self = {};
    bless $self, $pkg;
    
    $self->{MID_OUT_FILE_NAME} = {
    	PROGRESS_LOG 			=> "operate.log",
    	SVN_ALL_REVS_DF 		=> "all.revs.df",
    	ALL_MODULES_SUM_HEADER 	=> "all.modules.sum.header.csv",
    	BRIEF_REPORT	 		=> "brief.report.csv"
    };
    
    $self->{MID_DATA_FILE_NAME} = {
    	PMS 					=> "pms.ccv",
    	TASK_QUEUE 				=> "tasks.queue",
    	LOG_PARSED_INFO 		=> "log.parsed.info",
    	ALL_MODULES_SUM_INFO 	=> "all.modules.sum.info",
    	MODULE_FILES_INFO	 	=> "module.files.info.json",
    	CVS_GD_DATA_USER_INFO	=> "graph.user.data.info",
    	CVS_GD_DATA				=> "graph.data.info",
    	GRAPH_DATA 				=> "graph.data.json"  	
    };
    
	$self->{RPT_TPL_NAME} = {
		FRAME 					=> "frame.html",
		TOP 					=> "top.html",
		LOG 					=> "log_report.html",
		DIFF 					=> "diff_report.html"
	};
	
	$self->{OUTPUT_RPT_NAME} = {
		FRAME 					=> "rpt.html",  
		TOP 					=> "top.html",
		LOG_USERS 				=> "log.users.html",
		LOG_FILES 				=> "log.files.html",
		DIFF_GROUP 				=> "diff.group.html",
		DIFF_FLAT 				=> "diff.flat.html"		
	};
 
    return $self;
}

#===============================================================================
#
# END of the module.
#
#===============================================================================
1;
__END__
