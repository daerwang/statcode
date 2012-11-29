#!/usr/bin/perl -I ./thirds -w
# author: lilong'en (lilongen@163.com)
# date:   07/31/2008
#
use strict;
use English;
use IO::Seekable; 
use Data::Dumper;
use CGI;
use Assistor;
use Cwd;
use HTML::Entities;

sub add_diff_entry();
sub get_block_type();

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

#$params->{rdiff_file} 	= "operate/2008-08-25/075109/07-01-2008-07-31-2008/smt.diff";
#$params->{start} 		= 795615;
#$params->{end} 		= 813911;

if (defined($q->param('from')) && $q->param('from') eq "rlog") {
	$params->{start} 	= 0;
	$params->{end} 		= -1;	
	$params->{parent} 	= "";	
}

my $assistor    		= new Assistor();

if ($params->{end} == -1) {
	$params->{end} = -s "$params->{rdiff_file}";
}
my $diff_txt = $assistor->read_file_content_offsets_content($params->{rdiff_file}, $params->{start}, $params->{end} - $params->{start});

if (!defined($diff_txt)) {
	exit 2;
}

my @lines 			= split("\n", $diff_txt);
my $lines_cnt		= $#lines;
if ($lines[$lines_cnt] =~ m/^Index: / || $lines[$lines_cnt] =~ m/^\s*$/) {
	$lines_cnt --;	
}
my $diffs 			= [];

my $entry_l_start 	= 0;	
my $entry_r_start 	= 0;

my $entry_l_lines 	= 0;
my $entry_r_lines 	= 0;

my $entry_start 	= 0;	
my $entry_end 		= 0;	

my $block_start 	= 0;
my $block_end		= 0;
my $block_type		= " ";

my $first 			= " ";
my $previous_first	= " ";
my $previous_block_type	= " ";

my $blocks;

my $i_start = ($lines[0] =~ m/^Index: /) ? 4 : 3;

if (defined($q->param('from')) && $q->param('from') eq "rlog") {
	for (my $i = 0; $i < 4; $i++) {
		# --- webim/component/phoneselector/phoneselector.js:1.15	Thu Nov 12 02:07:45 2009
		# +++ webim/component/phoneselector/phoneselector.js	Sun Nov 15 20:21:47 2009
		if ($lines[$i] =~ m/^--- [^\s]+\s+(.+)$/) {
			$params->{rev1_time} = $1;
			
			next;
		}
		
		if ($lines[$i] =~ m/^\+\+\+ [^\s]+\s+(.+)$/) {
			$params->{rev2_time} = $1;
			
			next;
		}
	}	
	
}

for (my $i = $i_start; $i <= $lines_cnt; $i ++) {
	#print $i . "  " .$lines[$i]."\n";
	
	if ($lines[$i] =~ m/^\@\@ -(\d+),(\d+) \+(\d+),(\d+) \@\@$/) { # @@ -2215,7 +2217,7 @@
		if ($i > 4) {
			$entry_end 		= $i - 1;
			$block_end 		= $i - 1;
			get_block_type();
			push(@{$blocks}, {start => $block_start, end => $block_end, type => $block_type});			
			
			add_diff_entry();
		}
		
		$entry_start	= $i + 1;
		$entry_l_start 	= $1;
		$entry_l_lines	= $2;
		
		$entry_r_start	= $3;
		$entry_r_lines	= $4;
		
		$blocks 		= [];
		$previous_first = " ";
		$block_start	= $i + 1;
		
		next;
	}
	
	$first = substr($lines[$i], 0, 1);
	if ($first eq $previous_first) {
		next;
	}
	
	$block_end = $i - 1;
	get_block_type();
	push(@{$blocks}, {start => $block_start, end => $block_end, type => $block_type});
	
	$previous_first = $first;
	$block_start = $block_end + 1;
	$previous_block_type = $block_type;
} 

$entry_end 	= $lines_cnt;
$block_end = $lines_cnt;
get_block_type();
push(@{$blocks}, {start => $block_start, end => $block_end, type => $block_type});

add_diff_entry();


################################################################################
#
#
################################################################################

#my $DBG;
#if (open($DBG, ">", "1.txt")) {
#	print $DBG Dumper($diffs);
#}
#exit 1;

print "Content-type: text/html\n\n";

print <<HTML_BEGIN;
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
<title>CCV diff viewer</title>
<link rel="stylesheet" href="/ccv/css/report.css" type="text/css">
</head>
<body class="ccvDfView">
<table>
  <tr height="50">
    <td class="fileNameTitle">File: <span class="name">$params->{parent}$params->{self}</span></td>
  </tr>
</table>

<table>
  <tr height="40">
    <td class="leftTd version">Version: <span class="versionValue">$params->{rev1}</span>, <span class="versionTime">$params->{rev1_time}</span></td>
    <td class="rightTd version">Version: <span class="versionValue">$params->{rev2}</span>, <span class="versionTime">$params->{rev2_time}</span></td>
  </tr>
</table>  

<table class="dfLines">
  
HTML_BEGIN




################################################################################
#foramt diff and out


