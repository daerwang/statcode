#!/usr/bin/perl -I ./thirds
# author: lilong'en(lilongen@163.com)
# date: 01/23/2010
#
package ccvGraph;


use strict;
use English;
use Data::Dumper;
use Date::Calc qw(:all);
use CcvUtil;
use Definition;
use GD;
use GD::Graph::bars;
use GD::Graph::hbars;
use GD::Graph::lines;
use GD::Graph::linespoints;

sub new() {
    my $pkg = shift;
    my $filePath = shift;
    
    my $self = {};
    bless $self, $pkg;
    
    $self->{ccvUtil} = new CcvUtil();
    $self->{DEF} = new Definition();
	$self->{filePath} = $filePath;
	
    $self->{barWidth} = 18;
    $self->{barSpacing} = 12;

    $self->{width} = 720;
    $self->{height} = 480;    
    
    $self->{lineWidth1} = 2;
    $self->{lineWidth2} = 3;
    
    $self->{dateSkip} = 6;
	
	$self->{fgClr} = '#cccccc';
	$self->{dClr1} = ['green'];
	$self->{dClr2} = ['lorange'];
	$self->{dClrs} = [qw(lblue gold lgreen lred black lorange dpink marine cyan lgray lpurple lbrown gray dgray blue dblue green dgreen red dred purple dpurple orange pink dbrown)];
	
	$self->{legend_font} = GD::Font->MediumBold;
	
    $self->{user_loc_image} 			= $self->{filePath} . "user_loc.png";
    $self->{user_aver_loc_image} 		= $self->{filePath} . "user_aver_loc.png";
    $self->{user_date_loc_image} 		= "user_date_loc.png";
    $self->{user_date_accu_loc_image} 	= "user_date_accu_loc.png";
    $self->{module_date_loc_image} 		= $self->{filePath} . "module_date_loc.png";
    $self->{module_date_accu_loc_image} = $self->{filePath} . "module_date_accu_loc.png";
    
    
    if (!-e ($filePath . $self->{DEF}->{MID_DATA_FILE_NAME}->{CVS_GD_DATA})) {
    	$self->constructAndDumpGrpahData2File();
    } else {
		$self->loadGraphDataFromFile();
    }
    
    $self->setDayWidth();
    $self->setImageSize();
    $self->setDateSkip();
    
    return $self;
}

sub constructAndDumpGrpahData2File() {
    my $self = shift;		
    
    $self->{users} = undef;
    $self->{lines} = $self->{ccvUtil}->loadFile($self->{filePath} . $self->{DEF}->{MID_DATA_FILE_NAME}->{CVS_GD_DATA_USER_INFO});

    @{$self->{firstDate}} = split(/[\\\/\-]/, $self->{lines}->{first_date});
    @{$self->{lastDate}} = split(/[\\\/\-]/, $self->{lines}->{last_date});
    $self->{deltaDays} = Delta_Days(@{$self->{firstDate}}, @{$self->{lastDate}});
    
    $self->{dates} = [];

    $self->constructUserLOCs();
    $self->constructUserDateLOCs();
    $self->constructUserDateLOCs4Graph();
    $self->constructModuleDateLOCs4Graph();
    
    $self->{ccvUtil}->dumpFile($self->{filePath} . $self->{DEF}->{MID_DATA_FILE_NAME}->{CVS_GD_DATA} , {
    	users						=> $self->{users},
    	user_cnt					=> $self->{user_cnt},
    	
    	firstDate					=> $self->{firstDate},
    	lastDate					=> $self->{lastDate},
    	deltaDays					=> $self->{deltaDays},
    	dates						=> $self->{dates},
    	
		user_loc_graph 				=> $self->{user_loc_graph},
		user_aver_loc_graph			=> $self->{user_aver_loc_graph},
	    user_date_loc 				=> $self->{user_date_loc},
	    user_date_loc_graph 		=> $self->{user_date_loc_graph},
	    user_date_accu_loc 			=> $self->{user_date_accu_loc},
	    user_date_accu_loc_graph 	=> $self->{user_date_accu_loc_graph},
	    module_date_loc_graph 		=> $self->{module_date_loc_graph},
	    module_date_accu_loc_graph 	=> $self->{module_date_accu_loc_graph}
    });
    
}

