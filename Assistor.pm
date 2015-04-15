#!/usr/bin/perl -I ./thirds
# author: lilong'en(lilongen@163.com)
# date: 05/18/2007
#
package Assistor;


use strict;
use English;
use XML::TreePP;
use Data::Dumper;
use File::Iterator;
use Definition;

#===============================================================================
# CONSTRUCTOR:	
#       default config file: config.xml
#       $obj = new Assistor; 
#		$obj = new Assistor($config_file_name);
#===============================================================================
sub new() {
    my $pkg = shift;
    my $config_file = shift;
    
    my $self = {};
    bless $self, $pkg;
    
    $self->_get_config_files();
    
    if (!defined($config_file) || $config_file eq "") {
       $config_file = $self->{DEFAULT_CFG};
    } else {
    	if (!$self->isValidCfgFile($config_file)) {
    		$config_file = $self->{DEFAULT_CFG};
    	}
    }
    $config_file = "config/$config_file";    
    
    $self->{CONFIG_FILE} = $config_file;
	$self->{DEF} = new Definition();
	    
    my $time_snapshot = shift;
    if (defined($time_snapshot) && !($time_snapshot eq "")) {
		$time_snapshot =~ s/ /\+/;    
		$self->{tsnap} = $time_snapshot;
		$self->_split_time();
    } else {
		$self->_format_time();
    }
    $self->_initChker();
    
    return $self;
}


#==============================================================================
# #Begin
# snap assistant functions
sub get_date() {
    my $self = shift;
    my $date_string = shift;
    
    return substr($date_string, 0, index($date_string, " "));
}

sub get_time_snapshot() {
    my $self = shift;
    
    return $self->{tsnap};
}

sub get_time_date() {
    my $self = shift;
    
    return $self->{date};
}

sub get_time_serial() {
    my $self = shift;
    
    return $self->{serial};
}

sub get_friendly_time() {
    my $self = shift;
    
    return $self->{friendly_time};
}

sub _format_time() {
    my $self = shift;

    my $tsnap = time();
    #  0    1    2     3     4    5     6     7     8
    # ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime(time); 
    my @T = gmtime($tsnap);
    $tsnap = sprintf("%4d-%02d-%02d+%02d%02d%02d", 
                        $T[5] + 1900,
                        $T[4] + 1,
                        $T[3],
                        $T[2],
                        $T[1],
                        $T[0]);
    
    my $friendly_time = sprintf("%4d-%02d-%02d %02d:%02d:%02d", 
                        $T[5] + 1900,
                        $T[4] + 1,
                        $T[3],
                        $T[2],
                        $T[1],
                        $T[0]); 
                                           
    $self->{tsnap} = $tsnap;
    $self->{friendly_time} = $friendly_time;
    $self->_split_time();
}

sub _split_time() {
    my $self = shift; 
    
    my $tsnap = $self->{tsnap};
    $tsnap =~ m/(.*)\+(.*)/;                   
    $self->{date} = $1;
    $self->{serial} = $2;
    
    my $friendly_time = $self->{date} . " " 
                . substr($self->{serial}, 0, 2) . ":"
                . substr($self->{serial}, 2, 2) . ":"
                . substr($self->{serial}, 4, 2);
                                           
    $self->{friendly_time} = $friendly_time;       
}

sub set_time_snap() {
	my $self = shift;
	my $time_snapshot = shift;
	
	$self->{tsnap} = $time_snapshot;
	$self->_split_time();	
}
# snap assistant functions
# #End
#==============================================================================




#==============================================================================
# #Begin
# repository module configure file assistant functions
sub set_config_file() {
	my $self = shift;
	my $cfg = shift;
	
	$self->{CONFIG_FILE} = "config/$cfg";
}

sub _get_config_files() {
	my $self = shift;
	
    my $it = new File::Iterator(DIR     => "config",
                                RECURSE => 0,
                                FILTER  => sub { $_[0] =~ /\.xml$/});
    my $files = [];
    while (my $file = $it->next()) {
        $file =~ s/.*[\/\\]//;
        push(@{$files}, $file);
    }    
    $self->{CFG_FILES} = $files;
    
    $self->_get_default_config();
}

sub isValidCfgFile() {
	my $self = shift;
	my $cfgFile = shift;
	
	for (my $i = 0; $i <= $#{$self->{CFG_FILES}}; $i++) {
		if ($self->{CFG_FILES}->[$i] eq $cfgFile) {
			return 1;
		}
	}
	
	return 0;
}

sub _get_default_config() {
	my $self = shift;
	
	my $default = $self->{CFG_FILES}->[0];
	
	my $joinCfgs = join(",", @{$self->{CFG_FILES}});
	
	if (index(",$joinCfgs,", ",config.xml,") != -1) {
		$default = "config.xml";
	} elsif (index(",$joinCfgs,", ",example.xml,") != -1) {
		$default = "example.xml";
	}

	$self->{DEFAULT_CFG} = $default;
}

sub escape4Bash() {
	my $self = shift;	
	my $str = shift;
	
	$str =~ s/\$/\\\$/g;
	$str =~ s/\"/\\\"/g;
	
	return $str;
}

sub getModules4UI() {
	my $self = shift;
	$self->getModules();
	$self->_constructModules4UI();
	return $self->{modules4UI};
}

sub _fixTreePPOnlyOneItemIssue() {
	my $self = shift;
	my $config = shift;
	my $type = shift;
	
	my $tmpModules = [];
    if (defined($config->{$type}) && ref($config->{$type}) ne "ARRAY") {
    	push @{$tmpModules}, $config->{$type};
    	$config->{$type} = $tmpModules;
    }  	
}