for (my $i = 0; $i <= $lines_cnt; $i++) {
	$lines[$i] = substr($lines[$i], 1);
	
	if ($lines[$i] eq "") {
		$lines[$i] = "&nbsp;";
		next;
	}		
	
	if ($lines[$i]  =~ m/^([\s\t]*)/) {
		my $padding = $1;
		my $encodedPadding = '';
		my $paddingLen = length($padding);
		for (my $i = 0; $i < $paddingLen; $i++) {
			if (substr($padding, $i, 1) eq ' ') {
				$encodedPadding .= '&nbsp;';
			} else {
				$encodedPadding .= '&nbsp;&nbsp;&nbsp;&nbsp;';	
			}
		}
		$lines[$i]  =~ s|^[\s\t]*|$encodedPadding|g;
	}
	
	$lines[$i]  =~ s|<|&lt;|g;
	$lines[$i]  =~ s|>|&gt;|g;	
}

my $diffs_cnt = $#{$diffs};
my $line_template = "<tr><td class='diff_td_l %s'>%s</td><td class='diff_td_r %s'>%s</td></tr>\n";
for (my $i = 0; $i <= $diffs_cnt; $i++) {
	my $out_title = sprintf("<tr height='25'><td class='leftTd leftLineInfoTitle'>Line: %s</td><td class='rightLineInfoTitle'>Line: %s</td></tr>\n",
						$diffs->[$i]->{entry_l_start},
						$diffs->[$i]->{entry_r_start}
	);

	print $out_title;
		
	my $blocks 		= $diffs->[$i]->{entry_blocks};
	my $blocks_cnt 	= $#{$blocks};
	
	for (my $x = 0; $x <= $blocks_cnt; $x++) {
		my $out = "";
		
		my $info = $blocks->[$x]; 
	
		if ($info->{type} eq " ") {
			for (my $no = $info->{start}; $no <= $info->{end}; $no++) {
				$out .= sprintf($line_template,
						'bgClrNormal',
						$lines[$no],
						'bgClrNormal',
						$lines[$no]);
			}
		}

		if ($info->{type} eq "-") {
			for (my $no = $info->{start}; $no <= $info->{end}; $no++) {
				$out .= sprintf($line_template,
						'bgClrRemoved',
						$lines[$no],
						'bgClrAddedRemovedEmpty',
						"&nbsp;");
			}
		}
		
		if ($info->{type} eq "+") {
			for (my $no = $info->{start}; $no <= $info->{end}; $no++) {
				$out .= sprintf($line_template,
						'bgClrAddedRemovedEmpty',
						"&nbsp;",
						'bgClrAdded',
						$lines[$no],);
			}
		}	
		
		if ($info->{type} eq "!") {
			my $next_info 	= $blocks->[$x + 1];
			my $left_lines 	= $info->{end} - $info->{start};
			my $right_lines = $next_info->{end} - $next_info->{start};
			my $max 		= $left_lines >= $right_lines ? $left_lines : $right_lines;

			for (my $no = 0; $no <= $max; $no++) {
				my $left_content	= $no <= $left_lines ? $lines[$info->{start} + $no] : "&nbsp;";
				my $right_content 	= $no <= $right_lines ? $lines[$next_info->{start} + $no] : "&nbsp;";
				
				my $left_color		= $no <= $left_lines ? 'bgClrModified' : 'bgClrModifiedEmpty';
				my $right_color		= $no <= $right_lines ? 'bgClrModified' : 'bgClrModifiedEmpty';
				
				$out .= sprintf($line_template,
						$left_color,
						$left_content,
						$right_color,
						$right_content);
			}
			
			$x++;
		}				

		print $out;
	}
}



print <<HTML_END;
</table>

<div class="labelLegend">Legend:</div>

<table class="dfLegend">
	<tr height="22">
		<td class="leftTd bgClrRemoved alignCenter">Removed lines</td>
		<td class="bgClrAddedRemovedEmpty alignCenter">&nbsp;</td>
	</tr>
	<tr height="22">
		<td colspan="2" class="bgClrModified alignCenter">Changed lines</td>
	</tr>	
	<tr height="22">
		<td class="leftTd bgClrAddedRemovedEmpty alignCenter">&nbsp;</td>
		<td class="leftTd bgClrAdded alignCenter">Added lines</td>
	</tr>
</table>

<table class="powerBy">
  <tr>
    <td></td>
    <td class="copyright">
      <a target="_blank" href="http://sourceforge.net/projects/ccv" class="ftUline ftItalic">CodeChangeViewer</a>
      <br>
      http://sourceforge.net/projects/ccv    
    </td>
  </tr>
</table>
</body>
</html>

HTML_END



#
#
#
sub add_diff_entry() {
	my $diff_info = {entry_l_start 		=> $entry_l_start,
					 entry_r_start 		=> $entry_r_start,
					 entry_l_lines 		=> $entry_l_lines,
					 entry_r_lines 		=> $entry_r_lines,
					 entry_start		=> $entry_start,
					 entry_end			=> $entry_end,
					 entry_blocks		=> $blocks};
	
	push(@{$diffs}, $diff_info);
		
	$entry_l_start 	= 0;	
	$entry_r_start 	= 0;
	$entry_l_lines 	= 0;
	$entry_r_lines 	= 0;

	$entry_start 	= 0;	
	$entry_end 		= 0;	
	
	$block_start 	= 0;
	$block_end		= 0;
	$block_type		= " ";
	
	$first			= " ";
	$previous_first	= " ";
	$previous_block_type	= " ";	
}

sub get_block_type() {
	if ($previous_first eq "-" && $first eq "+") {
		$block_type = "!";#modified block left	
	} elsif ($previous_block_type eq "!" && $previous_first eq "+") {
		$block_type = "!";#modified block right	
	} else {
		$block_type = $previous_first;
	}	
}
