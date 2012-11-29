#!/usr/bin/perl -I ./thirds -w
# author: lilong'en(lilongen@163.com)
# date:   07/11/2008
#
# add this file to implement: 
#   1. LOC between two Revision
#   2. CVS WEB diff individually (without ViewVC)
#
use strict;
use English;
use Data::Dumper;
use CGI;
use Assistor;
use CcvUtil;
use bytes;
no warnings 'reserved';

sub main();
sub print_loc_info();
sub write_data_to_file();
sub generate_group_items();
sub write_flat_items();
sub get_flat_item($);
sub construct_tree();
sub get_file_viewcvs_diff_url($$$);
sub parse_command_line();
sub output($);
sub handle_file_finished();
sub get_file_shown_info($);
sub get_directory_shown_info($);
sub get_directory_suffix_info($);
sub friend_revs_dates_4UI();
sub replacePart1PMS($$);
sub replacePart2PMS($);
sub get_independent_file_diff_url($);
sub parse_unified_format();
sub parse_context_format();
sub isBinaryFile($);
sub persistence_module_info($$$);

#parameters for construct Assistor object
my $_CONFIG_FILE_   = "";
my $_TIME_          = "";

my $g_revisions     = "";
my $g_rev1			= "_CCV_NULL_";
my $g_rev2			= "_CCV_NULL_";

my $g_dates         = "";
my $g_date1         = "_CCV_NULL_";
my $g_date2         = "_CCV_NULL_";

my $g_module_id     = "";
my $g_module        = "";
my $g_diff_file     = "";
my $g_viewvc_entry  = "";
my $g_viewvc_repository= "";

parse_command_line();

my $g_revs_dates = "";
if ($g_revisions ne "") {
	$g_revs_dates = $g_revisions;
} else {
	$g_revs_dates = $g_dates;
}
my $assistor        = new Assistor($_CONFIG_FILE_, $_TIME_);
my $ccvUtil 		= new CcvUtil();
$assistor->getModules();
my $g_module_info   = $assistor->get_module_info_by_module_id($g_module_id);

my $brief_report_file  			= $assistor->get_brief_report_file();
my $module_brief_report_file 	= $assistor->get_module_brief_report_file($g_module_id);

my $file_filter     = $g_module_info->{file_filter};
my $cvs_repository  = $g_module_info->{repository};

$g_module            = $g_module_info->{module};
if ($g_diff_file eq "") {
	$g_diff_file      = $assistor->get_revisions_module_diff_out_file($g_revs_dates, $g_module_info->{diff});
}

$g_viewvc_entry      = $g_module_info->{viewvc_entry};
$g_viewvc_repository 	= $g_module_info->{viewvc_repository};
$file_filter 		= $g_module_info->{file_filter};
my $g_rdiff_loc_file_url  = "/ccv/" . $g_diff_file; 

my $_ERROR_			= "";

my $_EXPANDED_LEVELS_ 	= 4;

# all files level
my $changed_file_amount = 0;
my $line_cnt            = 0;
my $line_cnt_added      = 0;
my $line_cnt_removed    = 0;
my $line_cnt_modified   = 0;

my $un_exist_in_left	= 0;
my $un_exist_in_right   = 0;
my $removed_in_left     = 0;
my $removed_in_right    = 0;

my $init_status			= 1;
my $flat_items			= [];
my $new_files			= [];
my $binary_files		= [];
my $removed_files		= [];

my $items 				= {};
my $temp_items			= $items;
my $temp_previous_item 	= $temp_items;
my $lefts				= [];
my $tree_items			= [];

# file level
my $line        		= "";
my $file        		= "";

my $file_ext_match	    = 0;
my $file_found  		= 0;
my $version_found 		= 0;	
my $version_time_found 	= 0;

my $un_exist_in 		= "";
my $removed_in	 		= "";

my $file_line_add    	= 0;
my $file_line_del    	= 0;
my $file_line_modified 	= 0;

my $rev1	    		= "";
my $rev2    			= "";
my $rev1_time   		= "";
my $rev2_time  			= "";    

my $FILE_FLAG   		= "Index:";
my $UN_EXIST_FLAG 		= "/dev/null";
my $REMOVED_FLAG 		= "removed";

#color for item shown format
my $_clr_gray_          = "#555555";
my $_clr_user_          = "#0000ff";
my $_clr_file_          = "#0000ff";
my $_clr_item_          = "#999999";
my $_clr_directory_		= "#000000";

#handle for report files
my $h_text_file;
my $h_module_text_file;																			
my $h_group_html_file																		;
my $h_flat_html_file;
	
my $H_DIFF;		
my $file_pos_start 	= 0;
my $file_pos_end 	= 0;
my $DIFF_VIEWER		= "diff.unified.pl";															
my $LINE_NO  		= 0;

exit main();

sub main() {
	if (!open($H_DIFF, $g_diff_file)) {
		output("Can not open $g_diff_file!\n");
		
		return 1;
	}
	
	parse_unified_format();	
	#parse_context_format();

	close($H_DIFF);

# my $DEBUG;
# if (!open($DEBUG, ">", "DBG.txt")) {
# 	return 1;
# }
# print $DEBUG Dumper($items);
# print $DEBUG Dumper($flat_items);
# close($DEBUG);   	
	unshift(@{$flat_items}, @{$new_files}); # put new added files into first
	unshift(@{$flat_items}, @{$removed_files}); # put removed files into first
	push(@{$flat_items}, @{$binary_files}); # last binary file in array

	print_loc_info();
	write_data_to_file();

	return 0;
}


