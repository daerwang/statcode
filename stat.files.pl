#!/usr/bin/perl -I ./thirds -w
# author: lilong'en(lilongen@163.com)
# date:   05/01/2010
#

use strict;
use English;
use Data::Dumper;
use Assistor;
use Cwd;
use JSON;
use bytes;

sub main();
sub initial_files_info();
sub obtain_file_ext_info($$$);
sub getDef($);
sub set_file_lines_size($$$);
sub set_file_info_scale($$$);
sub initDistributionData($$);
sub construct_files_info();
sub outDataAsJson($$);
sub addTxtTypeInfo();

my $T_SNAP 				= $ARGV[0];
my $g_work_path			= $ARGV[1];
my $g_stat_dir 			= $ARGV[2];

my $assistor 			= new Assistor("", $T_SNAP);
my $GV = {};

exit main();

sub main() {
	setGV();
	
	my $cgiPath = getcwd;	
	chdir($g_work_path);
	#add grep -v to exclude CVS/svn files
	my $cmd = "find $g_stat_dir | grep -v -P \"(^|/)(CVS|\.svn)(\$|/)\" > $GV->{FilesListFile}";
	print `$cmd`;
	
	$cmd = "file -f $GV->{FilesListFile} > $GV->{FilesTypeInfoFile}";
	print `$cmd`;
	
	#need sed to add " in file name start & end, otherwise if file name include \s, will cause error
	$cmd = "cat $GV->{FilesListFile} | sed -r 's/(^|\$)/\"/g' | xargs wc -l -c > $GV->{FilesWcInfoFile} 2>/dev/null";
	print `$cmd`;
	
	construct_files_info();
	addTxtTypeInfo();
	
	outDataAsJson($GV->{FilesInfoFile}, $GV->{FilesInfo});
	
	chdir($cgiPath);

	return 0;
}

sub addTxtTypeInfo() {
	$GV->{FilesInfo}->{txt_type_info}= {};
	$GV->{FilesInfo}->{txt_type_info}->{code} = $GV->{Langs_Info}->{code}->{ext};
	$GV->{FilesInfo}->{txt_type_info}->{html} = $GV->{Langs_Info}->{html}->{ext};
	$GV->{FilesInfo}->{txt_type_info}->{configure} = $GV->{Langs_Info}->{configure}->{ext};
}

sub outDataAsJson($$) {
	my $dataFile = shift;
	my $data = shift;
	my $hOut = undef;
	if (!open($hOut, '>', $dataFile)) {
		return;
	}
	
	my $json = new JSON;
	print $hOut $json->pretty->encode($data);
	close($hOut);
}

sub setGV() {
	$GV->{Langs_Info} 			= $assistor->get_program_langs_ext();

	$GV->{FilesListFile} 		= "__ccv_file_list__";
	$GV->{FilesTypeInfoFile} 	= "$GV->{FilesListFile}.file";
	$GV->{FilesWcInfoFile} 		= "$GV->{FilesListFile}.wc";	
	
	$GV->{FilesInfo}  			= {};
	$GV->{_FilesLineSize}  		= {};
	$GV->{FilesInfoFile}		= $assistor->{DEF}->{MID_DATA_FILE_NAME}->{MODULE_FILES_INFO};
	
	$GV->{DEF} 					= {};
	$GV->{DEF}->{LINE_DISTRIBUTE} = [
		'[0,50)',
		'[50,100)',
		'[0,100)',
		'[100,200)',
		'[0,200)',
		'[200,500)',
		'[0,500)',
		'[500,1000)',
		'[0,1000)',
		'[1000,2000)',
		'[0,2000)',
		'[2000,5000)',
		'[0,5000)',
		'[5000,)'
	];
	$GV->{DEF}->{SIZE_DISTRIBUTE} = [
		'[0,5)',
		'[5,10)',
		'[0,10)',
		'[10,50)',
		'[0,50)',
		'[50,100)',
		'[0,100)',
		'[100,500)',
		'[0,500)',
		'[500,1000)',
		'[0,1000)',
		'[1000,2000)',
		'[0,2000)',
		'[2000,5000)',
		'[0,5000)',
		'[5000,)'
	];
	
	initial_files_info();
}

sub initDistributionData($$) {
	my $distributeKey = $_[0];
	my $type = $_[1];
	
	$GV->{FilesInfo}->{$distributeKey} = {};
	
	my $def = $type eq "size" ? $GV->{DEF}->{SIZE_DISTRIBUTE} : $GV->{DEF}->{LINE_DISTRIBUTE};
	my $cnt = $#{$def} + 1;
	for (my $i = 0; $i < $cnt; $i++) {
		$GV->{FilesInfo}->{$distributeKey}->{$def->[$i]} = 0;
	}
}

