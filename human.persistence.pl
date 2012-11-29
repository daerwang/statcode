#!/usr/bin/perl -I ./thirds -w
#  author: lilong'en(lilongen@163.com)
#  date:   08/24/2011
#

use strict;
use CcvUtil;
use YAML qw(DumpFile);
use Data::Dumper;
use Storable;
use File::Iterator;
use Definition;

sub help();
sub main();
sub yamlFiles($);
sub listNeed2YamlFiles();

my $DEF = new Definition();

main();

sub main() {
	if (($#ARGV + 1) < 2) {
		help();
		
		return;
	}
	
	my $files = listNeed2YamlFiles();
	yamlFiles($files);
}

sub listNeed2YamlFiles() {
	my $d = $ARGV[0];
	my $t = $ARGV[1];	
	my $files = [
		"operate/$d/$t/$DEF->{MID_DATA_FILE_NAME}->{ALL_MODULES_SUM_INFO}",
		"operate/$d/$t/$DEF->{MID_DATA_FILE_NAME}->{PMS}",
		"operate/$d/$t/$DEF->{MID_DATA_FILE_NAME}->{TASK_QUEUE}"	
	];
	
	if (($#ARGV + 1) == 2) { #not yaml data files in mid subdirectory
		return $files;
	}
	
	my $it = new File::Iterator(DIR => "operate/$d/$t", RECURSE => 0, RETURNDIRS => 1);
    my $revsPath = undef;
    
    
    while (my $f = $it->next()) {
        if (-d $f) {
        	$revsPath = $f;
        	last;
        }
    }   
	if (defined($revsPath)) {
		$it = undef;
		$it = new File::Iterator(DIR => $revsPath, RECURSE => 0, RETURNDIRS => 1);
                                
	    while (my $midPath = $it->next()) {
	    	if (-d $midPath) {
		        push(@{$files}, "$midPath/head/$DEF->{MID_DATA_FILE_NAME}->{CVS_GD_DATA_USER_INFO}");
		        push(@{$files}, "$midPath/head/$DEF->{MID_DATA_FILE_NAME}->{CVS_GD_DATA}");
		        
		        push(@{$files}, "$midPath/$DEF->{MID_DATA_FILE_NAME}->{LOG_PARSED_INFO}");
		        push(@{$files}, "$midPath/$DEF->{MID_DATA_FILE_NAME}->{LOG_PARSED_INFO}.o");	    		
	    	}
	    }  
	}
	
	return $files;	
}

sub yamlFiles($) {
	my $files = $_[0];
	
	for (my $i = 0; $i <= $#{$files}; $i++) {
		my $f = "$files->[$i]";
		
		if (-e $f) {
			my $tmp = retrieve($f);		
			DumpFile("$f.yaml", $tmp);
			
			print "done: $f.yaml\n";
		} else {
			print "$f not exist\n";
		}
	}
	
	print "\n";
}

sub help() {
	print <<"S_Usage";
Usage:
  perl $0 %date %time %yamlFilesInMidDirectory
	
S_Usage
}
