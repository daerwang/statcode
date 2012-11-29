#!/usr/bin/perl -I ./thirds -w
# author: lilong'en(lilongen@163.com)
#

#use strict;
use Data::Dumper;
use Storable;
use XML::TreePP;
use Assistor;
use PerlBase64;

sub preHandleXmlContent($);
sub removeUselessLastBackslash($$);
sub escape4Bash($) {
	my $str = shift;
	
	$str =~ s/\$/\\\$/g;
	$str =~ s/\"/\\\"/g;
	
	return $str;
}

my $file = "config/config.xml";

#my $assistor = new Assistor("example.sf.xml");
#my $a = $assistor->getModules();

#print Dumper($a);
#print Dumper($assistor->{modules4UI});

my $c0 = "\$ & \" \" lilongen is a good man!!!";
print "c0: $c0\n";
my $c1 = escape4Bash($c0);
print "c1: $c1\n";

my $c3 = '"$"';
print "c3: $c3\n";	
#my $content = <<ENDDEF;
#<configs>
#
#  <module>
#    <id>moduleId1</id>
#    <type>cvs</type>
#    <module>moduleNamePath</module>
#    <server>serverAddress</server>
#    <repository>/repositoryPath/</repository>
#    <account_id>AcountId</account_id>
#    <account_pw>password</account_pw>
#  </module>
#	
#  <module>
#    <id>moduleId2</id>
#    <type>svn</type>
#    <module>moduleNamePath</module>
#    <server>serverAddress</server>
#    <repository>/repositoryPath/</repository>
#    <account_id>AcountId</account_id>
#    <account_pw>password</account_pw>	
#  
#    <trunk_directory>/repositoryPath/trunk/</trunk_directory>
#    <branch_directory>//</branch_directory>   
#    <tag_directory>/repositoryPath/tags/</tag_directory>   
#  </module>
#
#</configs>
#ENDDEF
#
##print $content;
#
##preHandleXmlContent(\$content);
#
#
##print $content;
#	
#sub removeUselessLastBackslash($$) {
#	my $content = $_[0];
#	my $tagName = $_[1];
#	$$content =~ s|<($tagName)>\s*([^<>]+)/+\s*</\1>|<$1>$2</$1>|g;
#}
#
#sub preHandleXmlContent($) {
#	my $content = $_[0];
#	removeUselessLastBackslash($content, 'module');
#	removeUselessLastBackslash($content, 'repository');
#	removeUselessLastBackslash($content, 'trunk_directory');
#	removeUselessLastBackslash($content, 'branch_directory');
#	removeUselessLastBackslash($content, 'tag_directory');
#}
#
