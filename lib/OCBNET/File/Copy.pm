################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::File::Copy;
################################################################################

use strict;
use warnings;
use Carp qw(croak);
use File::Copy qw(cp);

################################################################################

# declare for exporter
our (@EXPORT, @EXPORT_OK);

# load exporter and inherit from it
BEGIN { use base 'Exporter'; }

# define our functions that will be exported
BEGIN { push @EXPORT, qw(xcopy fcopy) }

################################################################################
use List::MoreUtils qw(uniq);
use OCBNET::File::Find qw(find);
use OCBNET::File::Path qw(mkpath);
################################################################################
use File::Spec::Functions qw(abs2rel rel2abs);
use File::Spec::Functions qw(canonpath catfile);
use File::Basename qw(dirname basename fileparse);
################################################################################

################################################################################
# copy one or multiple files and/or directories!
# if a directory is discovered, we only copy something
# when the recursive option is set (defines maxdepth).
################################################################################

sub xcopy ($$;%)
{

	# get input arguments
	my ($paths, $dest, %option) = @_;

	# get callback function
	my $cb = $option{'cb'};
	# get base from options
	my $base = $option{'base'} || '.';

	# get option to define maxdepts
	my $recursive = $option{'recursive'};

	# force paths into array (if string passed)
	$paths = [ $paths ] if ref $paths ne 'ARRAY';

	# recursive paths
	@{$paths} = uniq map
	{
		# directory
		if (-d $_)
		{
			# only if recursive
			if (defined $recursive)
			{
				find(
					'*',
					'maxdepth' => $recursive,
					'filter' => sub { ! -d $_ },
					'base' => rel2abs($_, $base)
				);
			}
			else
			{
				warn "xcopy: skip directory: $_\n"; ();
			}
		}
		else
		{
			$_;
		}
	} @{$paths};
	# EO recursive

	# process all source paths
	foreach my $src (@{$paths || []})
	{

		# make src canonical
		$src = canonpath($src);

		# get default base directory from source
		$base = dirname($src) unless defined $base;

		# construct path from destination and source
		my $dst = rel2abs(abs2rel($src, $base), $dest);

		# check if we should rename files
		if (my $rename = $option{'rename'})
		{
			# get rename options (srch/repl)
			my ($srch, $repl) = @{$rename};
			# parse into directory and file
			my ($name, $dir) = fileparse($dst);
			# apply regex and call replace
			$name =~ s/$srch/&{$repl}/e;
			# re-build canonical path
			$dst = catfile $dir, $name;
		}

		# call copy function
		fcopy ($src, $dst, %option);

	}
	# EO each source file

}
# EO sub xcopy

################################################################################
# copy one file and optionaly create necessary paths
################################################################################

sub fcopy ($$;%)
{

	# get input arguments
	my ($src, $dst, %option) = @_;

	# get base from options
	my $mkpath = $option{'mkpath'};

	# make mkdir function configurable via options
	$option{'mkdir'} = $mkpath if ref $mkpath eq "CODE";
	$option{'mkdir'} = \ &mkpath unless $option{'mkdir'};
	# make copy function configurable via options
	unless ( $option{'read'} && $option{'write'} )
	{ $option{'fcopy'} = \ &cp unless $option{'fcopy'} }

	# make absolute path of mkpath directory
	$mkpath = rel2abs($mkpath) if defined $mkpath;

	# die with fatal error if copying a directory
	die "fcopy cannot copy directories" if -d $src;

	# make paths canonical
	$src = canonpath($src);
	$dst = canonpath($dst);

	# check arguments
	if ($dst eq $src)
	{
		# just give a warning (non fatal)
		warn "src equals dst: $src\n";
	}
	else
	{
		# ensure base directory exists
		# will also fail if not in chroot
		if ($option{'mkdir'}->(dirname($dst), %option))
		{
			if (ref $option{'fcopy'} eq "CODE")
			{
				# call fcopy and pass paths and options
				$option{'fcopy'}->($src, $dst, \ %option)
					|| croak "fcopy: could not copy file $!"
			}
			else
			{
				# assertion tag valid hooks have been configures
				croak "no read function" if ref $option{'read'} ne "CODE";
				croak "no write function" if ref $option{'write'} ne "CODE";
				# call reader callback and pass data to writer
				my $data = $option{'read'}->($src) || croak "fcopy: could not read file $!";
				$option{'write'}->($dst, $data) || croak "fcopy: could not write file $!";
			}
		}
	}

}
# EO sub fcopy

################################################################################
################################################################################
1;

