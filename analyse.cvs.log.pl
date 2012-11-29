#!/usr/bin/perl -I ./thirds -w
# author: lilong'en(lilongen@163.com)
# date:   03/01/2007
# analyse cvs log base on 'cvs rlog -r rev module_name' log
#

use strict;
use English;
use Data::Dumper;
use Assistor;
use CcvUtil;
use URI::Escape;
use Cwd;
use bytes;


sub main();
sub print_loc_info();
sub write_data_to_html_file();
sub write_users_actions($$$);
sub write_files_actions($);
sub out_user_actions($$);
sub out_file_actions($);
sub get_previous_revision($);
sub get_file_viewcvs_diff_url($$$);
sub parse_command_line();
sub output($);
sub replacePart1PMS($$);
sub replacePart2PMS($);
sub has_viewvc_entry();
sub statUserInfoByDate($);
sub getGraphParams();
sub persistence_module_info();
sub getSortedUsersString();

my $g_branch        = "";
my $g_module_id     = "";
my $g_module        = "";
my $g_log_file      = "";
my $g_viewvc_entry  = "";
my $g_viewvc_repository= "";
my $g_date          = "N/A";
my $g_wid           = "N/A";
my $g_module_graph  = "0";
my $g_calc_all_revs = "0";
my $g_stat_binary   = "0";
my $g_stat_binary_lines = "0";
my $g_not_stat_deleted = "0";

my $_CONFIG_FILE_   = "";
my $_TIME_          = "";

parse_command_line();

my $assistor        = new Assistor($_CONFIG_FILE_, $_TIME_);
my $ccvUtil 		= new CcvUtil();
$assistor->getModules();
my $g_module_info   = $assistor->get_module_info_by_module_id($g_module_id);

my $pms 		= $ccvUtil->loadFile($assistor->get_specified_operate_file("PMS"));

#OFilter:
#  dexCnt: 1
#  dexs:
#    - dir4
#    - dir5
#  dinCnt: 3
#  dins:
#    - dir1
#    - dir2
#    - dir3
#  fex: .ini;.jpg;.png;
#  fexLen: 14
#  filterNeeded: 1
#  fin: .java;.cpp;
#  finLen: 10

my $brief_report_file   		= $assistor->get_brief_report_file();
my $module_brief_report_file	= $assistor->get_module_brief_report_file($g_module_id);
my $g_langs_info 				= $assistor->get_program_langs_ext();
my $g_all_exts 					= $g_langs_info->{ext};
$g_all_exts 					=~ s/(^|\s)/ \./g;

my $file_filter     = $g_module_info->{file_filter};
my $cvs_repository  = $g_module_info->{repository};

#Add this to support repository directory redirect in some env
if ($g_module_info->{repository_mapping}) {
	$cvs_repository = $g_module_info->{repository_mapping};
}
#End

$g_module            = $g_module_info->{module};
if ($g_log_file eq "") {
   $g_log_file      = $assistor->get_repository_log_cmd_output_file($g_branch, $g_module_info->{log});
}

$g_viewvc_entry     = $g_module_info->{viewvc_entry};
$g_viewvc_repository	= $g_module_info->{viewvc_repository};
$file_filter 		= $g_module_info->{file_filter};

my $g_rlog_file_url = "/ccv/" . $g_log_file;

my $DIFF_LINK_SETTING = "";

my $changed_file_amount = 0;
my $line_cnt            = 0;
my $line_cnt_added      = 0;
my $line_cnt_removed    = 0;

my $all_actions         = [];
my $files_actions       = {};
my $users_actions       = {};

my $ModuleUserInfo		= {};
$ModuleUserInfo->{$g_module_id} = {};
$ModuleUserInfo->{$g_module_id}->{users} = {};

#For item color inidcator
my $file_removed = 0;
my $file_created = 0;
my $file_clr = "fileNormal";
my $action_clr = "revStyleNormal";
#End

my $CCV_DIFFER			= "/ccv-cgi/differ.pl";

my $verLogNoLineFileInfo = {};

my $_ERROR_		= "";

my $g_ld_pl             = getcwd;

my $g_users_info = {};
$g_users_info->{first_date} = '2999/12/31';
$g_users_info->{last_date} = '1970/01/01';
my $USER_INFO_PERSISTENCE_FILE	= $assistor->get_module_co_head_path($g_branch, $g_module_id) . $assistor->{DEF}->{MID_DATA_FILE_NAME}->{CVS_GD_DATA_USER_INFO};
my $g_file_patten_str_without_repository_path = $assistor->get_cvs_file_patten_str_without_repository_path($g_module);

exit main();