sub loadGraphDataFromFile() {
	my $self = shift;
	my $data = $self->{ccvUtil}->loadFile($self->{filePath} . $self->{DEF}->{MID_DATA_FILE_NAME}->{CVS_GD_DATA});
	$self->{users} 			= $data->{users};
	$self->{shown_users} 	= $self->{users};
	$self->{user_cnt} 		= $data->{user_cnt};
	
	$self->{firstDate}  	= $data->{firstDate};
	$self->{lastDate} 		= $data->{lastDate};	
	$self->{deltaDays} 		= $data->{deltaDays};
	$self->{dates} 			= $data->{dates};

	$self->{user_loc_graph} 			= $data->{user_loc_graph};
	$self->{user_aver_loc_graph} 		= $data->{user_aver_loc_graph};
	$self->{user_date_loc} 				= $data->{user_date_loc};
	$self->{user_date_loc_graph} 		= $data->{user_date_loc_graph};
	$self->{user_date_accu_loc} 		= $data->{user_date_accu_loc};
	$self->{user_date_accu_loc_graph} 	= $data->{user_date_accu_loc_graph};
	$self->{module_date_loc_graph}		= $data->{module_date_loc_graph};
	$self->{module_date_accu_loc_graph}	= $data->{module_date_accu_loc_graph};
	
	
}

sub setDateSkip() {
    my $self = shift;
    
    my $skip = 6;
	if ($self->{deltaDays} <= 30) {
		$skip = 6;
	} elsif($self->{deltaDays} <= 60) {
		$skip = 8;
	} elsif($self->{deltaDays} <= 90) {
		$skip = 10;
	} elsif($self->{deltaDays} <= 150) {
		$skip = 12;
	} elsif($self->{deltaDays} <= 300) {
		$skip = 14;
	} else {
		$skip = 16;
	}    
	
    $self->{dateSkip} = $skip;
}


sub setDayWidth() {
	my $self = shift;
	my $width = 10;
	if ($self->{deltaDays} <= 30) {
		$width = 20;
	} elsif($self->{deltaDays} <= 60) {
		$width = 10;
	} elsif($self->{deltaDays} <= 90) {
		$width = 6;
	} elsif($self->{deltaDays} <= 150) {
		$width = 4;
	} elsif($self->{deltaDays} <= 300) {
		$width = 2;
	} else {
		$width = 1;
	}
	
	$self->{dayWidth} = $width;
}

sub setImageSize() {
	my $self = shift;
    $self->{width} = ($self->{deltaDays} + 1) * $self->{dayWidth} + 160;
    $self->{height} = 480;
}

#
# Followings are for graph data construction 
#
#
sub constructUserLOCs() {
    my $self = shift;	
    
	my @curr_keys = sort {
	        	lc($a) cmp lc($b)     # compare with key
	    		}  keys %{$self->{lines}};
	
	my $arrUser = [];
	my $arrUserLines = [];
	my $arrUserAverLines = [];
	
	my $len = $#curr_keys;			
	for (my $index = 0; $index <= $len; $index++) {
		if (ref($self->{lines}->{$curr_keys[$index]}) ne "HASH") {
			splice(@curr_keys, $index, 1);
			$len --;
			$index --;
			
			next;
		}
		
		push(@{$arrUser}, $curr_keys[$index]);
		push(@{$arrUserLines}, $self->{lines}->{$curr_keys[$index]}->{lines});
		
        my @userFirstDay = split(/[\\\/\-]/, $self->{lines}->{$curr_keys[$index]}->{first_date});
        my @userLastDay = split(/[\\\/\-]/, $self->{lines}->{$curr_keys[$index]}->{last_date});
        my $userDeltaDays = Delta_Days(@userFirstDay, @userLastDay) || 1;
		push(@{$arrUserAverLines}, int($self->{lines}->{$curr_keys[$index]}->{lines} / $userDeltaDays));
	}
	
	$self->{users} = \@curr_keys;
	$self->{user_cnt} = $#{$self->{users}};
	
	$self->{user_loc_graph} = [$arrUser, $arrUserLines];
	$self->{user_aver_loc_graph} = [$arrUser, $arrUserAverLines];
}


