###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
###################################################################################################
package RTP::Webmerge;
###################################################################################################

use Carp;
use strict;
use warnings;

###################################################################################################

# load 3rd party module
use File::Which qw(which);

# override core glob (case insensitive)
use File::Glob qw(:globally :nocase bsd_glob);

# define uniq inline (copied from List::MoreUtils)
sub uniq (@) { my %seen = (); grep { not $seen{$_}++ } @_; }

###################################################################################################

# declare local globals
our (%programs, %executables, %processors, @initers, @checkers);

###################################################################################################

# define our version string
BEGIN { $RTP::Webmerge::VERSION = "0.70" }

# load exporter and inherit from it
BEGIN { use Exporter qw(); our @ISA = qw(Exporter) }

# define our functions to be exported
BEGIN { our @EXPORT = qw(initConfig checkConfig callProgram runProgram callProcessor); }

# define our functions that can be exported
BEGIN { our @EXPORT_OK = qw(%programs %executables %processors @initers @checkers); }

###################################################################################################

# make absolute paths (file may not exist yet)
use RTP::Webmerge::Path qw(res_path);

# collect all includes
# return result hash
sub collectOutputs
{

	# get input variables
	my ($config) = @_;

	# assertion that we only run once
	return if (exists $config->{'outpaths'});

	# get local variables from config
	my $paths = $config->{'paths'};
	my $doctype = $config->{'doctype'};

	# get local arrays from loaded xml file
	my $merges = $config->{'xml'}->{'merge'} || [];
	my $headers = $config->{'xml'}->{'header'} || [];

	# local variable
	$config->{'outpaths'} = {};

	# reset webpath after this block (make local)
	local $config->{'webpath'} = $config->{'webpath'};

	foreach my $block (@{$merges || []})
	{

		# change directory (restore previous state after this block)
		my $dir = RTP::Webmerge::Path->chdir($block->{'chdir'});

		# process all types
		foreach my $type ('css', 'js')
		{

			# process all include entries
			foreach my $merge (map { @{$_->{$type} || []} } @{$merges || {} })
			{

				# change directory (restore previous state after this block)
				my $dir = RTP::Webmerge::Path->chdir($merge->{'chdir'});

				# get id of this merge
				my $id = $merge->{'id'};

				# create and assign info hash for this merge
				my $info = $config->{'outpaths'}->{$id} = { 'out' => {} };

				# store some important attributes
				$info->{'id'} = $merge->{'id'};
				$info->{'type'} = $type;
				$info->{'media'} = $merge->{'media'};
				$info->{'disabled'} = $merge->{'disabled'} || 'false';

				# process all files to be written for this merge
				foreach my $output (@{$merge->{'output'} || []})
				{

					# get the class name for this output
					my $class = $output->{'class'} || 'default';

					# assert that the target has been given for this output
					die 'no target given for output' unless $output->{'target'};

					# create another sub hash for this class if needed
					$info->{'out'}->{$class} = {} unless exists $info->{'out'}->{$class};

					# store the filepath for this merge output (by class/target)
					# do not yet check for existence of the path as it may be created later
					$info->{'out'}->{$class}->{$output->{'target'}} = res_path($output->{'path'});

				}
				# EO each output

			}
			# EO each merge

		}
		# EO each type (css/js)

	}

	# return success
	return 1;

}
# EO sub collectOutputs

###################################################################################################

# collect available executables
# add them to the programs hash
sub collectExecutables
{

	my ($config) = @_;

	# do checks every executable
	foreach my $executable (keys %executables)
	{

		# get the bin path and the exec template
		my ($program, $tmpl, $prio) = @{$executables{$executable}};

		# create an array if not yet available
		$programs{$program} = [] unless exists $programs{$program};

		# skip if we have inline function
		if (ref($tmpl) eq 'CODE')
		{
			# finally store the info and found absolute path
			push(@{$programs{$program}}, [$tmpl]);
		}
		# look for external program
		else
		{

			# get name of executable
			my $exec = $executable;

			# remove optional suffix
			$exec =~ s/\[[a-zA-Z]+\]$//;

			# glob finds the executable
			my @files = which($exec) || bsd_glob($exec);

			if (scalar(@files) == 1 && -e $files[0] && -x $files[0] && ! -d $files[0])
			{
				# finally store the info and found absolute path
				push(@{$programs{$program}}, [$tmpl, $files[0], $prio]);
			}

		}

	}
	# EO each executable

	# process all collected programs
	foreach my $program (keys %programs)
	{

		# sort the programs by priority so they can run in given order
		@{$programs{$program}} = sort { $a->[2] - $b->[2] } @{$programs{$program}};

	}
	# EO each program

}
# EO sub collectExecutables

###################################################################################################

# check each program to have
# at least one executable
sub checkPrograms
{

	my ($config) = @_;

	# do checks every executable
	foreach my $program (keys %programs)
	{
		if (scalar(@{$programs{$program}}) == 0)
		{
			# we should tell te user which programs
			# he could install to solve to problem
			# for gifopt this would be gifsicle
			die "program $program has no executables";
		}
	}
	# EO each program

}
# EO sub checkPrograms

###################################################################################################

sub checkProcesses
{

	# to be implemented

}
# EO sub checkProcesses

###################################################################################################

sub initConfig
{

	# get input variables
	my ($config) = @_;

	# declare lexical variable
	my %getopts;

	# process all registered initers
	foreach my $initer (@initers)
	{

		# extend getopts by result from initer
		%getopts = (%getopts, $initer->($config));

	}
	# EO each initers

	# return the hash as list
	return %getopts;

}
# EO sub initConfig

