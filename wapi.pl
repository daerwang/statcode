#!/usr/bin/perl -I ./thirds -w
# author: lilong'en(lilongen@163.com)
# date:   06/11/2010
#

use strict;
use English;
use Data::Dumper;
use CGI;
use JSON;
use Assistor;
use ApiInnerParamUtil;

#WAPI commands list
my $WCH = {
	GET_OVERALL 	=> 1,
	GET_MODULES 	=> 1,
	GET_XML_FILES 	=> 1,
	UP_XML_FILE 	=> 1,
	SAVE_XML_FILE 	=> 1,
	DEL_XML_FILE 	=> 1,
	VERIFY_CFG_PWD 	=> 1,
	GENERATE 	    => 1,
	GET_PROGRESS    => 1,
	GET_XML_CONTENT => 1
};

sub main();
	
sub isPwdMatched();
sub deleteCfgFile();
sub uploadFile();
sub writeXmlFile();
sub formatXmlContent($);
sub preHandleXmlContent($);
sub removeUselessLastBackslash($$);

sub GET_OVERALL();
sub GET_MODULES();
sub GET_XML_FILES();
sub UP_XML_FILE();
sub SAVE_XML_FILE();
sub DEL_XML_FILE();
sub VERIFY_CFG_PWD();
sub GENERATE();
sub GET_PROGRESS();
sub GET_XML_CONTENT();

my $q = new CGI;
my $pms = {};
my $cfg = $q->param("cfg") || "";
my $T_SNAP = $q->param("T_SNAP") || "";
my $assistor = new Assistor($cfg, $T_SNAP);	

my $ret = {};

exit main();

sub main() {
    my $cmd = $q->param("cmd");
    my $contentType = ($cmd ne "UP_XML_FILE") ? "application/json" : "text/html";
    
    print "Content-type: $contentType\n\n";
	
	my $json = new JSON;

	if (!$cmd) {
        $ret->{error} = 1;
        $ret->{id} = "";
        $ret->{desc} = "NO_COMMAND"; 
	    
		print $json->pretty->encode($ret);
		return 1;
	}
	
	#&$cmd(); better performance compare to eval("$cmd()");
	# but can not "use strict"
	eval("$cmd()");

	print $json->pretty->encode($ret);
	return 0;	
}

sub GENERATE() {
	$T_SNAP = $assistor->get_time_snapshot();
	my $paramUtil = new ApiInnerParamUtil("wapi", $q);
	$paramUtil->setParamInnerVal("T_SNAP", $T_SNAP);
    my $cmdLine = $paramUtil->convertApi2InnerCmd();
   	system($cmdLine . " & ");
   	$ret->{T_SNAP} = $T_SNAP;	
}

sub GET_PROGRESS() {
    my $fileProgress = $assistor->get_specified_operate_file("PROGRESS_LOG");
    my $fileContent = "";
    
    $ret->{flagEnd} = 1;
    if (-e $fileProgress) {
    	$fileContent = $assistor->read_whole_file($fileProgress);
    	my $tail512 = substr($fileContent, -512);
    
    	if (index($tail512, "<DONE></DONE>") == -1) {
    		$ret->{flagEnd} = 0;
    	}
    	$fileContent =~ s|\n|<br/>|g;
    } else {
    	$ret->{flagEnd} = 0;
    }
    
    $ret->{content} = $fileContent;
}

sub GET_OVERALL() {
	my $modules = $assistor->getModules4UI();
	if (!defined($modules)) {
		$ret->{error} = 1;
		return;
	}
	$ret->{MODULES} = $modules;
	
	$ret->{CFG_FILE} = substr($assistor->{CONFIG_FILE}, length("config/"));
	$ret->{CFG_FILES} = $assistor->{CFG_FILES};
}

sub GET_MODULES() {
	my $modules = $assistor->getModules4UI();
	if (!defined($modules)) {
		$ret->{error} = 1;
		return;
	}
	$ret->{MODULES} = $modules;	
}

sub GET_XML_FILES() {
	$ret->{CFG_FILE} = substr($assistor->{CONFIG_FILE}, length("config/"));
    $ret->{CFG_FILES} = $assistor->{CFG_FILES};
}

