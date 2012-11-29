#!/usr/bin/perl -I ./thirds
# author: lilong'en(lilongen@163.com)
# date:   09/12/2012
#

use strict;
use English;
use Data::Dumper;
use Assistor;
use CcvUtil;

sub main();
sub createBotWS();
sub getXmls();
sub getRepositoiesInXml($);
sub parseXmls();
sub bot();
sub botFilter($$);
sub botRepository($$);
sub persistGV();

my $GV = {
	xmls => {},
	repos => {},
	xmlsReposURIs => {}
};
my $GV_OUT_FILE = '.bot/.gv';
my $BOT_OUT_FILE = '.bot/.bot';

my $assistor = new Assistor();
exit main();

sub main() {
    createBotWS();
    getXmls();
    parseXmls();
    bot();
    persistGV();
    
    return 0;
}

sub createBotWS() {
	my $botWS = '.bot';
	if ( ! -d $botWS) {
		mkdir($botWS);
	}
	
	system("rm -rf $BOT_OUT_FILE $GV_OUT_FILE");	
}

sub getXmls() {
	opendir(HDIR, 'config');
	my @files = readdir HDIR;
	closedir HDIR;
	
	my $cnt = $#files + 1;
	for (my $i = 0; $i < $cnt; $i++) {
		if ($files[$i] !~ m/.*.xml$/) {
			splice(@files, $i, 1);
			$cnt--;
			$i--;
		}
	}
	
	$GV->{xmls} = \@files;
}

sub parseXmls() {
	my $cnt = $#{$GV->{xmls}} + 1;
	for (my $i = 0; $i < $cnt; $i++) {
		my $xml = $GV->{xmls}->[$i];
		$GV->{xmlsReposURIs}->{$xml} = getRepositoiesInXml($xml);
	}
}

sub getRepositoiesInXml($) {
	my $xml = shift;
	$assistor->set_config_file($xml);
	my $modules = $assistor->getModules();
	if (!defined($modules)) {
		return;
	}
	
	my $repos = {};
	my $cnt = $#{$modules} + 1;
	for (my $i = 0; $i < $cnt; $i++) {
		my $mi = $modules->[$i];
		my $uriKey = undef;
		my $uris = [];
	    if ($mi->{type} eq "svn") {
	    	$uriKey = $assistor->get_svn_repository_uri($mi); 
	    	my $branchUri = $assistor->get_svn_repository_uri($mi, "branch"); 
	    	my $tagUri = $assistor->get_svn_repository_uri($mi, "tag");
	    	push(@{$uris}, $branchUri);
	    	push(@{$uris}, $tagUri);
	    } else {
	    	$uriKey = $assistor->get_cvs_repository_uri($mi); 
	    	push(@{$uris}, $uriKey); 	
	    }
	    
	    if (!defined($repos->{$uriKey})) {
	    	$repos->{$uriKey} = {
	    		'type' => $mi->{type},
    			'uris' => $uris,
	    		'account_id' => $mi->{account_id},
	    		'account_pw' => $mi->{account_pw}
	    	}
	    }
	    
	    if (!defined($GV->{repos}->{$uriKey})) {
	    	$GV->{repos}->{$uriKey} = $repos->{$uriKey};
	    }
	}
	
	return $repos;	
}

sub bot() {
	my @reposKeys = sort keys %{$GV->{repos}};
	my $cnt = $#reposKeys + 1;
	for (my $i = 0; $i < $cnt; $i++) {
		my $key = $reposKeys[$i];
		my $repos = $GV->{repos}->{$key};
		if (!botFilter($key, $GV->{repos}->{$key})) {
			next;
		}
		
		botRepository($key, $GV->{repos}->{$key});	
	}
}

sub botFilter($$) {
	my $key = shift;
	my $repos = shift;
	return $repos->{type} eq 'svn' && index($key, 'https://wwwin-svn') == 0
}

sub botRepository($$) {
	my $key = shift;
	my $repos = shift;
	
	my $cmdOutReposURI = "echo \'ccv.bot - $key\' >> $BOT_OUT_FILE";
	print "$cmdOutReposURI\n";
	system("$cmdOutReposURI");
	
	my $svnCmdOption = "--no-auth-cache --non-interactive --trust-server-cert";
	my $urisCnt = $#{$repos->{uris}} + 1;
	for (my $i = 0; $i < $urisCnt; $i++) {
		my $uri = $repos->{uris}->[$i];
		my $cmdBotReposAndOutInfo = "svn list $svnCmdOption '$uri' >>$BOT_OUT_FILE 2>/dev/null";	
		print "$cmdBotReposAndOutInfo\n";
		system("$cmdBotReposAndOutInfo");
		system("echo >> $BOT_OUT_FILE");		
	}
}

sub persistGV() {
    my $ccvUtil = new CcvUtil();
    $ccvUtil->dumpFile($GV_OUT_FILE, $GV);
}