###################################################################################################

# check everything
sub checkConfig
{

	# get input variables
	my ($config) = @_;

	# only do the config check once
	return if $config->{'checked'};

	# process all registered checkers
	foreach my $checker (@checkers)
	{
		# just call the sub
		$checker->($config)
	}
	# EO each checkers

	# collect available executables, some programs
	# may can use multiple executables (like pngopt)
	collectExecutables($config);

	# check if programs are available
	# each needs at least one executable
	checkPrograms($config);

	# only check the config once
	$config->{'checked'} = 1;

	# collect output information
	collectOutputs($config);

	# return success
	return $config;

}
# EO sub checkConfig

###################################################################################################

# call a program with a file
# also accept files array ref
sub runProgram ($$$$;$)
{

	# get input variables
	my ($config, $program, $files, $pattern, $options) = @_;

	# get the collected executables
	my $executables = $programs{$program};

	# check if we requested a valid program (typo?)
	die "program $program not defined" unless $executables;

	# process all executables found for this program
	for (my $i = 0; $i < scalar(@{$executables}); $i++)
	{

		# get options for executable and absolute path
		my ($tmpl, $executable) = @{$executables->[$i]};

		if (ref($tmpl) eq 'CODE')
		{

			# print a status message for execution
			printf "call %s on %s (%d files)\n",
				$program, $pattern, scalar(@{$files});

			# process file or all files
			foreach my $file (@{$files || [$files]})
			{

				# execute the function
				my $rv = $tmpl->($file, $config, $options);

				# give a warning if the executable returned an error
				warn "$program execution did not complete successfully\n"
					. " # " . join(' ', $program, $file) unless $rv;

			}
			# EO each file

		}
		else
		{

			# print a status message for execution
			printf "exec %s on %s (%d files)\n",
				$executable, $pattern, scalar(@{$files});

			# process file or all files
			foreach my $file (@{$files || [$files]})
			{

				# execute the executable (sprintf filename into commands)
				my $rv = system join(' ', $executable, sprintf($tmpl, $file, $file));

				# give a warning if the executable returned an error
				warn "executable execution did not complete successfully\n"
					. " # " . join(' ', $executable, sprintf($tmpl, $file, $file)) if $rv;

			}
			# EO each file

		}

	}
	# EO each program executable

}
# EO sub runProgram

###################################################################################################

# childrens
my @pids;

# call a program with a file
# also accept files array ref
sub callProgram ($$$$;$)
{

	# get input variables
	my ($config, $program, $files, $pattern, $options) = @_;

	# make array items unqiue
	@{$files} = uniq(@{$files});

	# do not run in parallel on windows
	# code has been developed for linux
	if ($^O eq "MSWin32")
	{

			# run the program with a set of all files
			runProgram($config, $program, $files, $pattern, $options);

	}
	else
	{

		# children files
		my (@files);

		# create an array with all indexes
		my @indexes = (0 .. $#{$files});

		# return immediately if nothing to do
		return if scalar @indexes == 0;

		# loop all jobs to distribute files
		for(my $j = 0; $j < $config->{'jobs'}; $j ++)
		{
			# distribute files accross all available jobs
			$files[$j] = [ @{$files}[grep { $_ % $config->{'jobs'} == $j } @indexes] ];
		}

		# do not wait for children
		# local $SIG{CHLD} = 'IGNORE';

		my $parent_pid = $$;

		# hook into termination signal
		# this is the default sent by kill
		local $SIG{INT} =
		local $SIG{TERM} =
		sub
		{

			# print a debug message
			if ($parent_pid == $$)
			{
				print "\n";
				print "ABORT EXTERNAL PROGRAM \n";
				print "WAITING FOR CHILDREN\n";
			}

			# wait for all jobs to finish
			foreach (@pids)
			{
				next unless $_;
				kill 'TERM', $_;
				waitpid ($_, 0);
				$_ = undef;
			}

			# exit now
			exit;

		};

		# loop all jobs to start commands on files
		for(my $j = 0; $j < $config->{'jobs'}; $j ++)
		{

			# fork a child
			my $pid = fork();

			# os error
			if (not defined $pid)
			{
				die "resources not avilable for fork";
			}
			# this is the child
			elsif ($pid == 0)
			{

				# set process group
				setpgrp(0,0);

				# run the program with a subset of files
				runProgram($config, $program, $files[$j], $pattern, $options);

				# stop child
				exit(0);

			}
			# this is the parrent
			else
			{
				# add child pid
				push @pids, $pid;
			}

		}
		# EO forking jobs

		# wait for all jobs to finish
		foreach (@pids)
		{
			next unless $_;
			waitpid ($_, 0);
			$_ = undef;
		}

	}

}
# EO sub callProgram

###################################################################################################

# make sure to kill children
END
{
	# wait for all jobs to finish
	foreach (@pids)
	{
		next unless $_;
		kill ($_);
		$_ = undef;
	}
}
# EO END Block

###################################################################################################

sub callProcessor
{

	# get input variables
	my ($processors, $data, $config, $item) = @_;

	# do nothing on void input
	return unless $processors;

	# call each processor (split string by whitespace)
	foreach my $processor (split(/\s+/, $processors))
	{

		# assert that the selected processor is available
		die "unknown processor $processor" unless $processors{$processor};

		# call the processor with the given data to alter
		$processors{$processor}->($data, $config, $item) or die "processor failed";

	}
	# EO each processor

}
# EO sub callProcessor

###################################################################################################
###################################################################################################
1;