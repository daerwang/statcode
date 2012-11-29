#!/usr/bin/perl -I ./thirds -w
# author: lilong'en(lilongen@163.com)
# date:   07/31/2008
#
use strict;
use English;
use IO::Seekable; 
use Data::Dumper;
use CGI;
use Assistor;
use Cwd;

sub add_diff_entry();
sub handle_only_right($);
sub handle_only_left($);
sub handle($);
sub format_diffs();
sub collect_blocks($$$);
sub adjust_blocks_accodingto_blocks($$$);

BEGIN { $|++ };
my $q = new CGI;

my $params = {};
$params->{rdiff_file} 	= $q->param('rdiff');
$params->{start} 		= $q->param('start');
$params->{end} 			= $q->param('end');
$params->{self} 		= $q->param('self');
$params->{parent} 		= $q->param('parent');
$params->{un_exist_in} 	= $q->param('un_exist_in');
$params->{removed_in} 	= $q->param('removed_in');
$params->{rev1} 		= $q->param('rev1');
$params->{rev2} 		= $q->param('rev2');
$params->{rev1_time} 	= $q->param('rev1_time');
$params->{rev2_time} 	= $q->param('rev2_time');

$params->{rdiff_file} 	= "operate/2008-07-31/075518/07-01-2008-07-31-2008/smt.diff";
$params->{start} 		= 993785;
$params->{end} 			= 1016365;

my $assistor    		= new Assistor();
if ($params->{end} == -1) {
	$params->{end} = -s $params->{rdiff_file};
}

my $diff_txt = $assistor->read_file_content_offsets_content($params->{rdiff_file}, $params->{start}, $params->{end} - $params->{start});

if (!defined($diff_txt)) {
	exit 2;
}
my $html_out		= "";

my @lines 			= split("\n", $diff_txt);
my $diffs 			= [];
my $lines_cnt		= 0;
my $line 			= "";

###
my $diff_l_found 	= 0;
my $diff_r_found 	= 0;
###
my $l_start 		= 0;	
my $r_start 		= 0;
my $l_end 			= 0;
my $r_end 			= 0;

my $l_lines_start 	= 0;	
my $r_lines_start 	= 0;	
my $l_lines_end 	= 0;
my $r_lines_end 	= 0;	

my $places			= 0;
$lines_cnt 			= $#lines;
for (my $i = 3; $i <= $lines_cnt; $i ++) {
	print $i . "  " .$lines[$i]."\n";
	if ($i == $lines_cnt && $lines[$i] =~ m/^Index: $/) {
		next;	
	}
	
	if ($lines[$i] =~ m/^\*+$/) {# ***************
		$places ++;

		if ($diff_r_found) {
			$r_lines_end = $i - 1;	
			add_diff_entry();
		}
		
		next;
	}
	
	if ($lines[$i] =~ m/^\*{3}\s(\d+),(\d+)\s\*{4}$/) { # *** 468,475 ****
		$diff_l_found = 1;
		$l_start 	= $1;
		$l_end	 	= $2;
		
		next;
	}
	
	if (!($lines[$i] =~ m/^-{3}\s(\d+),(\d+)\s\-{4}$/)) {
		if ($diff_l_found == 1 && $diff_r_found == 0) {
			if ($l_lines_start == 0) {
				$l_lines_start = $i;	
			}
		}
		
		if ($diff_l_found == 1 && $diff_r_found == 1) {
			if ($r_lines_start == 0) {
				$r_lines_start = $i;	
			}
		}
		
		next;
	} else {
		$l_lines_end	= $i - 1;
		$diff_r_found 	= 1;
		$r_start 		= $1;
		$r_end	 		= $2;
		
		next;		
	}
}

add_diff_entry();

format_diffs();

sub add_diff_entry() {
	my $diff_info = {l_start 		=> $l_start,
					 r_start 		=> $r_start,
					 l_end 			=> $l_end,
					 r_end 			=> $r_end,
					 
					 l_lines_start 	=> $l_lines_start,
					 r_lines_start 	=> $r_lines_start,
					 l_lines_end 	=> $l_lines_end,
					 r_lines_end 	=> $r_lines_end};
	
	push(@{$diffs}, $diff_info);
	
	$diff_l_found 	= 0;
	$diff_r_found 	= 0;
		
	$l_start 		= 0;	
	$r_start 		= 0;
	$l_end 			= 0;
	$r_end 			= 0;

	$l_lines_start 	= 0;	
	$r_lines_start 	= 0;	
	$l_lines_end 	= 0;	
	$r_lines_end 	= 0;	
}

sub format_diffs() {
	my $item;
	for (my $i = 0; $i < $#{$diffs}; $i ++) {
		$item = $diffs->[$i];
		
		if ($item->{l_lines_start} == 0) {
			handle_only_right($item);
		}
		
		if ($item->{r_lines_start} == 0) {
			handle_only_left($item);
		}		
		
		if ($item->{l_lines_start} != 0 && $item->{r_lines_start} != 0) {
			handle($item);
		}		
	}	
}

sub handle_only_right($) {
	
	return;
	my $item = $_[0];
	my $current = " ";
	my $previous = " ";
	
	my $l_block = "";
	my $r_block = "";
	for (my $i = $item->{r_lines_start}; $i <= $item->{r_lines_end}; $i ++) {
		$lines[$i] =~ m/^(.)\s(.*)$/;
		$current = $1;
		
		if ($current eq " ") {
			if ($previous ne $current) {
				$html_out .= sprintf("<tr><td width='50%'>%s</td><td>%s</td></tr>",
						$l_block,
						$r_block);
						
				$l_block = "";
				$r_block = "";							
			}
			
			$l_block .= $2 . "<br/>";
			$r_block .= $2 . "<br/>";			
		}
		
		if ($current eq "+") {
			if ($previous ne $current) {
				$html_out .= sprintf("<tr><td width='50%'>%s</td><td>%s</td></tr>",
						$l_block,
						$r_block);
						
				$l_block = "";
				$r_block = "";											
			}

			$r_block .= $2 . "<br/>";		
		}
		
		$previous = $current;
	}
}

