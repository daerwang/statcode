#!/usr/bin/perl -I ./thirds
# author: lilong'en(lilongen@163.com)
# date: 0|2/20/20|1|2
#
package ApiInnerParamUtil;


use strict;
use English;
use Data::Dumper;
use Storable;


#===============================================================================
# CONSTRUCTOR:	
#       $obj = new ApiInnerParamUtil("capi", $cmdLine); 
#		$obj = new ApiInnerParamUtil("wapi", $cgiQ); 
#===============================================================================
sub new() {
	my $pkg = shift;
    my $self = {};
    bless $self, $pkg;
    
    $self->{pmsFrom} = shift;# "capi" or "wapi" or "inner"
    $self->{pmsContainer} = shift;  # will be "capi command line" or "cgi $q" or "inner command line"
    $self->{cmdPmsLine} = "";
    $self->{ccvCmdLine} = "";
	
	$self->{OptBit} = {
		GenGraph 		=> 0,
		CalcAllRevs 	=> 1,
		StatBin 		=> 2,
		StatBinLines 	=> 3,
		NotStatDeleted 	=> 4,
		SvnWithLoc 		=> 10,
		DfIgnoreEOL 	=> 11
	};
    
    $self->{pmsDef} = {
		"mode"                   => {
			fromApi			=> 1,
			presenceInDef 	=> "0|1|2",
			positionNo		=> 1,
			outerVal		=> undef,
			innerVal		=> undef,
			innerCmdPmName	=> "R"
		},    	
		"T_SNAP" 				 => {
			fromApi			=> 1,
			presenceInDef 	=> "0|1|2",
			positionNo		=> 2,
			outerVal		=> undef,
			innerVal		=> undef,
			innerCmdPmName	=> "t"
		},
		"cfg"                    => {
			fromApi			=> 1,
			presenceInDef 	=> "0|1|2",
			positionNo		=> 3,
			outerVal		=> undef,
			innerVal		=> undef,
			innerCmdPmName	=> "f"
		},
		"mids"                   => {
			fromApi			=> 1,
			presenceInDef 	=> "0|1|2",
			positionNo		=> 4,
			outerVal		=> undef,
			innerVal		=> undef,
			innerCmdPmName	=> "m"
		},
		"uid"                   => {
			fromApi			=> 1,
			presenceInDef 	=> "0|1|2",
			positionNo		=> 5,
			outerVal		=> undef,
			innerVal		=> undef,
			innerCmdPmName	=> "uid"
		},  
		"upw"                   => {
			fromApi			=> 6,
			presenceInDef 	=> "0|1|2",
			positionNo		=> 1,
			outerVal		=> undef,
			innerVal		=> undef,
			innerCmdPmName	=> "upw"
		},  				
		"rev"                    => {
			fromApi			=> 1,
			presenceInDef 	=> "0|2",
			positionNo		=> 10,
			outerVal		=> undef,
			innerVal		=> undef,
			innerCmdPmName	=> "r"
		},
		"date"                   => {
			fromApi			=> 1,
			presenceInDef 	=> "0",
			positionNo		=> 11,
			outerVal		=> undef,
			innerVal		=> undef,
			innerCmdPmName	=> "d"
		},
		"wids"                   => {
			fromApi			=> 1,
			presenceInDef 	=> "0",
			positionNo		=> 12,
			outerVal		=> undef,
			innerVal		=> undef,
			innerCmdPmName	=> "w"
		},
		"dfAgainst"              => {
			fromApi			=> 1,
			presenceInDef 	=> "1",
			positionNo		=> 20,
			outerVal		=> undef,
			innerVal		=> undef,
			innerCmdPmName	=> "DFA"
		},
		"r1"                     => {
			fromApi			=> 1,
			presenceInDef 	=> "1",
			positionNo		=> 21,
			outerVal		=> undef,
			innerVal		=> undef,
			innerCmdPmName	=> "r1"
		},
		"r2"                     => {
			fromApi			=> 1,
			presenceInDef 	=> "1",
			positionNo		=> 22,
			outerVal		=> undef,
			innerVal		=> undef,
			innerCmdPmName	=> "r2"
		},
		"d1"                     => {
			fromApi			=> 1,
			presenceInDef 	=> "1",
			positionNo		=> 23,
			outerVal		=> undef,
			innerVal		=> undef,
			innerCmdPmName	=> "D1"
		},
		"d2"                     => {
			fromApi			=> 1,
			presenceInDef 	=> "1",
			positionNo		=> 24,
			outerVal		=> undef,
			innerVal		=> undef,
			innerCmdPmName	=> "D2"
		},
		"rd1b"                   => {
			fromApi			=> 1,
			positionNo		=> 25,
			presenceInDef 	=> "1",
			outerVal		=> undef,
			innerVal		=> undef,
			innerCmdPmName	=> "rd1b"
		},
		"rd2b"                   => {
			fromApi			=> 1,
			presenceInDef 	=> "1",
			positionNo		=> 26,
			outerVal		=> undef,
			innerVal		=> undef,
			innerCmdPmName	=> "rd2b"
		},
		"bb"                     => {
			fromApi			=> 1,
			presenceInDef 	=> "1",
			positionNo		=> 27,
			outerVal		=> undef,
			innerVal		=> undef,
			innerCmdPmName	=> "bb"
		},		
		"filter[includeExts]"    => {
			fromApi			=> 1,
			presenceInDef 	=> "0|1|2",
			positionNo		=> -1,
			outerVal		=> undef,
			innerVal		=> undef,
			innerCmdPmName	=> ""
		},
		"filter[excludeExts]"    => {
			fromApi			=> 1,
			presenceInDef 	=> "0|1|2",
			positionNo		=> -1,
			outerVal		=> undef,
			innerVal		=> undef,
			innerCmdPmName	=> ""
		},
		"filter[includeDirs]"    => {
			fromApi			=> 1,
			presenceInDef 	=> "0|1|2",
			positionNo		=> -1,
			outerVal		=> undef,
			innerVal		=> undef,
			innerCmdPmName	=> ""
		},
		"filter[excludeDirs]"    => {
			fromApi			=> 1,
			presenceInDef 	=> "0|1|2",
			positionNo		=> -1,
			outerVal		=> undef,
			innerVal		=> undef,
			innerCmdPmName	=> ""
		},
		"opts[OgenGraph]"        => {
			fromApi			=> 1,
			presenceInDef 	=> "0|1|2",
			positionNo		=> -1,
			outerVal		=> undef,
			innerVal		=> undef,
			innerCmdPmName	=> ""
		},
		"opts[OcalcAllRevs]"     => {
			fromApi			=> 1,
			presenceInDef 	=> "0|1|2",
			positionNo		=> -1,
			outerVal		=> undef,
			innerVal		=> undef,
			innerCmdPmName	=> ""
		},
		"opts[OstatBin]"         => {
			fromApi			=> 1,
			presenceInDef 	=> "0|1|2",
			positionNo		=> -1,
			outerVal		=> undef,
			innerVal		=> undef,
			innerCmdPmName	=> ""
		},
		"opts[OstatBinLines]"    => {
			fromApi			=> 1,
			presenceInDef 	=> "0|1|2",
			positionNo		=> -1,
			outerVal		=> undef,
			innerVal		=> undef,
			innerCmdPmName	=> ""
		},
		"opts[OnotStatDeleted]"  => {
			fromApi			=> 1,
			presenceInDef 	=> "0|1|2",
			positionNo		=> -1,
			outerVal		=> undef,
			innerVal		=> undef,
			innerCmdPmName	=> ""
		},
		"opts[OdfIgnoreEOL]"     => {
			fromApi			=> 1,
			presenceInDef 	=> "0|1|2",
			positionNo		=> -1,
			outerVal		=> undef,
			innerVal		=> undef,
			innerCmdPmName	=> ""
		},
		"filter"     			=> {
			fromApi			=> 0,
			presenceInDef 	=> "0|1|2",
			positionNo		=> 100,
			outerVal		=> undef,
			innerVal		=> undef,
			innerCmdPmName	=> "FILTER"
		},
		"GO"     				=> {
			fromApi			=> 0,
			presenceInDef 	=> "0|1|2",
			positionNo		=> 101,
			outerVal		=> undef,
			innerVal		=> undef,
			innerCmdPmName	=> "GO"
		},
		"fromCgi"     			=> {
			fromApi			=> 0,
			presenceInDef 	=> "0|1|2",
			positionNo		=> 102,
			outerVal		=> 0,
			innerVal		=> 0,
			innerCmdPmName	=> "FC"
		}	
    };
    
    if ($self->{pmsFrom} eq "wapi") {
    	$self->{pmsDef}->{fromCgi}->{outerVal} = 1;
    	$self->{pmsDef}->{fromCgi}->{innerVal} = 1;
    }
 
    return $self;
}

