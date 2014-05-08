################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::File::Copy;
################################################################################

use strict;
use warnings;

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

sub xcopy
{

	# get input arguments
	my ($paths, $dest, %option) = @_;

	# get callback function
	my $cb = $option{'cb'};
	# get base from options
	my $base = $option{'base'} || '.';

	my $recursive = $option{'recursive'};

	# force paths into array (if string passed)
	$paths = [ $paths ] if ref $paths ne 'ARRAY';

	# recursive paths
	@{$paths} = uniq map
	{
		if (-d $_)
		{
			if ($recursive)
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
				warn "skip: $_\n"; ();
			}
		}
		else
		{
			$_;
		}
	} @{$paths};

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
			my ($srch, $repl) = @{$rename};
			my ($name, $dir) = fileparse($dst);
			$name =~ s/$srch/&{$repl}/e;
			$dst = catfile $dir, $name;
		}

		# call copy function
		fcopy ($src, $dst, %option);

	}
	# EO each source file

}

################################################################################
################################################################################

sub fcopy
{

	# get input arguments
	my ($src, $dst, %option) = @_;

	# get base from options
	my $mkpath = $option{'mkpath'};

	# make absolute path of mkpath directory
	$mkpath = rel2abs($mkpath) if defined $mkpath;

	# die with fatal error if copying a directory
	die "fcopy cannot copy directories" if -d $src;

	if ($dst eq $src)
	{
		# just give a warning (non fatal)
		warn "src equals dst: $src\n";
	}
	else
	{
	# ensure base directory exists
		# will also fail if not in chroot
		if (mkpath(dirname($dst), %option))
		{
			# call reader callback and pass data to writer
			$option{'write'}->($dst, $option{'read'}->($src));
		}
	}

}

################################################################################
################################################################################
1;

