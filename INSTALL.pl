#!/usr/bin/perl -I ./thirds -w
# author: lilong'en(lilongen@163.com)
# date:   05/18/2007
#
use strict;
use English;
use Data::Dumper;
use Cwd;

sub main();
sub help_msg();
sub root_needed_msg();
sub isRoot();
sub valid_and_parse_command_line();
sub get_apache_conf_file_from_install_log();
sub phase_apache_configure();
sub read_whole_file($);
sub remove_redundant_slash($);
sub uninstall();

sub extrat_package();
sub set_files_property();
sub publish_content_to_document_root();
sub instance_cgi_def_template();
sub include_cgi_def_in_httpd_conf();
sub cron_jobs();
sub set_ccv_home_in_cron_sh();
sub log_install_info();
sub print_finished_info();

my $g_mode              = 1; # 1: install,  0: uninstall
my $G_INST_LOG          = "INST.LOG";
my $G_CCV_CGI_DEF_FILE  = "ccv.script.alias.httpd";

my $g_install_locate    = "/usr/local";
my $g_ccv_home 		= "$g_install_locate/ccv";
my $g_apache_conf;
my $g_configure;

my $g_logs = "Install ...\n"; 
my $g_cmd = "";

exit main();

sub main() {
	if (!isRoot()) {
		root_needed_msg();
        return 1;
	}
    if (valid_and_parse_command_line() != 0) {
        help_msg();
        return 2;
    }
    if ($g_mode == 0) { #uninstall
        if (!-e $G_INST_LOG) {
            print "Error: can not find ccv install log!\nRun \"perl $0 --help\" to get usage message.\n";
            return 1;
        }
        $g_apache_conf = get_apache_conf_file_from_install_log();
    }
    if (!-e $g_apache_conf) {
        print "Can not find apache configure file \"". $g_apache_conf . "\"\n";
        return 1;    
    }
    if (!phase_apache_configure()) {
        print "Error: can not get apache configure\n";
        return 1;
    }
    if ($g_mode == 0) { #uninstall
        return uninstall();
    }    
	
	my $old_umask = umask(18);

	extrat_package();
	set_files_property();
	publish_content_to_document_root();
	instance_cgi_def_template();
	include_cgi_def_in_httpd_conf();
	set_ccv_home_in_cron_sh();
	cron_jobs();
	log_install_info();
	print_finished_info();
	
	umask($old_umask);
	
    return 0;    
}

sub isRoot() {
	return 	`id -u` == 0;
}

sub get_apache_conf_file_from_install_log() {
    my $LOG = read_whole_file($G_INST_LOG);
    $LOG =~ m/^httpd conf: ([^\s]+)/;
    return $1 || undef;
}

sub extrat_package() {
    if (! -e $g_install_locate) {
        $g_cmd = "mkdir $g_install_locate";                    $g_logs .= "$g_cmd\n"; print `$g_cmd`;   
    }	
    $g_cmd = "tar -xzf ccv.tar.gz -C $g_install_locate";       $g_logs .= "$g_cmd\n"; print `$g_cmd`;
}

sub set_files_property() {
    $g_cmd = "chmod -R 755 $g_ccv_home/";                    print `$g_cmd`;
    $g_cmd = "chmod -R 777 $g_ccv_home/config";              print `$g_cmd`;
    $g_cmd = "chmod -R 777 $g_ccv_home/operate";             print `$g_cmd`;
    $g_cmd = "chmod -R 777 $g_ccv_home/web/reports";         print `$g_cmd`;
}

sub publish_content_to_document_root() {
    $g_cmd = "rm -rf $g_configure->{document_root}/ccv/operate"; 						remove_redundant_slash(\$g_cmd);$g_logs .= "$g_cmd\n"; print `$g_cmd`;   
    $g_cmd = "rm -rf $g_configure->{document_root}/ccv"; 								remove_redundant_slash(\$g_cmd);$g_logs .= "$g_cmd\n"; print `$g_cmd`;
    
    $g_cmd = "ln -s $g_ccv_home/web $g_configure->{document_root}/ccv";  				remove_redundant_slash(\$g_cmd);$g_logs .= "$g_cmd\n"; print `$g_cmd`;      
    $g_cmd = "ln -s $g_ccv_home/operate $g_configure->{document_root}/ccv/operate";  	remove_redundant_slash(\$g_cmd);$g_logs .= "$g_cmd\n"; print `$g_cmd`;      
}
    