sub constructPmsObjectFromInnerCmdLine() {
	my $self = shift;
	
	my $rptMode = $self->getRptModeIntVal();
	my $pmsObject = {};
	for my $key ( keys %{$self->{pmsDef}} ) {
		my $item = $self->{pmsDef}->{$key};
		if ($item->{innerCmdPmName} eq "") {
			next;
		}
		
		if (!$self->ifParamNeededInMode($key, $rptMode)) {
			next;
		}

		$pmsObject->{$key} = $self->getParam($key);
	}
	
	if (!$pmsObject->{rev} || $pmsObject->{rev} =~ m/^TRUNK$/i) {
		$pmsObject->{rev} = "MAIN";
	}	
	
	$pmsObject->{gopt} 		= $self->convertMergedOptionsToOptionsObject($pmsObject->{GO});
	$pmsObject->{OFilter} 	= $self->convertMergedFilterToFilterObject($pmsObject->{filter});
	$pmsObject->{dfOpts} 	= $self->getDfCmdAdditionalFlag($pmsObject->{gopt}->{OdfIgnoreEOL});
	
	return $pmsObject;
}

sub transferPmsFromOuterToInner(){
	my $self = shift;
	
    $self->{pmsDef}->{mode}->{innerVal} = $self->transferModeFromOuterToInner($self->{pmsDef}->{mode}->{innerVal});
    $self->mergeGlobalOptions();
    $self->mergeFilter();
}

