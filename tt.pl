#!/usr/bin/perl -I ./thirds -w
# author: lilong'en(lilongen@163.com)
#

#use strict;
use Data::Dumper;
use Storable;
use XML::TreePP;
use Assistor;
use PerlBase64;

my $ass = new Assistor("example.git.xml");

my $ms = $ass->getModules();

print Dumper($ms);
my $a = {
	url => "https://a.b.c/dsf/dsf",
	account_id => "lonli",
	account_pw => "123"
};

$ass->injectAccountInfo2GitUrl($a);
print Dumper($a);