sub instance_cgi_def_template() {
    my $cgi_web = "/ccv-cgi/";
    my $cgi_local = $g_ccv_home . "/";
    my $ccv_http_file = "$g_ccv_home/config/$G_CCV_CGI_DEF_FILE";
	my $ccv_http_template_file = $ccv_http_file . ".TEMPLATE";
	my $tmp_cgi_web = $cgi_web;
	my $tmp_cgi_local = $cgi_local;
	$tmp_cgi_web =~ s|/|\\/|g;
	$tmp_cgi_local =~ s|/|\\/|g;
	   
    $g_cmd = "sed -i 's/#CGI_WEB#/$tmp_cgi_web/g' $ccv_http_template_file"; 		$g_logs .= "$g_cmd\n"; print `$g_cmd`;
    $g_cmd = "sed -i 's/#CGI_LOCAL#/$tmp_cgi_local/g' $ccv_http_template_file"; 	$g_logs .= "$g_cmd\n"; print `$g_cmd`;
    $g_cmd = "mv $ccv_http_template_file $ccv_http_file";							$g_logs .= "$g_cmd\n"; print `$g_cmd`;
}

sub include_cgi_def_in_httpd_conf() {
	my $inlcude_ccv_cgi_define = "include $g_ccv_home/config/$G_CCV_CGI_DEF_FILE";
    $g_cmd = "sed -i.bak-by-ccv -re '/^(include .*" . $G_CCV_CGI_DEF_FILE . ")/d' " . $g_apache_conf;
    $g_logs .= "$g_cmd\n"; print `$g_cmd`;

    $g_cmd = "sed -i.bak-by-ccv -re '/^DocumentRoot/i \\" . $inlcude_ccv_cgi_define . "' " . $g_apache_conf;
    $g_logs .= "$g_cmd\n"; print `$g_cmd`;
}

sub cron_jobs() {
	$g_cmd = "rm -rf /etc/cron.weekly/bot-weekly.cron;ln -s $g_ccv_home/bot-weekly.cron /etc/cron.weekly/";remove_redundant_slash(\$g_cmd);	$g_logs .= "$g_cmd\n"; print `$g_cmd`;      
	$g_cmd = "rm -rf /etc/cron.daily/json.queried.revs-daily.cron;ln -s $g_ccv_home/json.queried.revs-daily.cron /etc/cron.daily/";remove_redundant_slash(\$g_cmd);$g_logs .= "$g_cmd\n"; print `$g_cmd`;      
}

sub set_ccv_home_in_cron_sh() {
	my $ccv_home = $g_ccv_home;
	$ccv_home =~ s|/|\\/|g;
	$g_cmd = "sed -i 's/#CCV_HOME#/$ccv_home/g' $g_ccv_home/bot-weekly.cron"; $g_logs .= "$g_cmd\n"; print `$g_cmd`;
	$g_cmd = "sed -i 's/#CCV_HOME#/$ccv_home/g' $g_ccv_home/json.queried.revs-daily.cron"; $g_logs .= "$g_cmd\n"; print `$g_cmd`;
}

sub log_install_info() {
	my $inlcude_ccv_cgi_define = "include $g_ccv_home/config/$G_CCV_CGI_DEF_FILE";
	my $H_LOG;
    if (!open($H_LOG, ">", "$g_ccv_home/$G_INST_LOG")) {
        print "Can not create install log!\n";    
        return 1;
    }
    my $out =<<"OUT_LOG";

Get apache configure...
httpd conf: $g_apache_conf
ccv: $g_ccv_home
ccv cgi conf: $inlcude_ccv_cgi_define

$g_logs

    
OUT_LOG
    
    print $H_LOG $out;
    print $out;

    close($H_LOG);
}

