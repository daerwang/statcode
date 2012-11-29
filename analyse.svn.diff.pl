#!/usr/bin/perl -I ./thirds -w
# author: lilong'en(lilongen@163.com)
# date:   11/14/2010
# add this file to implement: 
#   1. LOC between two Revision
#   2. svn web diff individually (without ViewVC)
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
sub parse_command_line();
sub output($);
sub handle_file_finished();
sub get_file_shown_info($);
sub get_directory_suffix_info($);
sub friend_revs_dates_4UI();
sub replacePart1PMS($$);
sub replacePart2PMS($);
sub get_independent_file_diff_url($);
sub parse_unified_format();
sub persistence_module_info($$$);
sub setGV();
sub resetSumInfo();
sub resetFileInfo();
sub initGlobals();


#parameters for construct Assistor object
my $CFG = "";
my $T_SNAP = "";
my $MID = "";
parse_command_line();

my $GV = {};
my $G_SumInfo = {};
my $G_FileInfo = {};
my $G_Flags = {};

my $G_H_TEXT_FILE = undef;
my $G_H_MODULE_TEXT_FILE = undef;																			
my $G_H_GROUP_HTML_FILE = undef;																	;
my $G_H_FLAT_HTML_FILE = undef;
my $G_H_DIFF = undef;	

my $assistor    = new Assistor($CFG, $T_SNAP); $assistor->getModules();
my $moduleInfo  = $assistor->get_module_info_by_module_id($MID);
my $ccvUtil 	= new CcvUtil();
my $pms 		= $ccvUtil->loadFile($assistor->get_specified_operate_file("PMS"));

sub setGV() {
	$GV->{revsDates}			= $pms->{dfRevs} || $pms->{dfDates};
	$GV->{dfOutFile}     		= $assistor->get_revisions_module_diff_out_file($GV->{revsDates}, $moduleInfo->{diff});
	$GV->{dfOutFileUrl}  		= "/ccv/" . $GV->{dfOutFile}; 
	
	#Error define
	# 0: no error
	# 1: acount id/passwd not correct
	# 2: no such tag/revision
	#
	$GV->{Error}				= 0;
	$GV->{ErrorString}			= "";
	$GV->{ExDirLevels} 			= 4;
	$GV->{DiffViewer}			= "/ccv-cgi/svn.differ.pl?AT=DF&DF=%s&OB=%d&OE=%d";															
	$GV->{InitStatus}			= 1;
	$GV->{AllBriefReportFile}  	= $assistor->get_brief_report_file();
	$GV->{ModuleBriefReportFile}= $assistor->get_module_brief_report_file($MID);		
}

sub resetSumInfo() {
	$G_SumInfo->{fileCnt} 			= 0;
	$G_SumInfo->{lines}           	= 0;
	$G_SumInfo->{linesAdded}      	= 0;
	$G_SumInfo->{linesRemoved}    	= 0;
	
	$G_SumInfo->{fsCntUnexistInLeft} = 0;
	$G_SumInfo->{fsCntUnexistInRight}= 0;
	
	$G_SumInfo->{flatItems}			= [];
	$G_SumInfo->{newFiles}			= [];
	$G_SumInfo->{binFiles}			= [];
	$G_SumInfo->{removedFiles}		= [];
	
	$G_SumInfo->{items} 			= {};
	$G_SumInfo->{tempItems}			= $G_SumInfo->{items};
	$G_SumInfo->{tempPrevItems} 	= $G_SumInfo->{tempItems};
	$G_SumInfo->{lefts}				= [];
	$G_SumInfo->{treeItems}			= [];
}

sub resetFileInfo() {
	$G_FileInfo->{file}        		= "";
	$G_FileInfo->{r1}        		= "";
	$G_FileInfo->{r2}        		= "";
	$G_FileInfo->{unExistIn} 		= "";
	$G_FileInfo->{linesAdded}    	= 0;
	$G_FileInfo->{linesRemoved}   	= 0;
	$G_FileInfo->{OffsetStart} 		= 0;
	$G_FileInfo->{OffsetEnd} 		= 0;
	$G_FileInfo->{isBinary} 		= 0;		 
}

sub initGlobals() {
	setGV();
	resetSumInfo();
	resetFileInfo();
}

exit main();

