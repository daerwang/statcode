#!/usr/bin/perl -I ./thirds
# author: lilong'en(lilongen@163.com)
# date: 05/12/2011
#
package GraphDataer;


use strict;
use English;
use Data::Dumper;
use Date::Calc qw(:all);

sub new() {
    my $pkg = shift;
    my $outTo = shift;
    my $phasedInfo = shift;
    
    my $self = {};
    bless $self, $pkg;
    
	$self->{PhasedInfo} = $phasedInfo;
    
    return $self;
}

sub constructGraphData() {
	my $self = shift; 
	
	$self->{GraphData} = {
		"User" => {
			"LOC" => [],
			"FOC" => [],
			"RevsCnt" => [],
			"AccuLOC" => [],
			"AccuRevsCnt" => [],
			"AverLOC" => [],
			"Liveless" => [],
			"DayLOC" => []
		},
		
		"UserNames" => undef,
		"Dates"  => undef,
		"RevsCnt" => 0,
		
		"Module" => {
			"DayLOC" => [],
			"AccuLOC" => [],
			"AverLOC" => [],
			"AccuRevsCnt" => [],
			"Liveless" => []
		}
	};

	my $usersInfo = $self->{PhasedInfo}->{UsersInfo};
	my $revsInfo = $self->{PhasedInfo}->{RevsInfo};
	my $pathsInfo = $self->{PhasedInfo}->{PathsInfo};
	
	my @usernames = sort { lc($a) cmp lc($b) } keys %{$usersInfo};
	$self->{GraphData}->{UserNames} = \@usernames;
	my $userCnt = $#usernames + 1;	
	for (my $i = 0; $i < $userCnt; $i++) {
		my $userInfo = $usersInfo->{$usernames[$i]}->{info};	
		push(@{$self->{GraphData}->{User}->{LOC}}, $userInfo->{addLines} + $userInfo->{delLines});
		push(@{$self->{GraphData}->{User}->{FOC}}, $userInfo->{filesCnt} + 0);
		push(@{$self->{GraphData}->{User}->{RevsCnt}}, $userInfo->{revsCnt} + 0);
	}

	my $dateInfo = {};
	my $firstDate = undef;
	my $lastDate = undef;
	
	my $revsMxIdx = $#{$revsInfo->{descRevs}};
	my $rev = "";
	
	$self->{GraphData}->{RevsCnt} = $revsMxIdx + 1;
	for (my $i = $revsMxIdx; $i >= 0; $i--) {
		$rev = $revsInfo->{descRevs}->[$i];
		
		my $revInfo = $revsInfo->{$rev};
		my $dateTime = $revInfo->{date};
		my @dt = split(/\s+/, $dateTime);
		my $d = $dt[0];
		my $t = $dt[1];
		
		if (!defined($firstDate)) {
			$firstDate = $d;
		}
		$lastDate = $d;
		
		my $author = $revInfo->{author};
		
		if (!defined($dateInfo->{$d})) {
			$dateInfo->{$d} = {
				module => {
					line => 0,
					revsCnt => 0
				},
				
				user => {}
			};
		}
		
		if (!defined($dateInfo->{$d}->{user}->{$author})) {
			$dateInfo->{$d}->{user}->{$author} = {
				line => 0,
				revsCnt => 0				
			};
		}
		
		my $cim = $dateInfo->{$d}->{module};
		my $ciu = $dateInfo->{$d}->{user}->{$author};
		
		$cim->{revsCnt} ++;
		$ciu->{revsCnt} ++;
		
		while ((my $k, my $v) = each %{$revInfo->{hashPaths}}) {
			if ($v->{type} eq 'T') {
				my $lines = $v->{addLines} + $v->{delLines};
				$cim->{line} += $lines;
				$ciu->{line} += $lines;
			}			
		}
	}
	
	my $moduleAccuLOC = 0;
	my $moduleAccuRevCnt = 0;
	
	my $usersAccuLOC = {};
	my $usersAccuRevsCnt = {};
	
	my $usersAccuLOCs = {}; 
	my $usersAccuRevsCnts = {};
	my $usersDayLOCs = {};
	
	my @dates = sort {$a cmp $b} keys %{$dateInfo};
	$self->{GraphData}->{Dates} = \@dates;
	my $dateCnt = $#dates + 1;
	
	for (my $i = 0; $i < $userCnt; $i++) {
		$usersAccuLOC->{$usernames[$i]} = 0;
		$usersAccuRevsCnt->{$usernames[$i]} = 0;
		$usersAccuLOCs->{$usernames[$i]} = [];
		$usersAccuRevsCnts->{$usernames[$i]} = [];
		$usersDayLOCs->{$usernames[$i]} = [];
	}
	
	for (my $i = 0; $i < $dateCnt; $i++) {	
		my $date = $dates[$i];
		my $dateInfo_date_module = $dateInfo->{$date}->{module};
		my $dateInfo_date_user = $dateInfo->{$date}->{user};
		
		$moduleAccuLOC += $dateInfo_date_module->{line};
		$moduleAccuRevCnt += $dateInfo_date_module->{revsCnt};
		$dateInfo_date_module->{AccuLOC} = $moduleAccuLOC;
		$dateInfo_date_module->{AccuRevsCnt} = $moduleAccuRevCnt;
		
		push(@{$self->{GraphData}->{Module}->{AccuLOC}}, $dateInfo_date_module->{AccuLOC});
		push(@{$self->{GraphData}->{Module}->{AccuRevsCnt}}, $dateInfo_date_module->{AccuRevsCnt});
		push(@{$self->{GraphData}->{Module}->{DayLOC}}, $dateInfo_date_module->{line});
		
		#if a user do not have loc in %date, then use previous date loc		
		for (my $j = 0; $j < $userCnt; $j++) {
			my $user = $usernames[$j];
			if (!defined($dateInfo_date_user->{$user})) {
				$dateInfo_date_user->{$user} = {};
			}
			$dateInfo_date_user->{$user}->{AccuLOC} = $usersAccuLOC->{$user};
			$dateInfo_date_user->{$user}->{AccuRevsCnt} = $usersAccuRevsCnt->{$user};			
		}
		
		foreach my $user (sort keys %{$dateInfo_date_user}) {
			$usersAccuLOC->{$user} += $dateInfo_date_user->{$user}->{line} || 0;
			$usersAccuRevsCnt->{$user} += $dateInfo_date_user->{$user}->{revsCnt} || 0;

			$dateInfo_date_user->{$user}->{AccuLOC} = $usersAccuLOC->{$user};
			$dateInfo_date_user->{$user}->{AccuRevsCnt} = $usersAccuRevsCnt->{$user};
		}
		
		for (my $j = 0; $j < $userCnt; $j++) {
			my $user = $usernames[$j];
			my $accuLOC = 0;
			my $accuRevsCnt = 0;
			my $dayLOC = 0;
			if (defined($dateInfo_date_user->{$user})) {
				$accuLOC = $dateInfo_date_user->{$user}->{AccuLOC};
				$accuRevsCnt = $dateInfo_date_user->{$user}->{AccuRevsCnt};
				$dayLOC = $dateInfo_date_user->{$user}->{line};
			}
			
			push(@{$usersAccuLOCs->{$user}}, $accuLOC);
			push(@{$usersAccuRevsCnts->{$user}}, $accuRevsCnt);
			push(@{$usersDayLOCs->{$user}}, $dayLOC);
		}
	}
	
	for (my $i = 0; $i < $userCnt; $i++) {
		my $user = $usernames[$i];
		push(@{$self->{GraphData}->{User}->{AccuLOC}}, $usersAccuLOCs->{$user});
		push(@{$self->{GraphData}->{User}->{AccuRevsCnt}}, $usersAccuRevsCnts->{$user});
		push(@{$self->{GraphData}->{User}->{DayLOC}}, $usersDayLOCs->{$user});
	}
	
	$self->uiTooltips();
}

