#!/usr/bin/perl -I ./thirds
# author: lilong'en(lilongen@163.com)
# date: 11/04/2010
#
package UDiffer;

use strict;
use English;
use Data::Dumper;
use CcvUtil;

#===============================================================================
# CONSTRUCTOR:	
#       $obj = new Differ; 
#===============================================================================
sub new() {
	my $pkg = shift;
    my $self = {};
    bless $self, $pkg;
    
    return $self;
}

sub resetVars() {
	my $self = shift;
	$self->{entry_l_start} 	= 0;	
	$self->{entry_r_start} 	= 0;
	$self->{entry_l_lines} 	= 0;
	$self->{entry_r_lines} 	= 0;
	$self->{entry_start} 	= 0;	
	$self->{entry_end} 		= 0;	
	$self->{block_start} 	= 0;
	$self->{block_end}		= 0;
	$self->{block_type}		= " ";
	$self->{first} 			= " ";
	$self->{previous_first}	= " ";
	$self->{previous_block_type}	= " ";	
}

sub genDiffHtml() {
	my $self = shift;
	my $df = shift;
	my @lines 			= split("\n", $$df);
		
	$self->{lines}		= \@lines;
	$self->{lines_cnt}	= $#lines;
	$self->{diffs}		= [];
	$self->{blocks} 	= undef;
	$self->{outHtml} 	= '';
	$self->resetVars();	
	
	$self->phaseLines();
	$self->preHandleLines();
	$self->constructDfFromatHtml();
	$self->getTemplateParts();
	
	$self->{outHtml} = $self->{TplParts}->{p1} . "\n\n" . $self->{outHtml} . "\n\n" . $self->{TplParts}->{p2};
}

sub genFileOutHtml() {
	my $self = shift;
	my $df = shift;
	my $file = shift;
	my $rev = shift;
	
	$$df =~ s|<|&lt;|g;
	$$df =~ s|>|&gt;|g;	
	$$df =~ s|&|&amp;|g;
	
	$self->{outHtml} = "<tr><td class='diff_td_l bgClrAddedRemovedEmpty'>&nbsp;</td><td class='diff_td_r bgClrAdded'><pre>" . $$df . "</pre></td></tr>\n";	

	$self->getTemplateParts($file, $rev);
	$self->{outHtml} = $self->{TplParts}->{p1} . "\n\n" . $self->{outHtml} . "\n\n" . $self->{TplParts}->{p2};		
}

sub getTemplateParts() {
	my $self = shift;
	my $file = shift;
	my $rev = shift;
	
	my $ccvUtil = new CcvUtil();
	my $tplContent = $ccvUtil->getFileAllContent('web/diff_tpl.html');
    my $separator = "#DF_LINES#";
    my $sepPos = index($tplContent, $separator);
    my $part1 = substr($tplContent, 0, $sepPos);
    my $part2 = substr($tplContent, $sepPos + length($separator));
    
    if (defined($file)) {
    	$part1 =~s/#FILE#/$file/;
    	$part1 =~s/#REV1#//;
    	$part1 =~s/#REV2#/$rev/;	
    } else {
    	$part1 =~s/#FILE#/$self->{file}/;
    	$part1 =~s/#REV1#/$self->{rev1}/;
    	$part1 =~s/#REV2#/$self->{rev2}/;
    }
	
    $self->{TplParts} = {'p1' => $part1, 'p2' => $part2};
}

sub phaseLines() {
	my $self = shift;
	my $i_start = 4;
	#Index: widget.profile.js
	#===================================================================
	#--- widget.profile.js	(revision 6563)
	#+++ widget.profile.js	(revision 6564)
	#@@ -1 +1 @@
	if ($self->{lines}->[0] =~ m/^Index: (.+)$/) {
		$self->{file} = $1;
	}
	
	if ($self->{lines}->[2] =~ m/^--- .+\s+\(revision (\d+)\)$/) {
		$self->{rev1} = $1;
	}
	
	if ($self->{lines}->[3] =~ m/^\+\+\+ .+\s+\(revision (\d+)\)$/) {
		$self->{rev2} = $1;
	}


	for (my $i = $i_start; $i <= $self->{lines_cnt}; $i ++) {
		if ($self->{lines}->[$i] =~ m/^\@\@ (.+) \@\@$/) { # @@ -2215,7 +2217,7 @@, @@ -2215 +2217 @@
			if ($i > $i_start) {
				$self->{entry_end} 		= $i - 1;
				$self->{block_end} 		= $i - 1;
				$self->get_block_type();
				push(@{$self->{blocks}}, {start => $self->{block_start}, end => $self->{block_end}, type => $self->{block_type}});			
				
				$self->add_diff_entry();
	
			}
			
		    my $data = $1;
		    $self->{entry_start}	= $i + 1;
		    if ($data =~ m/-(\d+),(\d+) \+(\d+),(\d+)/) {
	    		$self->{entry_l_start} 	= $1;
	    		$self->{entry_l_lines}	= $2;
	    		
	    		$self->{entry_r_start}	= $3;
	    		$self->{entry_r_lines}	= $4;
		    } elsif ($data =~ m/-(\d+) \+(\d+)/) {
	    		$self->{entry_l_start} 	= $1;
	    		$self->{entry_l_lines}	= 1;
	    		
	    		$self->{entry_r_start}	= $2;
	    		$self->{entry_r_lines}	= 1;
		    }
			
			$self->{blocks} 		= [];
			$self->{previous_first} = " ";
			$self->{block_start}	= $i + 1;
			
			next;
		}
		
		$self->{first} = substr($self->{lines}->[$i], 0, 1);
		if ($self->{first} eq $self->{previous_first}) {
			next;
		}
		
		$self->{block_end} = $i - 1;
		$self->get_block_type();
		push(@{$self->{blocks}}, {start => $self->{block_start}, end => $self->{block_end}, type => $self->{block_type}});
		
		$self->{previous_first} = $self->{first};
		$self->{block_start} = $self->{block_end} + 1;
		$self->{previous_block_type} = $self->{block_type};
	} 

	$self->{entry_end} 	= $self->{lines_cnt};
	$self->{block_end} = $self->{lines_cnt};
	$self->get_block_type();
	push(@{$self->{blocks}}, {start => $self->{block_start}, end => $self->{block_end}, type => $self->{block_type}});
	
	$self->add_diff_entry();
}

