################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::Runner::Watchdog;
################################################################################

use strict;
use warnings;

###################################################################################################

# load fork queue
use Fork::Queue qw();

# load function from core module
use List::MoreUtils qw(uniq);

# load core webmerge path functions
# use RTP::Webmerge::Path qw(check_path exportURI);

# load merge function to call on file change
# use RTP::Webmerge::Merge qw(merge);

###################################################################################################

# use RTP::Webmerge::Merge qw(%reader %merger);

###################################################################################################

# declare package variables
my ($child_pid, $mother_pid);

###################################################################################################

# watch for file changes
# pass them to our child
sub mother ($$$$$)
{

print "Hello mother\n";

	# get input variables
	my ($config, $queue, $blocks, $path2id, $id2path) = @_;

	# try to load the watch module conditional
	unless (eval { require Filesys::Notify::Simple; 1 })
	{ die "module Filesys::Notify::Simple not found"; }
print "Mother creates ", keys %{$path2id}, "\n";
	# create the watcher object on all filepaths
	my $watcher = Filesys::Notify::Simple->new([keys %{$path2id}]);

	# print all filenames?
	if ($config->{'debug'})
	{
		print '=' x 78, "\n";
		print join("\n",
		        map { substr($_, - 76) }
		          sort keys %{$path2id});
		print "\n";
	}

	# print delimiter line
	print '=' x 78, "\n";

	# print a debug message to the console
	print "Started watchdog, waiting for file changes ...\n";

	# print delimiter line
	print '=' x 78, "\n";

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
				my $path = $event->{path};
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
print "Hello child\n";

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
		# nothing to dequeue, we waited 0.5 seconds
		# maybe we have something in our to do list
		else
		{

			# count errors
			my $beeps = 1;

			# do nothing of queue is empty
			next if scalar(@queue) == 0;

			# print a debug message to the console about changed files
			print "file changed: ", ($id2path->{$_}), "\n" foreach (@queue);

			# reset merge cache
			%{$config->{'merged'}} = ();

			# resolve to merge blocks and remove duplicates
			my @todo = uniq map { @{$blocks->[$_]} } @queue;

			# process each merge block
			while (my $merge = shift @todo)
			{

				# get some vars from hash
				my $type = $merge->{'type'};

$merge->execute;

				# create new config scope
#				my $scope = $config->stage;

				# re-load the config for this block
#				$config->apply($merge->{'_conf'})->finalize;

				# check if type is disabled by config
#				next unless ($config->{$type});
				# check if merge is disabled by config
#				next unless ($config->{'merge'});

				# call the current step in eval mode
				# do not abort process if something goes wrong
#				eval { main::merge($config, $merge, $type); };

				# check if eval had an error
#				print $@ if $@; $beeps ++ if $@;

			}
			# EO if can dequeue

			# call the finish step last
			# this can copy and create files
#			main::process($config, $config->{'xml'}, 'finish');

			# call headinc function to generate headers
			# these can be included as standalone files
			# they have includes for all the css and js files
#			main::process($config, $config->{'xml'}, 'headinc');

			# call embedder to create standalone embedder code
			# this code will sniff the environment to choose
			# the correct headinc to be included in the html
#			main::process($config, $config->{'xml'}, 'embedder');

			# reset atomic operations
			# this will commit all changes
#			$config->{'atomic'} = {};

			# delete all temporarily created files
#			foreach (@{$config->{'temps'} || []})
#			{ unlink $_ if -e $_; }

			# reset temporarily files
#			$config->{'temps'} = [];

			# ring the bell
			print "\a" x ($beeps);
			# clear queue
			undef @queue;
			# print delimiter line
			print '=' x 78, "\n";

		}
		# EO can dequeue

	}
	# EO endless loop

};
# EO sub child

################################################################################
# implement watchdog
################################################################################

sub watchdog
{

	my ($node) = @_;

	return unless $node->option('watchdog');

	# variables
	my @files;
	my %files;
	my $config;
	my %path2id;
	my %id2path;

	foreach my $block
	(
		$node->collect('js'),
		$node->collect('css')
	) {
		# collect all inputs for this block
		foreach my $input ($block->collect('input'))
		{
			# read, resolve imports and close
			$input->read; $input->close;
			# add input file to watched files
			if (exists $files{$input->path})
			{ push @{$files{$input->path}}, $block; }
			else { $files{$input->path} = [ $block ]; }
			# collect further resolved includes
			foreach my $file ($input->collect('file'))
			{
				# read, resolve imports and close
				$file->read; $file->close;
				# add input file to watched files
				if (exists $files{$file->path})
				{ push @{$files{$file->path}}, $block; }
				else { $files{$file->path} = [ $block ]; }
			}
		}
	}

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

################################################################################
# register our tool within the main module
################################################################################

OCBNET::Webmerge::Runner::register('watchdog', \&watchdog, - 20, 0);

################################################################################
################################################################################
1;