sub main() {
	if (!open(LOG, $g_log_file)) {
		output("Can not open $g_log_file!\n");
		
		return 1;
	}
	
	# cvs rlog -r rev module format
	#
	#
	# RCS file: /cvs/webapps/waf/src/conf/dao/eventcenter/ECReportBuilder.xml,v
	# head: 1.172
	# branch:
	# locks: strict
	# access list:
	# keyword substitution: kv
	# total revisions: 196;	selected revisions: 3
	# description:
	# ----------------------------
	# revision 1.147.2.2.20.4.2.1.2.3
	# date: 2007/02/12 06:14:56;  author: jet;  state: Exp;  lines: +3 -3
	# Fixing bug#244709 and 244661
	# ----------------------------
	# revision 1.147.2.2.20.4.2.1.2.2
	# date: 2007/02/07 08:46:58;  author: jet;  state: Exp;  lines: +1 -1
	# Check in code for fixing bug#244116
	# ----------------------------
	# revision 1.147.2.2.20.4.2.1.2.1
	# date: 2007/02/07 08:33:08;  author: jet;  state: Exp;  lines: +8 -5
	# For fixing bug#244116
	# =============================================================================	

	my $changed     = 0;
	my $file_found  = 0;
	my $line        = "";
	my $author_found = 0;
    
    my $file        = "";
    my $revision    = "";
    my $date        = "";
    my $author      = "";
    my $state 		= "";
    my $line_add    = 0;
    my $line_del    = 0;
    
    my $ver_field_count = -1;
    my $is_first_log = 0;
    my $is_binary = 0;
    
    my $action_state = "NORMAL";
    
    my $comments_lines = 0;
    my $comments    = "";
    
    my $file_ext = "";
    
    my $LINE_NO = 0;
	while (1) {
		$line = <LOG>;
		if (!defined($line)) {
			last;
		}
		
		#Added for error handle (such as: no such tag, no such repository...)
		if ($LINE_NO++ == 0 && $line !~ m/^\s*$/i) {
			$_ERROR_ = $line;

			last;
		}
		#End
		
		#filename format
		# RCS file: /cvs/webapps/waf/src/conf/webex.properties,v
		# RCS file: /cvs/webapps/mywebex/.classpath,v
		# RCS file: /cvs/webapps/mywebex/license,v

		#   1) filename.ext
		#   2) filename
		#   3) .filename
		#
		if ($file_found == 0) {
			$ver_field_count = -1;
			$file_ext = "";
			if ($line =~ m/^RCS file: (.*\/([^\/]+)(\.\w+)),v/i) { #   1) filename.ext
				$file = $1;
				$file_ext = $3;
				if ($pms->{OFilter}->{filterNeeded}) {
					my $isIn = $ccvUtil->filter($file, $pms->{OFilter}, $file_ext);
					if ($isIn) {
		    		    $file_found = 1;
		    		    
		    		    if ($file =~ m/(.*)\/Attic\/(.*)/) {
		    		        $file = $1 . "/" . $2;
		    		    }
						next;						
					}
				} else {
	    		    $file_found = 1;
	    		    
	    		    if ($file =~ m/(.*)\/Attic\/(.*)/) {
	    		        $file = $1 . "/" . $2;
	    		    }
					next;						
				}
			} elsif ($line =~ m/^RCS file: (.*),v/i) { # 2) filename,  3) .filename
    			$file = $1;
    		    $file_found = 1;
    		    
    		    if ($file =~ m/(.*)\/Attic\/(.*)/) {
    		        $file = $1 . "/" . $2;
    		    }
    		    
				next;				
			}
		}
		# RCS file: /cvs/dms/idxmntr/web/META-INF/Attic/context.xml,v
		# head: 1.3
		# branch:
		# locks: strict
		# access list:
		# keyword substitution: kv
		# total revisions: 3;	selected revisions: 2
		
		# keyword substitution: kv   -- ascii
		# keyword substitution: b   -- binary
		if ($file_found == 1 && $line =~ m/^keyword substitution:\s+(\w)$/i) { #text or binary file
			if ($1 eq "b") {
				$is_binary = 1;
				if ($file_ext ne "" && index($g_all_exts, "$file_ext ") != -1) {
					$is_binary = 0;
				}
			} else {
				$is_binary = 0;
			}
			
			if (!$g_stat_binary_lines) {
				if (!$g_stat_binary && $is_binary == 1) {
					$file_found = 0;
					$is_binary = 0;
				}
			}
		}
		
		
		# Working file: src/windows/attraining/ateditorex/AtRecplyEx/WbxAudioVolume.cpp
		#if ($file_found == 1 && $line =~ m/^Working file: (.*)/i) {
		#	$file = $1;
		#	
		#	next;
		#}		
		
		# revision 1.147.2.2.20.4.2.1.2.2
		if ($file_found == 1 && $line =~ m/^revision\s(.*)$/i) {
			$changed = 1;
			$revision = $1;
			
			if ($g_calc_all_revs eq "1") { # for getting all revisons case
				next;				
			}
			
			# ...
			# ----------------------------
			# revision 1.3
			# date: 2009/11/18 00:16:29;  author: micro;  state: Exp;  lines: +38 -0
			# *** empty log message ***
			# ----------------------------
			# revision 1.2
			# date: 2009/11/18 00:16:12;  author: micro;  state: Exp;  lines: +20 -0
			# *** empty log message ***
			# ----------------------------
			# revision 1.1
			# date: 2009/11/18 00:15:53;  author: micro;  state: Exp;
			# *** empty log message ***
			# ----------------------------
			# revision 1.5.2.4
			# date: 2009/11/18 04:37:06;  author: micro;  state: Exp;  lines: +38 -0
			# branches:  1.5.2.4.2;
			# *** empty log message ***
			# ----------------------------
			# revision 1.5.2.3
			# date: 2009/11/18 04:37:03;  author: micro;  state: Exp;  lines: +38 -0
			# *** empty log message ***
			# ----------------------------
			# revision 1.5.2.2
			# date: 2009/11/18 04:36:56;  author: micro;  state: Exp;  lines: +38 -0
			# *** empty log message ***
			# ----------------------------
			# ...
			
			#Follwoing code is for above log case, this case only occurs in rlog on head
			my @ver_fileds = split(/\./, $revision);
			my $curr_ver_field_count = $#ver_fileds + 1;
			
			if ($ver_field_count != -1) {#not first log
				if ($curr_ver_field_count > $ver_field_count) {
					$changed = 0;
				}
				
			} else {#first log
				if (uc($g_branch) eq "MAIN" && $curr_ver_field_count > 2) {
					$changed = 0;
				} else {
					$ver_field_count = $curr_ver_field_count;
				}
			}
			#End
			
			next;
		}
		
		#Followings are some special log case example & explain.

		# init added on head branch , only occur in cvs rlog -N on head branch
		#
		#
		# ----------------------------
		# revision 1.1
		# date: 2009/11/18 00:15:53;  author: micro;  state: Exp;
		# *** empty log message ***	
		# =============================================================================
		
		
		# init added on a branch, only occur in cvs rlog -N on head branch, 
		# this case log in "cvs rlog -rRx" will be a normal check-in log
		#
		#
		# ----------------------------
		# revision 1.1
		# date: 2009/11/18 00:30:10;  author: micro;  state: dead;
		# branches:  1.1.2;
		# file 777 was initially added on branch B_T1.
		
		
		# if following log is the first log of the file, it indicate that, it's removed in this branch
		# if it is the last log of the file, it indicate that, the file still in current branch, but removed in other branch
		#
		# ----------------------------
		# revision 1.1.2.4
		# date: 2009/11/18 00:30:54;  author: micro;  state: dead;  lines: +0 -0   
		# rm it
		# ----------------------------
		# revision 1.5.2.1
		# date: 2009/11/18 00:17:20;  author: micro;  state: dead;  lines: +0 -134
		# file 222 was added on branch B1 on 2009-11-18 04:36:56 +0000
		
		
		# normal check-in case log
		#
		#
		# ----------------------------
		# revision 1.1.2.3
		# date: 2009/11/18 00:30:28;  author: micro;  state: Exp;  lines: +38 -0
		# *** empty log message ***


		# date: 2007/02/06 05:23:54;  author: robinl;  state: Exp;  lines: +0 -8
		if ($changed == 1 && $line =~ m/^date:\s([\d\/\\\-\s:]+);\s+author:\s([\w\.\-_\d]+);\s+state: (\w+);(.*)$/i) {
			$date       = $1;
			$author     = $2;
			$state 		= $3;
			$line_add   = 0;
			$line_del   = 0;
			$author_found = 1;
			
			$is_first_log = ($is_first_log == 0 ? 1 : 0);
			
			if ($g_wid ne "N/A" && index(",$g_wid,", ",$author,") == -1) {
				$changed = 0;
				$author_found = 0;
				
				next;
			}
			
			if ($state eq "dead") {
				if ($4 ne "" && $4 =~ m/\s+lines:\s\+(\d+)\s-(\d+)/i) {
					if ($is_first_log == 1) {
						# removed in current queried branch
						$action_state = "REMOVED";
						
						if ($g_not_stat_deleted eq "1") {
							$changed        = 0;
							$file_found     = 0;
				            $author_found   = 0;
				            $comments_lines = 0;
							$comments       = "";
							$ver_field_count = -1;
							$is_first_log 	= 0;
							
							next;
						}
					} else {
						# removed in other branch, this case will be regarded as normal check-in log, it's just an indicate that it's removed from other branch
						$action_state = "REMOVED_IN_OTHER"; 
					}
					$line_add   = $1;
					$line_del   = $2;					
				} else {
					# added on a non-head branch, 
					# in this case, cvs log will has two log, one version will include line change.
					# so just ignore dead action on non-head, use another action log which inlude line change info
					# Added in NON_HEAD branch, so ignore it, only cvs rlog on head, has this kind log
					# if added in branch B1, then cvs rlog -N -rB1, log will do not have this kind log
					$action_state = "ADDED_ON_NON_HEAD"; 
					
					if ($g_calc_all_revs eq "1") {# for getting all revisons case
						if ($is_first_log == 1) {
							$changed        = 0;
							$author_found   = 0;
							
							next;					
						}						
					}
					
					if ($is_first_log == 1) {
						$changed        = 0;
						$file_found     = 0;
			            $author_found   = 0;
			            $comments_lines = 0;
						$comments       = "";
						$ver_field_count = -1;
						$is_first_log 	= 0;
						
						next;					
					}
	
				}
			} elsif ($state eq "Exp") { # Exp -- normal
				if ($4 ne "" && $4 =~ m/\s+lines:\s\+(\d+)\s-(\d+)/i) {
					$action_state = "NORMAL"; 
					$line_add   = $1;
					$line_del   = $2;					
				} else {
					# new added on head branch, 
					# in this case, cvs log only has one log, ver 1.1, and no line chnage info
					$action_state = "ADDED_ON_HEAD"; 

					if (uc($g_branch) eq "MAIN") {
						$file =~ m/$cvs_repository\/($g_file_patten_str_without_repository_path)/;
				        my $fileInModule = $1;
				        $fileInModule = $assistor->get_module_co_ver11_file($g_branch, $g_module_id, $fileInModule);	
				        my $fileLines = `wc -l < "$fileInModule"`;
				        $line_add   = $fileLines;
			    	}					
				}
			}
			
			if ($is_binary && !$g_stat_binary_lines) {
				$line_add  = 0;
				$line_del  = 0;									
			}
	    	
	        
	        my $user_cvs_action = {};
	        $user_cvs_action->{file}        = $file;
			$user_cvs_action->{author}      = $author;
			$user_cvs_action->{date}        = $date;
			$user_cvs_action->{revision}    = $revision;
			$user_cvs_action->{lines_add}   = $line_add;
			$user_cvs_action->{lines_del}   = $line_del;
			$user_cvs_action->{action_state}= $action_state; # NORMAL, ADDED_ON_HEAD, ADDED_ON_NON_HEAD, REMOVED, 
			$user_cvs_action->{is_binary}	= $is_binary; 
            push(@{$all_actions}, $user_cvs_action);
            
	        if (!defined($users_actions->{$author})) {
	            $users_actions->{$author} = {};
	        }
	        
	        if (!defined($users_actions->{$author}->{$file})) {
	        	$users_actions->{$author}->{$file} = [];
	        }
	        
	        push(@{$users_actions->{$author}->{$file}}, $user_cvs_action);          

	        if (!defined($files_actions->{$file})) {
	            $files_actions->{$file} = [];
	        }
	        push(@{$files_actions->{$file}}, $user_cvs_action);               
    		
    		$line_cnt_added += $line_add;
			$line_cnt_removed += $line_del;

			next;
		}
		
		if ($author_found == 1) {
		    if ($line =~ m/(^\-+$|^=+$)/) {
                $users_actions->{$author}->{$file}->[$#{$users_actions->{$author}->{$file}}]->{comments} = $comments;		        
                $users_actions->{$author}->{$file}->[$#{$users_actions->{$author}->{$file}}]->{comments_lines} = $comments_lines;		        
                $author_found  = 0;
                $comments_lines = 0;
                $comments      = "";
		    } else {
		        $comments .= $line;
		        $comments_lines ++; 
		    }
		}
		
		# ===================================================================
		if ($file_found == 1 && $line =~ m/^=+$/) {
			if (defined($files_actions->{$file}) && $#{$files_actions->{$file}} >= 0) {
				$changed_file_amount ++;
			}
			$changed        = 0;
			$file_found     = 0;
            $author_found   = 0;
            $comments_lines = 0;
			$comments       = "";
			$ver_field_count = -1;
			$is_first_log 	= 0;
			$is_binary		= 0;
		}
	}
	close(LOG);
	
	$line_cnt = $line_cnt_added + $line_cnt_removed;
	
	print_loc_info();
	write_data_to_html_file();
	
	persistence_module_info();
	
	if ($g_module_graph eq "1") {
		$ccvUtil->dumpFile($USER_INFO_PERSISTENCE_FILE, $g_users_info);
	}

	return 0;
}

sub persistence_module_info() {
	my $G_ALL_MODULES_INFO_FILE = $assistor->get_all_modules_sum_info_data_file();
	my $tmp = $ModuleUserInfo;
	
	if (-e $G_ALL_MODULES_INFO_FILE) {
		$tmp = $ccvUtil->loadFile($G_ALL_MODULES_INFO_FILE);
		$tmp->{$g_module_id} = $ModuleUserInfo->{$g_module_id};
	} else {
		$tmp = $ModuleUserInfo;
	}
	
	$ccvUtil->dumpFile($G_ALL_MODULES_INFO_FILE, $tmp);
}

sub output($) {
	print $_[0];
}

sub print_loc_info() {
	output("File: $g_log_file\n");
	output("Changed file amount:   $changed_file_amount\n");
	output("Changed line amount:   $line_cnt (+$line_cnt_added, -$line_cnt_removed)\n\n\n");
}

sub write_data_to_html_file() {
	my $h_text_file;
	my $h_module_text_file;
	my $h_user_html_file;
	my $h_file_html_file;

	if (!open($h_text_file, ">>", "$brief_report_file")) {
		output("Can not create/open $brief_report_file!\n");
		
		return 1;
	}
	
	if (!open($h_module_text_file, ">>", "$module_brief_report_file")) {
		output("Can not create/open $module_brief_report_file!\n");
		
		return 1;
	}	
	
    my $HTML_TEMPLATE = $assistor->get_report_template_file("LOG");
    my $node_flag   = "#NODE#";
    my $template    = $assistor->read_whole_file($HTML_TEMPLATE);
    my $node_pos    = index($template, $node_flag);
    my $part1       = substr($template, 0, $node_pos);
    my $part2       = substr($template, $node_pos + length($node_flag));
    
    my $file_part1  = $part1;
        
    my $user_html_out_file = $assistor->get_specified_output_report_file({flag => "LOG_USERS", revs => $g_branch, mid=> $g_module_id});
    my $file_html_out_file = $assistor->get_specified_output_report_file({flag => "LOG_FILES", revs => $g_branch, mid=> $g_module_id});

    if (!open($h_user_html_file, ">", "$user_html_out_file")) {
		output("Can not create/open $user_html_out_file!\n");
		
		return 1;
	} 
	
    if (!open($h_file_html_file, ">", "$file_html_out_file")) {
		output("Can not create/open $file_html_out_file!\n");
		
		return 1;
	} 	
    
    my $cvs_root = $assistor->get_module_cvsroot_without_uid($g_module_info);
	my $LOC = sprintf("$line_cnt (+$line_cnt_added, -$line_cnt_removed)");

    my $module_brief_txt = sprintf("Module: %s (%s)\n%s; Branch/Revisions: %s; DateScope: %s; By: %s,,\n",
                        $g_module_id, 
                        $g_module,
                        $cvs_root,
                        $g_branch, 
                        $g_date,
                        $g_wid);
                        
    $module_brief_txt .= sprintf("Author, LOC, +, -, FOC\nAll users, %d, %d, %d, %d\n\n", 
                        $line_cnt,
						$line_cnt_added,
						$line_cnt_removed,                  
                        $changed_file_amount);
                        
    $ModuleUserInfo->{$g_module_id}->{foc} = $changed_file_amount;
    $ModuleUserInfo->{$g_module_id}->{loc} = $line_cnt;
    $ModuleUserInfo->{$g_module_id}->{loc_added} = $line_cnt_added;
    $ModuleUserInfo->{$g_module_id}->{loc_deleted} = $line_cnt_removed;
                        
	
    my $user_mode_report_url = $assistor->transReportLocalPath2WebPath($assistor->get_specified_output_report_file({flag => "LOG_USERS", revs => $g_branch, mid=> $g_module_id}));
    my $file_mode_report_url = $assistor->transReportLocalPath2WebPath($assistor->get_specified_output_report_file({flag => "LOG_FILES", revs => $g_branch, mid=> $g_module_id}));
    my $module_rlog_brief_report_url = $assistor->transReportLocalPath2WebPath($assistor->get_module_brief_report_file($g_module_id));
    my $rlog_brief_report_url = $assistor->transReportLocalPath2WebPath($assistor->get_brief_report_file());


    my $template_parametrs = {'MODULE' 			=> $g_module,
    						  'CVSROOT' 		=> $cvs_root,
    						  'REVS_DATES' 		=> $g_branch,
    						  'DATE_SCOPE' 		=> $g_date,
    						  'ACCOUNT' 		=> $g_wid,
    						  'FOC' 			=> $changed_file_amount,
    						  'LOC' 			=> $LOC,
    						  'CURRENT_URL'		=> "",
    						  'CURRENT_NAME' 	=> "",
        					  'OTHER_URL' 		=> $file_mode_report_url,
    						  'OTHER_NAME' 		=> "File",
    						  'MODULE_PLAIN_REPORT' => $module_rlog_brief_report_url,
    						  'PLAIN_REPORT' 		=> $rlog_brief_report_url};
	
	replacePart1PMS(\$part1, $template_parametrs);
	
	$template_parametrs->{OTHER_URL} 	= $user_mode_report_url;
	$template_parametrs->{OTHER_NAME} 	= "User";
    replacePart1PMS(\$file_part1, $template_parametrs);
    replacePart2PMS(\$part2);

    print $h_text_file $module_brief_txt;
    print $h_module_text_file $module_brief_txt;
    	
	print $h_user_html_file $part1;
	write_users_actions($h_text_file, $h_module_text_file, $h_user_html_file);
	print $h_user_html_file $part2;
    
	print $h_file_html_file $file_part1;
	write_files_actions($h_file_html_file);
	print $h_file_html_file $part2;

    print $h_text_file "\n\n";
    print $h_module_text_file "\n\n";

	close($h_text_file);
	close($h_module_text_file);
	close($h_user_html_file);
	close($h_file_html_file);
		
	return 0;
}

sub replacePart1PMS($$) {
	my $content	= $_[0];
    my $paras 	= $_[1];
	
	$$content =~ s/#BODY_CLS#/cvsLogReport/;				
    $$content =~ s/#MODULE#/$paras->{MODULE}/;
    $$content =~ s/#MODULE_URI#/$paras->{CVSROOT}/;
    
    if ($g_calc_all_revs eq "1") {
    	$$content =~ s/#REVS_DATES#/All revison\(no matter on which branch\)/;
    } else {
    	$$content =~ s/#REVS_DATES#/$paras->{REVS_DATES}/;	
    }

    $$content =~ s/#DATE_SCOPE#/$paras->{DATE_SCOPE}/;
    $$content =~ s/#ACCOUNT#/$paras->{ACCOUNT}/g;
    $$content =~ s/#FOC#/$paras->{FOC}/;
    $$content =~ s/#LOC#/$paras->{LOC}/;
    $$content =~ s/#OTHER_URL#/$paras->{OTHER_URL}/;
    $$content =~ s/#OTHER_NAME#/$paras->{OTHER_NAME}/;
    $$content =~ s/#LOG_FILE#/$g_rlog_file_url/;
    $$content =~ s/#ERROR#/$_ERROR_/;
    $$content =~ s/#MODULE_PLAIN_REPORT#/$paras->{MODULE_PLAIN_REPORT}/;
    $$content =~ s/#PLAIN_REPORT#/$paras->{PLAIN_REPORT}/;
    $$content =~ s/#GRAPH_HTML#/graph.html/;
    
    my $filterInfo = $ccvUtil->getShownFilterInfo($pms->{OFilter});
    $$content =~ s/#FILTER_INFO#/$filterInfo/;
    
    if ($g_module_graph eq "1") {
    	my $mfi_url = $assistor->transOperateLocalPath2WebPath($assistor->get_cvs_module_files_info_file($g_branch, $g_module_id));
    	$$content =~ s/#MFI_URL#/$mfi_url/;
    	
		my $params = getGraphParams();
		$$content =~ s/#GRPAH_ENTRY_PARAMS#/$params/;
	}
}

sub replacePart2PMS($) {
	my $content	= $_[0];
	my $error = $_ERROR_ eq "" ? 0 : 1;
print $error;	
    my $GV_IN_JS =<<GV_IN_JS;
{
	T_SNAP: "$_TIME_",
	MID: "$g_module_id",
	Error: "$error",
	ShowGraphEntry: "$g_module_graph",
	ShowSrcDetails: "$g_module_graph",
	ReportType: "CVS_LOG"
}
GV_IN_JS
    
	$$content =~ s/#GV#/$GV_IN_JS/;
}

sub getSortedUsersString() {
	my @keys_case_insensitive = sort {
	        	lc($a) cmp lc($b)     # compare with key
	    		}  keys %{$users_actions};
	    			
	return join(",", @keys_case_insensitive);	
}

sub write_users_actions($$$) {
    my $h_text_file = $_[0];
    my $h_module_text_file = $_[1];
    my $h_user_html_file = $_[2];
    #for my $user (keys %{$users_actions}) { 
    
	my @keys_case_insensitive = sort {
	        	lc($a) cmp lc($b)     # compare with key
	    		}  keys %{$users_actions};
	    			
	for (my $index = 0; $index <= $#keys_case_insensitive; $index++) {
		my $user = $keys_case_insensitive[$index];
		my $ret = out_user_actions($user, $users_actions->{$user});
		my $text = $ret->{'text'};
		my $html = $ret->{'html'};
		
		print $h_text_file $text . "\n";
		print $h_module_text_file $text . "\n";
		print $h_user_html_file $html;   		
	}			
}

sub write_files_actions($) {
    my $h_file_html_file = $_[0];
    #for my $user (keys %{$users_actions}) { 
    
	my @keys_case_insensitive = sort {
	        	lc($a) cmp lc($b)     # compare with key
	    		}  keys %{$files_actions};
	    			
	for (my $index = 0; $index <= $#keys_case_insensitive; $index++) {
		my $file = $keys_case_insensitive[$index];
		my $ret = out_file_actions($files_actions->{$file});
		my $html = $ret->{'html'};
		
		print $h_file_html_file $html;   		
	}			
}

sub out_user_actions($$) {
	my $user = $_[0];
    my $user_actions = $_[1];
    
    my $html_actions = "";
    my $html_file_actions = "";
    
    my $chks_cnt		= 0;#on a file
    my $user_added      = 0;
    my $user_deleted    = 0;
    my $file_added      = 0;
    my $file_deleted    = 0;
    
    my $file_first_revison = "";
    my $file_last_revison  = "";
	
	my $last_checkin_comments_index = 0;
	
	my @files = sort {
	        	lc($a) cmp lc($b)     # compare with key
	    		}  keys %{$user_actions};

	my $files_cnt =$#files;
	$g_users_info->{$user} = {};
	$g_users_info->{$user}->{first_date} = '2999/12/31';
	$g_users_info->{$user}->{last_date} = '1970/01/01';
	$g_users_info->{$user}->{date} = {};
	for (my $index = 0; $index <= $files_cnt; $index++) {
		my $file = $files[$index];
		my $file_actions = $user_actions->{$file};
    	$chks_cnt = $#{$file_actions};  # $chks_cnt = actual count - 1
    	
		$file =~ m/$cvs_repository\/($g_file_patten_str_without_repository_path)/;    	
        $file = $1; 
        
        $file_removed = 0;
        $file_created = 0;
        $file_clr = "fileNormal";
        
	    for (my $i = 0; $i <= $chks_cnt; $i++) {
	    	if ($file_actions->[$i]->{action_state} eq "ADDED_ON_NON_HEAD") {
	    		next;	
	    	}
			
			if ($g_module_graph eq "1") {
				statUserInfoByDate($file_actions->[$i]);
			}
			
			$action_clr = "revStyleNormal";	 
	        
	        $file_actions->[$i]->{comments} = $ccvUtil->replaceCharInComment($file_actions->[$i]->{comments});

	        my $diff_url = get_file_viewcvs_diff_url($file, $file_actions->[$i]->{revision}, get_previous_revision($file_actions->[$i]->{revision}));
	        $user_added     += $file_actions->[$i]->{lines_add};
	        $user_deleted   += $file_actions->[$i]->{lines_del};
	        $file_added     += $file_actions->[$i]->{lines_add};
	        $file_deleted   += $file_actions->[$i]->{lines_del};	
	        	        
	        my $div_name = $file_actions->[$i]->{author} . "-$i";
	        
        	my $a_html = sprintf("%07d (+%07d -%07d)", 
        			        $file_actions->[$i]->{lines_add} + $file_actions->[$i]->{lines_del},
                            $file_actions->[$i]->{lines_add},
                            $file_actions->[$i]->{lines_del});
             
            if ($file_actions->[$i]->{action_state} eq "REMOVED") {
            	$a_html = "Removed (ver: " . $file_actions->[$i]->{revision} . ")";
            	$DIFF_LINK_SETTING = "";
         	
            	$file_removed = 1;
            	$file_clr = "fileDelete";
            	$action_clr = "revStyleDelete";
            } elsif ($file_actions->[$i]->{action_state} eq "ADDED_ON_HEAD") {
            	$DIFF_LINK_SETTING = "";
            	$file_created = 1;
            	$action_clr = "revStyleAdd";
            	
            	if (uc($g_branch) eq "MAIN") {
            		$a_html = "Initial version 1.1 (+" . $file_actions->[$i]->{lines_add} . ")";
            	} else {
            		$a_html = "Initial version 1.1 (lines not counted)";
            	}
            }  
                            
			if ($file_actions->[$i]->{is_binary}) {
		        $html_file_actions .= sprintf("<li><span class='ci'></span><span onmouseover=\"showTip('%s')\"><span class='fileBinary'>%s</span></span>",
                            $file_actions->[$i]->{comments},
	                        $file_actions->[$i]->{date});			
			} else {
		        $html_file_actions .= sprintf("<li><span class='ci'></span><span class='$action_clr'>%s <a $DIFF_LINK_SETTING class='locInfo' target='_blank' href='%s' style='text-decoration: underline;' onmouseover=\"showTip('%s')\">$a_html</a></span>",
	                            $file_actions->[$i]->{date},
	                            $diff_url,
	                            $file_actions->[$i]->{comments});			
			}                        
                                                                        

				        
	        if ($i == $chks_cnt) {
		        $file_first_revison = get_previous_revision($file_actions->[$chks_cnt]->{revision});
		        $file_last_revison  = $file_actions->[0]->{revision};
		        my $last_viewable_version = $file_last_revison;
		        if ($file_removed) {
		        	$last_viewable_version = get_previous_revision($file_last_revison);
		        }
		        my $file_diff = get_file_viewcvs_diff_url($file, $last_viewable_version, $file_first_revison);
		        my $begin = "";
		        
	        	if ($file_actions->[$i]->{is_binary}) {
			        $begin = sprintf("<li><span class='plus' onclick='showChildren(this)'></span><span class='fileBinary'>CIS: #TIMES# - #LINES#</span> <span class='fileBinary' title='%s' #TIPS#>%s (binary)</span>\n<ul>\n",
									($file_removed ? "removed" : ""),
									$file);	        	
	        	} else {
	        		$begin = sprintf("<li><span class='plus' onclick='showChildren(this)'></span>CIS: #TIMES# - <a class='locInfo' $DIFF_LINK_SETTING target='_blank' style='text-decoration: underline;' href='%s' #TIPS#>#LINES#</a> <a $DIFF_LINK_SETTING target='_blank' href='%s' class='$file_clr' title='%s'>%s</a>\n<ul>\n",
								$file_diff,
								$file_diff,
								($file_removed ? "removed" : ""),
								$file);
	        	}
				
		        my $end = "</ul>\n</li>\n";
		        
		        my $file_lines          = $file_added + $file_deleted;
		        my $str_checkin_counter = sprintf("%03d", $chks_cnt + 1);
		        my $str_file_lines      = sprintf("%07d", $file_lines);
		        my $str_file_added      = sprintf("%07d", $file_added);
		        my $str_file_deleted    = sprintf("%07d", $file_deleted);
		
		        $begin =~ s/#TIMES#/$str_checkin_counter/;
		        $begin =~ s/#LINES#/$str_file_lines (+$str_file_added -$str_file_deleted)/;
		        
		       	my $comm = " onmouseover=\"showTip('$file_actions->[0]->{comments}')\"";
		       	$begin =~ s/#TIPS#/$comm/;
		         
		        $html_actions .= $begin . $html_file_actions . $end;
		        $html_file_actions = "";
		
		        $file_added         = 0;
		        $file_deleted       = 0;  
	        }                          
    	}    	
	}	

    my $html_node = sprintf("<li><span class='plus' onclick='showChildren(this)'></span><span class=\"userChangeinfo\">FOC: %04d LOC: %07d (+%07d -%07d)</span> <span class=\"userName\">%s </span>\n<ul>\n%s\n</ul>\n</li>\n",
                            $files_cnt + 1,
                            $user_added + $user_deleted,
                            $user_added,
                            $user_deleted,
                            $user,
                            $html_actions);
                            
    my $text_node = sprintf("%s, %d, %d, %d, %d",
    						$user,
                            $user_added + $user_deleted,
                            $user_added,
                            $user_deleted,
                            $files_cnt + 1);  
                            
	$g_users_info->{$user}->{file_amount} 	= $files_cnt + 1;
	$g_users_info->{$user}->{lines} 		= $user_added + $user_deleted;
	$g_users_info->{$user}->{loc_added} 	= $user_added;
	$g_users_info->{$user}->{loc_deleted} 	= $user_deleted;
	
	$ModuleUserInfo->{$g_module_id}->{users}->{$user}->{foc} = $files_cnt + 1;
	$ModuleUserInfo->{$g_module_id}->{users}->{$user}->{loc} = $user_added + $user_deleted;
	$ModuleUserInfo->{$g_module_id}->{users}->{$user}->{loc_added} = $user_added;
	$ModuleUserInfo->{$g_module_id}->{users}->{$user}->{loc_deleted} = $user_deleted;
    
    return {"text" => $text_node, "html" => $html_node};
}

sub statUserInfoByDate($) {
	my $action = $_[0];
	my $date = $assistor->get_date($action->{date});
	if (($g_users_info->{first_date} cmp $date) == 1) { #grate than
		$g_users_info->{first_date} = $date;
	}
	
	if (($g_users_info->{last_date} cmp $date) == -1) { #less than
		$g_users_info->{last_date} = $date;
	}
	
	if (($g_users_info->{$action->{author}}->{first_date} cmp $date) == 1) { #grate than
		($g_users_info->{$action->{author}}->{first_date}) = $date;
	}
	
	if (($g_users_info->{$action->{author}}->{last_date} cmp $date) == -1) { #less than
		$g_users_info->{$action->{author}}->{last_date} = $date;
	}	
	
	
	if (defined($g_users_info->{$action->{author}}->{date}->{$date})) {
		$g_users_info->{$action->{author}}->{date}->{$date} += $action->{lines_add} + $action->{lines_del};
	} else {
		$g_users_info->{$action->{author}}->{date}->{$date} = $action->{lines_add} + $action->{lines_del};
	}
}

sub out_file_actions($) {
    my $actions = $_[0];

	$file_removed = 0;
	$file_created = 0;
	$file_clr = "fileNormal";
	    
    my $html_actions = "";
    my $html_file_actions = "";

    my $file_added      = 0;
    my $file_deleted    = 0;
    
    my $file_first_revison = "";
    my $file_last_revison  = "";
	my $actions_cnt = $#{$actions};
	
	$file_first_revison = get_previous_revision($actions->[$actions_cnt]->{revision});
	$file_last_revison = $actions->[0]->{revision};

    my $file = $actions->[0]->{file};

	$file =~ m/$cvs_repository\/($g_file_patten_str_without_repository_path)/;    
    $file = $1;	
	
    my $file_diff = get_file_viewcvs_diff_url($file, $file_last_revison, $file_first_revison);
    
    my $begin = "";
    
	if ($actions->[0]->{is_binary}) {
		$begin = sprintf("<li><span class='plus' onclick='showChildren(this)'></span>CIS: #TIMES# <span class='fileBinary'>LOC: #LINES# </span><span class='fileBinary' title='#TITLE#' #TIPS#>%s (binary)</span>\n<ul>\n",
                         $file);
	} else {
		$begin = sprintf("<li><span class='plus' onclick='showChildren(this)'></span>CIS: #TIMES# <a class='locInfo' $DIFF_LINK_SETTING target='_blank' style='text-decoration: underline;' href='%s' #TIPS#>#LINES#</a> <a $DIFF_LINK_SETTING target='_blank' href='%s' class='#FILE_COLOR#' title='#TITLE#'>%s</a>\n<ul>\n",
                         $file_diff,
                         $file_diff,
                         $file);
	}
	                         
    my $end = "</ul>\n</li>\n";

    for (my $i = 0; $i <= $actions_cnt; $i++) {
    	if ($actions->[$i]->{action_state} eq "ADDED_ON_NON_HEAD") {
    		next;	
    	}
    	my $action_clr = "revStyleNormal";	
        my $diff_url = get_file_viewcvs_diff_url($file, $actions->[$i]->{revision}, get_previous_revision($actions->[$i]->{revision}));

        $file_added     += $actions->[$i]->{lines_add};
        $file_deleted   += $actions->[$i]->{lines_del};
        
        my $div_name = $actions->[$i]->{file} . "-$i";
        
		my $a_html = sprintf("%07d (+%07d -%07d)", 
				        $actions->[$i]->{lines_add} + $actions->[$i]->{lines_del},
		                $actions->[$i]->{lines_add},
		                $actions->[$i]->{lines_del});
	 
		if ($actions->[$i]->{action_state} eq "REMOVED") {
			$a_html = "Removed (ver: " . $actions->[$i]->{revision} . ")";
			$DIFF_LINK_SETTING = "";
			$file_removed = 1;
			$file_clr = "fileDelete";
			$action_clr = "revStyleDelete";		
		} elsif ($actions->[$i]->{action_state} eq "ADDED_ON_HEAD") {
			$DIFF_LINK_SETTING = "";
			
			$file_created = 1;
			$action_clr = "revStyleAdd";
        	if (uc($g_branch) eq "MAIN") {
        		$a_html = "Initial version 1.1 (+" . $actions->[$i]->{lines_add} . ")";
        	} else {
        		$a_html = "Initial version 1.1 (lines not counted)";
        	}			          	
		}  

		if ($actions->[0]->{is_binary}) {
	    	$html_file_actions .= sprintf("<li><span class='ci'></span><span onmouseover=\"showTip('%s')\"><span class='fileBinary'>%s %s</span></span>",
                            $actions->[$i]->{comments},
                            $actions->[$i]->{date},
                            $actions->[$i]->{author});   
		} else {
	    	$html_file_actions .= sprintf("<li><span class='ci'></span><span class='$action_clr'>%s <a $DIFF_LINK_SETTING target='_blank' href='%s' class='locInfo' style='text-decoration: underline;' onmouseover=\"showTip('%s')\">$a_html</a> <i>%s</i></span> ",
                            $actions->[$i]->{date},
                            $diff_url,
                            $actions->[$i]->{comments},
                            $actions->[$i]->{author});    
		}
    }
    
    my $file_lines          = $file_added + $file_deleted;
    my $str_checkin_counter = sprintf("%03d", $actions_cnt + 1);
    my $str_file_lines      = sprintf("%07d", $file_lines);
    my $str_file_added      = sprintf("%07d", $file_added);
    my $str_file_deleted    = sprintf("%07d", $file_deleted);

    $begin =~ s/#TIMES#/$str_checkin_counter/;
    $begin =~ s/#LINES#/$str_file_lines (+$str_file_added -$str_file_deleted)/;
    $begin =~ s/#FILE_COLOR#/$file_clr/;
    my $title = $file_removed ? "removed" : "";
    $begin =~ s/#TITLE#/$title/;
    

	my $comm = " onmouseover=\"showTip('$actions->[0]->{comments}')\"";
	$begin =~ s/#TIPS#/$comm/;
    
    $html_actions .= $begin . $html_file_actions . $end;
	
    return {"html" => $html_actions};
}

# view cvs diff link example
# http://engcvsserv.corp.webex.com:8080/viewcvs/viewcvs.cgi/
#     supportcenter/src/java/com/webex/webapp/supportcenter/biz/report/ReportMgr.java.diff?r1=1.22&r2=1.22.74.1&only_with_tag=T25L10NSP41_B
sub get_file_viewcvs_diff_url($$$) {
    my $file = $_[0];
    my $new_revision = $_[1];
    my $previous_version = $_[2];
    
    my $file_view_cvs_diff_url = "";
    my $has_viewvc = has_viewvc_entry();
    my $difer = $has_viewvc ? $g_viewvc_entry : $CCV_DIFFER;
    
    my $url_params = "";
    if ($has_viewvc) {
	    if ($new_revision eq "1.1") {
			$file_view_cvs_diff_url = sprintf("%s/%s?rev=%s", 
										$difer, 
										$file, 
										uri_escape($new_revision));
	    } else {
			$file_view_cvs_diff_url = sprintf("%s/%s?r1=%s&r2=%s", 
										$difer, 
										$file, 
										uri_escape($previous_version), 
										uri_escape($new_revision));
		}
	} else {
	    if ($new_revision eq "1.1") {
			$file_view_cvs_diff_url = sprintf("%s?file=%s&r1=0&r2=%s", 
										$difer, 
										uri_escape($file), 
										uri_escape($new_revision));
	    } else {
			$file_view_cvs_diff_url = sprintf("%s?file=%s&r1=%s&r2=%s", 
										$difer, 
										uri_escape($file), 
										uri_escape($previous_version), 
										uri_escape($new_revision));	
		}		
		
	}
	
	if (!$has_viewvc) {
		$file_view_cvs_diff_url .= sprintf("&branch=%s&T_SNAPSHOT=%s&CFG=%s&module_id=%s&module=%s",
										uri_escape($g_branch), 
										uri_escape($_TIME_), 
										uri_escape($_CONFIG_FILE_), 
										uri_escape($g_module_id), 
										uri_escape($g_module));
	}
	
	
	return $file_view_cvs_diff_url;
}

sub has_viewvc_entry() {
	if ($g_viewvc_entry eq "" || $g_viewvc_entry eq "NONE" ) {
	    return 0;
	} else {
		return 1;	
	}
}

sub get_previous_revision($) {
    my $new_revision = $_[0];
    
    $new_revision =~ m/^(.*)\.(\d+)$/;
    my $previous_version = "";
    if ($2 > 1) {
        $previous_version = $1 . "." . ($2 - 1) 
    } else {
        $previous_version = $1;
        $previous_version =~ m/^(.*)\.(\d+)$/;
        if (defined($2)) {
            $previous_version = $1;
        }
    }  
    
    return $previous_version;   
}

sub getGraphParams() {
	return sprintf("&cgi_uri=%s&G_PATH=%s&cfg=%s&users=%s",
					uri_escape("/ccv-cgi/"), 
					uri_escape($assistor->get_module_co_head_path($g_branch, $g_module_id)),
					uri_escape($_CONFIG_FILE_),
					uri_escape(getSortedUsersString()));				
}

sub parse_command_line() {
    my $cmd_line = join (" ", @ARGV);
    
    if ($cmd_line =~ m/^-f([^\s]+)/) {
        $_CONFIG_FILE_ = $1;
    }
    
    if ($cmd_line =~ m/\s-t([^\s]+)/) {
        $_TIME_ = $1;   
    }
    
    if ($cmd_line =~ m/\s-r([^\s]+)/) {
        $g_branch = $1;   
    } 
    
    if ($cmd_line =~ m/\s-m([^\s]+)/) {
        $g_module_id = $1;
    }
    
    if ($cmd_line =~ m/\s-l([^\s]+)/) {
        $g_log_file = $1;
    }
    
    if ($cmd_line =~ m/\s-d([^\s]+)/) {
        $g_date = $1;
    }
    
    if ($cmd_line =~ m/\s-w([^\s]+)/) {
        $g_wid = $1;
    }
    if ($cmd_line =~ m/\s-gm([^\s]+)/) {
        $g_module_graph = $1;
    } 
    if ($cmd_line =~ m/\s-arm([^\s]+)/) {
        $g_calc_all_revs = $1;
    }
    if ($cmd_line =~ m/\s-sbm([^\s]+)/) {
        $g_stat_binary = $1;
    }
    if ($cmd_line =~ m/\s-sbl([^\s]+)/) {
        $g_stat_binary_lines = $1;
    }                  
    if ($cmd_line =~ m/\s-nsd([^\s]+)/) {
        $g_not_stat_deleted = $1;
    }                  

    return 0;
}
