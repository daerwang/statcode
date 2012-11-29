#!/usr/bin/perl -I ./thirds
# author: lilong'en(lilongen@163.com)
# date: 10/25/2010
#
package CcvUtil;


use strict;
use English;
use Data::Dumper;
use Storable;
use JSON;

sub new() {
	my $pkg = shift;
	
    my $self = {};
    bless $self, $pkg;
 
    return $self;
}

sub formatLoc4UI() {
	my $self = shift;
	my $info = shift;
	my $withLoc = shift;
	
	if (!$withLoc) {
		return '???';
	}

	my $tpl = "%07d (+%07d -%07d)";
	if (defined($info->{addLines})) {
		return sprintf($tpl,
			$info->{addLines} + $info->{delLines},
			$info->{addLines},
			$info->{delLines}
		);
	} else {
		return sprintf($tpl,
			0,
			0,
			0
		);			
	}
}

#rev check in action UI clz, new add, normal, delete
sub getRevActionUIClz() {
	my $self = shift;
	my $action = shift;
	
	return $action eq 'A' ? 'revStyleAdd' : ($action eq 'D' ? 'revStyleDelete' : 'revStyleNormal');   
}

sub getFileUIClz() {
	my $self = shift;
	my $action = shift;
	
	return $action eq 'A' ? 'fileAdd' : ($action eq 'D' ? 'fileDelete' : 'fileNormal');   
}

sub getFileTypeIndicatorHtml() {
	my $self = shift;
	my $type = shift;
	
	my $ret = '';
	if ($type eq 'D') {
		$ret = " <span class=\"ftFlagDir\">D</span>";
	} elsif ($type eq 'B') {
		$ret = " <span class=\"ftFlagBin\">B</span>";
	}
	return $ret;
}


sub readFileContent() {
    my $self = shift;
    my $file = shift;
    my $start = shift;
    my $end = shift;
    
    if (!open(INPUT, "<", $file)) {
        return undef;   
    }
    seek(INPUT, $start, 0);
    
    my $content = "";
    my $a_len = read(INPUT, $content, $end - $start);
    close INPUT;

    return $content;
}

sub updateFile() {
    my $self = shift;
    my $file = shift;
    my $start = shift;
    my $end = shift;
}

sub getFileDiffParams() {
    my $self = shift;
    my $file = shift;
    my $rev = shift;
    my $info = shift;
    
    return "'$file', $rev, " 
        . (defined($info->{offsetB}) ? $info->{offsetB} : -1) 
        . ", "
        . (defined($info->{offsetE}) ? $info->{offsetE} : -1)
        . ", '$info->{action}'";
}

sub isAnonymousAccessSVN() {
    my $self = shift;
    my $moduleInfo = shift;
    
    return $moduleInfo->{account_id} eq '' && $moduleInfo->{account_pw} eq ''; 
}

sub replaceCharInComment() {
    my $self = shift;
    my $comment = shift;
    $comment =~ s|\\|\\\\|g;
    $comment =~ s|'|\\'|g;
    $comment =~ s|"|\\'|g;    #"
    $comment =~ s|\n|<br/>|g;    
    
    return $comment;
}

sub isTxtFile() {
    my $self = shift;
    my $allTxtExts = shift;
    my $ext = shift;
    
	return index($$allTxtExts, " $ext ") >= 0;    		
}

sub getFileAllContent() {
    my $self = shift;
    my $file = shift;
    if (!open(INPUT, "<", $file)) {
        return undef;   
    }
    
    my $old = $/;
    undef $/;
    my $content = <INPUT>;
    close INPUT;
    $/ = $old;
    
    return $content;
}

sub convertDate2SvnFormat() {
    my $self = shift;
    my $date = shift;
    
    if ($date =~ m|^(\d+)/(\d+)/(\d{4})$|) {
    	return "$3-$1-$2";
    }
    
    return $date;
}

sub convertDateLogic2SvnNeeded() {
    my $self = shift;
    my $ds = shift;	
    
    my $logic = "";
    my $d1 = "";
    my $d2 = "";
    
    my $ret = "";
	if ($ds =~ m|^([<>=]+)([\d/]+)$|) {
		$logic = $1;
		$d1 = $self->convertDate2SvnFormat($2);
		if (index($logic, ">") != -1) {
			$d2 = "2020-1-1";
			$ret = "{$d2}:{$d1}";
		} else {
			$d2 = "2000-1-1";
			$ret = "{$d1}:{$d2}";
		}
	} elsif ($ds =~ m|^([\d/]+)([<>=]+)([\d/]+)$|) {
		$logic = $2;
		$d1 = $self->convertDate2SvnFormat($1);
		$d2 = $self->convertDate2SvnFormat($3);
		
		if (index($logic, ">") != -1) {
			$ret = "{$d1}:{$d2}";
		} else {
			$ret = "{$d2}:{$d1}";
		}		
	}
	
	return $ret;
}

