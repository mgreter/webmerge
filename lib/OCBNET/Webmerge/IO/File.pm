################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::IO::File;
################################################################################
use base qw(OCBNET::Webmerge::Tree::Node);
################################################################################
# load mixins for actual implementation
################################################################################
use base qw(OCBNET::Webmerge::IO::Mixin::MD5);
use base qw(OCBNET::Webmerge::IO::Mixin::URL);
use base qw(OCBNET::Webmerge::IO::Mixin::Open);
use base qw(OCBNET::Webmerge::IO::Mixin::Read);
use base qw(OCBNET::Webmerge::IO::Mixin::Load);
use base qw(OCBNET::Webmerge::IO::Mixin::Write);
use base qw(OCBNET::Webmerge::IO::Mixin::Atomic);
use base qw(OCBNET::Webmerge::IO::Mixin::Process);
use base qw(OCBNET::Webmerge::IO::Mixin::Fingerprint);
################################################################################

use strict;
use warnings;

################################################################################
use OCBNET::Webmerge qw(loadmodule);
################################################################################

sub initialize
{
	# bless into file specific class
	if (ref($_[0]) =~ m/\:\:(?:input|output)$/i)
	{
		my $type = $_[0]->scope->tag;
		loadmodule join '::', ref $_[0], uc $type;
		bless $_[0], join '::', ref $_[0], uc $type;
	}
	# assign path if it has been passed
	$_[0]->{'attr'}->{'path'} = $_[2];
	# declare default encoding
	$_[0]->{'encoding'} = 'utf-8';
}

################################################################################
# return path or selector for inline content
################################################################################

sub path
{
	# we have no path given so this looks like a inline text node
	# use the selector from the tree node to indicate config location
	return '>' . $_[0]->selector unless defined $_[0]->attr('path');
	# otherwise we have a path and will return it absolute
	return $_[0]->abspath($_[0]->respath($_[0]->attr('path')))
}

################################################################################
# return the file encoding
################################################################################

sub encoding : lvalue { $_[0]->{'encoding'} }

################################################################################
# some common attribute getters
################################################################################

sub target { $_[0]->attr('target') || 'join' }

################################################################################
# map to basename functions
################################################################################

sub ext { $_[0]->path =~ m/\.([a-zA-Z0-9]+)$/ && lc $1 }
sub dirname { File::Basename::dirname(shift->path, @_) }
sub basename { File::Basename::basename(shift->path, @_) }

################################################################################
# same as read but cached
################################################################################

sub contents
{
	my $self = shift;
	# return written content
	if (exists $self->{'written'})
	{ return $self->{'written'}; }
	# read from disk if not cached yet
	unless (exists $self->{'readed'})
	{ $self->{'readed'} = $self->read(@_); }
	# return cached reference
	return $self->{'readed'};
}

################################################################################
# access the cached values
################################################################################

sub readed : lvalue { $_[0]->{'readed'} }
sub written : lvalue { $_[0]->{'written'} }

################################################################################
# accessor methods
################################################################################

# return node type
sub type { 'FILE' }

################################################################################
# use binary as base file type
################################################################################

sub ftype { 'bin' }

################################################################################
################################################################################
1;
