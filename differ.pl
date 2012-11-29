#!/usr/bin/perl -I ./thirds -w
# author: lilong'en(lilongen@163.com)
# date:   12/25/2009
#
use strict;
use English;
use Data::Dumper;
use File::Iterator;
use CGI;
use Assistor;
use Cwd;
use URI::Escape;

my $q = new CGI;

my $T_SNAPSHOT  = $q->param("T_SNAPSHOT");
my $CFG  		= $q->param("CFG");

my $assistor    = new Assistor($CFG, $T_SNAPSHOT);
my $branch 		= $q->param("branch");
my $module 		= $q->param("module");
my $module_id 	= $q->param("module_id");
my $file		= $q->param("file");
my $rev1		= $q->param("r1");
my $rev2		= $q->param("r2");

$assistor->getModules();
my $moduleInfo 	= $assistor->get_module_info_by_module_id($module_id);
my $cvsroot		= $assistor->get_module_cvsroot($moduleInfo);

my $pwd_pl = getcwd;
if ($rev1 eq "1") {
	my $rev_files_path = $assistor->get_branch_module_rev_files_operate_path($branch, $module_id);
	my $file_full_path = $rev_files_path . "/" . $file; 
	if (!(-e $file_full_path)) {
		chdir($rev_files_path);
		my $cmd = "cvs -Q -d $cvsroot co -r$rev2 \"$file\" 2>&1";
		print `$cmd`;
		chdir($pwd_pl);
	}
	
	if (!(-e $file_full_path)) { #cvs co error
		print $q->redirect(-url => $file_full_path);
	}
	
	my $rev2_file_url = "/ccv/" . $file_full_path;
	print $q->redirect(-url => $rev2_file_url);
	
} elsif ($rev1 eq "0") { # initial create
	my $file_initial_ver_url = $assistor->get_branch_module_11_file_operate_webpath($branch, $module_id ,$file);
	print $q->redirect(-url => $file_initial_ver_url);
} else {
	my $diff_out_file = $assistor->get_branch_module_file_diff_out_file($branch, $module_id, $file, $rev1, $rev2);
	if (!(-e "$diff_out_file")) {
		my $cmd = "cvs -Q -d $cvsroot rdiff -u -r$rev1 -r$rev2 \"$file\" >> \"$diff_out_file\" 2>&1";
		print `$cmd`;	
	}
	
	my $diffUrl = sprintf("diff.unified.pl?from=rlog&rdiff=%s&self=%s&un_exist_in=&removed_in=&rev1=%s&rev2=%s",
						uri_escape($diff_out_file),
						uri_escape($file),
						uri_escape($rev1),
						uri_escape($rev2));	
	
	print $q->redirect(-url => $diffUrl);
}