sub _getConfigItemsBytype() {
	my $self = shift;
	my $config = shift;
	my $globalCfg = shift;
	my $repositoryType = shift;
	my $items = [];
    for (my $i = 0; $i<= $#{$config->{$repositoryType}}; $i++) {
        my $item = {};
        my $cfgI = $config->{$repositoryType}->[$i];
        $item->{id} = $self->_get_value($cfgI->{id}, "");
        if ($repositoryType eq "module") {
        	$item->{type} = lc($self->_get_value($cfgI->{type}, "cvs"));
    	} else {
    		$item->{type} = $repositoryType;
    	}
    	
		$item->{account_id} 			= $self->_get_value($cfgI->{account_id}, "");
       	$item->{account_pw} 			= $self->_get_value($cfgI->{account_pw});
        $item->{access_mode} 			= $self->_get_value($cfgI->{access_mode});					
        $item->{file_filter} 			= $self->_get_value($cfgI->{file_filter}, $globalCfg->{file_filter});
        $item->{log}          			= $cfgI->{id} . ".log";
        $item->{diff}         			= $cfgI->{id} . ".diff";
		$item->{account_pw} 			= $self->escape4Bash($item->{account_pw});

		$item->{useRuntimeAccount}= $self->_get_value($cfgI->{useRuntimeAccount}, $globalCfg->{useRuntimeAccount});
		if ($item->{useRuntimeAccount} =~ m/true/i) {
		    $item->{useRuntimeAccount} = '1';
		} elsif ($item->{useRuntimeAccount} =~ m/false/i) {
		    $item->{useRuntimeAccount} = '0';
		}
		if ($item->{account_id} eq '') {
			$item->{useRuntimeAccount} = '1';
		}    	
		
		if ($repositoryType eq "module" 
			|| $repositoryType eq "cvs"
			|| $repositoryType eq "svn") {
	        $item->{module} = $self->_get_value($cfgI->{module}, "");
	    	if ($item->{module} eq '/' || $item->{module} eq '*') {
	    		$item->{module} = $item->{type} eq 'svn' ? '' : '.';	
	    	}
	        $item->{server}       = $self->_get_value($cfgI->{server}, "");
	        $item->{repository}   = $self->_get_value($cfgI->{repository}, "");
	        
	        $self->remove_redundant_slash(\$item->{module});
	        $self->remove_redundant_slash(\$item->{repository});
	        $self->backslash2slash(\$item->{module});
	        $self->backslash2slash(\$item->{repository});	        	        
    	}
        
        if ($item->{type} eq "cvs") {
	        $item->{viewvc_entry} 		= $self->_get_value($cfgI->{viewvc_entry}, "");					
	        $item->{viewvc_repository} 	= $self->_get_value($cfgI->{viewvc_repository}, "");					
	        $item->{repository_mapping} 	= $self->_get_value($cfgI->{repository_mapping}, "");
    	}
    	
        if ($item->{type} eq "svn") {
        	$item->{original_trunk_directory}  = $self->_get_value($cfgI->{trunk_directory}, "");
        	$item->{original_branch_directory} = $self->_get_value($cfgI->{branch_directory}, "");
        	$item->{original_tag_directory}    = $self->_get_value($cfgI->{tag_directory}, "");        	
        	
        	if ($item->{module} eq '') {
	        	$item->{trunk_directory}  = $item->{original_trunk_directory};
	        	$item->{branch_directory} = $item->{original_branch_directory} . "/%s";
	        	$item->{tag_directory}    = $item->{original_tag_directory} . "/%s";
        	} else {
	        	$item->{trunk_directory}  = $item->{original_trunk_directory} . "/" . $item->{module};
	        	$item->{branch_directory} = $item->{original_branch_directory} . "/%s/" . $item->{module};
	        	$item->{tag_directory}    = $item->{original_tag_directory} . "/%s/" . $item->{module};
        	}
        	$self->remove_redundant_slash(\$item->{trunk_directory});
        	$self->remove_redundant_slash(\$item->{branch_directory});
        	$self->remove_redundant_slash(\$item->{tag_directory});
        	$self->backslash2slash(\$item->{trunk_directory});
        	$self->backslash2slash(\$item->{branch_directory});
        	$self->backslash2slash(\$item->{tag_directory});
        	
        } 
        if ($item->{type} eq "git") {
	        $item->{url} 		= $self->_get_value($cfgI->{url}, "");
	        $self->backslash2slash(\$item->{url});
    	}           	

        push @{$items}, $item;
    }
    return $items;
}