sub construct_files_info() {
	obtain_files_line_size();
	
	my $H_FileTypeFile;
	if (!open($H_FileTypeFile, $GV->{FilesTypeInfoFile})) {
		output("Can not open $GV->{FilesTypeInfoFile}!\n");
		return 1;
	}

	while (1) {
		my $line = <$H_FileTypeFile>;
		if (!defined($line)) {
			last;
		}
		
		my $file = "";
		my $fileType = "";
		
		#supportcenter/src/conf:                                                                                                          directory
		#supportcenter/src/conf/supportcenter:                                                                                            directory
		#supportcenter/src/conf/supportcenter/sc_parametersconfig.properties:                                                             ASCII C++ program text
		#supportcenter/src/conf/supportcenter/sc_test_config.properties:                                                                  ASCII text, with CRLF, LF line terminators
		#supportcenter/src/conf/supportcenter/supportcenter_docshow_config_scsession.properties:                                          ASCII English text
		#supportcenter/src/conf/supportcenter/supportcenter_docshow_config_smtsession.properties:                                         ASCII text		
		if ($line =~ m/^([^:]+):\s+([^\s].*)$/) {
			$file = $1;
			$fileType = $2;
			
			if ($file =~ m/^.*\/(\.svn|CVS)($|\/)/) {
				next;
			}			
			
			if ($fileType eq "directory") {
				$GV->{FilesInfo}->{dir} ++;
				next;
			} else {
				$GV->{FilesInfo}->{file} ++;
				
				my $fileInfo = $GV->{_FilesLineSize}->{$file};					
				my $isText = (index($fileType, 'text') != -1);
				if ($isText) {
					$GV->{FilesInfo}->{text_file} ++;
				} else {
					$GV->{FilesInfo}->{binary_file} ++;
				}
				set_file_lines_size($file, $isText, $fileInfo);
				obtain_file_ext_info($file, $isText, $fileInfo);
			}
		} else {
			next;	
		}
	}
	
	close($H_FileTypeFile);		
}

sub obtain_files_line_size() {
	my $H_FilesLineSizeFile;
	if (!open($H_FilesLineSizeFile, $GV->{FilesWcInfoFile})) {
		output("Can not open $GV->{FilesWcInfoFile}!\n");
		return 1;
	}
	
	while (1) {
		my $line = <$H_FilesLineSizeFile>;
		if (!defined($line)) {
			last;
		}
		
		my $file = "";
		my $lines = 0;
		my $size = 0;
		#289   12869 supportcenter/src/conf/supportcenter/sc_parametersconfig.properties
		if ($line =~ m/^\s*(\d+)\s+(\d+)\s+([^\s].*)$/) {
			$lines = $1;
			$size = $2;
			$file = $3;
			
			$GV->{_FilesLineSize}->{$file} = {
				lines => $lines,
				size => $size
			};
		} else {
			next;	
		}
	}
	
	close($H_FilesLineSizeFile);		
	
}

sub initial_files_info() {
	$GV->{FilesInfo}->{all_file_total_size} 		= 0;
	$GV->{FilesInfo}->{all_text_file_total_lines}	= 0;
	$GV->{FilesInfo}->{dir} 						= 0;
	$GV->{FilesInfo}->{file} 						= 0;
	
	$GV->{FilesInfo}->{binary_file} 				= 0;
	$GV->{FilesInfo}->{text_file} 					= 0;
	$GV->{FilesInfo}->{text_sourcecode_file} 		= 0;
	$GV->{FilesInfo}->{text_html_file} 				= 0;
	$GV->{FilesInfo}->{text_configure_file}			= 0;
	$GV->{FilesInfo}->{text_other_file} 			= 0;

	$GV->{FilesInfo}->{binary_file_size} 			= 0;
	$GV->{FilesInfo}->{text_file_size} 				= 0;
	$GV->{FilesInfo}->{text_sourcecode_file_size} 	= 0;
	$GV->{FilesInfo}->{text_html_file_size} 		= 0;
	$GV->{FilesInfo}->{text_configure_file_size} 	= 0;
	$GV->{FilesInfo}->{text_other_file_size} 		= 0;	
		
	$GV->{FilesInfo}->{text_sourcecode_file_lines} 	= 0;
	$GV->{FilesInfo}->{text_html_file_lines} 		= 0;
	$GV->{FilesInfo}->{text_configure_file_lines} 	= 0;
	$GV->{FilesInfo}->{text_other_file_lines} 		= 0;	
	
	$GV->{FilesInfo}->{image_file} 					= 0;
	$GV->{FilesInfo}->{voice_vedio_file} 			= 0;
	$GV->{FilesInfo}->{no_ext_file} 				= 0;

	$GV->{FilesInfo}->{file_ext_distribute} 		= {};
	
	initDistributionData("text_file_lines_distribute", "lines");
	initDistributionData("file_size_distribute", "size");
	initDistributionData("text_file_size_distribute", "size");
	initDistributionData("binary_file_size_distribute", "size");		
}

