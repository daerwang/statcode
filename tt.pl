#!/usr/bin/perl -I ./thirds -w
# author: lilong'en(lilongen@163.com)
#

#use strict;
use Data::Dumper;
use Storable;
use XML::TreePP;
use Assistor;
use PerlBase64;

my $a = 1;
print "$a\n";
$a = !$a;
if ($a) {
	print "$a\n";
} else {
	print "false\n"
}

$a = !$a;
if ($a) {
	print "$a\n";
}