sub SAVE_XML_FILE() {
    $pms->{cfg} = $q->param("cfg");
    $pms->{content} = $q->param("content");
	$pms->{cfgPwd} = $q->param("cfgPwd");
	$pms->{flag} = $q->param("flag");
	
	preHandleXmlContent(\$pms->{content});
	
	$ret->{cfg} = $pms->{cfg};
	if ($pms->{flag} eq "edit") {
    	my $pwdMatched = isPwdMatched();
    	if ($pwdMatched == 1) {
			if (writeXmlFile() == 0) {
	            $ret->{error} = 0;
	            $ret->{id} = "SUCCESS";
	            $ret->{desc} = "configure file \"%1\" updated";
			} else {
	            $ret->{error} = 1;
	            $ret->{id} = "FILE_OPERATION_FAILED";
	            $ret->{desc} = "FILE_OPERATION_FAILED";	            
			}
    	} else {
            $ret->{error} = 1;
            $ret->{id} = "ILLEGAL_WAPI_CALL";
            $ret->{desc} = "ILLEGAL_WAPI_CALL";
    	}    		
	} else {
		my $fileExist = $assistor->isValidCfgFile($pms->{cfg});
		if ($fileExist) {
            $ret->{error} = 1;
            $ret->{id} = "FILE_OPERATION_FAILED";
            $ret->{desc} = "\"%1\" already exist, change file name then try again!";
		} else {
			if (writeXmlFile() == 0) {
				my $cfgPwdLine = "$pms->{cfg}=$pms->{cfgPwd}\n";
				$assistor->addLine2PwnFile($cfgPwdLine);
	            $ret->{error} = 0;
	            $ret->{id} = "SUCCESS";
	            $ret->{desc} = "\"%1\" saved!";
			} else {
	            $ret->{error} = 1;
	            $ret->{id} = "FILE_OPERATION_FAILED";
	            $ret->{desc} = "FILE_OPERATION_FAILED";	            
			}				
		}
	}	
}

sub DEL_XML_FILE() {
    $pms->{cfg} = $q->param("cfg");
    $pms->{cfgPwd} = $q->param("cfgPwd");	    
    
	my $error = deleteCfgFile();
	
	if ($error == 0) {
        $ret->{error} = 0;
        $ret->{id} = "";
        $ret->{desc} = ""; 
	} else {
        $ret->{error} = 1;
        $ret->{id} = "";
        $ret->{desc} = ""; 
	}
}

sub VERIFY_CFG_PWD() {
    $pms->{cfg} = $q->param("cfg");
    $pms->{cfgPwd} = $q->param("cfgPwd");	    
    
	my $pwdMatched = isPwdMatched();
	
	if ($pwdMatched == 1) {
        $ret->{error} = 0;
        $ret->{id} = "SUCCESS";
        $ret->{cfg} = $pms->{cfg};
        $ret->{desc} = $assistor->read_whole_file("config/$pms->{cfg}");
        formatXmlContent(\$ret->{desc});
	} else {
        $ret->{error} = 1;
        $ret->{id} = "PWD_NOT_MATCHED";
        $ret->{desc} = "File write-protect-password not right, upload failed!"; 
	}	
}

sub UP_XML_FILE() {
    $pms->{hUploadedFile} = $q->param("uploadedFile");
    $pms->{cfgPwd} = $q->param("cfgPwd");
        	
    my $upRet = uploadFile();
    
    if (ref($upRet) eq "HASH") {
    	if ($upRet->{errCounter}) {
    		$ret->{error} = $upRet->{errCounter};
    		$ret->{id} = "CONFIG_ERROR";
    		$ret->{modules} = $upRet->{modules};
    		$ret->{desc} = "";
    		if ($upRet->{errCounter} == -1) {
    			$ret->{desc} = "Configure file can not be phased, pls correct it then upload again";
    		}
    	}
    } else {
        if ($upRet eq "E1") {
            $ret->{error} = 1;
            $ret->{id} = "";
            $ret->{desc} = "Upload failed!"; 
        } elsif ($upRet eq "E2") {
            $ret->{error} = 1;
            $ret->{id} = "PWD_NOT_MATCHED";
            $ret->{desc} = "File write-protect-password not right, upload failed!";
        } elsif ($upRet eq "new") {
            $ret->{error} = 0;
            $ret->{id} = "NEW";
            $ret->{desc} = "Upload successfully!";
        } elsif ($upRet eq "update") {
            $ret->{error} = 0;
            $ret->{id} = "UPDATE";
            $ret->{desc} = "Update successfully!";            
        }
    }	
}

sub GET_XML_CONTENT() {
	my $cfg = $q->param("cfg") || "";
    if ($cfg eq "example.xml") {
    	$ret->{error} = 0;
		$ret->{desc} = $assistor->read_whole_file("config/$cfg");
		formatXmlContent(\$ret->{desc});
	} else {
		$ret->{error} = 1;
		$ret->{desc} = "error!";            
	}	
}