sub main() {
	initGlobals();
	
	if (!open($G_H_DIFF, $GV->{dfOutFile})) {
		output("Can not open $GV->{dfOutFile}!\n");
		return 1;
	}
	parse_unified_format();	
	close($G_H_DIFF);


	unshift(@{$G_SumInfo->{flatItems}}, @{$G_SumInfo->{newFiles}}); # put new added files into first
	unshift(@{$G_SumInfo->{flatItems}}, @{$G_SumInfo->{removedFiles}}); # put removed files into first
	push(@{$G_SumInfo->{flatItems}}, @{$G_SumInfo->{binFiles}}); # last binary file in array

	print_loc_info();
	write_data_to_file();

	return 0;
}


sub parse_unified_format() {
	my $fileBeginLineNo = -1;
	my $lineNo = -1;
	my $line = "";
	my $flagFileFound = 0;
	while (1) {
		$line = <$G_H_DIFF>;
		if (!defined($line)) {
			if ($flagFileFound == 1) {
				$G_FileInfo->{OffsetEnd} = tell($G_H_DIFF);
				handle_file_finished();
			}
			
			$G_SumInfo->{tempItems} 		= $G_SumInfo->{items};
			$G_SumInfo->{tempPrevItems} 	= $G_SumInfo->{tempItems};
			$G_SumInfo->{lines} 			= $G_SumInfo->{linesAdded} + $G_SumInfo->{linesRemoved};		
				
			last;
		}
		if ($lineNo++ == -1) {
			if ($line !~ m/^Index: (.*)$/) { # no such tag, and so on
				$GV->{Error} = 2;
				$GV->{ErrorString} = $line;

				last;
			}		
		}
		
		#Index: res/strings/bulid.xml
		#===================================================================
		#--- res/strings/bulid.xml	(revision 0)
		#+++ res/strings/bulid.xml	(revision 1000)
		#@@ -0,0 +1,45 @@
		if ($line =~ m/^Index: (.*)$/) {
			$fileBeginLineNo = $lineNo;
			if ($flagFileFound == 1 && $G_SumInfo->{fileCnt} > 0) {
				$G_FileInfo->{OffsetEnd} = tell($G_H_DIFF) - length($line);
				handle_file_finished();		
			}
			
			my $fileExt = substr($1, rindex($1, "."));
			if ($moduleInfo->{file_filter} eq ".*"
				|| index($moduleInfo->{file_filter}, $fileExt) != -1) {
	 			$flagFileFound 	= 1;
    			$G_FileInfo->{file} 		= $1;
    			$G_FileInfo->{OffsetStart}	= tell($G_H_DIFF) - length($line);
    		    $G_SumInfo->{fileCnt}++;
				next;
			} else {
				$flagFileFound = 0;
				next;	
			}
		}
		
		#print "fileBeginLineNo: $fileBeginLineNo    -- lineNo: $lineNo  -- $line";
		if ($flagFileFound == 1 && $lineNo == ($fileBeginLineNo + 1)) {
			next;
		}
		
		if ($flagFileFound == 1 && $lineNo == ($fileBeginLineNo + 2)) {
			if ($line =~ m/^\-\-\-\s+.*\s+\(revision (\d+)\)$/) {
				$G_FileInfo->{r1} = $1;
				$G_FileInfo->{isBinary} = 0;
			} else {
				$G_FileInfo->{r1} = "";
				$G_FileInfo->{isBinary} = 1;
			}
			
			next;
		}
		
		if ($flagFileFound == 1 && $lineNo == ($fileBeginLineNo + 3)) {
			if ($line =~ m/^\+\+\+\s+.*\s+\(revision (\d+)\)$/) {
				$G_FileInfo->{r2} = $1;
			} else {
				$G_FileInfo->{r2} = "";
			}
			next;
		}
		
		#@@ -0,0 +1,160 @@
		#@@ -1 +1 @@
		if ($flagFileFound == 1 
			&& $lineNo == ($fileBeginLineNo + 4)) {
			if ($line =~ m/^\@\@ -(\d+),(\d+) +(\d+),(\d+) \@\@$/) {
				if ($1 == 0 && $2 == 0) {
					$G_FileInfo->{unExistIn} = "L";
					$G_SumInfo->{fsCntUnexistInLeft} ++;
				} elsif ($3 == 0 && $4 == 0) {
					$G_FileInfo->{unExistIn} = "R";
					$G_SumInfo->{fsCntUnexistInRight} ++;
				} else {
					$G_FileInfo->{unExistIn} = "";
				}
			}				
			
			next;
		}

		if ($flagFileFound == 1
			&& $lineNo > ($fileBeginLineNo + 4)
			&& $line =~ m/^([\-\+])/) {
			if ($1 eq "+") {
				$G_FileInfo->{linesAdded} ++;
			} elsif ($1 eq "-") {
				$G_FileInfo->{linesRemoved} ++;
			}
		}
	} #end while
}