sub mergeGlobalOptions() {
	my $self = shift;
    
	$self->{pmsDef}->{GO}->{innerVal} = 0;
	$self->{pmsDef}->{GO}->{innerVal} += 							   							   1  << $self->{OptBit}->{SvnWithLoc};
    $self->{pmsDef}->{GO}->{innerVal} += ($self->getParamOuterVal("opts[OgenGraph]") 			|| 0) << $self->{OptBit}->{GenGraph};
    $self->{pmsDef}->{GO}->{innerVal} += ($self->getParamOuterVal("opts[OcalcAllRevs]") 		|| 0) << $self->{OptBit}->{CalcAllRevs};
    $self->{pmsDef}->{GO}->{innerVal} += ($self->getParamOuterVal("opts[OstatBin]") 			|| 0) << $self->{OptBit}->{StatBin};
    $self->{pmsDef}->{GO}->{innerVal} += ($self->getParamOuterVal("opts[OstatBinLines]") 		|| 0) << $self->{OptBit}->{StatBinLines};
    $self->{pmsDef}->{GO}->{innerVal} += ($self->getParamOuterVal("opts[OnotStatDeleted]") 		|| 0) << $self->{OptBit}->{NotStatDeleted};
    $self->{pmsDef}->{GO}->{innerVal} += ($self->getParamOuterVal("opts[OdfIgnoreEOL]") 		|| 1) << $self->{OptBit}->{DfIgnoreEOL}; 
}

