#!/usr/bin/perl -I ./thirds -w
# author: lilong'en(lilongen@163.com)
#
# exist reason:
#   use this process as the fork parent, to minimize memory requirement
#

use strict;
use English;
use Data::Dumper;
use IPC::SysV qw(IPC_PRIVATE S_IRUSR S_IWUSR IPC_CREAT);
use IPC::Semaphore;


sub main();
sub initGV();
sub ifAllChildProcessFinished();
sub showChildProcessesStatus();
sub logInfo($);

my $__DEBUG = 0;

chdir($ARGV[0]);
my $GV = {};

main();

sub initGV() {
	$GV->{DfSliceInfo} = {};
	$GV->{DfSliceInfo}->{DfCmdsCnt} = $ARGV[1];
	$GV->{DfSliceInfo}->{DfCmdsSliceCnt} = $ARGV[2];
	$GV->{DfSliceInfo}->{SliceCmdsCnt} = $ARGV[3];
	$GV->{DfSliceInfo}->{uid} = $ARGV[4];
	$GV->{DfSliceInfo}->{upw} = $ARGV[5];
	
	$GV->{DfCmdsShTpl} 		= "__ccv_df_slice_%d_%d.sh";
	$GV->{DfSliceOutTpl} 	= "__ccv_df_slice_out_%d_%d";
}

sub main() {
	initGV();
	
	$GV->{dfSemaphore} = IPC::Semaphore->new(IPC_PRIVATE, $GV->{DfSliceInfo}->{DfCmdsSliceCnt}, S_IRUSR | S_IWUSR | IPC_CREAT);
	#
	# smaphore value 
	#    0: initial 
	#    1: process started
	#    2: process finished
	#
	$GV->{dfSemaphore}->setall((0) x $GV->{DfSliceInfo}->{DfCmdsSliceCnt});
	
	for (my $i = 0; $i < $GV->{DfSliceInfo}->{DfCmdsSliceCnt}; $i++) {
		my $sh = sprintf($GV->{DfCmdsShTpl}, $GV->{DfSliceInfo}->{DfCmdsSliceCnt}, $i);
		my $pid = fork();
		if (defined($pid)) {
			if ($pid == 0) {#child process
				$GV->{dfSemaphore}->setval($i, 1);
				#system("bash $sh \"$GV->{DfSliceInfo}->{uid}\"  $GV->{DfSliceInfo}->{upw}");
				system("bash $sh");
				$GV->{dfSemaphore}->setval($i, 2);
				
				exit 0;
			} else {#parent process
				logInfo("new child process pid: $pid");
				next;
			}
		} else {
			#create cloned progress failed	
		}
	}
	
	while(1) {
		if ($__DEBUG) {
			showChildProcessesStatus();
		}
		
		if (ifAllChildProcessFinished()) {
			$GV->{dfSemaphore}->remove();
			
			last;
		}
		
		sleep(5);	
	}
	
	logInfo "all child process finished!";
}

sub showChildProcessesStatus() {
	my @semaDf = $GV->{dfSemaphore}->getall();
	print Dumper(@semaDf);
}

sub ifAllChildProcessFinished() {
	for (my $i = 0; $i < $GV->{DfSliceInfo}->{DfCmdsSliceCnt}; $i++) {
		if ($GV->{dfSemaphore}->getval($i) != 2) {
			return 0;
		}
	}
	
	return 1;
}

sub logInfo($) {
	if ($__DEBUG) {
		print $_[0] . "\n";
	}	
}