sub handle_only_left($) {
	return;
	my $item = $_[0];
	my $current = " ";
	my $previous = " ";
	
	my $l_block = "";
	my $r_block = "";
	for (my $i = $item->{l_lines_start}; $i <= $item->{l_lines_end}; $i ++) {
		$lines[$i] =~ m/^(.)\s(.*)$/;
		$current = $1;
		
		if ($current eq " ") {
			if ($previous ne $current) {
				$html_out .= sprintf("<tr><td width='50%'>%s</td><td>%s</td></tr>",
						$l_block,
						$r_block);
						
				$l_block = "";
				$r_block = "";							
			}
			
			$l_block .= $2 . "<br/>";
			$r_block .= $2 . "<br/>";			
		}
		
		if ($current eq "-") {
			if ($previous ne $current) {
				$html_out .= sprintf("<tr><td width='50%'>%s</td><td>%s</td></tr>",
						$l_block,
						$r_block);
						
				$l_block = "";
				$r_block = "";											
			}

			$l_block .= $2 . "<br/>";		
		}
		
		$previous = $current;
	}
}


sub handle($) {
	my $item 		= $_[0];

	my $l_blocks 	= [];
	my $r_blocks 	= [];
	
	collect_blocks($l_blocks, $item->{l_lines_start}, $item->{l_lines_end});
	collect_blocks($r_blocks, $item->{r_lines_start}, $item->{r_lines_end});
	
	adjust_blocks_accodingto_blocks($l_blocks, $r_blocks, "L2R");
	adjust_blocks_accodingto_blocks($l_blocks, $r_blocks, "R2L");

	print "left\n" . Dumper($l_blocks);
	print "right\n" . Dumper($r_blocks);
}

sub adjust_blocks_accodingto_blocks($$$) {
	my $l_blocks 	= $_[0];
	my $r_blocks 	= $_[1];
	my $direction 	= $_[2];
	
	my $source_blocks 		= $direction eq "L2R" ? $l_blocks : $r_blocks;
	my $object_blocks 		= $direction eq "L2R" ? $r_blocks : $l_blocks;
	my $FLAG 				= $direction eq "L2R" ? "-" : "+";
	my $source_blocks_cnt 	= $#{$source_blocks};
	my $object_blocks_cnt 	= $#{$object_blocks};

	my $unchange_blocks 	= 0;
	my $change_blocks 		= 0;
	
	
	
	for (my $i = 0; $i <= $source_blocks_cnt; $i++) {
		if ($source_blocks->[$i]->{block_type} eq " ") {
			$unchange_blocks ++;
		}
		
		if ($source_blocks->[$i]->{block_type} eq "!") {
			$change_blocks ++;
		}		
		
		if ($source_blocks->[$i]->{block_type} eq $FLAG) {
			for (my $j = 0; $j <= $object_blocks_cnt; $j++) {
				if ($object_blocks->[$j]->{block_type} eq " ") {
					$unchange_blocks --;
				}
				
				if ($object_blocks->[$j]->{block_type} eq "!") {
					$change_blocks --;
				}	
				
				if ($unchange_blocks == 0 && $change_blocks == 0) {
					splice(@{$object_blocks}, $j + 1, 0, {block_type => 0, block_start => 0, block_end => 0});
					
					last;					
				}
			}		
		}
	}	
}

sub collect_blocks($$$) {
	my $blocks		= $_[0];
	my $start 		= $_[1];
	my $end 		= $_[2];

	my $current 	= " ";
	my $previous 	= " ";
	
	my $block_type 	= "";
	my $block_begin = 0;
	my $block_end 	= 0;
		
	for (my $i = $start; $i <= $end; $i ++) {
		$lines[$i] =~ m/^(.)\s(.*)$/;
		$current = $1;		

		if ($block_begin == 0) {
			$block_type = $current;
			$block_begin = $i;
		}
		
		if ($current ne $previous) {
			$block_end = $i - 1;
		}
		
		if ($i == $end) {
			$block_end = $i;
		}
		
		if ($block_begin != 0 && $block_end != 0) {
			my $block_def = {	block_type 	=> $block_type,
								block_begin => $block_begin,
								block_end 	=> $block_end};
								
			push(@{$blocks}, $block_def);
	
			$block_type 	= $current;
			$block_begin 	= $i;
			$block_end 		= 0;
		}
		
		$previous = $current;
	}	
}


#print "Content-type: text/html\n\n";

#print Dumper($diffs);

#print <<HTML;
#<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
#<html xmlns="http://www.w3.org/1999/xhtml">
#<head>
#<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
#<title>Query History</title>
#<link rel="stylesheet" type="text/css" href="/cvschangeviewer/css/xquery.css" />
#<style type="text/css">
#a {color: #000000; text-decoration: none;}
#a:hover {color: #0066cc; text-decoration: underline; font-weight: normal;}
#</style>	
#</head>
#<body>
#<table width="100%">
#  <tr height="20">
#    <td>$params->{rdiff_file}</td>
#    <td>$params->{start}</td>
#    <td>$params->{end}</td>
#    <td>$params->{self}</td>
#    <td>$params->{parent}</td>
#  </tr>
#  
#  <tr>
#    <td colspan="5">$diff_txt</td>
#  </tr>  
#</table>
#
#</body>
#</html>
#
#HTML
