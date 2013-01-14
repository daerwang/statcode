sub storeCmtInfo($);
sub setCmtFileDiffOffset($);
sub generateMoreInfos($);
my $CFG			= "example.sf.xml";
my $MID			= "winscp.winscp3";
#parse_command_line();
#my $pms 		= $ccvUtil->loadFile($assistor->get_specified_operate_file("PMS"));
my $pms = {};
    #$GV->{LogFile}      = $assistor->get_repository_log_cmd_output_file($pms->{cmt}, $GV->{ModuleInfo}->{log});
	$GV->{LogFile}      = '2';
        'authorsCnt' => 0,
        'cmtsCnt'  => 0   
	$GV->{Cmts} = [];
    $GV->{CmtsInfo}     = {}; 
    $GV->{AuthorsInfo}    = {};
    $GV->{FilesInfo}    = {};
	my $LOG = undef;
	if (!open($LOG, $GV->{LogFile})) {

    my $lineCnter = 0;
	my $cmtCnter = 0;
    my $flags = {}; resetFlags($flags);
    my $cmtInfo;
	my $cmtFileInfo;
    my $line;
    my $prevLine;
	while (!eof($LOG)) {
		$line = <$LOG>;
		$lineCnter++;
		$prevLine = $line;
		#print $line;
#git log -u --date=iso --numstat
#Date:   2013-01-08 01:14:01 -0800
#-	-	docs/ins.vsd
#diff --git a/docs/ins.vsd b/docs/ins.vsd
#new file mode 100755
#index 0000000..b68ad1d
#Binary files /dev/null and b/docs/ins.vsd differ
#diff --git a/draw.graph.pl b/draw.graph.pl
#new file mode 100755
#index 0000000..756ea35
#--- /dev/null
#+++ b/draw.graph.pl
#@@ -0,0 +1,57 @@
#+#!/usr/bin/perl -I ./thirds -w
#+# author: lilong'en(lilongen@163.com)
#+# date:   04/05/2010

#commit => m/^commit ([\d\w]+)$/,
#author => m/^Author (.+) <(.*)>$/,
#date => m/^Date:\s+([\d\-]+) ([\d:]+) \-(\d+)$/,
#comment => m/^(\s){4}(.+)$/,
#fileLOC => m/^([\d\-]+) ([\d\-]+) (.+)$/,
#fileDiffHeader => m/^diff --git a\/(.+) b\/(.+)$/,
#changeMode => m/^(old mode|new mode|deleted file mode|new file mode|copy from|copy to|rename from|rename to) (.+)$/,
#similarity => m/^(similarity index) (.+)$/,
#dissimilarity => m/^(dissimilarity index) (.+)$/,
#changeIndexAndMode => m/^index (\w+)\.\.(\w+) (.+)$/,
#oldMode => m/^old mode(.+)$/,
#newMode => m/^new mode(.+)$/

		#print Dumper($flags);

		if ($flags->{doCmtReTest}) {
			if ($line =~ m/^commit ([\d\w]+)$/) {
print "cmtFound: $1 \n";
				$cmtCnter++;
				if ($cmtCnter > 1) {
					setCmtFileDiffOffset({
						flags => $flags,
						LOG => $LOG,
						line => $line,
						cmtInfo => $cmtInfo
					});
					
					storeCmtInfo($cmtInfo);
					resetFlags($flags);
				}
				
				$flags->{doCmtReTest} = 0;
				$flags->{cmtFound} = 1;
				
				$cmtInfo = {};
				$cmtInfo->{cmt} = $1;
				next;
		if ($flags->{cmtFound} && $line =~  m/^Author: (.+) <(.*)>$/) {
print "authorFound: $1 \n";		
			$flags->{authorFound} = 1;
			$flags->{cmtFound} = 0;
			$cmtInfo->{author} = $1;
			$cmtInfo->{email} = $2;
		if ($flags->{authorFound} && $line =~ m/^Date:\s+([\d\-]+) ([\d:]+) \-(\d+)$/) {
print "dateFound: $1 \n";			
			$flags->{dateFound} = 1;
			$flags->{authorFound} = 0;
			$cmtInfo->{date} = $1;
			$cmtInfo->{time} = $2;
			$cmtInfo->{timeZone} = $3;
		if ($flags->{dateFound} && $line =~ m/^$/) {
print "commentBeginFound:\n";		
			$flags->{commentBeginFound} = 1;
			$flags->{dateFound} = 0;
			$cmtInfo->{comment} = '';
		if ($flags->{commentBeginFound}) {

			if ($line =~ m/^$/) {
print "cmtFilesBeginFound: \n";			
				$flags->{cmtFilesBeginFound} = 1;
				$flags->{commentBeginFound} = 0;
				$cmtInfo->{arrayFiles} = [];
				$cmtInfo->{hashFiles} = {};
			} else {
				# m/^(\s){4}(.+)$/
print "comment: $line\n";		
				$cmtInfo->{comment} .= substr($line, 4);
			}
		
		if ($flags->{cmtFilesBeginFound}) {
			if ($line =~ m/^([\d\-]+)\t([\d\-]+)\t(.+)$/) {
				$cmtFileInfo = {};
				$cmtFileInfo->{file} = $3;
print "cmt changed file:  $3\n";				
				$cmtFileInfo->{addLines} = $1;
				$cmtFileInfo->{delLines} = $2;
				$cmtFileInfo->{cmt} = $cmtInfo->{cmt};
				push(@{$cmtInfo->{arrayFiles}}, $cmtFileInfo->{file});
				$cmtInfo->{hashFiles}->{$cmtFileInfo->{file}} = $cmtFileInfo;
			} else {
				$flags->{filesDiffBegin} = 1;
print "filesDiffBegin:  \n";				
				$flags->{cmtFilesBeginFound} = 0;
			}
		if ($flags->{filesDiffBegin}) {
			if ($line =~ m/^diff --git a\/(.+) b\/(.+)$/) {
print "diff --git:  \n";			
				 setCmtFileDiffOffset({
					file => $1,
					flags => $flags,
					LOG => $LOG,
					line => $line,
					cmtInfo => $cmtInfo
				});
				$flags->{prevDiffFile} = $1;
				$flags->{doCmtReTest} = 1;
				$flags->{doFileChangeModeTest} = 1;
			} else {
				if ($flags->{doFileChangeModeTest}) {
					my $changeMode = 'normal';
					if ($line =~ m/^(deleted|new) file mode \d+$/) { #this will closely follow "$line =~ m/^diff --git a\/(.+) b\/(.+)$/"
						$changeMode = $1;
					}
					$cmtInfo->{hashFiles}->{$flags->{prevDiffFile}}->{changeMode} = $changeMode;
					$flags->{doFileChangeModeTest} = 0;
				}
	if ($flags->{prevDiffFile}) {
		setCmtFileDiffOffset({
			flags => $flags,
			LOG => $LOG,
			line => undef,
			cmtInfo => $cmtInfo
		});
		storeCmtInfo($cmtInfo);
		resetFlags($flags);
	}

	close($LOG);
	if ($lineCnter == 1) {
		$GV->{Error} = $prevLine;

	#$ccvUtil->dumpFile('git.log.ccv', {
	#    'OverallInfo' => $GV->{OverallInfo},
	#	'AuthorsInfo' => $GV->{AuthorsInfo},
	#	'CmtsInfo'  => $GV->{CmtsInfo},
	#	'FilesInfo'  => $GV->{FilesInfo},
	#	'Error' 	=> $GV->{Error}
	#});
	$assistor->write_file('git.log.ccv', Dumper($GV));
sub storeCmtInfo($) {
	my $cmtInfo = $_[0];
	$GV->{CmtsInfo}->{$cmtInfo->{cmt}} = $cmtInfo;
	
	generateMoreInfos($cmtInfo);
sub generateMoreInfos($) {
	my $cmtInfo = $_[0];
	
	push(@{$GV->{Cmts}}, $cmtInfo->{cmt});
	
	if (!defined($GV->{AuthorsInfo}->{$cmtInfo->{author}})) {
		$GV->{AuthorsInfo}->{$cmtInfo->{author}} = {
			cmtsArray => [],
			files => {}
		};		
	}
	
	my $authorInfo = $GV->{AuthorsInfo}->{$cmtInfo->{author}};
	push(@{$authorInfo->{cmtsArray}}, $cmtInfo->{cmt});
	
	for my $file (keys %{$cmtInfo->{hashFiles}}) {
		if (!defined($authorInfo->{files}->{$file})) {
			$authorInfo->{files}->{$file} = [];
		}
		push(@{$authorInfo->{files}->{$file}}, $cmtInfo->{cmt});

		if (!defined($GV->{FilesInfo}->{$file})) {
			$GV->{FilesInfo}->{$file} = [];
		}
		push(@{$GV->{FilesInfo}->{$file}}, $cmtInfo->{cmt});
sub setCmtFileDiffOffset($) {
	my $po = $_[0];
	my $file 	= $po->{file};
	my $flags 	= $po->{flags};
	my $LOG 	= $po->{LOG};
	my $line 	= $po->{line};
	my $cmtInfo = $po->{cmtInfo};
	if (defined($flags->{prevDiffFile})) {
		if (!defined($line)) {
			$cmtInfo->{hashFiles}->{$flags->{prevDiffFile}}->{offsetE} = tell($LOG);
		} else {
			$cmtInfo->{hashFiles}->{$flags->{prevDiffFile}}->{offsetE} = tell($LOG) - length($line) - 1;
	}

	if (defined($file)) {
		$cmtInfo->{hashFiles}->{$file}->{offsetB} = tell($LOG) - length($line);
sub statIt($) {
	my $user = $_[0];
	if (length($pms->{wids}) > 0) {
		return index(",$pms->{wids},", ",$user,") != -1;
	} else {
		return 1;	
	}
	$flags->{doCmtReTest} = 1;
	$flags->{cmtFound} = 0;
	$flags->{authorFound} = 0;
	$flags->{dateFound} = 0;
	$flags->{commentBeginFound} = 0;
	$flags->{cmtFilesBeginFound} = 0;
	$flags->{filesDiffBegin} = 0;
	$flags->{prevDiffFile} = undef;