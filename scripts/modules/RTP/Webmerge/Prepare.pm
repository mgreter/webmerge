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

		# process prerun script (feature will change)
		foreach my $run (@{$prepare->{'prerun'} || []})
		{

			my $cmd = $run->{'cmd'};

			my @args = @{$run->{'arg'} || []};

			print "executing $cmd ", join(" ", @args), "\n";

			chdir $config->{'directory'} or die "chdir";

			my $rv = system $cmd, @args;

			croak "prerun execution failure" if $?;

		}

		# override core glob (case insensitive)
		use File::Glob qw(:globally :nocase bsd_glob);
		use File::Basename qw (dirname basename);

		my @copy = @{$prepare->{'copy'} || []};

		# process all directories to create
		foreach my $todo (@copy)
		{

			my @todo = ( $todo );

			my $recursive = $todo->{'recursive'} || 0;

			$recursive = 0 if lc $recursive eq 'false';
			$recursive = -1 if lc $recursive eq 'true';


			# get path for source and destination
			my $srcs = check_path $todo->{'src'};
			my $dest = check_path $todo->{'dst'};

			print "copy ", substr(exportURI($srcs), -40),
			      " to ", substr(exportURI($dest), -40);
			print " (recursive)" if !-f $srcs && $recursive;
			print " (directory)" if -d $srcs && !$recursive;
			print " (file)" if -f $srcs;
			print "\n";

			foreach my $copy (@todo)
			{

				my $recursive = $copy->{'recursive'} || 0;

				$recursive = 0 if lc $recursive eq 'false';
				$recursive = -1 if lc $recursive eq 'true';

				# get path for source and destination
				my $srcs = check_path $copy->{'src'};
				my $dest = check_path $copy->{'dst'};

				my $root = $dest;
				my $oldroot = $root;

				# is destination a directory?
				# this test is rubish as it may be false
				# before and true after the operation,
				# and therefore leads to wrong behaviours.

				# we may have multiple inputs, so how would
				# we know how to rename a specific file or dir?
				# so has the destination always to be the base dir?

				# add a special rename task to run afterwards?
				# or differenciate between single and bulk copy?

				# we may also be able to tell if it should be a
				# directory or a file to be renamed, but we may
				# never know if we want to rename a directory!

				my $rebase = $copy->{'rebase'} && $copy->{'rebase'} ne "false";

				# get all sources files via glob
				# this does not yet support recursive
				foreach my $src (bsd_glob($srcs))
				{

					my $tmpl;

					if ($rebase && -d $src)
					{
						$tmpl = basename($oldroot);
						$root = dirname($oldroot);
					}
					elsif (-d $src || -d $oldroot)
					{
						$tmpl = '$(filename)';
						$root = $oldroot;
					}
					else
					{
						$tmpl = basename($oldroot);
						$root = dirname($oldroot);
					}

					my $dst = join('/', $root, $tmpl);

					my %options = (
						'filename' => basename($src)
					);

					# replace destination file place holders
					$dst =~ s/\$\(([^\)]*)\)/$options{lc$1}/egm;

					if (-d $src)
					{

						next unless $recursive;

						mkdir $dst;

						opendir(my $dh, $src) or die "error opendir: $!";

						while (my $item = readdir($dh))
						{

							next if $item eq '.';
							next if $item eq '..';
							next if $item =~ m/\.TMP\.webmerge$/;


							push(@todo, {
								'src' => join('/', $src, $item),
								'dst' => join('/', $dst, dirname($item)),
								'recursive' => $recursive ? $recursive - 1 : 0
							})

						}

						closedir($dh);

					}
					else
					{

						# print "copying ", exportURI($src), "\n";

						# check if we do not copy a text file
						my $bin = ($copy->{'text'} || '') ne "true";

						# copy the file binary if text is not set to true
						my $data = readfile($src, $config->{'atomic'}, $bin);
						writefile($dst, $data, $config->{'atomic'}, $bin);

						# print " copied to ", exportURI($dst), "\n";

					}

				}

			}

		}
		# EO each copy

		# process postrun script (feature will change)
		foreach my $run (@{$prepare->{'postrun'} || []})
		{

			my $cmd = $run->{'cmd'};

			my @args = @{$run->{'arg'} || []};

			print "executing $cmd ", join(" ", @args), "\n";

			chdir $config->{'directory'} or die "chdir";

			my $rv = system $cmd, @args;

			croak "postrun execution failure" if $?;

		}

	}
	# EO unless disabled

	# commit all changes to the filesystem if configured
	$config->{'atomic'} = {} if $commit =~ m/^\s*(?:bo|af)/i;

}
# EO sub prepare

###################################################################################################
###################################################################################################
1;
