###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
###################################################################################################
package RTP::Webmerge::Watchdog;
###################################################################################################
# maybe improve child handling, atm we leave zoombies
# when the mother process gets killed hard by SIGKILL
# use Linux::Prctl; prctl(PR_SET_PDEATHSIG, SIGHUP);
###################################################################################################

use Carp;
use strict;
use warnings;

###################################################################################################

# define our version string
BEGIN { $RTP::Webmerge::Watcher::VERSION = "0.9.0" }

# load exporter and inherit from it
BEGIN { use Exporter qw(); our @ISA = qw(Exporter) }

# define our functions to be exported
BEGIN { our @EXPORT = qw(watchdog); }

###################################################################################################

# load fork queue
use Fork::Queue qw();

# load function from core module
use List::MoreUtils qw(uniq);

# load core webmerge path functions
use RTP::Webmerge::Path qw(check_path exportURI);

# load merge function to call on file change
use RTP::Webmerge::Merge qw(merge);

###################################################################################################

use RTP::Webmerge::Merge;

###################################################################################################

# declare package variables
my ($child_pid, $mother_pid);

###################################################################################################

# watch for file changes
# pass them to our child
sub mother ($$$$$)
{

	# get input variables
	my ($config, $queue, $blocks, $path2id, $id2path) = @_;

	# try to load the watch module conditional
	unless (eval { require Filesys::Notify::Simple; 1 })
	{ die "module Filesys::Notify::Simple not found"; }

	# create the watcher object on all filepaths
	my $watcher = Filesys::Notify::Simple->new([keys %{$path2id}]);

	# print all filenames?
	if ($config->{'debug'})
	{
		print '#' x 78, "\n";
		print join("\n",
		        map { substr($_, -60) }
		          sort keys %{$path2id});
		print "\n";
	}

	# print delimiter line
	print '#' x 78, "\n";

	# print a debug message to the console
	print "Started watchdog, waiting for file changes ...\n";

	# print delimiter line
	print '#' x 78, "\n";

	# go into endless loop
	while (1)
	{

		# watch for file changes
		# this will block forever
		$watcher->wait(sub
		{

			# get all file events
			for my $event (@_)
			{
				# get the normalized path string
				my $path = check_path($event->{path});
				# enqueue our merge block key (string) to child
				$queue->enqueue($path2id->{$path});

			}
			# EO all events

		});
		# EO wait for watcher

	};
	# EO endless loop

};
# EO sub mother

###################################################################################################

# process passed items
sub child ($$$$$)
{

	# store mother pid
	$child_pid = $$;

	# get input variables
	my ($config, $queue, $blocks, $path2id, $id2path) = @_;

	# local queue
	my (@queue);

	# go into endless loop
	while (1)
	{

		# check if we have something to
		# dequeue in the next seconds
		if ($queue->can_dequeue(0.5))
		{

			# dequeue a key from notifier
			my $item = $queue->dequeue();

			# wait for exit command
			exit if $item eq "stop";

			# push the real hash to the queue
			push(@queue, $item);

			# make the queue unique
			@queue = uniq @queue;

		}
		# nothing to dequeue, idle
		else
		{

			next if scalar(@queue) == 0;

			# print a debug message to the console about changed files
			print "file changed: ", exportURI($id2path->{$_}), "\n" foreach (@queue);

			# print delimiter line if something to do
			print '#' x 78, "\n";

			# resolve to merge blocks and remove duplicates
			my @todo = uniq map { @{$blocks->[$_]} } @queue;

			# process each merge block
			while (my $merge = shift @todo)
			{

				# get some vars from hash
				my $type = $merge->{'type'};

				# create new config scope
				my $scope = $config->stage;

				# re-load the config for this block
				$config->apply($merge->{'_conf'})->finalize;

				# now dispatch to merge this entry in eval
				eval { $merger{$type}->($config, $merge); };

				# check if eval had an error
				print $@ if $@;

			}
			# EO if can dequeue

			# reset atomic operations
			# this will commit all changes
			$config->{'atomic'} = {};

			# delete all temporarily created files
			foreach (@{$config->{'temps'} || []})
			{ unlink $_ if -e $_; }

			# reset temporarily files
			$config->{'temps'} = [];

			# ring the bell
			print "\a";
			# clear queue
			undef @queue;
			# print delimiter line
			print '#' x 78, "\n";

		}
		# EO can dequeue

	}
	# EO endless loop

};
# EO sub child