sub convertMergedOptionsToOptionsObject() {
	my $self = shift;
	my $go = shift;

	my $opts = {};
	
	$opts->{OSvnWithLoc} 	= 1;
	$opts->{graph} 			= (($go >> $self->{OptBit}->{GenGraph}) 		& 1) ? 1 : 0;
	$opts->{allRevs} 		= (($go >> $self->{OptBit}->{CalcAllRevs}) 		& 1) ? 1 : 0;
	$opts->{statBin} 		= (($go >> $self->{OptBit}->{StatBin}) 			& 1) ? 1 : 0;
	$opts->{statBinLines} 	= (($go >> $self->{OptBit}->{StatBinLines}) 	& 1) ? 1 : 0;
	$opts->{notStatDeleted} = (($go >> $self->{OptBit}->{NotStatDeleted}) 	& 1) ? 1 : 0;
	$opts->{OdfIgnoreEOL} 	= (($go >> $self->{OptBit}->{DfIgnoreEOL}) 		& 1) ? 1 : 0;
	
	return $opts;
}


sub getDfCmdAdditionalFlag() {
	my $self = shift;
	my $optDfIgnoreEOL = shift;
	
	return {
		cvs => '',
		svn => $optDfIgnoreEOL ? '-x --ignore-eol-style' : ''
	};
}

