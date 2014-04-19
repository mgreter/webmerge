################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::IO::File;
################################################################################

use strict;
use warnings;

################################################################################
use OCBNET::Webmerge qw();
################################################################################

sub new
{
	# get arguments
	my ($node, $parent) = @_;
	# default encoding is utf8
	$node->{'encoding'} = 'utf8';
}

################################################################################
use Encode qw(encode decode);
################################################################################

sub encoding : lvalue { $_[0]->{'encoding'} }

################################################################################
# get or set atomic instance
################################################################################
use IO::AtomicFile qw();
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
	my $rv = open(my $fh, $mode, $node->path);
	# report errors back when opening failed
	die "could not open " . $node->path unless $rv;
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
	my $data;
	# get arguments
	my ($node) = @_;
	# log action to console
	$node->logFile('read');
	# get path from node
	my $path = $node->path;
	# get atomic entry if available
	my $atomic = $node->atomic($path);
	# check if commit is pending
	if (defined $atomic)
	{
		# simply return the last written data
		$data = ${*$atomic}{'io_atomicfile_data'};
	}
	# read from the disk
	else
	{
		# open readonly filehandle
		my $fh = $node->open('r');
		# implement proper error handling
		die "error ", $path unless $fh;
		# slurp the while file into memory and decode unicode
		# $fh->binmode(sprintf(':encoding(%s)', $node->encoding));
		my $content = decode($node->encoding, join('', <$fh>));
		# attach written scalar to atomic instance
		${*$fh}{'io_atomicfile_data'} = \ $content;
		# store handle as atomic handle
		# disallow changes from this point
		$node->atomic($path, $fh);
		# return scalar reference
		$data = \ $content;
	}
	# also set the read cache
	$node->{'readed'} = $data;
	# create and store the checksum
	$node->{'crc'} = $node->md5sum($data);
	# call the importer
	$node->import($data);
	# call the processors
	$node->process($data);
	# store copy to cache
	return $data;

}

################################################################################
# same as read but cached
################################################################################

sub content
{
	# log action to console
	$_[0]->logFile('content');
	# return written content
	if (exists $_[0]->{'written'})
	{ return $_[0]->{'written'}; }
	# read from disk if not cached yet
	unless (exists $_[0]->{'readed'})
	{ $_[0]->{'readed'} = &read; }
	# return cached reference
	return $_[0]->{'readed'};
}

################################################################################
# access the cached values
################################################################################

sub readed : lvalue { $_[0]->{'readed'} }
sub written : lvalue { $_[0]->{'written'} }

################################################################################
# write scalar atomic
################################################################################

sub write
{
	# get arguments
	my ($node, $data) = @_;

	# get path from node
	my $path = $node->path;

	# do some checking before writing to give good error messages
	die "error\nwriting to non existent directory" unless (-d $node->dirname);
	die "error\nwriting to unwriteable directory" unless (-w $node->dirname);

	# call the processors
	$node->process($data);
	# alter data for output
	$node->export($data);
	# create output checksum
	$node->checksum($data);
	# finalize for writing
	$node->finalize($data);

	# get atomic entry if available
	my $atomic = $node->atomic($path);
	# check if commit is pending
	if (defined $atomic)
	{
		$_[0]->logFile('write[a]');
		# check if the new data matches the previous commit
		if (${$data} eq ${${*$atomic}{'io_atomicfile_data'}})
		{ warn "writing same content more than once"; }
		else { die "writing different content to the same file"; }
	}
	# check if file has been read
	elsif ($node->{'readed'})
	{
		$_[0]->logFile('write[c]');
		# check if the new data matches the previous commit
		if (${$data} eq ${$node->{'readed'}})
		{ warn "overwriting same content more than once"; }
		else { die "overwriting different content to the same file"; }
	}
	# write to the disk
	else
	{
		$_[0]->logFile('write[w]');
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
		# error out if we could not open the file
		die "failed\n$!" unless $fh;
		# attach written scalar to atomic instance
		${*$atomic}{'io_atomicfile_data'} = $data;
		# attach atomic instance to scope
		$node->atomic($path, $atomic);
		# also set the read cache
		$node->{'readed'} = $data;
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
	# read from disk next time
	delete $node->{'readed'};
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
	# read from disk next time
	delete $node->{'readed'};
	# get atomic entry if available
	my $atomic = $node->atomic($path);
	# die if there is nothing to revert
	die "file never written" unless $atomic;
	# commit changes
	my $rv = $atomic->close
}

################################################################################
use Digest::MD5;
###############################################################################
use Encode qw(encode_utf8);
###############################################################################

sub md5sum
{
	# get the file node
	my ($node, $data) = @_;
	# create a new digest object
	my $md5 = Digest::MD5->new;
	# add encoded string for md5 digesting
	$md5->add(encode_utf8(${$data || $node->content}));
	# return uppercase hex crc
	return uc($md5->hexdigest);
}

sub md5short
{
	# get the optionaly configured fingerprint length
	my $len = $_[0]->config('fingerprint-length') || 12;
	# return a short configurable length md5sum
	return substr($_[0]->md5sum($_[1], $_[2]), 0, $len);
}

###############################################################################
# return path with added fingerprint
###############################################################################
OCBNET::Webmerge::options('fingerprint', 'fingerprint|f=s', 'q');
###############################################################################

sub fingerprint
{

	# get passed variables
	my ($node, $target, $data) = @_;

	# get the fingerprint config option if not explicitly given
	my $technique = $node->config(join('-', 'fingerprint', $target));

	# do not add a fingerprint at all if feature is disabled
	return $node->path unless $node->config('fingerprint') && $technique;

	# simply append the fingerprint as a unique query string
	return join('?', $node->path, $node->md5short) if $technique eq 'q';

	# insert the fingerprint as a (virtual) last directory to the given path
	# this will not work out of the box - you'll need to add some rewrite directives
	return join('/', $node->dirname, $node->md5short, $node->basename) if $technique eq 'd';
	return join('/', $node->dirname, $node->md5short . '-' . $node->basename) if $technique eq 'f';

	# exit and give an error message if technique is not known
	die 'fingerprint technique <', $technique, '> not implemented', "\n";

	# at least return something
	return $node->path;

}
################################################################################
################################################################################
1;