sub parse_unified_format() {
	my $file_found_line_no = -1;
	while (1) {
		$line = <$H_DIFF>;
		if (!defined($line)) {
			if ($file_ext_match == 1) {
				handle_file_finished();
			}
			$temp_items 		= $items;
			
			$temp_previous_item = $temp_items;
			$line_cnt 			= $line_cnt_added + $line_cnt_removed + $line_cnt_modified;		
				
			last;
		}
		
		if ($LINE_NO++ == 0) {
			if ($line !~ m/^$FILE_FLAG (.*)$/) { # no such tag, and so on
				$_ERROR_ = $line;

				last;
			}		
		}
		
		#  Index: mywebex/src/java/com/webex/webapp/mywebex/biz/UserTicket.java
		if ($file_found == 0 && $line =~ m/^$FILE_FLAG (.*)$/) {
			if ($file_ext_match == 1 && $changed_file_amount > 0) {
				handle_file_finished();		
			}
			$file_found_line_no = $LINE_NO;
			my $file_ext_name = substr($1, rindex($1, "."));
			if ($file_filter eq ".*"
				|| index($file_filter, $file_ext_name) != -1) {
				$file_ext_match 	= 1;
	 			$file_found 		= 1;
    			$file 				= $1;
    			$file_pos_start		= tell($H_DIFF);
    		    $changed_file_amount++;
    		    #print "changed_file_amount: $changed_file_amount -- $file\n";
    		    if ($file =~ m/(.*)\/Attic\/(.*)/) {
    		        $file = $1 . "/" . $2;
    		    }
			        		    
				next;
			} else {
				$file_ext_match = 0;
				next;	
			}
		}
			
		##Begin Following block handle this case -- add in 9/11/2009
		# 
		# cvs rdiff: failed to read diff file header /tmp/cvsir7v9D for ui-icons_cd0a0a_256x240.png,v: end of file
		# Index: web/jquery/ui/css/smoothness/images/ui-icons_ffffff_256x240.png
		# cvs rdiff: failed to read diff file header /tmp/cvsAwmkgd for ui-icons_ffffff_256x240.png,v: end of file
		# Index: web/jquery/ui/js/jquery-ui-1.7.2.custom.min.js
		# diff -u /dev/null web/jquery/ui/js/jquery-ui-1.7.2.custom.min.js:1.1
		# --- /dev/null	Fri Sep 11 04:43:26 2009
		# +++ web/jquery/ui/js/jquery-ui-1.7.2.custom.min.js	Wed Sep  9 05:45:30 2009
		# @@ -0,0 +1,298 @@			
		#
		if ($file_found == 1 && $LINE_NO - $file_found_line_no == 1) {
			if ($line !~ m/^diff -u /) {
				if ($file_ext_match == 1) {
					handle_file_finished();
				} else {
					$file_ext_match = 0;
		 			$file_found 	= 0;
				}
				
				next;
			}
		}
		##End		
		
		#  diff -u mywebex/src/java/com/webex/webapp/mywebex/biz/UserTicket.java:1.11 mywebex/src/java/com/webex/webapp/mywebex/biz/UserTicket.java:1.13
		#  diff -u /dev/null mywebex/src/java/com/webex/webapp/mywebex/common/ServiceRequestAction.java:1.4  
		if ($file_ext_match == 1
			&& $file_found == 1 
			&& $line =~ m/^diff -u ($UN_EXIST_FLAG|[^\s]+:($REMOVED_FLAG|[^\s]+)) ($UN_EXIST_FLAG|[^\s]+:($REMOVED_FLAG|[^\s]+))$/) {
		
			if ($1 eq $UN_EXIST_FLAG) {
				$un_exist_in = "L";
				$un_exist_in_left ++;
			} elsif ($2 eq $REMOVED_FLAG) {
				$removed_in = "L";	
				$removed_in_left ++;
			} else {
				$rev1 = $2;	
			}
			
			if ($3 eq $UN_EXIST_FLAG) {
				$un_exist_in = "R";
				$un_exist_in_right ++;
			} elsif ($4 eq $REMOVED_FLAG) {
				$removed_in = "R";
				$removed_in_right ++;
			} else {
				$rev2 = $4;
			}

			$version_found = 1;
			
			next;
		}
		
		# --- src/windows/ST/AASETUP/aasetup.rc:1.23	Sun Jun 29 23:31:13 2008
		# +++ src/windows/ST/AASETUP/aasetup.rc	Mon Jul 21 02:36:10 2008		
		
		# --- /dev/null	Fri Jul 11 00:02:41 2008
		# +++ mywebex/src/java/com/webex/webapp/mywebex/common/ServiceRequestAction.java	Wed Jul  9 22:51:30 2008		
		if ($file_ext_match == 1
			&& $version_found == 1
			&& $line =~ m/^-{3}\s[^\s]+\s+(.*)$/) {
			$rev1_time = $1;
			
			next;
		}		
		
		if ($file_ext_match == 1
			&& $version_found == 1
			&& $line =~ m/^\+{3}\s[^\s]+\s+(.*)$/) {
			$rev2_time = $1;
			
			$version_time_found = 1;
			
			$file_found = 0;			
			$version_found = 0;

			next;
		}
		
		if ($file_ext_match == 1
			&& $version_time_found  == 1
			&& $line =~ m/^([\-\+])/) {
			if ($1 eq "+") {
				$file_line_add ++;
			} elsif ($1 eq "-") {
				$file_line_del ++;
			} elsif ($1 eq "!") {
				$file_line_modified ++;
			}
		}
	} #end while
}