sub handle_file_finished() {
	#clone hash reference 
	my %item = %{$G_FileInfo};
	my $fileItem = \%item;
	my @directorys = split(/[\/\\]+/, $G_FileInfo->{file});
	$fileItem->{SELF} 	= $directorys[$#directorys];
	my $dir_levels = $#directorys;
	
	for (my $level = 0; $level < $dir_levels; $level++) {
		if (!defined($G_SumInfo->{tempItems}->{$directorys[$level]})) {
			$G_SumInfo->{tempItems}->{$directorys[$level]} = {};
			$G_SumInfo->{tempItems}->{$directorys[$level]}->{'__CCV_INFO__'} = {};
			$G_SumInfo->{tempItems}->{$directorys[$level]}->{'__CCV_INFO__'}->{LEVEL} = $level;
			$G_SumInfo->{tempItems}->{$directorys[$level]}->{'__CCV_INFO__'}->{HANDLED} = 0;
			$G_SumInfo->{tempItems}->{$directorys[$level]}->{'__CCV_INFO__'}->{SELF} = $directorys[$level];
			if ($level == 0) {
				$G_SumInfo->{tempItems}->{$directorys[$level]}->{'__CCV_INFO__'}->{PARENT} = "";
			} else {
				$G_SumInfo->{tempItems}->{$directorys[$level]}->{'__CCV_INFO__'}->{PARENT} = $G_SumInfo->{tempPrevItems}->{$directorys[$level - 1]}->{'__CCV_INFO__'}->{PARENT} . $directorys[$level - 1] . "/";
			}
		}
		
		$G_SumInfo->{tempItems}->{$directorys[$level]}->{'__CCV_INFO__'}->{'FILES'} ++ ;
		$G_SumInfo->{tempItems}->{$directorys[$level]}->{'__CCV_INFO__'}->{'LINE_ADDED'} += $fileItem->{linesAdded};
		$G_SumInfo->{tempItems}->{$directorys[$level]}->{'__CCV_INFO__'}->{'LINE_REMOVED'} += $fileItem->{linesRemoved};
		
		$G_SumInfo->{tempPrevItems} = $G_SumInfo->{tempItems};
		$G_SumInfo->{tempItems} = $G_SumInfo->{tempItems}->{$directorys[$level]};				
	}
	
	$fileItem->{LEVEL}  = $G_SumInfo->{tempPrevItems}->{$directorys[$dir_levels - 1]}->{'__CCV_INFO__'}->{LEVEL} + 1;
	$fileItem->{PARENT} = $G_SumInfo->{tempPrevItems}->{$directorys[$dir_levels - 1]}->{'__CCV_INFO__'}->{PARENT} . $directorys[$dir_levels - 1] . "/";
	
	$G_SumInfo->{tempItems}->{$directorys[$dir_levels]} = $fileItem;
	
	$G_SumInfo->{tempItems} = $G_SumInfo->{items};
	
	if ($fileItem->{unExistIn} eq 'L' ) {
		push(@{$G_SumInfo->{newFiles}}, $fileItem);
	} elsif ($fileItem->{unExistIn} eq "R") {
		push(@{$G_SumInfo->{removedFiles}}, $fileItem);
	} elsif ($G_FileInfo->{isBinary}) {
		push(@{$G_SumInfo->{binFiles}}, $fileItem);
	} else {
		push(@{$G_SumInfo->{flatItems}}, $fileItem);
	}
	
	$G_SumInfo->{linesAdded}    += $fileItem->{linesAdded};
	$G_SumInfo->{linesRemoved}  += $fileItem->{linesRemoved};
	resetFileInfo();
}

sub write_data_to_file() {
	if (!open($G_H_TEXT_FILE, ">>", "$GV->{AllBriefReportFile}")) {
		output("Can not create/open $GV->{AllBriefReportFile}!\n");
		
		return 1;
	}
	
	if (!open($G_H_MODULE_TEXT_FILE, ">>", "$GV->{ModuleBriefReportFile}")) {
		output("Can not create/open $GV->{ModuleBriefReportFile}!\n");
		
		return 1;
	}	
	
    my $HTML_TEMPLATE = $assistor->get_report_template_file("DIFF");
    my $node_flag   = "#NODE#";
    my $template    = $assistor->read_whole_file($HTML_TEMPLATE);
    my $node_pos    = index($template, $node_flag);
    my $part1       = substr($template, 0, $node_pos);
    my $part2       = substr($template, $node_pos + length($node_flag));
    
    my $file_part1  = $part1;
        
    my $group_html_out_file = $assistor->get_specified_output_report_file({flag => "DIFF_GROUP", revs => $GV->{revsDates}, mid=> $MID});
    my $flat_html_out_file = $assistor->get_specified_output_report_file({flag => "DIFF_FLAT", revs => $GV->{revsDates}, mid=> $MID});

    if (!open($G_H_GROUP_HTML_FILE, ">", "$group_html_out_file")) {
		output("Can not create/open $group_html_out_file!\n");
		
		return 1;
	} 
	
    if (!open($G_H_FLAT_HTML_FILE, ">", "$flat_html_out_file")) {
		output("Can not create/open $flat_html_out_file!\n");
		
		return 1;
	} 	
    
    my $moduleSvnUrl = $assistor->get_svn_module_url($moduleInfo, "", "trunk");
    
    friend_revs_dates_4UI();

    my $module_brief_txt = sprintf("Module: %s (%s - %s); Revision1: %s; Revision2: %s; Date1: %s; Date2: %s,,\n",
                        $MID, 
                        $moduleInfo->{module},
                        $moduleSvnUrl,
                        $pms->{r1},
                        $pms->{r2},
                        $pms->{d1},
                        $pms->{d2});
                        
    $module_brief_txt .= sprintf("LOC, FOC\n%07d, %04d\n\n", 
                        $G_SumInfo->{lines},
                        $G_SumInfo->{fileCnt});
                        
	my $LOC =  sprintf("%d(+%d, -%d)\n", 
                        $G_SumInfo->{lines}, 
                        $G_SumInfo->{linesAdded},
                        $G_SumInfo->{linesRemoved});                                           
                        
	
    my $diff_group_report_url = $assistor->transReportLocalPath2WebPath($assistor->get_specified_output_report_file({flag => "DIFF_GROUP", revs => $GV->{revsDates}, mid=> $MID}));
    my $diff_flat_report_url = $assistor->transReportLocalPath2WebPath($assistor->get_specified_output_report_file({flag => "DIFF_FLAT", revs => $GV->{revsDates}, mid=> $MID})); 
    my $module_rdiff_brief_report_url = $assistor->transReportLocalPath2WebPath($assistor->get_module_brief_report_file($MID));
    my $rdiff_brief_report_url = $assistor->transReportLocalPath2WebPath($assistor->get_brief_report_file());
    
    my $template_parametrs = {'MODULE' 			=> $moduleInfo->{module},
    						  'SVN_URL' 		=> $moduleSvnUrl,
    						  'REVISION1' 		=> $pms->{r1},
    						  'REVISION2' 		=> $pms->{r2},
    						  'DATE1' 			=> $pms->{d1},
    						  'DATE2' 			=> $pms->{d2},
    						  'FOC' 			=> $G_SumInfo->{fileCnt},
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
	
	if ($GV->{Error} != 0) {
		$GV->{ErrorString} = "<font size='8pt' color='#ff0000'><b>" . $GV->{ErrorString} . "</b></font><br/><br/>";	
	}
	
	print $G_H_GROUP_HTML_FILE $part1;
	if ($GV->{Error} == 0) {# no error
		generate_group_items();
		construct_tree();	
	} else {
		print $G_H_GROUP_HTML_FILE $GV->{ErrorString};
	}	
	print $G_H_GROUP_HTML_FILE $part2;
    

	print $G_H_FLAT_HTML_FILE $file_part1;
	if ($GV->{Error} == 0) {# no error
		write_flat_items();
	} else {
		print $G_H_FLAT_HTML_FILE $GV->{ErrorString};
	}
	print $G_H_FLAT_HTML_FILE $part2;

    print $G_H_TEXT_FILE $module_brief_txt . "\n\n";
    print $G_H_MODULE_TEXT_FILE $module_brief_txt . "\n\n";

	close($G_H_TEXT_FILE);
	close($G_H_MODULE_TEXT_FILE);
	close($G_H_GROUP_HTML_FILE);
	close($G_H_FLAT_HTML_FILE);
	
	persistence_module_info($MID, $G_SumInfo->{fileCnt}, $G_SumInfo->{lines});


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

sub replacePart1PMS($$){
	my $content	= $_[0];
    my $paras 	= $_[1];
	
	$$content =~ s/#BODY_CLS#/svn/;
    $$content =~ s/#MODULE#/$paras->{MODULE}/;
    $$content =~ s/#MODULE_URI#/$paras->{SVN_URL}/;
    $$content =~ s/#REVISION1#/$paras->{REVISION1}/;
    $$content =~ s/#REVISION2#/$paras->{REVISION2}/;
    $$content =~ s/#DATE1#/$paras->{DATE1}/;
    $$content =~ s/#DATE2#/$paras->{DATE2}/;
    $$content =~ s/#FOC#/$paras->{FOC}/;
    $$content =~ s/#LOC#/$paras->{LOC}/;
    $$content =~ s/#OTHER_URL#/$paras->{OTHER_URL}/;
    $$content =~ s/#OTHER_NAME#/$paras->{OTHER_NAME}/;
    $$content =~ s/#DIFF_FILE#/$GV->{dfOutFileUrl}/;
    $$content =~ s/#MODULE_PLAIN_REPORT#/$paras->{MODULE_PLAIN_REPORT}/;
    $$content =~ s/#PLAIN_REPORT#/$paras->{PLAIN_REPORT}/;
}

sub replacePart2PMS($) {
	my $content	= $_[0];
	
    my $GV_IN_JS =<<GV_IN_JS;
{
	T_SNAP: "$T_SNAP",
	MID: "$MID",
	Error: "$GV->{Error}",
	ShowGraphEntry: "0",
	ShowSrcDetails: "0",	
	ReportType: "SVN_DIFF"
}
GV_IN_JS
    
	$$content =~ s/#GV#/$GV_IN_JS/;
}

sub friend_revs_dates_4UI() {
	my $HEAD = "HEAD(MAIN)";
    if ($pms->{r1} eq "_CCV_NULL_" && $pms->{r2} eq "_CCV_NULL_") {
    	$pms->{r1} 	= "N/A";
    	$pms->{r2} 	= "N/A";	
    } else {
    	if (!($pms->{r1} ne "_CCV_NULL_" && $pms->{r2} ne "_CCV_NULL_")) {
    		$pms->{r1} = ($pms->{r1} ne "_CCV_NULL_" ? $pms->{r1} : $pms->{r2});
    		$pms->{r2} = $HEAD;
    	}
    }
    
    if ($pms->{d1} eq "_CCV_NULL_" && $pms->{d2} eq "_CCV_NULL_") {
    	$pms->{d1} 	= "N/A";
    	$pms->{d2} 	= "N/A";	
    } else {
    	if (!($pms->{d1} ne "_CCV_NULL_" && $pms->{d2} ne "_CCV_NULL_")) {
    		$pms->{d1} = ($pms->{d1} ne "_CCV_NULL_" ? $pms->{d1} : $pms->{d2});
    		$pms->{d2} = $HEAD;
    	}
    }    
}

#use stack method to replace recursive calling
sub generate_group_items() {
	while (1) {
		if ($GV->{InitStatus} == 1 || defined($G_SumInfo->{tempItems}->{__CCV_INFO__})) { # directory
			$GV->{InitStatus} = 0;
			my @curr_keys = sort {
			        	lc($a) cmp lc($b)     # compare with key
			    		}  keys %{$G_SumInfo->{tempItems}};
			
			my $checked_length = $#curr_keys;			
			for (my $index = 0; $index <= $checked_length; $index++) {
				if ($curr_keys[$index] ne "__CCV_INFO__" && !defined($G_SumInfo->{tempItems}->{$curr_keys[$index]}->{__CCV_INFO__})) { # file
					my $kname = $curr_keys[$index];
		
					splice(@curr_keys, $index, 1);
					push(@curr_keys, $kname);
					$checked_length --;
					$index --;
				}
			}
		
			for (my $i = $#curr_keys; $i >= 0; $i--) {
				if (defined($G_SumInfo->{tempItems}->{$curr_keys[$i]}->{__CCV_INFO__})) { # directory
					push(@{$G_SumInfo->{lefts}}, $G_SumInfo->{tempItems}->{$curr_keys[$i]});	
					
					next;	
				} else { # file
					if ($curr_keys[$i] eq "__CCV_INFO__") {
						next;
					}
					
					push(@{$G_SumInfo->{lefts}}, $G_SumInfo->{tempItems}->{$curr_keys[$i]});	
				}
			}
		}
		
		if ($#{$G_SumInfo->{lefts}} < 0) {
			last;
		}
		
		$G_SumInfo->{tempItems} = pop(@{$G_SumInfo->{lefts}});
		push(@{$G_SumInfo->{treeItems}}, $G_SumInfo->{tempItems});	
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
	for (my $i = 0; $i <= $#{$G_SumInfo->{treeItems}}; $i++) {
		$is_directory = defined($G_SumInfo->{treeItems}->[$i]->{__CCV_INFO__});
		if ($is_directory) {
			$dir_suffix_info = get_directory_suffix_info($G_SumInfo->{treeItems}->[$i]->{__CCV_INFO__});
		}
		if ($is_directory) { #directory
			$level = $G_SumInfo->{treeItems}->[$i]->{__CCV_INFO__}->{LEVEL};
		} else {
			$level = $G_SumInfo->{treeItems}->[$i]->{LEVEL};
		}
		
		my $indent = 220 + (12 - $level) * 22;
		$indent .= "px";
		
		if ($i == 0) {
			$suffix = "";
			$previous_level = 0;
			$previous_is_directory = 1;
			
			my $treeOperator = "<i>[<a href='javascript: expandAll(true)' class='treeOperator'>Expand All</a>&nbsp;/&nbsp;<a href='javascript: expandAll(false)' class='treeOperator'>Collapse All</a>]</i>";		
			$item = "\n<li class='shown'><span class='minus' onclick='showChildren(this)'></span><span class='fwspan' style='width: $indent;'><a href='#' class='directory'>" . $G_SumInfo->{treeItems}->[$i]->{__CCV_INFO__}->{SELF} . "</a>&nbsp;&nbsp;&nbsp;&nbsp;" . $treeOperator . "</span>$dir_suffix_info \n<ul style='display: block;'>";
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
				$dir_operator_style = $level >= $GV->{ExDirLevels} ? "plus" : "minus";
				$dir_display = $level >= $GV->{ExDirLevels} ? "none" : "block";

				$item = "\n<li><span class='$dir_operator_style' onclick='showChildren(this)'></span><a href='#' class='dirLOC'><span class='fwspan' style='width: $indent;'><span class='directory'>" . $G_SumInfo->{treeItems}->[$i]->{__CCV_INFO__}->{SELF} . "</span></span></a>" . $dir_suffix_info . "\n<ul style='display: $dir_display;'>";
			} else {
				my $file_shown_info = get_file_shown_info($G_SumInfo->{treeItems}->[$i]);
				if ($G_SumInfo->{treeItems}->[$i]->{isBinary} == 1) {
					$item = sprintf("\n<li><span class='ci'></span><span class='fwspan' title='%s' style='width: $indent;'><span class='file %s'>%s</span></span>\n</li>",
							$file_shown_info->{tips},
							$file_shown_info->{color},
							$G_SumInfo->{treeItems}->[$i]->{SELF});				
				} else {
					my $LOC = sprintf("<span class='fileLoc'>%s(+%s, -%s)</span>",
								$file_shown_info->{total_lines},
								$file_shown_info->{added_lines},
								$file_shown_info->{removed_lines});	
					$item = sprintf("\n<li><span class='ci'></span><a target='_blank' class='loc' href='%s' title='%s'><span class='fwspan' style='width: $indent;'><span class='file %s'>%s</span></span>%s</a>\n</li>",
							$file_shown_info->{diff_url},
							$file_shown_info->{tips},
							$file_shown_info->{color},
							$G_SumInfo->{treeItems}->[$i]->{SELF},
							$LOC);
				}
			}			

			$previous_level = $level;
			$previous_is_directory = $is_directory;
		}
		
		$tree_string .= $suffix . $item;
		
		if ($i % 20 == 0 || $i == $#{$G_SumInfo->{treeItems}}) {
			print $G_H_GROUP_HTML_FILE $tree_string;	
			
			$tree_string = "";
		}
	}
}

sub write_flat_items() {
	my $files_cnt = $#{$G_SumInfo->{flatItems}};

	my $html_out = "";
	for (my $index = 0; $index <= $files_cnt; $index++) {
		$html_out .= get_flat_item($index);
		
		if ($index % 20 == 0 || $index == $files_cnt) {
			print $G_H_FLAT_HTML_FILE $html_out;
			$html_out = "";
		}
	}
}


sub get_flat_item($) {
    my $index = $_[0];
    
    my $file_shown_info = get_file_shown_info($G_SumInfo->{flatItems}->[$index]);
    my $ret = "";
    if ($G_SumInfo->{flatItems}->[$index]->{isBinary} == 1) {
    	$ret = sprintf("<li><span class='ci'></span><span title='%s'><span class='binLocTxt %s'>#LINES#</span> <span class='%s'>%s</span></span></li>\n",
                         $file_shown_info->{tips},
                         $file_shown_info->{color},
                         $file_shown_info->{color},
                         $G_SumInfo->{flatItems}->[$index]->{file});    	
    } else {
    	$ret = sprintf("<li><span class='ci'></span><a target='_blank' href='%s' title='%s'><span class='txtLocTxt'>#LINES#</span> <span class='%s'>%s</span></a></li>\n",
                         $file_shown_info->{diff_url},
                         $file_shown_info->{tips},
                         $file_shown_info->{color},
                         $G_SumInfo->{flatItems}->[$index]->{file});
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
	my $clr_4filename = "fileNormal";
	if ($item->{unExistIn} eq "L") {
		$file_tips = "un-exist in revison1/date1";
		$clr_4filename = "fileUnExistAtL";
	}
	
	if ($item->{unExistIn} eq "R") {
		$file_tips = "un-exist in revison2/date2";	
		$clr_4filename = "fileUnExistAtR";
	}
	
	if ($item->{isBinary} == 1) {
		$file_tips = "binary file, diff unavaiable!";
		$clr_4filename = "fileBinary";
	}
	
	my $file_diff = "";
	#if ($moduleInfo->{viewvc_entry} eq "" || $moduleInfo->{viewvc_entry} eq "NONE") { riff mode, always use ccv self diff viewer
   	$file_diff = get_independent_file_diff_url($item);

    my $str_total_lines         = sprintf("%07d", $item->{linesAdded} + $item->{linesRemoved});
    my $str_added_lines      	= sprintf("%07d", $item->{linesAdded});
    my $str_removed_lines    	= sprintf("%07d", $item->{linesRemoved});
    
    
    return {'color' 			=> $clr_4filename,
    		'tips'  			=> $file_tips,
    		'diff_url' 			=> $file_diff,
    		'total_lines' 		=> $str_total_lines,
    		'added_lines' 		=> $str_added_lines,
    		'removed_lines' 	=> $str_removed_lines};
}

sub get_directory_suffix_info($) {
	my $item = $_[0];
	
	my $ret = sprintf("<span class='dirLoc'>%07d(+%07d, -%07d)</span><span class='dirFileCnt'> - %04d files</span>",
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
	output("File: $GV->{dfOutFile}\n");
	output("Changed file amount:   $G_SumInfo->{fileCnt}\n");
	output("Changed line amount:   $G_SumInfo->{lines} (+$G_SumInfo->{linesAdded}, -$G_SumInfo->{linesRemoved})\n\n\n");
}

sub get_independent_file_diff_url($) {
	my $item = $_[0];
	my $url = sprintf($GV->{DiffViewer},
						CGI::escape($GV->{dfOutFile}),
						$item->{OffsetStart},
						$item->{OffsetEnd}
	);

	return $url;
}

sub parse_command_line() {
    my $cmd_line = join (" ", @ARGV);
    if ($cmd_line =~ m/(^|\s)-t([^\s]+)/) {
        $T_SNAP = $2; 
    }

    if ($cmd_line =~ m/(^|\s)-f([^\s]+)/) {
        $CFG = $2;
    }

    if ($cmd_line =~ m/(^|\s)-m([^\s]+)/) {
        $MID = $2;
    } 

    return 0;
}
