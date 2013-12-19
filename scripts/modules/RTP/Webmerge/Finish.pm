###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
###################################################################################################
package RTP::Webmerge::Finish;
###################################################################################################

use Carp;
use strict;
use warnings;

###################################################################################################

# define our version string
BEGIN { $RTP::Webmerge::Finish::VERSION = "0.9.0" }

# load exporter and inherit from it
BEGIN { use Exporter qw(); our @ISA = qw(Exporter) }

# define our functions to be exported
BEGIN { our @EXPORT = qw(finish); }

###################################################################################################

# load core io module
use RTP::Webmerge::IO;
# load core path module
use RTP::Webmerge::Path;

###################################################################################################

# finish various stuff
# only mkdir is implemented
sub finish
{

	# get input variables
	my ($config, $finish) = @_;

	# should we commit filesystem changes?
	my $commit = $finish->{'commit'} || 0;

	# commit all changes to the filesystem if configured
	$config->{'atomic'} = {} if $commit =~ m/^\s*(?:bo|be)/i;

	# do not process if disabled attribute is given and set to true
	unless ($finish->{'disabled'} && lc $finish->{'disabled'} eq 'true')
	{

		# process all directories to create
		foreach my $mkdir (@{$finish->{'mkdir'} || []})
		{

			# skip this if entry has been disabled
			next if ($finish->{'disabled'} && lc $finish->{'disabled'} eq 'true');

			# resolve the path to be created
			my $path = check_path $mkdir->{'path'};

			# allready exists?
			next if -d $path;

			# try to create the given directory and give status messages (abort on error)
			if (mkdir $path) { print "created directory ", exportURI($path), "\n"; }
			else { die "could not create directory ", exportURI($path), ": ", $!; }

		}
		# EO each mkdir

		# process all directories to create
		foreach my $run (@{$finish->{'prerun'} || []})
		{

			my $cmd = $run->{'cmd'};

			my @args = @{$run->{'arg'} || []};

			my $rv = system $cmd, @args;

			print "executing $cmd ", join(" ", @args), "\n";

		}

		# process all directories to create
		foreach my $copy (@{$finish->{'copy'} || []})
		{

			# get path for source and destination
			my $src = check_path $copy->{'src'};
			my $dst = check_path $copy->{'dst'};

			print "copying ", exportURI($src), "\n";

			# check if we do not copy a text file
			my $bin = ($copy->{'text'} || '') ne "true";

			# copy the file binary if text is not set to true
			my $data = readfile($src, $config->{'atomic'}, $bin);
			writefile($dst, $data, $config->{'atomic'}, $bin);

			print " copied to ", exportURI($dst), "\n";

		}
		# EO each copy

	}
	# EO unless disabled

	# commit all changes to the filesystem if configured
	$config->{'atomic'} = {} if $commit =~ m/^\s*(?:bo|af)/i;

}
# EO sub finish

###################################################################################################
###################################################################################################
1;