sub parse_context_format() {
	while (1) {
		$line = <$H_DIFF>;
		if (!defined($line)) {
			last;
		}
		
		if ($LINE_NO++ == 0) {
			if ($line !~ m/^$FILE_FLAG (.*)$/) { # no such tag, and so on
				$_ERROR_ = $line;

				last;
			}		
		}
		
		
		#  Index: mywebex/src/java/com/webex/webapp/mywebex/biz/UserTicket.java
		if ($file_found == 0 && $line =~ m/^$FILE_FLAG (.*)$/) {
			if ($file_ext_match == 1 && $changed_file_amount > 0) {
				handle_file_finished();		
			}
			
			my $file_ext_name = substr($1, rindex($1, "."));
			if ($file_filter eq ".*"
				|| index($file_filter, $file_ext_name) != -1) {
				$file_ext_match 	= 1;
	 			$file_found 		= 1;
    			$file 				= $1;
    		    
    		    $changed_file_amount++;
    		    #print "changed_file_amount: $changed_file_amount -- $file\n";
    		    if ($file =~ m/(.*)\/Attic\/(.*)/) {
    		        $file = $1 . "/" . $2;
    		    }
			        		    
				next;
			} else {
				$file_ext_match = 0;
				next;	
			}
		}
		#  diff -c mywebex/src/java/com/webex/webapp/mywebex/biz/UserTicket.java:1.11 mywebex/src/java/com/webex/webapp/mywebex/biz/UserTicket.java:1.13
		#  diff -c /dev/null mywebex/src/java/com/webex/webapp/mywebex/common/ServiceRequestAction.java:1.4  
		if ($file_ext_match == 1
			&& $file_found == 1 
			&& $line =~ m/^diff -c ($UN_EXIST_FLAG|[^\s]+:($REMOVED_FLAG|[^\s]+)) ($UN_EXIST_FLAG|[^\s]+:($REMOVED_FLAG|[^\s]+))$/) {
			if ($1 eq $UN_EXIST_FLAG) {
				$un_exist_in = "L";
				$un_exist_in_left ++;
			} elsif ($2 eq $REMOVED_FLAG) {
				$removed_in = "L";	
				$removed_in_left ++;
			} else {
				$rev1 = $2;	
			}
			
			if ($3 eq $UN_EXIST_FLAG) {
				$un_exist_in = "R";
				$un_exist_in_right ++;
			} elsif ($4 eq $REMOVED_FLAG) {
				$removed_in = "R";
				$removed_in_right ++;
			} else {
				$rev2 = $4;
			}

			$version_found = 1;
			
			next;
		}
		
		#  *** mywebex/src/java/com/webex/webapp/mywebex/biz/UserTicket.java:1.11	Wed Apr 16 19:59:15 2008
		#  --- mywebex/src/java/com/webex/webapp/mywebex/biz/UserTicket.java	Tue Jul  8 18:53:25 2008
		
		#  *** /dev/null	Fri Jul 11 00:02:41 2008
		#  --- mywebex/src/java/com/webex/webapp/mywebex/common/ServiceRequestAction.java	Wed Jul  9 22:51:30 2008		
		if ($file_ext_match == 1
			&& $version_found == 1
			&& $line =~ m/^\*{3}\s[^\s]+\s+(.*)$/) {
			$rev1_time = $1;
			
			next;
		}		
		
		if ($file_ext_match == 1
			&& $version_found == 1
			&& $line =~ m/^\-{3}\s[^\s]+\s+(.*)$/) {
			$rev2_time = $1;
			
			$version_time_found = 1;
			
			$file_found = 0;			
			$version_found = 0;

			next;
		}
		
		if ($file_ext_match == 1
			&& $version_time_found  == 1
			&& $line =~ m/^([\-\+!])/) {
			if ($1 eq "+") {
				$file_line_add ++;
			} elsif ($1 eq "-") {
				$file_line_del ++;
			} elsif ($1 eq "!") {
				$file_line_modified ++;
			}
				
		}
	} #end while	
}

