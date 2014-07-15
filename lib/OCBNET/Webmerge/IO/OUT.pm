################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::IO::OUT;
################################################################################
use base OCBNET::Webmerge::IO::File;
################################################################################

use strict;
use warnings;

# sub write { die "ja"; }

################################################################################
# implement file interface
################################################################################

sub workdir { shift->parent->dirname(@_) }

################################################################################
# outfile may return temporary file for path if written
################################################################################

sub path
{

	# get resolved path from file node
	my $path = $_[0]->respath($_[0]->SUPER::path);
	# create an absolute path again
	$path = $_[0]->abspath($path);
	# attach atomic instance to scope
	my $atomic = $_[0]->atomic($path);
	# return atomic temp file name or actual file path
	return $atomic ? ${*{$atomic}}{'io_atomicfile_temp'} : $path;
}

################################################################################
use File::Basename qw();
################################################################################

sub dirname { File::Basename::dirname($_[0]->path) }
sub basename { File::Basename::basename($_[0]->path) }
sub parsefile { File::Basename::basename($_[0]->path) }

################################################################################
# implement additional methods
################################################################################

sub commit {}
sub revert {}
sub collect {}
# sub process {}
sub processors {}

################################################################################
# accessor methods
################################################################################

# return node type
sub type { 'OUT' }

################################################################################
# implement some methods
################################################################################

sub importer { return $_[1] }
sub resolve { return $_[1] }

# sub exporter { return $_[1] }
# sub include { return $_[1] }

################################################################################
################################################################################
1;