sub constructUserDateLOCs() {
    my $self = shift;	

	my $year = 0;
	my $month = 0;
	my $day = 0;
	
	$self->{user_date_loc} = {};
	$self->{user_date_accu_loc} = {};
	
	for (my $index = 0; $index <= $self->{user_cnt}; $index++) {
		my $user = $self->{users}->[$index];
		
		$self->{user_date_loc}->{$user} = [];
		$self->{user_date_accu_loc}->{$user} = [];
		
		my $accuLOC = 0;
		for (my $i = 0; $i < $self->{deltaDays}; $i++) {
			($year, $month, $day) = Add_Delta_Days(@{$self->{firstDate}}, $i);
			my $date = sprintf("%04d/%02d/%02d", $year, $month, $day);
			
			if ($index == 0) {
				push(@{$self->{dates}}, $date);
			}
			my $lines = defined($self->{lines}->{$user}->{date}->{$date}) ? $self->{lines}->{$user}->{date}->{$date} : 0;
			push(@{$self->{user_date_loc}->{$user}}, $lines);
			
			$accuLOC += $lines;
			push(@{$self->{user_date_accu_loc}->{$user}}, $accuLOC);			
		}
	}	
}

sub constructUserDateLOCs4Graph() {
    my $self = shift;
    my $users_string = shift;
    
    if (!defined($users_string)) {
    	$users_string = "";
    }
	
	$self->{user_date_loc_graph} = [];
	push(@{$self->{user_date_loc_graph}}, $self->{dates});
	
	$self->{user_date_accu_loc_graph} = [];
	push(@{$self->{user_date_accu_loc_graph}}, $self->{dates});
	
	$self->{shown_users} = undef;
	$self->{shown_users} = [];
	for (my $index = 0; $index <= $self->{user_cnt}; $index++) {
		my $user = $self->{users}->[$index];
		
		if ($users_string eq "" || index(",$users_string,", ",$user,") != -1) {
			push(@{$self->{shown_users}}, $user);
			
			push(@{$self->{user_date_loc_graph}}, $self->{user_date_loc}->{$user});
			push(@{$self->{user_date_accu_loc_graph}}, $self->{user_date_accu_loc}->{$user});		
		}
	}
	
	$self->{users_file_prefix} = "";
	if ($#{$self->{shown_users}} < $self->{user_cnt}) {
		$self->{users_file_prefix} = join(".", @{$self->{shown_users}});
	}
}

sub constructModuleDateLOCs4Graph() {
    my $self = shift;	

	my $year = 0;
	my $month = 0;
	my $day = 0;
	
	my $module_date_loc = {};
	my $module_date_loc_array = [];
	
	my $module_date_accu_loc = {};
	my $module_date_accu_loc_array = [];
	my $date_accu_loc = 0;	
	
	for (my $i = 0; $i < $self->{deltaDays}; $i++) {
		($year, $month, $day) = Add_Delta_Days(@{$self->{firstDate}}, $i);
		
		my $date = sprintf("%04d/%02d/%02d", $year, $month, $day);
		
		for (my $index = 0; $index <= $self->{user_cnt}; $index++) {
			my $user = $self->{users}->[$index];
			my $lines = defined($self->{lines}->{$user}->{date}->{$date}) ? $self->{lines}->{$user}->{date}->{$date} : 0;
			
			if (defined($module_date_loc->{$date})) {
				$module_date_loc->{$date} += $lines;
			} else {
				$module_date_loc->{$date} = $lines;
			}
			
			if (defined($module_date_accu_loc->{$date})) {
				$module_date_accu_loc->{$date} += $lines;
			} else {
				$module_date_accu_loc->{$date} = $date_accu_loc + $lines;
			}			
		}
		
		$date_accu_loc = $module_date_accu_loc->{$date};
		
		push(@{$module_date_loc_array}, $module_date_loc->{$date});
		push(@{$module_date_accu_loc_array}, $module_date_accu_loc->{$date});
	}
	
	$self->{module_date_loc_graph} = [];
	push(@{$self->{module_date_loc_graph}}, $self->{dates});		
	push(@{$self->{module_date_loc_graph}}, $module_date_loc_array);
	
	$self->{module_date_accu_loc_graph} = [];
	push(@{$self->{module_date_accu_loc_graph}}, $self->{dates});		
	push(@{$self->{module_date_accu_loc_graph}}, $module_date_accu_loc_array);		
}