sub print_finished_info() {
    my $ccv_entry_url = "http://$g_configure->{server_name}/ccv/ccv.html";
    my $ccv_manual_url = "http://$g_configure->{server_name}/ccv/manual.html";
    remove_redundant_slash(\$ccv_entry_url);
    
    my $config_location = "$g_ccv_home/config/";
    remove_redundant_slash(\$config_location);
    	
    print <<INS;
    
Install finished!!
You need to restart apache server!!

1. CCV url: 
   $ccv_entry_url
   
2. Manual url: 
   $ccv_manual_url
   
3. Refer to manual, and configure your repository modules xml file using following methods:
   a). offline configure one or more then put it to $config_location
   b). access "$ccv_entry_url" and configure one or more online
     
     
    
INS
}  

sub remove_redundant_slash($) {
    ${$_[0]} =~ s|/{2,}|/|g;
}

sub valid_and_parse_command_line(){
    if ($#ARGV < 0 || $ARGV[0] eq "--help") {
        return 1;
    }
        
    my $cmd_line = join (" ", @ARGV);
    if ($cmd_line =~ m/\-U/) {
        $g_mode = 0;
        
        return 0;
    }      
    
    if ($cmd_line =~ m/\-\-apache-conf=([^\s]+)/) {
        $g_apache_conf = $1;
    }  else {
        return 2;   
    }

    if ($cmd_line =~ m/\-\-prefix=([^\s]+)/) {
        $g_install_locate = $1;
        $g_install_locate =~ s|\\|/|g;
        remove_redundant_slash(\$g_install_locate);
        if ($g_install_locate =~ m/(.*)\/$/) {
        	$g_install_locate = $1;
        }
        
        $g_ccv_home = "$g_install_locate/ccv";
    }
    
    remove_redundant_slash(\$g_ccv_home);                

    return 0;
}

sub phase_apache_configure() {
	my $httpd_conf_content = read_whole_file($g_apache_conf);
    my $cgi_web;
    my $cgi_local;
    if ($httpd_conf_content =~ /\nDocumentRoot\s+("?)([^\s]+)\1/s) {
        $g_configure->{document_root} = $2;
    }
    
    if ($httpd_conf_content =~ /\nServerName\s+("?)([^\s]+)\1/s) {
        $g_configure->{server_name} = $2;
    }
	    
    if (!defined($g_configure->{server_name})) {
    	if ($httpd_conf_content =~ /\nListen\s+("?)([^\s]+)\1/s) { #"
    		$g_configure->{server_name} = $2;
    	}
    }      
    
    if ($httpd_conf_content =~ /\nScriptAlias\s+("?)([^\s]+)\1\s+("?)([^\s]+)\3\s*\n/s) {
        $g_configure->{cgi_web} = $2;
        $g_configure->{cgi_local} = $4;    
    }
    
    if (!defined($g_configure->{document_root}) || !defined($g_configure->{server_name})) {
        print "Your apache configure is not OK, pls check it first!\n";
        return 0;
    }
    
    return 1;
}

sub help_msg(){        
    print <<EOF;

Usage:
perl $0 [-U] --apache-conf=/apache/configure/file [--prefix=/ccv/installed/directory]
If --prefix option is omited, it will be installed to /usr/local/ccv.

Example: 
  * Install
    perl $0 --apache-conf=/usr/local/apache2/conf/httpd.conf --prefix=/ccv/install/location
  
  * Uninstall
    perl $0 -U #Run this in ccv installed directory
     
     
    
EOF
}

sub root_needed_msg(){        
    print <<EOF;
Warning: 
This script running needs root privilege account!
Switch to root, then run it again!!

    
EOF
}

sub read_whole_file($) {
    my $file = $_[0];
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

sub uninstall() {
    my $g_cmd = "";
    print "Unistall ccv ...\n\n";
    if (-e "$g_configure->{document_root}/ccv") {
        $g_cmd = "rm -rf $g_configure->{document_root}/ccv";
        remove_redundant_slash(\$g_cmd);
        print "$g_cmd\n"; print `$g_cmd`;
    }

    $g_cmd = "sed -i.bak-by-ccv-uni -re '/^(include .*" . $G_CCV_CGI_DEF_FILE . ")/d' " . $g_apache_conf;
    print "$g_cmd\n"; print `$g_cmd`; 

    print "\n\nUnistall finished!!\n\n";
    
    return 0;    
}