sub constructFilterInfo() {
	my $self = shift;
	my $pms = shift;
	
	$pms->{OFilter} = {};
	$pms->{OFilter}->{filterNeeded} = 0;
	
	my $filtersLen = length($pms->{filter});
	if ($filtersLen > 0) {
		my $fromIdx = 0;
		my @filterArr = ();
		my $sp = "__SP__";
		for (my $i = 0; $i < 4; $i++) {
			my $idx = index($pms->{filter}, $sp, $fromIdx);
			if ($i == 3) {
				$filterArr[$i] = substr($pms->{filter}, $fromIdx);
			} else {
				$filterArr[$i] = substr($pms->{filter}, $fromIdx, $idx - $fromIdx);
			}
			
			$fromIdx = $idx + length($sp);			
		}
		
		
		if (($#filterArr + 1) != 4 
		||    ($filterArr[0] =~ m/^\s*$/
			&& $filterArr[1] =~ m/^\s*$/
			&& $filterArr[2] =~ m/^\s*$/
			&& $filterArr[3] =~ m/^\s*$/
		)) {
			return;
		}
		
		$pms->{OFilter}->{filterNeeded} = 1;
		
		$pms->{OFilter}->{finLen} = length($filterArr[0]);
		$pms->{OFilter}->{fexLen} = length($filterArr[1]);
		
		$pms->{OFilter}->{fin} = $filterArr[0] . ';';
		$pms->{OFilter}->{fex} = $filterArr[1] . ';';
		
		if (length($filterArr[2]) > 0) {
			my @dinArr = split(/[\,;]/, $filterArr[2]);
			$pms->{OFilter}->{dins} = \@dinArr;
			$pms->{OFilter}->{dinCnt} = $#dinArr + 1;
		} else {
			$pms->{OFilter}->{dinCnt} = 0;
		}
		
		if (length($filterArr[3]) > 0) {
			my @dexArr = split(/[\,;]/, $filterArr[3]);
			$pms->{OFilter}->{dexs} = \@dexArr;
			$pms->{OFilter}->{dexCnt} = $#dexArr + 1;
		} else {
			$pms->{OFilter}->{dexCnt} = 0;
		}
	}
}

sub filter() {
	my $self = shift;
	my $file = shift;
	my $OFilter = shift;
	my $ext = shift;

	if ($OFilter->{filterNeeded} == 0) {
		return 1;
	}

	my $isIn = 0;
	if (   ($OFilter->{finLen} > 0 && index($OFilter->{fin}, ".*;") == -1) 
		|| ($OFilter->{fexLen} > 0 && index($OFilter->{fex}, ".*;") == -1)) {
		if (!defined($ext) && $file =~ m|^.*[^/]+(\.[^\s]+)$|) {
			$ext = $1;
		}
		
		if (defined($ext)) {
			if ($OFilter->{finLen} > 0) {
				$isIn = (index($OFilter->{fin}, "$ext;") != -1) ? 1 : 0;
			} else {
				$isIn = 1;
			}
			
			if ($OFilter->{fexLen} > 0 && $isIn) {
				$isIn = ((index($OFilter->{fex}, "$ext;") != -1) ? 0 : 1);
			}		
		}
	} else {
		$isIn = 1;
	}
	
	if ($isIn && $OFilter->{dinCnt} > 0) {
		my $inDirs = 0;
		for (my $i = 0; $i < $OFilter->{dinCnt}; $i++) {
			if (index($file, $OFilter->{dins}->[$i]) != -1) {
				$inDirs = 1;
				last;
			}
		}
		
		$isIn = $inDirs;
	}
	
	if ($isIn && $OFilter->{dexCnt} > 0) {
		my $exDirs = 0;
		for (my $i = 0; $i < $OFilter->{dexCnt}; $i++) {
			if (index($file, $OFilter->{dexs}->[$i]) != -1) {
				$exDirs = 1;
				last;
			}
		}
		
		$isIn = !$exDirs;
	}
	
	return $isIn;
}

sub mergeFilterInfo() {
	my $self = shift;
	my $mFilter = shift;
	my $OFilter = shift;		
	
	if ($OFilter->{finLen} == 0 
	&& $mFilter ne "" 
	&& $mFilter ne ".*") {
		$OFilter->{fin} = "$mFilter;";
		$OFilter->{finLen} = length($mFilter);
		$OFilter->{filterNeeded} = 1;
	}
	
	return $OFilter;
}

sub getShownFilterInfo() {
	my $self = shift;
	my $OFilter = shift;
	
	if ($OFilter->{filterNeeded} == 0) {
		return "N/A";
	}
	
	my $filterInfo = "";
	if ($OFilter->{finLen} > 0) {
		$filterInfo .= "include[$OFilter->{fin}]";
	}
	
	if ($OFilter->{fexLen} > 0) {
		$filterInfo .= ", exclude[$OFilter->{fex}]";
	}

	if ($OFilter->{dinCnt} > 0 || $OFilter->{dexCnt} > 0) {
		$filterInfo .= ", ";
		
		if ($OFilter->{dinCnt} > 0) {
			my $inDirs =  join(" ", @{$OFilter->{dins}});;
			$filterInfo .= " include[$inDirs]";
		}
		if ($OFilter->{dexCnt} > 0) {
			my $exDirs =  join(" ", @{$OFilter->{dexs}});;
			$filterInfo .= ", exclude[$exDirs]";
		}		
	}
	
	return $filterInfo;
}

sub dumpFile() {
	my $self = shift;	
	my $file = shift;
	my $obj = shift;
	store($obj, $file);
}

sub loadFile() {
	my $self = shift;	
	my $file = shift;
	retrieve($file);
}

sub getNoPathFile() {
	my $self = shift;
	my $f = shift;
	return substr($f, rindex($f, "/") + 1);
}

sub writeJsonToFile() {
	my $self = shift;
    my $finalJSON = shift;
    my $outFile = shift;
    
    my $json = JSON->new->pretty->utf8->encode($finalJSON);
    my $hBotJson;
	if (!open($hBotJson, ">$outFile")) {
		return undef;	
	}    
    print $hBotJson $json;
    close($hBotJson);    
}
#===============================================================================
#
# END of the module.
#
#===============================================================================
1;
__END__