sub set_file_lines_size($$$) {
	my $file = $_[0];
	my $isText = $_[1];
	my $fileInfo = $_[2];	
	
	my $lines = $fileInfo->{lines};
	my $size = $fileInfo->{size} / 1000;
	if ($isText) {
		$GV->{FilesInfo}->{all_file_total_size} += $size;
		$GV->{FilesInfo}->{text_file_size} += $size;
		$GV->{FilesInfo}->{all_text_file_total_lines} += $lines;
		
		set_file_info_scale("lines", "text_file_lines_distribute", $lines);
		set_file_info_scale("size", "text_file_size_distribute", $size);
	} else {
		$GV->{FilesInfo}->{all_file_total_size} += $size;
		$GV->{FilesInfo}->{binary_file_size} += $size;
		set_file_info_scale("size", "binary_file_size_distribute", $size);
	}
	
	set_file_info_scale("size", "file_size_distribute", $size);
}

sub obtain_file_ext_info($$$) {
	my $file = $_[0];
	my $isText = $_[1];
	my $info = $_[2];
	my $size = $info->{size} / 1000;
	if ($file =~ m/^.*[\/\\]([^\/\\]+)$/) {
		my $fileName = $1;
		my $name = "";
		my $ext = "";
		if ($fileName =~ m/(.*)\.([^\.]+)/i) {
			$name = $1;	
			$ext = $2;
			
	        if (!defined($GV->{FilesInfo}->{file_ext_distribute}->{$ext})) {
	            $GV->{FilesInfo}->{file_ext_distribute}->{$ext} = 1;
	        } else {
	        	$GV->{FilesInfo}->{file_ext_distribute}->{$ext} ++;
	        }
	        		
			if ($isText) {
				if ($GV->{Langs_Info}->{code}->{ext} =~ m/(^|\s)$ext($|\s)/) {
					$GV->{FilesInfo}->{text_sourcecode_file} ++;
					$GV->{FilesInfo}->{text_sourcecode_file_lines} += $info->{lines};
					$GV->{FilesInfo}->{text_sourcecode_file_size} += $size;
				} elsif ($GV->{Langs_Info}->{html}->{ext} =~ /(^|\s)$ext($|\s)/) {
					$GV->{FilesInfo}->{text_html_file} ++;
					$GV->{FilesInfo}->{text_html_file_lines} += $info->{lines};
					$GV->{FilesInfo}->{text_html_file_size} += $size;
				} elsif ($GV->{Langs_Info}->{configure}->{ext} =~ /(^|\s)$ext($|\s)/) {
					$GV->{FilesInfo}->{text_configure_file} ++;
					$GV->{FilesInfo}->{text_configure_file_lines} += $info->{lines};
					$GV->{FilesInfo}->{text_configure_file_size} += $size;
				} else {
					$GV->{FilesInfo}->{text_other_file} ++;
					$GV->{FilesInfo}->{text_other_file_lines} += $info->{lines};
					$GV->{FilesInfo}->{text_other_file_size} += $size;
				}				
			} else {
				if ($ext =~ m/(gif|jpg|jpeg|png|bmp)/i) {
					$GV->{FilesInfo}->{image_file} ++;
				}
				
				if ($ext =~ m/(mp3|mp4|avi|mov|mepg|mpg|rm)/i) {
					$GV->{FilesInfo}->{voice_vedio_file} ++;
				}				
			}
		} else {
			$name = $file;
			$ext = "";
			$GV->{FilesInfo}->{no_ext_file} ++;
			if ($isText) {
				$GV->{FilesInfo}->{text_other_file_lines} += $info->{lines};
				$GV->{FilesInfo}->{text_other_file_size} += $size;
			}				
		}
	}	
	
}

sub getDef($) {
	my $def = $_[0];
	
	if ($def =~ m/\[(\d+),(\d*)\)/) {
		my $vL = $1;
		my $vR = $2;
		if ($vR eq "") {
			$vR = 99999999;	
		}
		return [$vL, $vR];
	}
	
	return undef;
}

sub set_file_info_scale($$$) {
	my $infoType = $_[0];
	my $distributeKey = $_[1];
	my $data = $_[2];
	
	my $DEF = $infoType eq "size" ? $GV->{DEF}->{SIZE_DISTRIBUTE} : $GV->{DEF}->{LINE_DISTRIBUTE};
	my $CNT = $#{$DEF} + 1;
	for (my $i = 0; $i < $CNT; $i++) {
		my $itemKey = $DEF->[$i];
		
		my $itemKeyInfo = getDef($itemKey);
		if (!defined($itemKeyInfo)) {
			return;
		}
				
		if ($data >= $itemKeyInfo->[0] && $data < $itemKeyInfo->[1]) {
			if (defined($GV->{FilesInfo}->{$distributeKey}->{$itemKey})) {
				$GV->{FilesInfo}->{$distributeKey}->{$itemKey} ++;
			} else {
				$GV->{FilesInfo}->{$distributeKey}->{$itemKey} = 1;
			}
		} 
	}	
}
