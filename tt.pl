#!/usr/bin/perl -I ./thirds -w
# author: lilong'en(lilongen@163.com)
#

#use strict;
use Data::Dumper;
use Storable;
use XML::TreePP;
use Assistor;
use PerlBase64;

my $ass = new Assistor("example.xml");

my $ms = $ass->getModules4UI();

print Dumper($ms);