sub preHandleLines() {
	my $self = shift;
	
	for (my $i = 0; $i <= $self->{lines_cnt}; $i++) {
		$self->{lines}->[$i] = substr($self->{lines}->[$i], 1);
		$self->{lines}->[$i] =~ s|&|&amp;|g;
		if ($self->{lines}->[$i] eq "") {
			$self->{lines}->[$i] = "&nbsp;";
			next;
		}		
		
		if ($self->{lines}->[$i]  =~ m/^([\s\t]*)/) {
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
			$self->{lines}->[$i]  =~ s|^[\s\t]*|$encodedPadding|g;
		}
		
		$self->{lines}->[$i] =~ s|<|&lt;|g;
		$self->{lines}->[$i] =~ s|>|&gt;|g;
	}
}


sub constructDfFromatHtml() {
	my $self = shift;
	################################################################################
	#foramt diff and out
	my $diffs_cnt = $#{$self->{diffs}};
	my $line_template = "<tr><td class='diff_td_l %s'>%s</td><td class='diff_td_r %s'>%s</td></tr>\n";
	for (my $i = 0; $i <= $diffs_cnt; $i++) {
		my $out_title = sprintf("<tr height='25'><td class='leftTd leftLineInfoTitle'>Line: %s</td><td class='rightLineInfoTitle'>Line: %s</td></tr>\n",
							$self->{diffs}->[$i]->{entry_l_start},
							$self->{diffs}->[$i]->{entry_r_start});
	
		$self->{outHtml} .= $out_title;
			
		my $blocks = $self->{diffs}->[$i]->{entry_blocks};
		my $blocks_cnt 	= $#{$blocks};
		
		for (my $x = 0; $x <= $blocks_cnt; $x++) {
			my $info = $blocks->[$x]; 
		
			if ($info->{type} eq " ") {
				for (my $no = $info->{start}; $no <= $info->{end}; $no++) {
					$self->{outHtml} .= sprintf($line_template,
							'bgClrNormal',
							$self->{lines}->[$no],
							'bgClrNormal',
							$self->{lines}->[$no]
					);
				}
			}
	
			if ($info->{type} eq "-") {
				for (my $no = $info->{start}; $no <= $info->{end}; $no++) {
					$self->{outHtml} .= sprintf($line_template,
							'bgClrRemoved',
							$self->{lines}->[$no],
							'bgClrAddedRemovedEmpty',
							"&nbsp;"
					);
				}
			}
			
			if ($info->{type} eq "+") {
				for (my $no = $info->{start}; $no <= $info->{end}; $no++) {
					$self->{outHtml} .= sprintf($line_template,
							'bgClrAddedRemovedEmpty',
							"&nbsp;",
							'bgClrAdded',
							$self->{lines}->[$no]
					);
				}
			}	
			
			if ($info->{type} eq "!") {
				my $next_info 	= $blocks->[$x + 1];
				my $left_lines 	= $info->{end} - $info->{start};
				my $right_lines = $next_info->{end} - $next_info->{start};
				my $max 		= $left_lines >= $right_lines ? $left_lines : $right_lines;
	
				for (my $no = 0; $no <= $max; $no++) {
					my $left_content	= $no <= $left_lines ? $self->{lines}->[$info->{start} + $no] : "&nbsp;";
					my $right_content 	= $no <= $right_lines ? $self->{lines}->[$next_info->{start} + $no] : "&nbsp;";
					
					my $left_color		= $no <= $left_lines ? 'bgClrModified' : 'bgClrModifiedEmpty';
					my $right_color		= $no <= $right_lines ? 'bgClrModified' : 'bgClrModifiedEmpty';
					
					$self->{outHtml} .= sprintf($line_template,
							$left_color,
							$left_content,
							$right_color,
							$right_content
					);
				}
				
				$x++;
			}				
		}
	}
}

sub add_diff_entry() {
	my $self = shift;
	
	my $diff_info = {entry_l_start 		=> $self->{entry_l_start},
					 entry_r_start 		=> $self->{entry_r_start},
					 entry_l_lines 		=> $self->{entry_l_lines},
					 entry_r_lines 		=> $self->{entry_r_lines},
					 entry_start		=> $self->{entry_start},
					 entry_end			=> $self->{entry_end},
					 entry_blocks		=> $self->{blocks}};
	
	push(@{$self->{diffs}}, $diff_info);
		
	$self->resetVars();
}

sub get_block_type() {
	my $self = shift;
	if ($self->{previous_first} eq "-" && $self->{first} eq "+") {
		$self->{block_type} = "!";#modified block left	
	} elsif ($self->{previous_block_type} eq "!" && $self->{previous_first} eq "+") {
		$self->{block_type} = "!";#modified block right	
	} else {
		$self->{block_type} = $self->{previous_first};
	}	
}

#===============================================================================
#
# END of the module.
#
#===============================================================================
1;
__END__
