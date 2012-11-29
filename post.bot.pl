#!/usr/bin/perl -I ./thirds
# author: lilong'en(lilongen@163.com)
# date:   09/12/2012
#

use strict;
use English;
use Data::Dumper;
use CcvUtil;

sub main();
sub constructOutJson();
sub writeJsonToFile($);
sub structureBotInfo();

my $GV_OUT_FILE = '.bot/.gv';
my $BOT_OUT_FILE = '.bot/.bot';
my $BOT_OUT_JS_FILE = '.bot/bot.info.json';
my $BOT_OUT_JS_WEB_FILE = 'web/bot.info.json';

my $ccvUtil = new CcvUtil();
exit main();

sub main() {
    my $outJsonText = constructOutJson(); 
    $ccvUtil->writeJsonToFile($outJsonText, $BOT_OUT_JS_FILE);
    system("cp -f $BOT_OUT_JS_FILE $BOT_OUT_JS_WEB_FILE");
    
    return 0;
}

sub constructOutJson() {
    my $GV = $ccvUtil->loadFile($GV_OUT_FILE);
    my $finalJSON = {
        xmlsReposURIs => undef,
        reposURIRevsInfo => undef
    };
    my $xmlsReposURIs = {};
    foreach my $xml (keys %{$GV->{xmlsReposURIs}}) {
        my @reposURIs = sort keys %{$GV->{xmlsReposURIs}->{$xml}};
        $xmlsReposURIs->{$xml} = \@reposURIs;
    }
    $finalJSON->{xmlsReposURIs} = $xmlsReposURIs || {};
    $finalJSON->{reposURIRevsInfo} = structureBotInfo() || {};
    
    return $finalJSON;
}

sub structureBotInfo() {
	my $hBot;
	if (!open($hBot, $BOT_OUT_FILE)) {
		return undef;	
	}
	
	my $reReposURI = qr/^ccv.bot - (.*)$/;
	my $reposRevs = {};
	my $revInfo = undef;
	my $status = -1;#0: repos uri, 1: branches out end, 2: tags out end
	my $reposURI = undef;
	while (1) {
		my $line = <$hBot>;
		if (!defined($line)) {
			last;	
		}
		
		if ($line =~ $reReposURI) {
			$reposURI = $1;
			$status = 0;
			$revInfo = {
				branches => [],	
				tags => []
			};
			next;
		}
		
		if (length($line) == 1) {#empty line(^\n$), branches and tags separator
			$status++;
			
			if ($status == 2) {
				if ($#{$revInfo->{branches}} >= 0 || $#{$revInfo->{tags}} >= 0) {
					$reposRevs->{$reposURI} = $revInfo;
				}
			}
			next;				
		}
		
		$line = substr($line, 0, -2); #trash last character '\n' and '/'
		if ($status == 0) {
			push(@{$revInfo->{branches}}, $line);
			next;
		}
		if ($status == 1) {
			push(@{$revInfo->{tags}}, $line);
			next;
		}
	}
	close($hBot);
	
	return $reposRevs;
}