sub handle_file_finished() {
	$file_pos_end = tell($H_DIFF);

	my $file_item = {};
	$file_item->{file} 			= $file;
	$file_item->{line_added} 	= $file_line_add;
	$file_item->{line_removed} 	= $file_line_del;
	$file_item->{line_modified} = $file_line_modified;
	
	$file_item->{rev1}			= $rev1;
	$file_item->{rev2}			= $rev2;
	$file_item->{rev1_time}		= $rev1_time;
	$file_item->{rev2_time}		= $rev2_time;
					
	$file_item->{un_exist_in} 	= $un_exist_in;
	$file_item->{removed_in} 	= $removed_in;
	
	$file_item->{pos_start}		= $file_pos_start;
	$file_item->{pos_end}		= $file_pos_end;
	
	my @directorys = split(/[\/\\]+/, $file);
	
	$file_item->{SELF} 	= $directorys[$#directorys];
	
	my $dir_levels = $#directorys;
	for (my $level = 0; $level < $dir_levels; $level++) {
		if (!defined($temp_items->{$directorys[$level]})) {
			$temp_items->{$directorys[$level]} = {};
			$temp_items->{$directorys[$level]}->{'__CCV_INFO__'} = {};
			$temp_items->{$directorys[$level]}->{'__CCV_INFO__'}->{LEVEL} = $level;
			$temp_items->{$directorys[$level]}->{'__CCV_INFO__'}->{HANDLED} = 0;
			$temp_items->{$directorys[$level]}->{'__CCV_INFO__'}->{SELF} = $directorys[$level];
			if ($level == 0) {
				$temp_items->{$directorys[$level]}->{'__CCV_INFO__'}->{PARENT} = "";
			} else {
				$temp_items->{$directorys[$level]}->{'__CCV_INFO__'}->{PARENT} = $temp_previous_item->{$directorys[$level - 1]}->{'__CCV_INFO__'}->{PARENT} . $directorys[$level - 1] . "/";
			}
		}
		
		$temp_items->{$directorys[$level]}->{'__CCV_INFO__'}->{'FILES'} ++ ;
		$temp_items->{$directorys[$level]}->{'__CCV_INFO__'}->{'LINE_ADDED'} += $file_item->{line_added};
		$temp_items->{$directorys[$level]}->{'__CCV_INFO__'}->{'LINE_REMOVED'} += $file_item->{line_removed};
		$temp_items->{$directorys[$level]}->{'__CCV_INFO__'}->{'LINE_MODIFIED'} += $file_item->{line_modified};						
		
		$temp_previous_item = $temp_items;
		$temp_items = $temp_items->{$directorys[$level]};				
	}
	
	$file_item->{LEVEL}  = $temp_previous_item->{$directorys[$dir_levels - 1]}->{'__CCV_INFO__'}->{LEVEL} + 1;
	$file_item->{PARENT} = $temp_previous_item->{$directorys[$dir_levels - 1]}->{'__CCV_INFO__'}->{PARENT} . $directorys[$dir_levels - 1] . "/";
	
	$temp_items->{$directorys[$dir_levels]} = $file_item;
	
	$temp_items = $items;
	
	if ($file_item->{un_exist_in} ne "") {
		push(@{$new_files}, $file_item);
	} elsif ($file_item->{removed_in} ne "") {
		push(@{$removed_files}, $file_item);
	}  elsif (isBinaryFile($file_item)) {
		push(@{$binary_files}, $file_item);
	} else {
		push(@{$flat_items}, $file_item);
	}
	
	$line_cnt_added    += $file_item->{line_added};
	$line_cnt_removed  += $file_item->{line_removed};
	$line_cnt_modified += $file_item->{line_modified};				


    $file_found 		= 0;
    $file_ext_match		= 0;
	$version_found 		= 0;
	$version_time_found = 0;
	    		    			    
    $un_exist_in 		= "";
    $removed_in			= "";
    
    $file_line_add    	= 0;
    $file_line_del    	= 0;
    $file_line_modified = 0;
    
	$rev1 				= "";
	$rev2 				= "";
	$rev1_time 			= "";
	$rev2_time 			= "";
	
	$file_pos_start 	= $file_pos_end;				
}

sub write_data_to_file() {
	if (!open($h_text_file, ">>", "$brief_report_file")) {
		output("Can not create/open $brief_report_file!\n");
		
		return 1;
	}
	
	if (!open($h_module_text_file, ">>", "$module_brief_report_file")) {
		output("Can not create/open $module_brief_report_file!\n");
		
		return 1;
	}	
	
    my $HTML_TEMPLATE = $assistor->get_report_template_file("DIFF");
    my $node_flag   = "#NODE#";
    my $template    = $assistor->read_whole_file($HTML_TEMPLATE);
    my $node_pos    = index($template, $node_flag);
    my $part1       = substr($template, 0, $node_pos);
    my $part2       = substr($template, $node_pos + length($node_flag));
    
    my $file_part1  = $part1;
        
    my $group_html_out_file = $assistor->get_specified_output_report_file({flag => "DIFF_GROUP", revs => $g_revs_dates, mid=> $g_module_id});
    my $flat_html_out_file = $assistor->get_specified_output_report_file({flag => "DIFF_FLAT", revs => $g_revs_dates, mid=> $g_module_id});

    if (!open($h_group_html_file, ">", "$group_html_out_file")) {
		output("Can not create/open $group_html_out_file!\n");
		
		return 1;
	} 
	
    if (!open($h_flat_html_file, ">", "$flat_html_out_file")) {
		output("Can not create/open $flat_html_out_file!\n");
		
		return 1;
	} 	
    
    my $cvs_root = $assistor->get_module_cvsroot_without_uid($g_module_info);
    
    friend_revs_dates_4UI();

    my $module_brief_txt = sprintf("Module: %s (%s - %s); Revision1: %s; Revision2: %s; Date1: %s; Date2: %s,,\n",
                        $g_module_id, 
                        $g_module,
                        $cvs_root,
                        $g_rev1,
                        $g_rev2,
                        $g_date1,
                        $g_date2);
                        
    $module_brief_txt .= sprintf("LOC, FOC\n%07d, %04d\n\n", 
                        $line_cnt,
                        $changed_file_amount);
                        
	my $LOC =  sprintf("%d(+%d, -%d)\n", 
                        $line_cnt, 
                        $line_cnt_added,
                        $line_cnt_removed);                                           
                        
	
    my $diff_group_report_url = $assistor->transReportLocalPath2WebPath($assistor->get_specified_output_report_file({flag => "DIFF_GROUP", revs => $g_revs_dates, mid=> $g_module_id}));
    my $diff_flat_report_url = $assistor->transReportLocalPath2WebPath($assistor->get_specified_output_report_file({flag => "DIFF_FLAT", revs => $g_revs_dates, mid=> $g_module_id})); 
    my $module_rdiff_brief_report_url = $assistor->transReportLocalPath2WebPath($assistor->get_module_brief_report_file($g_module_id));
    my $rdiff_brief_report_url = $assistor->transReportLocalPath2WebPath($assistor->get_brief_report_file());
    
    my $template_parametrs = {'MODULE' 			=> $g_module,
    						  'CVSROOT' 		=> $cvs_root,
    						  'REVISION1' 		=> $g_rev1,
    						  'REVISION2' 		=> $g_rev2,
    						  'DATE1' 			=> $g_date1,
    						  'DATE2' 			=> $g_date2,
    						  'FOC' 			=> $changed_file_amount,
    						  'LOC' 			=> $LOC,
    						  'CURRENT_URL'		=> "",
    						  'CURRENT_NAME' 	=> "",
        					  'OTHER_URL' 		=> $diff_flat_report_url,
    						  'OTHER_NAME' 		=> "Flat",
    						  'MODULE_PLAIN_REPORT'	=> $module_rdiff_brief_report_url,
    						  'PLAIN_REPORT'		=> $rdiff_brief_report_url};
	
	replacePart1PMS(\$part1, $template_parametrs);
	
	$template_parametrs->{OTHER_URL} 	= $diff_group_report_url;
	$template_parametrs->{OTHER_NAME} 	= "Tree";
    replacePart1PMS(\$file_part1, $template_parametrs);
    
    replacePart2PMS(\$part2);
	
	print $h_group_html_file $part1;
	if ($_ERROR_ eq "") {# no error
		generate_group_items();
		construct_tree();	
	}	
	print $h_group_html_file $part2;
    

	print $h_flat_html_file $file_part1;
	if ($_ERROR_ eq "") {# no error
		write_flat_items();
	}
	print $h_flat_html_file $part2;

    print $h_text_file $module_brief_txt . "\n\n";
    print $h_module_text_file $module_brief_txt . "\n\n";

	close($h_text_file);
	close($h_module_text_file);
	close($h_group_html_file);
	close($h_flat_html_file);
	
	persistence_module_info($g_module_id, $changed_file_amount, $line_cnt);


	return 0;
}

sub persistence_module_info($$$) {
	my $mid = shift;
	my $foc = shift;
	my $loc = shift;
	
	my $data = {};
	$data->{$mid} = {foc => $foc, loc => $loc};

	my $G_ALL_MODULES_INFO_FILE = $assistor->get_all_modules_sum_info_data_file();
	my $tmp;
	
	if (-e $G_ALL_MODULES_INFO_FILE) {
		$tmp = $ccvUtil->loadFile($G_ALL_MODULES_INFO_FILE);
		$tmp->{$mid} = $data->{$mid};
	} else {
		$tmp = $data;
	}
	
	$ccvUtil->dumpFile($G_ALL_MODULES_INFO_FILE, $tmp);	
}

sub replacePart1PMS($$) {
	my $content	= $_[0];
    my $paras 	= $_[1];
	
	$$content =~ s/#BODY_CLS#/svnDiffReport/;    						
    $$content =~ s/#MODULE#/$paras->{MODULE}/;
    $$content =~ s/#MODULE_URI#/$paras->{CVSROOT}/;
    $$content =~ s/#REVISION1#/$paras->{REVISION1}/;
    $$content =~ s/#REVISION2#/$paras->{REVISION2}/;
    $$content =~ s/#DATE1#/$paras->{DATE1}/;
    $$content =~ s/#DATE2#/$paras->{DATE2}/;
    $$content =~ s/#FOC#/$paras->{FOC}/;
    $$content =~ s/#LOC#/$paras->{LOC}/;
    $$content =~ s/#OTHER_URL#/$paras->{OTHER_URL}/;
    $$content =~ s/#OTHER_NAME#/$paras->{OTHER_NAME}/;
    $$content =~ s/#DIFF_FILE#/$g_rdiff_loc_file_url/;
    $$content =~ s/#MODULE_PLAIN_REPORT#/$paras->{MODULE_PLAIN_REPORT}/;
    $$content =~ s/#PLAIN_REPORT#/$paras->{PLAIN_REPORT}/;
    $$content =~ s/#ERROR#/$_ERROR_/;
}

sub replacePart2PMS($) {
	my $content	= $_[0];
	my $error = $_ERROR_ eq "" ? 0 : 1;
    my $GV_IN_JS =<<GV_IN_JS;
{
	T_SNAP: "$_TIME_",
	MID: "$g_module_id",
	Error: "$error",
	ShowGraphEntry: "0",
	ShowSrcDetails: "0",
	ReportType: "CVS_DIFF"
}
GV_IN_JS
    
	$$content =~ s/#GV#/$GV_IN_JS/;
}

sub friend_revs_dates_4UI() {
	my $HEAD = "HEAD(MAIN)";
    if ($g_rev1 eq "_CCV_NULL_" && $g_rev2 eq "_CCV_NULL_") {
    	$g_rev1 	= "N/A";
    	$g_rev2 	= "N/A";	
    } else {
    	if (!($g_rev1 ne "_CCV_NULL_" && $g_rev2 ne "_CCV_NULL_")) {
    		$g_rev1 = ($g_rev1 ne "_CCV_NULL_" ? $g_rev1 : $g_rev2);
    		$g_rev2 = $HEAD;
    	}
    }
    
    if ($g_date1 eq "_CCV_NULL_" && $g_date2 eq "_CCV_NULL_") {
    	$g_date1 	= "N/A";
    	$g_date2 	= "N/A";	
    } else {
    	if (!($g_date1 ne "_CCV_NULL_" && $g_date2 ne "_CCV_NULL_")) {
    		$g_date1 = ($g_date1 ne "_CCV_NULL_" ? $g_date1 : $g_date2);
    		$g_date2 = $HEAD;
    	}
    }    
}

#sub generate_group_items() {
#	if ($init_status == 1 || defined($temp_items->{__CCV_INFO__})) { # directory
#		$init_status = 0;
#		my @curr_keys = sort {
#		        	lc($a) cmp lc($b)     # compare with key
#		    		}  keys %{$temp_items};
#		
#		my $checked_length = $#curr_keys;			
#		for (my $index = 0; $index <= $checked_length; $index++) {
#			if ($curr_keys[$index] ne "__CCV_INFO__" && !defined($temp_items->{$curr_keys[$index]}->{__CCV_INFO__})) { # file
#				my $kname = $curr_keys[$index];
#	
#				splice(@curr_keys, $index, 1);
#				push(@curr_keys, $kname);
#				$checked_length --;
#				$index --;
#			}
#		}
#	
#		for (my $i = $#curr_keys; $i >= 0; $i--) {
#			if (defined($temp_items->{$curr_keys[$i]}->{__CCV_INFO__})) { # directory
#				push(@{$lefts}, $temp_items->{$curr_keys[$i]});	
#				
#				next;	
#			} else { # file
#				if ($curr_keys[$i] eq "__CCV_INFO__") {
#					next;
#				}
#				
#				push(@{$lefts}, $temp_items->{$curr_keys[$i]});	
#			}
#		}
#	}
#
#	if ($#{$lefts} >= 0) {
#		$temp_items = pop(@{$lefts});
#		push(@{$tree_items}, $temp_items);	
#		
#		generate_group_items();
#	}
#}

#use stack method to replace recursive calling
sub generate_group_items() {
	while (1) {
		if ($init_status == 1 || defined($temp_items->{__CCV_INFO__})) { # directory
			$init_status = 0;
			my @curr_keys = sort {
			        	lc($a) cmp lc($b)     # compare with key
			    		}  keys %{$temp_items};
			
			my $checked_length = $#curr_keys;			
			for (my $index = 0; $index <= $checked_length; $index++) {
				if ($curr_keys[$index] ne "__CCV_INFO__" && !defined($temp_items->{$curr_keys[$index]}->{__CCV_INFO__})) { # file
					my $kname = $curr_keys[$index];
		
					splice(@curr_keys, $index, 1);
					push(@curr_keys, $kname);
					$checked_length --;
					$index --;
				}
			}
		
			for (my $i = $#curr_keys; $i >= 0; $i--) {
				if (defined($temp_items->{$curr_keys[$i]}->{__CCV_INFO__})) { # directory
					push(@{$lefts}, $temp_items->{$curr_keys[$i]});	
					
					next;	
				} else { # file
					if ($curr_keys[$i] eq "__CCV_INFO__") {
						next;
					}
					
					push(@{$lefts}, $temp_items->{$curr_keys[$i]});	
				}
			}
		}
		
		if ($#{$lefts} < 0) {
			last;
		}
		
		$temp_items = pop(@{$lefts});
		push(@{$tree_items}, $temp_items);	
	}
}

sub construct_tree() {
	my $tree_string 	= "";
	my $suffix 			= "";
	my $item 			= "";	
	my $level 			= -1;
	my $previous_level 	= -1;	
	
	my $previous_is_directory 	= 0;
	my $is_directory 	= 0;
	my $delta_level 	= 0;
	
	my $dir_operator_style = "";
	my $dir_display 	   = "";
	
	my $dir_suffix_info    = "";
	for (my $i = 0; $i <= $#{$tree_items}; $i++) {
		$is_directory = defined($tree_items->[$i]->{__CCV_INFO__});
		if ($is_directory) {
			$dir_suffix_info = get_directory_suffix_info($tree_items->[$i]->{__CCV_INFO__});
		}
		if ($is_directory) { #directory
			$level = $tree_items->[$i]->{__CCV_INFO__}->{LEVEL};
		} else {
			$level = $tree_items->[$i]->{LEVEL};
		}
		
		my $indent = 220 + (12 - $level) * 22;
		$indent .= "px";
		
		if ($i == 0) {
			$suffix = "";
			$previous_level = 0;
			$previous_is_directory = 1;
			
			#@todo, add collapse/expand all feature
			#my $operator_url = "&nbsp;&nbsp;&nbsp;";
			#$operator_url = "<a href='javascript: expandAll(false);'>-Collapse All</a>";
			#$operator_url .= "&nbsp;&nbsp;&nbsp;";
			#$operator_url .= "<a href='javascript: expandAll(true);'>+Expand All</a>";
			my $treeOperator = "<i>[<a href='javascript: expandAll(true)' class='treeOperator'>Expand All</a>&nbsp;/&nbsp;<a href='javascript: expandAll(false)' class='treeOperator'>Collapse All</a>]</i>";		
			$item = "\n<li style='margin-left: 10px; display: block;'><span class='plus' onclick='showChildren(this)'></span><span class='fwspan' style='width: $indent;'><a href='#' style='color: $_clr_directory_'><b>" . $tree_items->[$i]->{__CCV_INFO__}->{SELF} . "</b></a>&nbsp;&nbsp;&nbsp;&nbsp;" . $treeOperator . "</span>\n<ul style='display: block;'>";
		} else {
			$delta_level = $level - $previous_level;
			if (!$previous_is_directory) {
				if ($is_directory) {
					$delta_level ++;	
				}
			}	
			
			if ($delta_level > 0) {
				$suffix = "";
			} elsif ($delta_level < 0) {
				$suffix = "";
				
				if (!$previous_is_directory && !$is_directory) {
					$delta_level ++;
				}
				
				for (my $j = 0; $j <= abs($delta_level); $j ++) {
					$suffix .= "\n</ul>\n</li>";
				}
			} else { #equal
				if ($is_directory) {
					$suffix = "\n</ul>\n</li>";
				} else {
					$suffix = "";
				}
			}
			
			if ($is_directory) {
				$dir_operator_style = $level >= $_EXPANDED_LEVELS_ ? "plus" : "minus";
				$dir_display = $level >= $_EXPANDED_LEVELS_ ? "none" : "block";

				$item = "\n<li><span class='$dir_operator_style' onclick='showChildren(this)'></span><a href='#' class='dirLOC'><span class='fwspan' style='width: $indent;'><span class='directory'>" . $tree_items->[$i]->{__CCV_INFO__}->{SELF} . "</span></span></a>" . $dir_suffix_info . "\n<ul style='display: $dir_display;'>";
			} else {
				my $file_shown_info = get_file_shown_info($tree_items->[$i]);
				
				if (isBinaryFile($tree_items->[$i])) {
					$item = sprintf("\n<li><span class='ci'></span><span class='fwspan' title='%s' style='width: $indent;'><span class='file' style='color: %s;'>%s</span></span>\n</li>",
							$file_shown_info->{tips},
							$file_shown_info->{color},
							$tree_items->[$i]->{SELF});				
				} else {
					my $LOC = sprintf("<span class='fileLoc'>%s(+%s, -%s)</span>",
								$file_shown_info->{total_lines},
								$file_shown_info->{added_lines},
								$file_shown_info->{removed_lines});					
					$item = sprintf("\n<li><span class='ci'></span><a target='_blank' class='txtLocTxt' href='%s' title='%s'><span class='fwspan' style='width: $indent;'><span class='file' style='color: %s;'>%s</span></span>%s</a>\n</li>",
							$file_shown_info->{diff_url},
							$file_shown_info->{tips},
							$file_shown_info->{color},
							$tree_items->[$i]->{SELF},
							$LOC);
				}
			}			

			$previous_level = $level;
			$previous_is_directory = $is_directory;
		}
		
		$tree_string .= $suffix . $item;
		
		if ($i % 20 == 0 || $i == $#{$tree_items}) {
			print $h_group_html_file $tree_string;	
			
			$tree_string = "";
		}
	}
}

sub write_flat_items() {
	my $files_cnt = $#{$flat_items};

	my $html_out = "";
	for (my $index = 0; $index <= $files_cnt; $index++) {
		$html_out .= get_flat_item($index);
		
		if ($index % 20 == 0 || $index == $files_cnt) {
			print $h_flat_html_file $html_out;
			$html_out = "";
		}
	}
}


sub get_flat_item($) {
    my $index = $_[0];
    
    my $file_shown_info = get_file_shown_info($flat_items->[$index]);
    my $ret = "";
    if (isBinaryFile($flat_items->[$index])) {
    	$ret = sprintf("<li><span class='ci'></span><span title='%s'><span class='binLocTxt %s'>#LINES#</span> <span class='%s'>%s</span></span></li>\n",
                         $file_shown_info->{tips},
                         $file_shown_info->{color},
                         $file_shown_info->{color},
                         $flat_items->[$index]->{file});    	
    } else {
    	$ret = sprintf("<li><span class='ci'></span><a target='_blank' href='%s' title='%s'><span class='txtLocTxt'>#LINES#</span> <span class='%s'>%s</span></a></li>\n",
                         $file_shown_info->{diff_url},
                         $file_shown_info->{tips},
                         $file_shown_info->{color},
                         $flat_items->[$index]->{file});
	}
                         
        
    my $str_total_lines         = $file_shown_info->{total_lines};
    my $str_added_lines      	= $file_shown_info->{added_lines};
    my $str_removed_lines    	= $file_shown_info->{removed_lines};

    $ret =~ s/#LINES#/$str_total_lines (+$str_added_lines, -$str_removed_lines)/;
	
    return $ret;
}

sub get_file_shown_info($) {
	my $item = $_[0];

	my $file_tips = "";
	my $clr_4filename = $_clr_file_;
	if ($item->{un_exist_in} eq "L") {
		$file_tips = "un-exist in revison1/date1";
		$clr_4filename = "fileUnExistAtL";
	}
	
	if ($item->{un_exist_in} eq "R") {
		$file_tips = "un-exist in revison2/date2";	
		$clr_4filename = "fileUnExistAtR";
	}
	
	if (isBinaryFile($item)) {
		$file_tips = "binary file, diff unavaiable!";
		$clr_4filename = "fileBinary";
	}
	
	my $file_diff = "";
	#if ($g_viewvc_entry eq "" || $g_viewvc_entry eq "NONE") { riff mode, always use ccv self diff viewer
	if (1) {
    	$file_diff = get_independent_file_diff_url($item);
    } else {
    	$file_diff = get_file_viewcvs_diff_url($item->{file}, $item->{rev1}, $item->{rev2});
    }

    my $str_total_lines         = sprintf("%07d", $item->{line_added} + $item->{line_removed} + $item->{line_modified});
    my $str_added_lines      	= sprintf("%07d", $item->{line_added});
    my $str_removed_lines    	= sprintf("%07d", $item->{line_removed});
    
    return {'color' 			=> $clr_4filename,
    		'tips'  			=> $file_tips,
    		'diff_url' 			=> $file_diff,
    		'total_lines' 		=> $str_total_lines,
    		'added_lines' 		=> $str_added_lines,
    		'removed_lines' 	=> $str_removed_lines
    };
}



sub get_directory_shown_info($) {
}

sub get_directory_suffix_info($) {
	my $item = $_[0];
	
	my $ret = sprintf("<span class='dirLOC'>%07d(+%07d, -%07d)</span><span class='dirFileCnt'> - %04d files</span>",
						$item->{LINE_ADDED} + $item->{LINE_REMOVED},
						$item->{LINE_ADDED},
						$item->{LINE_REMOVED},
						$item->{FILES});	
			
	return $ret;
}

sub output($) {
	print $_[0];
}

sub print_loc_info() {
	output("File: $g_diff_file\n");
	output("Changed file amount:   $changed_file_amount\n");
	output("Changed line amount:   $line_cnt (+$line_cnt_added, -$line_cnt_removed)\n\n\n");
}

# view cvs diff link example
# http://engcvsserv.corp.webex.com:8080/viewcvs/viewcvs.cgi/
#     supportcenter/src/java/com/webex/webapp/supportcenter/biz/report/ReportMgr.java.diff?r1=1.22&r2=1.22.74.1&only_with_tag=T25L10NSP41_B
sub get_file_viewcvs_diff_url($$$) {
    my $file = $_[0];
    my $rev1 = $_[1];
    my $rev2 = $_[2];
	
	my $file_view_cvs_diff_url = "";
	if ($rev1 ne "" && $rev2 ne "") {
		$file_view_cvs_diff_url = sprintf("%s/%s?r1=%s&r2=%s", 
									$g_viewvc_entry, 
									$file, 
									$rev1, 
									$rev2);
	} else {
		$file_view_cvs_diff_url = sprintf("%s/%s?rev=%s", 
									$g_viewvc_entry, 
									$file, 
									($rev1 ne "" ? $rev1 : $rev2));		
	}
	if ($g_viewvc_repository ne "") {
		$file_view_cvs_diff_url .= "&cvsroot=$g_viewvc_repository";
	}
	
	return $file_view_cvs_diff_url;
}

sub get_independent_file_diff_url($) {
	my $item = $_[0];
	my $url = sprintf("%s%s?rdiff=%s&start=%d&end=%d&self=%s&parent=%s&un_exist_in=%s&removed_in=%s&rev1=%s&rev2=%s&rev1_time=%s&rev2_time=%s",
						"/ccv-cgi/",
						$DIFF_VIEWER,
						CGI::escape($g_diff_file),
						$item->{pos_start},
						$item->{pos_end},
						CGI::escape($item->{SELF}),
						CGI::escape($item->{PARENT}),
						$item->{un_exist_in},
						$item->{removed_in},
						$item->{rev1},
						$item->{rev2},
						CGI::escape($item->{rev1_time}),
						CGI::escape($item->{rev2_time}));

	return $url;
}

sub isBinaryFile($) {
	my $item = $_[0];
	
	return ($item->{rev1} eq "" && $item->{rev2} eq "");
}

sub parse_command_line() {
    my $cmd_line = join (" ", @ARGV);
    
    if ($cmd_line =~ m/^-f([^\s]+)/) {
        $_CONFIG_FILE_ = $1;
    }
    
    if ($cmd_line =~ m/\s-t([^\s]+)/) {
        $_TIME_ = $1;   
    }
    
    if ($cmd_line =~ m/\s-m([^\s]+)/) {
        $g_module_id = $1;
    }
    
    if ($cmd_line =~ m/\s-l([^\s]+)/) {
        $g_diff_file = $1;
    }
    
    if ($cmd_line =~ m/\s-r1([^\s]+)/) {
        $g_rev1 = $1;   
    }  
    
    if ($cmd_line =~ m/\s-r2([^\s]+)/) {
        $g_rev2 = $1;   
    } 
    
    if ($cmd_line =~ m/\s-D1([^\s]+)/) {
        $g_date1 = $1;   
    }  
    
    if ($cmd_line =~ m/\s-D2([^\s]+)/) {
        $g_date2 = $1;   
    } 
    
	if ($g_rev1 ne "_CCV_NULL_" || $g_rev2 ne "_CCV_NULL_") {
		if ($g_rev1 ne "_CCV_NULL_" && $g_rev2 ne "_CCV_NULL_") {
			$g_revisions = "$g_rev1-$g_rev2"	
		} else {
			$g_revisions = ($g_rev1 ne "_CCV_NULL_" ? $g_rev1 : $g_rev2);
		}
	}
	
	if ($g_date1 ne "_CCV_NULL_" || $g_date2 ne "_CCV_NULL_") {
		if ($g_date1 ne "_CCV_NULL_" && $g_date2 ne "_CCV_NULL_") {
			$g_dates = "$g_date1-$g_date2"	
		} else {
			$g_dates = ($g_date1 ne "_CCV_NULL_" ? $g_date1 : $g_date2);
		}
		$g_dates =~ s|/|\-|g;
	}

    return 0;
}


# cvs rdiff -u -r rev1 -r rev2 module

# index: src/windows/ST/AASETUP/aasetup.rc
# diff -u src/windows/ST/AASETUP/aasetup.rc:1.23 src/windows/ST/AASETUP/aasetup.rc:1.25
# --- src/windows/ST/AASETUP/aasetup.rc:1.23	Sun Jun 29 23:31:13 2008
# +++ src/windows/ST/AASETUP/aasetup.rc	Mon Jul 21 02:36:10 2008
# @@ -214,8 +214,8 @@
#  //
#  
#  VS_VERSION_INFO VERSIONINFO
# - FILEVERSION 929,2008,630,2700
# - PRODUCTVERSION 929,2008,630,2700
# + FILEVERSION 929,2008,721,2700
# + PRODUCTVERSION 929,2008,721,2700
#   FILEFLAGSMASK 0x3fL
#  #ifdef _DEBUG
#   FILEFLAGS 0x1L
# @@ -233,14 +233,14 @@
#              VALUE "Comments", "\0"
#              VALUE "CompanyName", "WebEx Communications, Inc.\0"
#              VALUE "FileDescription", "aasetup\0"
# -            VALUE "FileVersion", "929, 2008, 630, 2700\0"
# +            VALUE "FileVersion", "929, 2008, 721, 2700\0"
#              VALUE "InternalName", "aasetup\0"
#              VALUE "LegalCopyright", "?1997-2008 WebEx Communications, Inc.  All rights reserved.\0"
#              VALUE "LegalTrademarks", "\0"
#              VALUE "OriginalFilename", "aasetup.dll\0"
#              VALUE "PrivateBuild", "\0"
#              VALUE "ProductName", "Remote Access AASetup\0"
# -            VALUE "ProductVersion", "929, 2008, 630, 2700\0"
# +            VALUE "ProductVersion", "929, 2008, 721, 2700\0"
#              VALUE "SpecialBuild", "\0"
#          END
#      END
# @@ -404,8 +404,8 @@
#  STRINGTABLE DISCARDABLE 
#  BEGIN
#      IDS_ERROR_REINSTALL_ST_IT 
# -                            "Il computer ?gi?dotato di un agente Remote Access. Per reinstallare l'agente, ?necessario disinstallarlo prima dal computer."
# -    IDS_ERROR_REINSTALL_IT  "Il computer ?gi?dotato di un agente Access Anywhere o di laboratorio pratico. Per reinstallare l'agente, ?necessario disinstallarlo prima dal computer."
# +                            "Il computer ?gi?dotato di un agente Remote Access. Per reinstallare l'agente, ?necessario disinstallarlo prima dal computer."
# +    IDS_ERROR_REINSTALL_IT  "Il computer ?gi?dotato di un agente Access Anywhere o di laboratorio pratico. Per reinstallare l'agente, ?necessario disinstallarlo prima dal computer."
#      IDS_ERROR_NO_PRIVILEGE_IT 
#                              "L'account di accesso non dispone dei privilegi richiesti per installare l'agente Remote Access. Utilizzare un account di amministrazione."
#  END
# @@ -430,9 +430,9 @@
#  
#  STRINGTABLE DISCARDABLE 
#  BEGIN
# -    IDS_ERROR_REINSTALL_PT  "Este computador j?est?configurado com um Agente Access Anywhere. Para reinstalar o agente com êxito, primeiro desinstale-o deste computador."
# +    IDS_ERROR_REINSTALL_PT  "Este computador j?est?configurado com um agente Laboratório prático ou Access Anywhere. Para reinstalar o agente, primeiro desinstale-o deste computador."
#      IDS_ERROR_REINSTALL_ST_PT 
# -                            "Este computador j?est?configurado com um Agente Remote Access. Para reinstalar o agente, primeiro desinstale-o deste computador."
# +                            "Este computador j?est?configurado com um Agente Remote Access. Para reinstalar o agente, primeiro desinstale-o deste computador."
#  END
#  
#  STRINGTABLE DISCARDABLE 
# Index: src/windows/ST/ATRARES/atrares.rc
# diff -u src/windows/ST/ATRARES/atrares.rc:1.100 src/windows/ST/ATRARES/atrares.rc:1.107
# --- src/windows/ST/ATRARES/atrares.rc:1.100	Tue Jun 24 23:44:33 2008
# +++ src/windows/ST/ATRARES/atrares.rc	Mon Jul 28 19:03:54 2008
# @@ -39,8 +39,8 @@
#  //
#  
#  VS_VERSION_INFO VERSIONINFO
# - FILEVERSION 929,2008,624,2700
# - PRODUCTVERSION 929,2008,624,2700
# + FILEVERSION 929,2008,729,2700
# + PRODUCTVERSION 929,2008,729,2700
#   FILEFLAGSMASK 0x3fL
#  #ifdef _DEBUG
#   FILEFLAGS 0x1L
