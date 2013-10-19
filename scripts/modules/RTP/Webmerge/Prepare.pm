###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
###################################################################################################
package RTP::Webmerge::Prepare;
###################################################################################################

use Carp;
use strict;
use warnings;

###################################################################################################

# define our version string
BEGIN { $RTP::Webmerge::Prepare::VERSION = "0.9.0" }

# load exporter and inherit from it
BEGIN { use Exporter qw(); our @ISA = qw(Exporter) }

# define our functions to be exported
BEGIN { our @EXPORT = qw(prepare); }

###################################################################################################

# load core io module
use RTP::Webmerge::IO;
# load core path module
use RTP::Webmerge::Path;

###################################################################################################

# prepare various stuff
# only mkdir is implemented
sub prepare
{

	# get input variables
	my ($config, $prepare) = @_;

	# should we commit filesystem changes?
	my $commit = $prepare->{'commit'} || 0;

	# commit all changes to the filesystem if configured
	$config->{'atomic'} = {} if $commit =~ m/^\s*(?:bo|be)/i;

	# do not process if disabled attribute is given and set to true
	unless ($prepare->{'disabled'} && lc $prepare->{'disabled'} eq 'true')
	{

		# process all directories to create
		foreach my $mkdir (@{$prepare->{'mkdir'} || []})
		{

			# skip this if entry has been disabled
			next if ($prepare->{'disabled'} && lc $prepare->{'disabled'} eq 'true');

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
		foreach my $copy (@{$prepare->{'copy'} || []})
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
# EO sub prepare

###################################################################################################
###################################################################################################
1;