#
# Followings are graph drawing.
#
sub drawUserLOC() {
    my $self = shift;	
    
	if (-e $self->{user_loc_image}) {
		return;		
	}
	
    my $userCnt = $#{$self->{user_loc_graph}->[0]};
    my $height = $userCnt * ($self->{barWidth} + $self->{barSpacing}) + 80; 
	my $graph = new GD::Graph::hbars(600, $height);
	
	$graph->set(
		x_label         => 'Developer',
		y_label         => 'LOC',
		title           => 'Developer LOC graph',
		dclrs     		=> $self->{dClr1},
		fgclr 			=> $self->{fgClr},
		bar_spacing 	=> $self->{barSpacing},
		bar_width 		=> $self->{barWidth},
		x_ticks      	=> 0,
		long_ticks		=> 1,
		y_tick_number   => 10,
		show_values     => 1,
	)
	or warn $graph->error;
	$graph->set_x_axis_font(GD::Font->MediumBold);	
	$graph->plot($self->{user_loc_graph}) or die $graph->error;
	
	my $H_GRAPH;
	open($H_GRAPH, ">", $self->{user_loc_image}) || die "Cannot open $self->{user_loc_image}: $!\n";
	print $H_GRAPH $graph->gd->png;
	
	close($H_GRAPH);
}

sub drawUserAverLOC() {
    my $self = shift;	
    
	if (-e $self->{user_aver_loc_image}) {
		return;		
	}
	
    my $userCnt = $#{$self->{user_aver_loc_graph}->[0]};
    my $height = $userCnt * ($self->{barWidth} + $self->{barSpacing}) + 80; 
	my $graph = new GD::Graph::hbars(600, $height);
	
	$graph->set(
		x_label         => 'Developer',
		y_label         => 'LOC per day',
		title           => 'Developer average LOC graph',
		dclrs     		=> $self->{dClr2},
		fgclr 			=> $self->{fgClr},
		bar_spacing 	=> $self->{barSpacing},
		bar_width 		=> $self->{barWidth},
		x_ticks      	=> 0,
		long_ticks		=> 1,
		y_tick_number   => 10,
		show_values     => 1,
	)
	or warn $graph->error;
	$graph->set_x_axis_font(GD::Font->MediumBold);	
	$graph->plot($self->{user_aver_loc_graph}) or die $graph->error;
	
	my $H_GRAPH;
	open($H_GRAPH, ">", $self->{user_aver_loc_image}) || die "Cannot open $self->{user_aver_loc_image}: $!\n";
	print $H_GRAPH $graph->gd->png;
	
	close($H_GRAPH);
}

sub getUsersDateImageFile() {
	my $self = shift;
	my $file = shift;
	
	if ($self->{users_file_prefix}) {
		return $self->{filePath} . $self->{users_file_prefix} . "-" . $file;
	} else {
		return $self->{filePath} . $file;
	}
	
}

sub drawUserDateLOC() {
	my $self = shift;
	
	my $image_file = $self->getUsersDateImageFile($self->{user_date_loc_image});
	if (-e $image_file) {
		return $image_file;		
	}
	
	my $graph = new GD::Graph::linespoints($self->{width}, $self->{height});

	$graph->set(
		x_label         => 'Date',
		y_label         => 'Code Lines',
		title           => 'Developer Date LOC graph',
		fgclr 			=> $self->{fgClr},
		dclrs			=> $self->{dClrs},
		x_ticks      	=> 1,
		long_ticks		=> 1,
		y_tick_number   => 10,
		x_label_skip 	=> $self->{dateSkip},
		x_labels_vertical => 1,
		show_values     => 0,
		line_width      => $self->{lineWidth1},
		marker_size		=> 0,
	)
	or warn $graph->error;
	
	$graph->set_legend(@{$self->{shown_users}});
	$graph->set_legend_font($self->{legend_font});
	$graph->plot($self->{user_date_loc_graph}) or die $graph->error;
	
	my $H_GRAPH;
	
	open($H_GRAPH, ">", $image_file) || die "Cannot open $image_file: $!\n";
	print $H_GRAPH $graph->gd->png;
	
	close($H_GRAPH);
	
	return $image_file;
}

