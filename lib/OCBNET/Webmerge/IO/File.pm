################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::IO::File;
################################################################################
# use base 'OCBNET::Webmerge::Merge';
################################################################################

use strict;
use warnings;

################################################################################
require IO::AtomicFile;
################################################################################
use Encode qw(encode decode);
################################################################################

sub new
{
	# get arguments
	my ($node, $parent) = @_;
	# default encoding is utf8
	$node->{'encoding'} = 'utf8';
}

################################################################################
# get or set atomic instance
################################################################################

sub atomic
{
	# get arguments
	my ($node, $path, $atomic) = @_;
	# find next scope
	while ($node)
	{
		# abort search in tree
		last if $node->{'atomic'};
		# move node up in tree
		$node = $node->parent;
	}
	# abort if no scope found
	return unless $node;
	# call atomic method on IO::Atomic
	return $node->atomic($path, $atomic);
}

################################################################################
# open a filehandle
################################################################################

sub open
{
	# get arguments
	my ($node, $mode, $encoding) = @_;
	# resolve mode strings
	if ($mode eq 'r') { $mode = '<:raw'; }
	elsif ($mode eq 'w') { $mode = '>:raw'; }
	elsif ($mode eq 'rw') { $mode = '<+:raw'; }
	# we only support some open modes
	else { die "invalid open mode $mode"; }
	# try to open the filehandle with correct encoding
	open(my $fh, $mode, $node->path);
	# read raw data
	binmode ($fh);
	# return filehandle
	return $fh;
}

################################################################################
# read file path into scalar
################################################################################

sub read
{
	# get arguments
	my ($node) = @_;
	# get path from node
	my $path = $node->path;
	# get atomic entry if available
	my $atomic = $node->atomic($path);
	# check if commit is pending
	if (defined $atomic)
	{
		# simply return the last written data
		return ${*$atomic}{'io_atomicfile_data'};
	}
	# read from the disk
	else
	{
		# open readonly filehandle
		my $fh = $node->open('r');
		# implement proper error handling
		die "error ", $path unless $fh;
		# slurp the while file into memory and decode unicode
		my $data = decode($node->{'encoding'}, join('', <$fh>));
		# attach written scalar to atomic instance
		${*$fh}{'io_atomicfile_data'} = \ $data;
		# store handle as atomic handle
		# disallow changes from this point
		$node->atomic($path, $fh);
		# return scalar reference
		return \ $data;
	}
}

################################################################################
# write scalar atomic
################################################################################

sub write
{
	# get arguments
	my ($node, $data) = @_;
	# get path from node
	my $path = $node->path;
	# get atomic entry if available
	my $atomic = $node->atomic($path);
	# check if commit is pending
	if (defined $atomic)
	{
		# check if the new data matches the previous commit
		if (${$data} eq ${${*$atomic}{'io_atomicfile_data'}})
		{ warn "writing same content more than once"; }
		else { die "writing different content to the same file"; }
	}
	# read from the disk
	else
	{
		# create a new atomic instance
		$atomic = IO::AtomicFile->new;
		# add specific webmerge suffix to temp files
		${*$atomic}{'io_atomicfile_suffix'} = '.webmerge';
		# some more options you could fetch via glob
		# my $temp = ${*$atomic}{'io_atomicfile_temp'};
		# my $path = ${*$atomic}{'io_atomicfile_path'};
		# my $closed = ${*$atomic}{'io_atomicfile_closed'};
		# open a new writeable file handle
		my $fh = $atomic->open($path, 'w+');
		# attach written scalar to atomic instance
		${*$atomic}{'io_atomicfile_data'} = $data;
		# attach atomic instance to scope
		$node->atomic($path, $atomic);
		# return scalar reference
		print $fh ${$data};
	}
	# return atomic instance
	return $atomic;
}

################################################################################
# revert any changes written
################################################################################

sub revert
{
	# get arguments
	my ($node) = @_;
	# get path from node
	my $path = $node->path;
	# get atomic entry if available
	my $atomic = $node->atomic($path);
	# die if there is nothing to revert
	die "file never written" unless $atomic;
	# revert changes
	my $rv = $atomic->delete
}

################################################################################
# commit any changes written
################################################################################

sub commit
{
	# get arguments
	my ($node) = @_;
	# get path from node
	my $path = $node->path;
	# get atomic entry if available
	my $atomic = $node->atomic($path);
	# die if there is nothing to revert
	die "file never written" unless $atomic;
	# commit changes
	my $rv = $atomic->close
}

################################################################################
################################################################################
1;