sub formatXmlContent($) {
	my $content = $_[0];	
	
	$$content =~ s|[\r\n]|\n|g;
	$$content =~ s|\n[ \t]*<|\n    <|g;
	$$content =~ s|\n[ ]*(</?configs>)|\n$1|g;
	$$content =~ s|\n[ ]*(<module>)[ ]*\n|\n  $1\n|g;
	$$content =~ s|\n[ ]*(</module>)[ ]*\n|\n  $1\n|g;
}

sub deleteCfgFile() {
	my $pwdMatched = isPwdMatched();
	my $PWD_FILE = "config/CFG_PWD";
	my $cfgPwdLine = "$pms->{cfg}=$pms->{cfgPwd}";
	
	if ($pwdMatched) {
		my $file = "config/$pms->{cfg}";
    	my $bkfile = $file . "-delete";
		print `mv -f $file $bkfile`;
	
		$cfgPwdLine =~ s|/|\\/|g;
		print `sed -i /$cfgPwdLine/d $PWD_FILE`;
		
		return 0;
  	} else {
		return 1;
	}
}

sub isPwdMatched() {
	my $pwdMatched = 0;
    my $PWD_FILE = "config/CFG_PWD";
	my $cfgPwdLine = "$pms->{cfg}=$pms->{cfgPwd}";
    if (-e $PWD_FILE) {
	    my $pwdFileContent = $assistor->read_whole_file($PWD_FILE);
		$pwdMatched = index($pwdFileContent, "$cfgPwdLine\n") != -1;
	}	
	
	return $pwdMatched;
}

sub writeXmlFile() {
    my $OUT;
    if (!open($OUT, ">", "config/$pms->{cfg}")) {
       return 1;
    }
    print $OUT $pms->{content};
    close($OUT);
    
    return 0;
}

sub removeUselessLastBackslash($$) {
	my $content = $_[0];
	my $tagName = $_[1];
	$$content =~ s|<($tagName)>\s*([^<>]+?)[\\/]+\s*</\1>|<$1>$2</$1>|g;
}

sub preHandleXmlContent($) {
	my $content = $_[0];
	removeUselessLastBackslash($content, 'module');
	removeUselessLastBackslash($content, 'repository');
	removeUselessLastBackslash($content, 'trunk_directory');
	removeUselessLastBackslash($content, 'branch_directory');
	removeUselessLastBackslash($content, 'tag_directory');
}

sub uploadFile() {
	my $pwdMatched = 0;
	my $fileName = substr($pms->{hUploadedFile}, rindex($pms->{hUploadedFile}, '/') + 1);
	$fileName =~ s/^.*[\\\/]//g;
	$fileName =~ s/\s//g;	
	my $cfgPwdLine = "$fileName=$pms->{cfgPwd}\n";
    my $PWD_FILE = "config/CFG_PWD";
    if (-e $PWD_FILE) {
	    my $pwdFileContent = $assistor->read_whole_file($PWD_FILE);
	    if (index($pwdFileContent, $cfgPwdLine) != -1) {
	    	$pwdMatched = 1;
	    }
	} 

	my $file = "config/$fileName";
	my $fileExist = $assistor->isValidCfgFile($fileName);
	
	if ($fileExist && $pwdMatched) {
    	my $bkfile = substr($fileName, 0, -4) . ".xml." . "-" . $assistor->get_time_serial();
    	$bkfile = "config/$bkfile";
    	
    	print `mv $file $bkfile`;
    	
  	}
    
	if (!$fileExist || ($fileExist && $pwdMatched)) {
	    my $OUT;
	    if (!open($OUT, ">", $file)) {
	       return "E1";   
	    }
	    binmode($OUT);
	    while (my $ret = read($pms->{hUploadedFile}, my $buffer, 1024)) {
	       print $OUT $buffer;
	    }
	    close($OUT);
    
	    my $ret = $assistor->validateCfg($file);
	    if ($ret->{errCounter} == -1) {
	    	print `rm -rf $file`;
	    	
	    	return $ret;
	    }

		if (!$fileExist) {	    
		    $assistor->addLine2PwnFile($cfgPwdLine);
	  	}
	  	  
	    if ($ret->{errCounter}) {
	    	return $ret;
	    }
	} else {
		return "E2";
	}
  	
    if ($fileExist) {
    	return "update";	
    } else {
    	return "new";
    }
}