sub getModules() {
    my $self = shift;
    my $cfgFile = shift;

	my $treePP = XML::TreePP->new();
	
	my $tmp;
	eval {
		$tmp = $treePP->parsefile($cfgFile || $self->{CONFIG_FILE});
	} or do {
		return undef;	
	};
	
	my $config = $tmp->{configs};

    my $globalCfg = {};
    $globalCfg->{cvsId}     = $self->_get_value($config->{cvs_account_id}, "");
    $globalCfg->{cvsPw}     = $self->_get_value($config->{cvs_account_pw}, "");
    $globalCfg->{cvsMode}   = $self->_get_value($config->{cvs_access_mode}, "pserver");
    $globalCfg->{svnId}     = $self->_get_value($config->{svn_account_id}, "");
    $globalCfg->{svnPw}     = $self->_get_value($config->{svn_account_pw}, "");
    $globalCfg->{svnMode}   = $self->_get_value($config->{svn_access_mode}, "svn");
    $globalCfg->{file_filter} = $self->_get_value($config->{file_filter}, ".*");
    $globalCfg->{useRuntimeAccount} = $self->_get_value($config->{useRuntimeAccount}, "0");
   
    my $items = [];
    my $types = ['module', 'cvs', 'svn', 'git'];
    for (my $i = 0; $i <= $#{$types}; $i++) {
    	my $type = $types->[$i];
    	if (defined($type)) {
    		$self->_fixTreePPOnlyOneItemIssue($config, $type);
    		my $typeItems = $self->_getConfigItemsBytype($config, $globalCfg, $type);
    		splice @{$items}, ($#{$items} + 1), 0, @{$typeItems};
    	}
    }

	$self->{modules} = $items;
	return $self->{modules};
}

sub _constructModules4UI() {
    my $self = shift;
    my $modules4UI = [];
	for (my $i = 0; $i <= $#{$self->{modules}}; $i++) {
		my $module = $self->{modules}->[$i];
        my $module4UI = {};
        $module4UI->{id} = $module->{id};
        $module4UI->{type} = $module->{type};
        my $type = $module->{type};
        if ($type eq "cvs" || $type eq "svn") {
	        $module4UI->{module}		= $module->{module};
	        if ($module->{module} eq '.' || $module->{module} eq '') {#svn '', cvs '.'  --> *
	        	$module4UI->{module} 	= '*';
	        }
	        $module4UI->{server} 		= $module->{server};
	        $module4UI->{repository} 	= $module->{repository};        	
        }
        
        $module4UI->{useRuntimeAccount} = $module->{useRuntimeAccount};
        $module4UI->{access_mode} 	= $module->{access_mode};
        if ($type eq "svn") {
        	$module4UI->{trunk_directory} =  $module->{trunk_directory};
        	$module4UI->{branch_directory} =  $module->{branch_directory};
        	$module4UI->{tag_directory} =  $module->{tag_directory};

        	$module4UI->{trunkFullPath} =  $self->get_svn_module_url($module, "", "trunk");
        	$module4UI->{branchFullPath} =  $self->get_svn_module_url($module, "%s", "branch");
        	$module4UI->{tagFullPath} =  $self->get_svn_module_url($module, "%s", "tag");
        } elsif ($type eq "cvs") {
        	$module4UI->{repositoryPath}= $self->get_module_cvsroot_without_uid($module4UI);	
        } elsif ($type eq "git") {
        	$module4UI->{url}= $module->{url};
        }
        $self->_attachValidation2ModulesUI($module, $module4UI);
        push @{$modules4UI}, $module4UI;
    }
    
    $self->{modules4UI} = $modules4UI;
}

sub _attachValidation2ModulesUI() {
	my $self = shift;
	my $module = shift;
	my $moduleUI = shift;
	if ($module->{type} eq 'git') {
		return;
	}
	
	$moduleUI->{CFG_ERROR} = "";
	my $ckherCnt = $#{$self->{CHKER_KEY_PRIORITY_QUEUE}} + 1;
	for (my $p = 0; $p < $ckherCnt; $p++) {
		my $chkerKey = $self->{CHKER_KEY_PRIORITY_QUEUE}->[$p];
		my $moduleInfoKeyValue = $module->{$chkerKey};

		if (!defined($moduleInfoKeyValue)) {
			next;
		}
		if ($moduleInfoKeyValue =~ m/^\s*$/) {
			if ($chkerKey eq 'account_id' || $chkerKey eq 'account_pw') {
				if ($module->{useRuntimeAccount}) {
					next;
				}
			}
			
			$moduleUI->{CFG_ERROR} = "<$chkerKey> - Can not be empty or unset";
			last;					
		}
		if (!$self->{CHKER}->{$chkerKey}->{fn}($module->{type}, $moduleInfoKeyValue)) {
			$moduleUI->{CFG_ERROR} = "<$chkerKey> - $self->{CHKER}->{$chkerKey}->{error}";
			last;
		}				
	}
}

sub injectRuntimeAccount2Modules() {
	my $self = shift;
	my $runtimeAccountId = shift;
	my $runtimeAccountPw = shift;

    my $cnt = $#{$self->{modules}};
    for (my $i = 0; $i<= $cnt; $i++) {
    	my $item = $self->{modules}->[$i];
        if ($item->{useRuntimeAccount} eq '1') {
    		$item->{account_id} = $runtimeAccountId;   	
    		$item->{account_pw} = $self->escape4Bash($runtimeAccountPw);   	
        }
        
        if ($item->{type} eq "git") {
        	$self->injectAccountInfo2GitUrl($item);	
        }
    }
}

sub get_module_info_by_module_id() {
    my $self = shift;
    my $module_id = shift;
  	my $modules = $self->{modules};
    for (my $i = 0; $i <= $#{$modules}; $i++) {
        if ($modules->[$i]->{id} eq $module_id) {
            return $modules->[$i];   
        }
    }
    
    return undef;
}

sub validateCfg() {
	my $self = shift;
	my $cfgFile = shift;
	
	eval {
		my $modules = $self->getModules($cfgFile);
		my $cnt = $#{$modules} + 1;
		
		my $errModules = [];
		my $errCounter = 0;
				
		for (my $i = 0; $i < $cnt; $i++) {
			while ( my ($key, $value) = each(%{$modules->[$i]}) ) {
				if (!$self->{CHKER}->{$key}) {
					delete $modules->[$i]->{$key};
					next;
				}
				
				if ($value =~ m/^\s*$/) {
					$modules->[$i]->{$key} = "<$key>$modules->[$i]->{$key}</$key> - Can not be empty or unset";
					$errCounter++;
				} else {
					if (!$self->{CHKER}->{$key}->{fn}($modules->[$i]->{type}, $value)) {
						$modules->[$i]->{$key} = "<$key>$modules->[$i]->{$key}</$key> - $self->{CHKER}->{$key}->{error}";
						$errCounter++;
					} else {
						delete $modules->[$i]->{$key};
					}					
				}

	    	}
		}
		
		return {
			'errCounter' => $errCounter,
			'modules' => $modules
		};		
	} or do {
		return {
			'errCounter' => -1
		};			
	};
}

sub _initChker() {
	my $self = shift;
	
	my $chker = {
		'id' => {
			'fn' => sub($$) {
				my $type = lc(shift);
				my $id = shift;
				return $id =~ m/^[\w_\-\.\+]+$/i;
			},
			
			'error' => "Only can include 'a-z A-Z 0-9 . - _'"
		},
				
		'path' => {
			'fn' => sub($$) {
				my $type = lc(shift);
				my $str = shift;
				return $str =~ m/^\/?([\w\s\._\-]+\/?)+$/i;
			},
			
			'error' => "Is not a legal path"
		},
		
		'svnTBTPath' => {
			'fn' => sub($$) {
				my $type = lc(shift);
				my $str = shift;
				return $type eq "cvs" || $str =~ m/^\/?([\w\s\._\-%]+\/?)+$/i;
			},
			
			'error' => "Not a legal svn trunk/branches/tag path"
		},
		
		'domain' => {
			'fn' => sub($$) {
				my $type = lc(shift);
				my $server = shift;	
				return $server =~ m/^(([\w\-]+.)+[\w\-]+|\d+.\d+.\d+.\d+)$/i;			
			},
			
			'error' => "Not a legal domain name or ip"
		},
		
		'type' => {
			'fn' => sub($$) {
				my $type = lc(shift);
				return $type =~ m/^(cvs|svn)$/i;		
			},
			
			'error' => "Not a legal type, must be cvs or svn"
		},
		
		'accessmode' => {
			'fn' => sub($$) {
				my $type = lc(shift);
				my $mode = shift;
				return $type eq "cvs" && $mode =~ m/^(pserver|ext)$/i
					|| $type eq "svn" && $mode =~ m/^(svn|http|https|svn\+ssh)$/i;		
			},
			
			'error' => "Not a legal svn trunk/branches/tag path"
		}	
	};
	
	$self->{CHKER} = {
		'id' 				=> $chker->{id},
		#'module' 			=> $chker->{path},
		'repository' 		=> $chker->{path},
		'server' 			=> $chker->{domain},
		'account_id' 		=> $chker->{id},
		'type' 				=> $chker->{type},
		'access_mode' 		=> $chker->{accessmode},
		'trunk_directory' 	=> $chker->{svnTBTPath},
		'branch_directory' 	=> $chker->{svnTBTPath},
		'tag_directory' 	=> $chker->{svnTBTPath}
	};
	
	$self->{CHKER_KEY_PRIORITY_QUEUE} = [
		'id',
		#'module',
		'repository',
		'server',
		'account_id',
		'type',
		'access_mode',
		'trunk_directory',
		'branch_directory',
		'tag_directory'
	];	
}

sub _get_value() {
    my $self 	= shift;
    my $value 	= shift;
    my $default = shift;
	
	if (defined($value)) {
		return $value;
	} else {
		return $default;	
	}
}
# repository module configure IO assistant functions
# #End
#==============================================================================




#==============================================================================
# #Begin
# program language configure assistant functions
sub _get_program_langs() {
    my $self = shift;
    
	my $treePP = XML::TreePP->new();
	my $tmp = $treePP->parsefile("config/program.lang");
	my $langs = $tmp->{langs};
	
    return $langs;
}

sub get_program_langs_ext() {
    my $self = shift;

    my $cfg = $self->_get_program_langs();
    my $langs = {
    	name => "",
    	ext => "",
    	code => {
    		name => "",
    		ext => ""
    	},
    	
    	configure => {
    		name => "",
    		ext => ""
    	},
    	
    	html => {
    		name => "",
    		ext => ""
    	},    	
    	
    	other => {
    		name => "",
    		ext => ""
    	}    	
    };
    
    my $cnt = $#{$cfg->{lang}} + 1;
    for (my $i = 0; $i < $cnt; $i++) {
    	my $item = $cfg->{lang}->[$i];
    	my $name = $item->{'-name'};
    	my $ext = $item->{'-ext'};
    	my $type = $item->{'-type'};
    	
    	my $separator = $i < ($cnt - 1) ? " " : "";
    	
		$langs->{name} .= $name . $separator;
		$langs->{ext} .= $ext . $separator;
		
		for my $key (keys %{$langs}) {
			if ($key =~ m/(name|ext)/) {
				next;
			}
			$langs->{$key}->{name} .=  $name . $separator;
			$langs->{$key}->{ext} .=  $ext . $separator;			
		} 
    }
	for my $key (keys %{$langs}) {
		if ($key =~ m/(name|ext)/) {
			next;
		}
		$langs->{$key}->{name} =~ s/\s$//;
		$langs->{$key}->{ext} =~ s/\s$//;			
	}     
    
	return $langs;
}
# program language configure assistant functions
# #End
#==============================================================================




#==============================================================================
# #Begin
# assistant function for
#   1. get repository rev, revs, dates and other info 
#   2. repository rev, revs, dates map to ccv shown info,
#   3. repository rev, revs, dates map to ccv operating directory
sub _get_cvsroot() {
    my $self            = shift;
    my $cvs_username    = shift;
    my $cvs_password    = shift;
    my $cvs_server      = shift;
    my $cvs_repository  = shift;
    my $cvs_mode = shift;
    
    my $cvsroot = "";
    if (!$cvs_mode || $cvs_mode eq "pserver") {
    	$cvsroot = sprintf(":pserver:%s:%s@%s:%s",
                    $cvs_username,
                    $cvs_password,
                    $cvs_server,
                    $cvs_repository);
	} else {
    	$cvsroot = sprintf(":ext:%s@%s:%s",
                    $cvs_username,
                    $cvs_server,
                    $cvs_repository);		
	}                    
                    
    return $cvsroot;   
}

sub get_cvs_repository_uri() {
    my $self            = shift;
    my $minfo 			= shift;

	return sprintf(":%s@%s:%s",
        $minfo->{access_mode},
        $minfo->{server},
        $minfo->{repository}
    );  
}

sub get_module_cvsroot_without_uid() {
    my $self            = shift;
    my $module_info	    = shift;
    
    my $cvsroot = sprintf(":pserver@%s:%s",
                    $module_info->{server},
                    $module_info->{repository}); 
                    
    return $cvsroot;   
}

sub get_module_cvsroot() {
    my $self        = shift;
    my $mInfo	    = shift;
    
    my $cvs_username    = $mInfo->{account_id};
    my $cvs_password    = $mInfo->{account_pw};
    my $cvs_server      = $mInfo->{server};
    my $cvs_repository  = $mInfo->{repository};
    my $cvs_mode = $mInfo->{access_mode};
    
    return $self->_get_cvsroot($cvs_username, $cvs_password, $cvs_server, $cvs_repository, $cvs_mode);
}

sub get_operate_revs_dates_dir_name() {
	my $self = shift;
	my $pms = shift;
	
	my $ret = "";
	if ($pms->{mode} == 0) {
    	$ret = $pms->{rev};
    } elsif ($pms->{mode} == 1) {
    	if ($pms->{dfRevs} ne "") {
    		$ret = $pms->{dfRevs};
    	} else {
    		$ret = $pms->{dfDates};
    	}
    } elsif ($pms->{mode} == 2) {
    	$ret = $pms->{rev};
    }
    
    return $ret;
}

sub set_diff_revs_dates() {
	my $self = shift;
	my $pms = shift;
	
	if ($pms->{mode} == 1) {
		$pms->{dfRevs} = "";
		if ($pms->{r1} ne "" || $pms->{r2} ne "") {
			if ($pms->{r1} ne "" && $pms->{r2} ne "") {
				$pms->{dfRevs} = "$pms->{r1}-$pms->{r2}"	
			} else {
				$pms->{dfRevs} = ($pms->{r1} ne "" ? $pms->{r1} : $pms->{r2});
			}
		}
		
		$pms->{dfDates} = "";
		if ($pms->{d1} ne "" || $pms->{d2} ne "") {
			if ($pms->{d1} ne "" && $pms->{d2} ne "") {
				$pms->{dfDates} = "$pms->{d1}-$pms->{d2}"	
			} else {
				$pms->{dfDates} = ($pms->{d1} ne "" ? $pms->{d1} : $pms->{d2});
			}
			
			$pms->{dfDates} =~ s|/|\-|g;
		}		
	}
}

sub getSvnModuleOperatedPath() {
    my $self        = shift;
    my $mInfo	    = shift;
    my $revsInfo    = shift;
    
	my $operatedPath = $mInfo->{trunk_directory};
	
	if ($revsInfo->{Flag}->{IsTrunk} || $revsInfo->{Flag}->{OnTrunk}) {
		$operatedPath = $mInfo->{trunk_directory};
	} else {
		$operatedPath = sprintf($mInfo->{branch_directory}, $revsInfo->{Base})
	}
	
	return $operatedPath;
}

sub get_svn_repository_uri() {
    my $self        = shift;
    my $mInfo	    = shift;
    my $revType		= shift;
	
	my $repositoryPath = $mInfo->{repository};
	if (defined($revType)) {
		if ($revType eq "branch") {
			$repositoryPath = $mInfo->{original_branch_directory};
		} elsif ($revType eq "tag") {
			$repositoryPath = $mInfo->{original_tag_directory};
		} elsif ($revType eq "trunk") {
			$repositoryPath = $mInfo->{original_trunk_directory};
		}
	} 
	
	my $url = "";	
    if ($mInfo->{access_mode} eq "file") {
		$url = sprintf("file://%s",
					$repositoryPath);
    } else { #svn, svn+ssh, http, https
		$url = sprintf("%s://%s/%s",
					$mInfo->{access_mode},
					$mInfo->{server},
					$repositoryPath);       		
    }

    $url =~ s|([^:])[\/]{2,}|$1\/|g;
    return $url;
}

sub get_svn_module_url() {
    my $self        = shift;
    my $mInfo	    = shift;
    my $rev 		= shift;
    my $revType		= shift;
	
	my $revsInfo = $self->getSvnLogRevsInfo($rev);
	my $url = "";
	my $moduleOperatedPath = $mInfo->{trunk_directory};
	
	if (defined($revType)) {
		if ($revType eq "branch") {
			$moduleOperatedPath = sprintf($mInfo->{branch_directory}, $rev);
		} elsif ($revType eq "tag") {
			$moduleOperatedPath = sprintf($mInfo->{tag_directory}, $rev);
		}
	} else {
		$moduleOperatedPath = $self->getSvnModuleOperatedPath($mInfo, $revsInfo);		
	}
	
    if ($mInfo->{access_mode} eq "file") {
		$url = sprintf("file://%s",
					$moduleOperatedPath);
    } else { #svn, svn+ssh, http, https
		$url = sprintf("%s://%s/%s",
					$mInfo->{access_mode},
					$mInfo->{server},
					$moduleOperatedPath);       		
    }

    $url =~ s|([^:])[\/]{2,}|$1\/|g;
    return $url;
}

sub getCvsLogRevs() {
    my $self = shift;
    my $revs = shift;
    
    my $atPos = index($revs, "\@");
    if ($atPos == -1) {
    	return $revs;
    } else {
    	return substr($revs, 0, $atPos);	
    }
}

sub getSvnLogRevsInfo() {
    my $self = shift;
    my $revs = shift;	
	
	my $info = {
		Revs => $revs,
		Flag => {
			IsTrunk => 0,	
			IsBranch => 0,
			OnTrunk => 0,
			OnBranch =>0
		},
		
		Base => $revs
	};
	
	if ($revs =~ m/^(\d+:\d+)\@(.*)$/) {#123:456@T27L10N_FR23
		my $revsScale = $1;
		my $onRev = $2;

		if ($onRev =~ m/^(|TRUNK)$/i) {
			$info->{Flag}->{OnTrunk} = 1;
			$info->{Base} = "TRUNK";
		} else {
			$info->{Flag}->{OnBranch} = 1;
			$info->{Base} = $onRev;
		}
		
		$info->{Revs} = $revsScale;
	} elsif ($revs =~ m/^(\d+:\d+)$/) {
		$info->{Flag}->{OnTrunk} = 1;
		$info->{Base} = "TRUNK";
	} elsif ($revs =~ m/^(TRUNK|MAIN)$/i) {
		$info->{Flag}->{IsTrunk} = 1;
		$info->{Base} = "TRUNK";
	} else {
		$info->{Flag}->{IsBranch} = 1;
	}
	
	return $info;
}

sub get_svn_file_url() {
    my $self        = shift;
    my $mInfo	    = shift;
    my $file 		= shift;
	
	my $url = '';
    if ($mInfo->{access_mode} eq "file") {
		$url = sprintf("file://%s/%s",
					$mInfo->{repository},
					$file);
    } else { #svn, svn+ssh, http, https
		$url = sprintf("%s://%s/%s/%s",
					$mInfo->{access_mode},
					$mInfo->{server},
					$mInfo->{repository},
					$file);       		
    }

    $url =~ s|([^:])[\/]{2,}|$1\/|g;
    return $url;
}

sub get_co_svn_file_cmd() {
    my $self        = shift;
    my $mInfo	    = shift;
    my $file 		= shift;
    my $rev			= shift;
	
	return sprintf("svn cat --non-interactive --username \"%s\" --password '%s' -r %s \"%s\"",
		$mInfo->{account_id},
		$mInfo->{account_pw},
		$rev,
		$self->get_svn_file_url($mInfo, $file)
	);
}

sub get_df_svn_file_cmd() {
    my $self        = shift;
    my $mInfo	    = shift;
    my $file 		= shift;
    my $rev			= shift;
    my $dfOpts		= shift;
    
	return sprintf("svn diff %s --non-interactive --username \"%s\" --password '%s' -c %s \"%s\"",
		$dfOpts,
		$mInfo->{account_id},
		$mInfo->{account_pw},
		$rev,
		$self->get_svn_file_url($mInfo, $file)
	);
}

sub isTrunk() {
	my $self = shift;
	my $pms = shift;

	return $pms->{rev} eq 'MAIN' || $pms->{rev} eq 'TRUNK';
}

sub getSvnRevBase() {
	my $self = shift;
	my $pms = shift;

	return $self->isTrunk($pms) ? 'trunk' : 'branch';
}

sub getSvnModuleRevFullPath() {
	my $self = shift;
	my $mInfo = shift;
	my $pms = shift;
	my $revBase = $self->getSvnRevBase($pms);
	
	my $revFullPath = ($revBase eq 'trunk') ? $mInfo->{trunk_directory} : (($revBase eq 'branch') ? sprintf($mInfo->{branch_directory}, $pms->{rev}) :  sprintf($mInfo->{tag_directory}, $pms->{rev}));
	return $revFullPath;
}
#==============================================================================
# assistant function for 
#   1. cvs/svn repository rev, revs, dates map to ccv shown info,
#   2. cvs/svn repository rev, revs, dates map to ccv operating directory
# #End



#==============================================================================
# #Begin
# reports/operates local or web file location service assistant functions
sub reportLocalPath() {
    my $self = shift;
    return "web/reports/$self->{date}/$self->{serial}/";
}
sub reportWebPath() {
    my $self = shift;
    return "/ccv/reports/$self->{date}/$self->{serial}/";
}

sub operateLocalPath() {
    my $self = shift;
    return "operate/$self->{date}/$self->{serial}/";
}
sub operateWebPath() {
    my $self = shift;
    return "/ccv/operate/$self->{date}/$self->{serial}/";
}

sub transReportLocalPath2WebPath() {
	my $self = shift;
	my $path = shift;
	
	return '/ccv/' . substr($path, length('web/'));	
}

sub transOperateLocalPath2WebPath() {
	my $self = shift;
	my $path = shift;
	
	return '/ccv/' . $path;	
}

sub _get_output_report_name() {
    my $self = shift;
    my $flag = shift;

    return $self->{DEF}->{OUTPUT_RPT_NAME}->{$flag};
}

sub _get_report_template_name() {
    my $self = shift;
    my $flag = shift;
    
    return $self->{DEF}->{RPT_TPL_NAME}->{$flag};
}

sub get_report_template_file() {
    my $self = shift;
    my $flag = shift;
    
    return "web/" . $self->_get_report_template_name($flag);    
}

sub get_cvs_file_patten_str_without_repository_path() {
	my $self = shift;
	my $module = shift;
	return $module eq '.' ? ".*" : "$module\/.*";
}

sub get_specified_output_report_file() {
    my $self = shift;
    my $pmo = shift;
    
    my $reportFilePrefix = ($pmo->{flag} eq "TOP" || $pmo->{flag} eq "FRAME") ? "$pmo->{revs}-" : "$pmo->{revs}-$pmo->{mid}-";
    return $self->reportLocalPath() . $reportFilePrefix . $self->_get_output_report_name($pmo->{flag});
}

sub get_repository_log_cmd_output_file() {
    my $self = shift;
    my $branch = shift;
    my $module_log = shift;
    
    my $log_file = $self->operateLocalPath() . "$branch/$module_log";  
    return $log_file;         
}

sub get_branch_module_11_file_operate_webpath() {
    my $self = shift;
    my $branch = shift;
    my $module_id = shift;    
	my $file = shift;
    my $full_path = $self->operateWebPath() . "$branch/$module_id/1.1/$file";
    
    return $full_path;   
}

sub get_cvs_module_files_info_file() {
    my $self = shift;
    my $branch = shift;
    my $module_id = shift;    
    
    return $self->operateLocalPath() . "$branch/$module_id/head/$self->{DEF}->{MID_DATA_FILE_NAME}->{MODULE_FILES_INFO}";
}

sub get_svn_log_mode_all_diff_output_file() {
    my $self = shift;
    my $branch = shift;
    my $mInfo = shift;
    
    return $self->operateLocalPath() . "$branch/$mInfo->{id}/$self->{DEF}->{MID_OUT_FILE_NAME}->{SVN_ALL_REVS_DF}";
}

sub get_branch_module_rev_files_operate_path() {
    my $self = shift;
    my $branch = shift;
    my $module_id = shift;
   
    return $self->operateLocalPath() . "$branch/$module_id/rev_files";  
}

sub get_branch_module_file_diff_out_file() {
    my $self = shift;
    my $branch = shift;
    my $module_id = shift;
    my $file = shift;
    my $rev1 = shift;
    my $rev2 = shift;
    
    $file =~ s|/|\.|g;
    
    my $diff_out_file = $self->operateLocalPath() . "$branch/$module_id/$file+$rev1+$rev2";  
    
    return $diff_out_file;         
}

sub get_all_modules_sum_info_data_file() {
    my $self = shift;
    
    return  $self->operateLocalPath() . $self->{DEF}->{MID_DATA_FILE_NAME}->{ALL_MODULES_SUM_INFO};         
}

sub get_revisions_module_diff_out_file() {
    my $self = shift;
    my $revisions = shift;
    my $module_diff = shift;
    
    return $self->operateLocalPath() . "$revisions/$module_diff";
}

#brief txt report functions
sub get_brief_report_file() {
    my $self = shift;
    
    return $self->reportLocalPath() . $self->{DEF}->{MID_OUT_FILE_NAME}->{BRIEF_REPORT};    
}

sub get_module_brief_report_file() {
    my $self = shift;
    my $moduleId = shift;
    
    return $self->reportLocalPath() . "$moduleId-$self->{DEF}->{MID_OUT_FILE_NAME}->{BRIEF_REPORT}";    
}

sub get_all_modules_sum_header_file() {
    my $self = shift;
    
    return $self->reportLocalPath() . $self->{DEF}->{MID_OUT_FILE_NAME}->{ALL_MODULES_SUM_HEADER};    
}
#End

sub get_specified_operate_file() {
    my $self = shift;
    my $flag = shift;
    
    my $keyParent = $flag eq "PROGRESS_LOG" ? "MID_OUT_FILE_NAME" : "MID_DATA_FILE_NAME";
    
    return $self->operateLocalPath() . $self->{DEF}->{$keyParent}->{$flag};
}

sub get_operate_revs_location() {
	my $self = shift;
	my $revsDirInTsnap = shift;
	
	return $self->operateLocalPath() . "$revsDirInTsnap/";
}

sub get_module_co_ver11_path() {
	my $self = shift;
	my $branch = shift;
	my $module_id = shift;
	
	return $self->operateLocalPath() . "$branch/$module_id/1.1/";
}
sub get_module_co_ver11_file() {
	my $self = shift;
	my $branch = shift;
	my $module_id = shift;
	my $file = shift;
	
	return $self->get_module_co_ver11_path($branch, $module_id) . $file;
}

sub get_module_co_head_path() {
	my $self = shift;
	my $branch = shift;
	my $module_id = shift;
	
	return $self->operateLocalPath() . "$branch/$module_id/head/";
}
sub get_module_co_head_file() {
	my $self = shift;
	my $branch = shift;
	my $module_id = shift;
	my $file = shift;

	return $self->get_module_co_head_path($branch, $module_id) . $file;
}

sub getSvnModuleLogParsedInfoFile() {
	my $self = shift;
	my $pms = shift;
	my $mid = shift;
	
	return $self->operateLocalPath() . "$pms->{rev}/$mid/$self->{DEF}->{MID_DATA_FILE_NAME}->{LOG_PARSED_INFO}";
}

sub getGitLogParsedInfoFile() {
	my $self = shift;
	my $pms = shift;
	my $mid = shift;
			
	return $self->operateLocalPath() . "$pms->{rev}/$mid/$self->{DEF}->{MID_DATA_FILE_NAME}->{LOG_PARSED_INFO}";
}

sub getSvnMoudleAllRevsDFFile() {
	my $self = shift;
	my $pms = shift;
	my $mid = shift;
	
	return $self->operateLocalPath() . "$pms->{rev}/$mid/$self->{DEF}->{MID_OUT_FILE_NAME}->{SVN_ALL_REVS_DF}";    
}

sub getSvnMoudleInitRevFileLocation() {
	my $self = shift;
	my $pms = shift;
	my $mid = shift;
	
	return $self->operateLocalPath() . "$pms->{rev}/$mid/rev_src/init";    
}

sub getSvnMoudleHeadRevFileLocation() {
	my $self = shift;
	my $pms = shift;
	my $mid = shift;
	
	return $self->operateLocalPath() . "$pms->{rev}/$mid/rev_src/head";    
}

sub getSvnMoudleGraphDataFile() {
	my $self = shift;
	my $pms = shift;
	my $mid = shift;
	
	return $self->operateLocalPath() . "$pms->{rev}/$mid/$self->{DEF}->{MID_DATA_FILE_NAME}->{GRAPH_DATA}";    
}

sub getSvnMoudleFilesInfoDataFile() {
	my $self = shift;
	my $pms = shift;
	my $mid = shift;
	
	return $self->operateLocalPath() . "$pms->{rev}/$mid/rev_src/head/$self->{DEF}->{MID_DATA_FILE_NAME}->{MODULE_FILES_INFO}";    
}

sub get_history_reports_log_file() {
    return "operate/ccv.log";
}

sub get_wids_file() {
    return "config/accounts";
}
# reports/operates local or web file location service assistant functions
# #End
#==============================================================================

sub remove_redundant_slash() {
    ${$_[1]} =~ s|/{2,}|/|g;
}

sub backslash2slash() {
    ${$_[1]} =~ s|\\|/|g;
}

#==============================================================================
# file io assistant functions
# #Begin
sub read_whole_file() {
    my $self = shift;
    my $file = shift;
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

sub read_file_content_offsets_content() {
    my $self = shift;
    my $file = shift;
    my $begin = shift;
    my $len = shift;
    
    if (!open(INPUT, "<", $file)) {
        return undef;   
    }
    seek(INPUT, $begin, 0);
    
    my $content = "";
    my $a_len = read(INPUT, $content, $len);
    close INPUT;

    return $content;
}

sub write_file() {
    my $self = shift;
    my $file = shift;
    my $content = shift;
    my $mode = shift;
    
    if (!defined($mode) || $mode eq "") {
    	$mode = ">";
    }
    my $H;
    if (!open($H, $mode, $file)) {
       return 1;
    }
    
    print $H $content; 
    close($H);
}

sub debug() {
    my $self            = shift;    
    my $info            = shift;
    
    my $old = umask(0);
    my $DEBUG;
    if (!open($DEBUG, ">>", "/tmp/CCV-DEBUG")) {
       return 1;
    }
    print $DEBUG (ref($info) eq "" ? $info : Dumper($info)) . "\n";
    close($DEBUG);     
    umask($old);
    return 0;
}

sub addLine2PwnFile() {
	my $self = shift;
	my $cfgPwdLine = shift;
	
    my $HPWD;
    if (!open($HPWD, ">>", "config/CFG_PWD")) {
    	return 1;
    }
    print $HPWD $cfgPwdLine;
    close($HPWD);
    
    return 0;
}

sub logCcvQueryEntry() {
	my $self = shift;
	my $ccv_query_log = shift;
	
	my $_REPORT_LOG_ = $self->get_history_reports_log_file();
	my $_H_REPORT_LOG_ = undef;
    if (!open($_H_REPORT_LOG_, ">>", $_REPORT_LOG_)) {
		return;
	}  
	
    print $_H_REPORT_LOG_  $ccv_query_log;
    close($_H_REPORT_LOG_);
}
# file io assistant functions
# #End
#==============================================================================



# git relative functions
sub injectAccountInfo2GitUrl() {
	my $self = shift;	
	my $gitInfo = shift;
	
	my $url = $gitInfo->{url};
	my $idxProtocalDelimiter = index($url, '://');
	my $protocal = substr($url, 0, $idxProtocalDelimiter);
	my $accountInfo = "$gitInfo->{account_id}:$gitInfo->{account_pw}@";
	$gitInfo->{urlWithAccount} = substr($url, 0, $idxProtocalDelimiter + 3)
		. "$gitInfo->{account_id}:$gitInfo->{account_pw}@"
		. substr($url, $idxProtocalDelimiter + 3);
}
# git relative functions
# #End




#==============================================================================
# END of the module.
#==============================================================================
1;
__END__