sub uiTooltips() {
	my $self = shift;
	my $cnt = $#{$self->{GraphData}->{UserNames}} + 1;


	my $locs = $self->{GraphData}->{User}->{LOC};
	my $totalLOC = 0;
	for (my $i = 0; $i < $cnt; $i++) {
		$totalLOC += $locs->[$i];
	}
	
	$self->{GraphData}->{User}->{LOC_TOOLTIP} = [];
	for (my $i = 0; $i < $cnt; $i++) {
		push(@{$self->{GraphData}->{User}->{LOC_TOOLTIP}}, sprintf("%d (%.1f%%)", 
			$locs->[$i],
			($locs->[$i] / $totalLOC) * 100
		));
	}
		
	my $focs = $self->{GraphData}->{User}->{FOC};
	my $totalFOC = 0;
	for (my $i = 0; $i < $cnt; $i++) {
		$totalFOC += $focs->[$i];
	}
	
	$self->{GraphData}->{User}->{FOC_TOOLTIP} = [];
	for (my $i = 0; $i < $cnt; $i++) {
		push(@{$self->{GraphData}->{User}->{FOC_TOOLTIP}}, sprintf("%d (%.1f%%)", 
			$focs->[$i],
			($focs->[$i] / $totalFOC) * 100
		));
	}
	
	my $revsCnt = $self->{GraphData}->{User}->{RevsCnt};
	my $totalRevsCnt = 0;
	for (my $i = 0; $i < $cnt; $i++) {
		$totalRevsCnt += $revsCnt->[$i];
	}
	
	$self->{GraphData}->{User}->{RevsCnt_TOOLTIP} = [];
	for (my $i = 0; $i < $cnt; $i++) {
		push(@{$self->{GraphData}->{User}->{RevsCnt_TOOLTIP}}, sprintf("%d (%.1f%%)", 
			$revsCnt->[$i],
			($revsCnt->[$i] / $totalRevsCnt) * 100
		));
	}	
}


#===============================================================================
#
# END of the module.
#
#===============================================================================
1;
__END__
