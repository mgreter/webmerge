################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::IO::Mixin::Atomic;
################################################################################

use strict;
use warnings;

################################################################################
# commit any changes written
################################################################################

sub commit
{

	# get arguments
	my ($file, $quiet) = @_;

	# get path from node
	my $path = $file->path;

	# read from disk next time
	delete $file->{'loaded'};
	delete $file->{'readed'};
	delete $file->{'written'};

	# get atomic entry if available
	my $atomic = $file->atomic($path);

	# silently return if node is unknown
	return 1 if $quiet && ! $atomic;

	# die if there is nothing to revert
	Carp::croak "file never written: $path" unless $atomic;

	# also call on possible children
	$_->commit foreach $file->children;

	# handle commit according to object type
	if (UNIVERSAL::can($atomic, 'commit')) { $atomic->commit }
	elsif (UNIVERSAL::can($atomic, 'close')) { $atomic->close }

}

################################################################################
# revert any changes written
################################################################################

sub revert
{

	# get arguments
	my ($file, $quiet) = @_;

	# get path from node
	my $path = $file->path;

	# read from disk next time
	delete $file->{'loaded'};
	delete $file->{'readed'};
	delete $file->{'written'};

	# get atomic entry if available
	my $afh = $file->atomic($path);

	# silently return if node is unknown
	return 1 if $quiet && ! $afh;

	# die if there is nothing to revert
	Carp::croak "file never written: $path" unless $afh;

	# also call on possible children
	$_->revert foreach $file->children;

	# handle commit according to object type
	if (UNIVERSAL::can($afh, 'revert')) { $afh->revert }
	elsif (UNIVERSAL::can($afh, 'delete')) { $afh->delete }

}

################################################################################
################################################################################
1;