sub drawUserDateAccuLOC() {
	my $self = shift;
	
	my $image_file = $self->getUsersDateImageFile($self->{user_date_accu_loc_image});
	if (-e $image_file) {
		return $image_file;		
	}

	my $graph = new GD::Graph::linespoints($self->{width}, $self->{height});

	$graph->set(
		x_label         => 'Date',
		y_label         => 'LOC',
		title           => 'Developer date accumulative LOC graph',
		fgclr 			=> $self->{fgClr},
		dclrs			=> $self->{dClrs},
		x_ticks      	=> 1,
		long_ticks		=> 1,
		y_tick_number   => 10,
		x_label_skip 	=> $self->{dateSkip},
		x_labels_vertical => 1,
		show_values     => 0,
		line_width      => $self->{lineWidth1},
		marker_size		=> 0,
	)
	or warn $graph->error;

	$graph->set_legend(@{$self->{shown_users}});
	$graph->set_legend_font($self->{legend_font});
	$graph->plot($self->{user_date_accu_loc_graph}) or die $graph->error;
	
	my $H_GRAPH;
	open($H_GRAPH, ">", $image_file) || die "Cannot open $image_file: $!\n";
	print $H_GRAPH $graph->gd->png;
	
	close($H_GRAPH);
	
	return $image_file;
}

sub drawModuleDateLOC() {
	my $self = shift;

	if (-e $self->{module_date_loc_image}) {
		return;		
	}
		
	my $graph = new GD::Graph::linespoints($self->{width}, $self->{height});

	$graph->set(
		x_label         => 'Date',
		y_label         => 'LOC',
		title           => 'Moudle date LOC graph',
		dclrs     		=> $self->{dClr2},
		fgclr 			=> $self->{fgClr},
		x_ticks      	=> 1,
		long_ticks		=> 1,
		y_tick_number   => 10,
		x_label_skip 	=> $self->{dateSkip},
		x_labels_vertical => 1,
		show_values     => 0,
		line_width      => $self->{lineWidth2},
		marker_size		=> 0,
	)
	or warn $graph->error;
	
	$graph->set_legend('LOC');
	$graph->plot($self->{module_date_loc_graph}) or die $graph->error;
	
	my $H_GRAPH;
	open($H_GRAPH, ">", $self->{module_date_loc_image}) || die "Cannot open $self->{module_date_loc_image}: $!\n";
	print $H_GRAPH $graph->gd->png;
	
	close($H_GRAPH);	
}

sub drawModuleDateAccuLOC() {
	my $self = shift;

	if (-e $self->{module_date_accu_loc_image}) {
		return;		
	}
	
	my $graph = new GD::Graph::linespoints($self->{width}, $self->{height});

	$graph->set(
		x_label         => 'Date',
		y_label         => 'Accumulative LOC',
		title           => 'Moudle date accumulative LOC graph',
		dclrs     		=> $self->{dClr1},
		fgclr 			=> $self->{fgClr},
		x_ticks      	=> 1,
		long_ticks		=> 1,
		y_tick_number   => 10,
		x_label_skip 	=> $self->{dateSkip},
		x_labels_vertical => 1,
		show_values     => 0,
		line_width      => $self->{lineWidth2},
		marker_size		=> 0,
	)
	or warn $graph->error;
	
	$graph->set_legend('Accumulative LOC');
	$graph->plot($self->{module_date_accu_loc_graph}) or die $graph->error;
	
	my $H_GRAPH;
	open($H_GRAPH, ">", $self->{module_date_accu_loc_image}) || die "Cannot open $self->{module_date_accu_loc_image}: $!\n";
	print $H_GRAPH $graph->gd->png;
	
	close($H_GRAPH);	
}

#===============================================================================
#
# END of the module.
#
#===============================================================================
1;
__END__