sub convertMergedFilterToFilterObject() {
	my $self = shift;
	my $mergedFilter = shift;
	
	my $filterInfo = {};
	$filterInfo->{filterNeeded} = 0;
	
	my $filtersLen = length($mergedFilter);
	if ($filtersLen > 0) {
		my $fromIdx = 0;
		my @filterArr = ();
		my $sp = "__SP__";
		for (my $i = 0; $i < 4; $i++) {
			my $idx = index($mergedFilter, $sp, $fromIdx);
			if ($i == 3) {
				$filterArr[$i] = substr($mergedFilter, $fromIdx);
			} else {
				$filterArr[$i] = substr($mergedFilter, $fromIdx, $idx - $fromIdx);
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
		
		$filterInfo->{filterNeeded} = 1;
		
		$filterInfo->{finLen} = length($filterArr[0]);
		$filterInfo->{fexLen} = length($filterArr[1]);
		
		$filterInfo->{fin} = $filterArr[0] . ';';
		$filterInfo->{fex} = $filterArr[1] . ';';
		
		if (length($filterArr[2]) > 0) {
			my @dinArr = split(/[\,;]/, $filterArr[2]);
			$filterInfo->{dins} = \@dinArr;
			$filterInfo->{dinCnt} = $#dinArr + 1;
		} else {
			$filterInfo->{dinCnt} = 0;
		}
		
		if (length($filterArr[3]) > 0) {
			my @dexArr = split(/[\,;]/, $filterArr[3]);
			$filterInfo->{dexs} = \@dexArr;
			$filterInfo->{dexCnt} = $#dexArr + 1;
		} else {
			$filterInfo->{dexCnt} = 0;
		}
	}
	
	return $filterInfo;
}

sub mergeFilter() {
	my $self = shift;
	
	my $fin = $self->getParamOuterVal("filter[includeExts]");
	my $fex = $self->getParamOuterVal("filter[excludeExts]");
	my $din = $self->getParamOuterVal("filter[includeDirs]");
	my $dex = $self->getParamOuterVal("filter[excludeDirs]");

	if ($fin || $fex || $din || $dex) {
    	my $sp = "__SP__";
    	$self->{pmsDef}->{filter}->{innerVal} = "$fin$sp$fex$sp$din$sp$dex";
	} else {
		$self->{pmsDef}->{filter}->{innerVal} =  "";	
	}	
}

sub ifParamNeededInMode() {
	my $self = shift;
	my $key = shift;
	my $mode = shift;

	return index($self->{pmsDef}->{$key}->{presenceInDef}, $mode) != -1;
}

sub transferModeFromOuterToInner() {
	my $self = shift;
	my $mode = shift;

	my $MODES = {
		'log'  => 0,
		'diff' => 1,
		'file' => 2
	};
	
	return $MODES->{$mode};
}

sub getRptModeIntVal() {
	my $self = shift;
	
	my $rptMode = $self->getParamInnerVal("mode");
	if (defined($rptMode)) {
		return $rptMode;
	}

	$rptMode = $self->getParam("mode");
	if ($self->{pmsFrom} eq "capi" || $self->{pmsFrom} eq "wapi") {
		$rptMode = $self->transferModeFromOuterToInner($rptMode);
	}
	
	return $rptMode;
}

sub getApiParams() {
	my $self = shift;

	my $rptMode = $self->getRptModeIntVal();
    for my $key ( keys %{$self->{pmsDef}} ) {
    	if (!$self->{pmsDef}->{$key}->{fromApi}) {
    		next;
    	}

		if (!$self->ifParamNeededInMode($key, $rptMode)) {
			next;
		}
   	
        my $value = $self->getParam($key);
        $self->{pmsDef}->{$key}->{outerVal} = $value;
        $self->{pmsDef}->{$key}->{innerVal} = $value;
    }	
}

sub getParam($) {
	my $self = shift;
	my $indicator = shift;

	if ($self->{pmsFrom} eq "capi") {
	    if ($self->{pmsContainer} =~ m/(^|\s)\-\-$indicator=([^\s]+?)(\s+\-\-[\w\d]+=|$)/) {
	        return $2;   
	    } else {
	    	return "";
	    } 	
	}
	
	if ($self->{pmsFrom} eq "wapi") {
		return $self->{pmsContainer}->param($indicator) || "";
	}
	
	if ($self->{pmsFrom} eq "inner") {
		my $innerIndicator = $self->{pmsDef}->{$indicator}->{innerCmdPmName};
	    if ($self->{pmsContainer} =~ m/(^|\s)\-$innerIndicator([^\s]+?)(\s+\-[\w\d]+|$)/) {
	        return $2;   
	    } else {
	    	return "";
	    } 
	}	
}

sub setParamInnerVal() {
	my $self = shift;
	my $key = shift;
	my $val = shift;
	
	$self->{pmsDef}->{$key}->{innerVal} = $val;
}

sub getParamInnerVal() {
	my $self = shift;
	my $key = shift;
	
	return 	$self->{pmsDef}->{$key}->{innerVal};
}

sub getParamOuterVal() {
	my $self = shift;
	my $key = shift;
	
	return 	$self->{pmsDef}->{$key}->{outerVal};
}


sub joinInnerPmsToCmdLine() {
	my $self = shift;
	
	my $rptMode = $self->getRptModeIntVal();
	my $positionNoToKey = {};
	for my $key ( keys %{$self->{pmsDef}} ) {
		my $item =  $self->{pmsDef}->{$key};

		if ($self->ifParamNeededInMode($key, $rptMode) && $item->{innerCmdPmName} ne "") {
			$positionNoToKey->{$item->{positionNo}} = $key;
		}
	}
	
	for my $key ( sort{ $a <=> $b } keys %{$positionNoToKey} ) {
		$self->addArgu($positionNoToKey->{$key});
	}
	
	$self->{ccvCmdLine} = "perl -w ccv.pl $self->{cmdPmsLine}";
	if ($self->{pmsFrom} eq "wapi") {
		$self->{ccvCmdLine} .= " 2>/dev/null 1>/dev/null";	
	}
}

sub convertApi2InnerCmd() {
	my $self = shift;
	$self->getApiParams();
	$self->transferPmsFromOuterToInner();
	$self->joinInnerPmsToCmdLine();
	
	return $self->{ccvCmdLine};
}

sub addArgu() {
	my $self = shift;
	my $key = shift;

	my $innerCmdPmName = $self->{pmsDef}->{$key}->{innerCmdPmName};
	my $val = $self->{pmsDef}->{$key}->{innerVal};
	if (!defined($val) || $val =~ m/^\s*$/) {
		return;
	}
	
	$self->{cmdPmsLine} .= " \"-$innerCmdPmName$val\"";
}
#===============================================================================
#
# END of the module.
#
#===============================================================================
1;
__END__
