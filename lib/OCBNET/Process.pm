################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
# Takes a list of calls to execute and
# a number of jobs to run in parallel.
################################################################################
package OCBNET::Process;
################################################################################

use strict;
use warnings;

################################################################################

# declare for exporter
our (@EXPORT, @EXPORT_OK);

# load exporter and inherit from it
BEGIN { use Exporter qw(); our @ISA = qw(Exporter); }

# define our functions that will be exported
BEGIN { push @EXPORT, qw(process) }

################################################################################
# define main module
################################################################################
use Cwd qw(getcwd);
use File::Which qw(which);
################################################################################

sub new
{

	# get input arguments
	my ($pkg, $cmd, %opt) = @_;

	# use file which
	$cmd = which $cmd;

	# create object
	my $process = {

		'cmd' => $cmd,
		'cwd' => getcwd,
		'args' => '',
		%opt

	};

	# bless into class and return
	return bless $process, $pkg;
}

################################################################################
# accessor methods
################################################################################

sub cmd { $_[0]->{'cmd'} }
sub cwd { $_[0]->{'cwd'} }
sub pid { $_[0]->{'pid'} }
sub args { $_[0]->{'args'} }

################################################################################

sub cb { $_[0]->{'cb'} || sub { } }

################################################################################
# load the correct implementation
################################################################################

BEGIN
{
	if ($^O eq 'MSWin32')
	{
		require OCBNET::Process::Win32;
		OCBNET::Process::Win32->import;
	}
	else
	{
		require OCBNET::Process::Unix;
		OCBNET::Process::Unix->import;
	}
}

################################################################################
# static interface
################################################################################

sub process
{

	# get input arguments
	my ($processes, $jobs, $idle) = @_;

	# default to two jobs
	$jobs = 2 unless $jobs;

	# force to array if we only have a single command
	my @work = ref $processes eq 'ARRAY' ?
	           @{$processes} : $processes;

	# resolve squences
	@work = grep { defined $_ } map
	{

		# put array into sequence
		if (ref $_ eq 'ARRAY')
		{
			for (my $i = 0; $i < scalar(@{$_}) - 1; $i++)
			{ $_->[$i]->{'next'} = $_->[$i + 1]; }
			$_->[0]
		}
		# single process
		else { $_ }

	} @work;

	# running jobs
	my @jobs;

	# loop until everything is done
	while (scalar @work || scalar @jobs)
	{

		# put more processes to work
		while (scalar @jobs < $jobs)
		{
			# exit if no more processes
			last unless scalar @work;
			# get next process from list
			my $process = shift @work;
			# add process to jobs

			push @jobs, $process;
			# start processing
			$process->start;
		}

		# check if jobs are done
		foreach my $job (@jobs)
		{
			# check if job has finished
			if (my $rv = $job->wait(0))
			{
				# make room for work to be done
				@jobs = grep { $_ ne $job } @jobs;
				# store return value
				$job->{'rv'} = $rv;
				# run callback
				$job->cb->($rv);
				# do we have another task
				if (exists $job->{'next'})
				{
					# add next task to jobs
					push @jobs, $job->{'next'};
					# start to process task
					$job->{'next'}->start;
				}
			}
		}

		# wait a very short time
		# this is a "pull" implementation
		# therefore we need to query endlessly
		# but we do not want to hog the cpu
		# this might limit the maximum number
		# of processes that can be run per second
		select(undef, undef, undef, 0.001);

		# run idle subroutine if passed
		$idle->(\@jobs, \@work) if $idle;

	}

}

################################################################################
################################################################################
1;

__DATA__

# IDLE_PRIORITY_CLASS
# ABOVE_NORMAL_PRIORITY_CLASS
# NORMAL_PRIORITY_CLASS
# BELOW_NORMAL_PRIORITY_CLASS
# HIGH_PRIORITY_CLASS
# REALTIME_PRIORITY_CLASS

process([

	OCBNET::Process->new('perl', 'args' => q(-e "print \"hello world 1\n\"; sleep 1; print \"end 1\n\";"), 'cb' => \&cb,
		'next' => OCBNET::Process->new('perl', 'args' => q(-e "print \"hello world 2\n\"; sleep 2; print \"end 2\n\";"), 'cb' => \&cb,
			'next' => OCBNET::Process->new('perl', 'args' => q(-e "print \"hello world 3\n\"; sleep 3; print \"end 3\n\";"), 'cb' => \&cb)
		)
	),
	OCBNET::Process->new('perl', 'args' => q(-e "print \"hello world 4\n\"; sleep 4; print \"end 4\n\";"), 'cb' => \&cb,
		'next' => OCBNET::Process->new('perl', 'args' => q(-e "print \"hello world 5\n\"; sleep 5; print \"end 5\n\";"), 'cb' => \&cb,
			'next' => OCBNET::Process->new('perl', 'args' => q(-e "print \"hello world 6\n\"; sleep 6; print \"end 6\n\";"), 'cb' => \&cb)
		)
	),
	OCBNET::Process->new('perl', 'args' => q(-e "print \"hello world 7\n\"; sleep 7; print \"end 7\n\";"), 'cb' => \&cb,
		'next' => OCBNET::Process->new('perl', 'args' => q(-e "print \"hello world 8\n\"; sleep 8; print \"end 8\n\";"), 'cb' => \&cb,
			'next' => OCBNET::Process->new('perl', 'args' => q(-e "print \"hello world 9\n\"; sleep 9; print \"end 9\n\";"), 'cb' => \&cb)
		)
	)
], 3, sub {

	# print "idle\n";

});