###################################################################################################

# main watchdog function
# forks mother and child
sub watchdog
{

	# get configuration
	my ($config) = @_;

	# files to watch
	my (%files, @files, %path2id, %id2path);

	# get xml settings object
	my $xml = $config->{'xml'};

	# store mother pid
	$mother_pid = $$;

	# do not wait for children
	local $SIG{CHLD} = 'IGNORE';

	# hook into termination signal
	# this is the default sent by kill
	local $SIG{INT} =
	local $SIG{TERM} =
	sub
	{

		# this is the mother process
		if ($mother_pid == $$)
		{
			# print "ABORTED MOTHER PROCESS\n";
			# print "GOING TO KILL $child_pid\n";
			kill 'TERM', $child_pid;
			exit;
		}
		# this is the child process
		elsif ($mother_pid != $$)
		{
			# print "ABORTED CHILD PROCESS\n";
			# print "GOING TO KILL $mother_pid\n";
			kill 'TERM', $mother_pid;
			exit;
		}

	};
	# EO sig term handler

	sub collectMerge
	{

		my ($config, $xml, $files, $type) = @_;

		my $scope = $config->scope($xml);

		# get nodes to process
		foreach my $item
		(
			([ 'js', $xml->{'js'} || [] ]),
			([ 'css', $xml->{'css'} || [] ]),
			([ 'block', $xml->{'block'} || [] ]),
			([ 'merge', $xml->{'merge'} || [] ]),
			([ 'prepare', $xml->{'prepare'} || [] ]),
			([ 'headinc', $xml->{'headinc'} || [] ]),
			([ 'feature', $xml->{'feature'} || [] ]),
			([ 'embedder', $xml->{'embedder'} || [] ]),
			([ 'optimize', $xml->{'optimize'} || [] ]),
		)
		{

			# get variables from item
			my ($type, $nodes) = @{$item};

			# loop from behind so we can splice items out
			for (my $i = $#{$nodes}; $i != -1; -- $i)
			{
				# setup blocks recursively
				collectMerge($config, $nodes->[$i], $files, $type);
			}

		}
		# EO each item

		# check if type is a merger
		if (exists $merger{$type})
		{

			# attach some variables
			$xml->{'type'} = $type;
			# $xml->{'block'} = $block;

			# loop all input elements to watch for
			foreach my $input (@{$xml->{'input'} || []})
			{

				# resolve the input path
				my $path = check_path($input->{'path'});

				# create array by filepath if it does not exist
				$files->{$path} = [] unless exists $files->{$path};

				# push merge block to this path
				push(@{$files->{$path}}, $xml);

				# make the merge blocks unique for path
				@{$files->{$path}} = uniq @{$files->{$path}};

			}
			# EO each input

		}
		# EO if is merger

	}
	# EO sub collectMerge

	collectMerge($config, $xml, \%files, 'xml');

	# create file array and lookup index
	foreach my $path (keys %files)
	{
		# define the lookup index
		$path2id{$path} = scalar(@files);
		$id2path{$path2id{$path}} = $path;
		# add merge blocks by index
		push (@files, $files{$path});
	}
	# EO each file path

	# create a new queue object
	# used to pass commands around
	my $queue = Fork::Queue->new();

	# start child process
	if ($child_pid = fork())
	{ mother($config, $queue, \@files, \%path2id, \%id2path); }
	else { child($config, $queue, \@files, \%path2id, \%id2path); }

}
# EO sub watchdog

###################################################################################################

END
{
	if ($mother_pid && $mother_pid == $$)
	{
		# make sure child is terminated
		kill 'TERM', $child_pid if $child_pid;
	}
	elsif ($mother_pid && $mother_pid != $$)
	{
		# make sure mother is terminated
		kill 'TERM', $mother_pid if $mother_pid;
	}
}

###################################################################################################
###################################################################################################
1;