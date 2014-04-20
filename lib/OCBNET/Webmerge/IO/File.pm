################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::IO::File;
################################################################################

use strict;
use warnings;

################################################################################
# create a new IO::File
################################################################################
use OCBNET::Webmerge qw();
################################################################################

sub new
{
	# get arguments
	my ($pkg, $path) = @_;
	# create a new object
	my $file = bless {}, $pkg;
	# default encoding is utf8
	$file->{'encoding'} = 'utf8';
	# assertion that we have some input
	die "no path given for new" unless $path;
	die "ref path given for new" if ref $path;
	# emulate old deprecated key
	$file->{'attr'}->{'path'} = $path;
	# store directly on object
	$file->{'path'} = $path;
	# return object
	return $file;
}

################################################################################
# normaly we just need to call init
################################################################################

sub init
{
	# get arguments
	my ($file, $parent) = @_;
	# default encoding is utf8
	unless (exists $file->{'encoding'})
	{ $file->{'encoding'} = 'utf8'; }
	# return object
	return $file;
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
# return false if lock could not be
# aquired after the given timeout (in s)
################################################################################
use Fcntl qw(O_RDWR O_RDONLY SEEK_SET);
use Fcntl qw(LOCK_SH LOCK_EX LOCK_UN LOCK_NB);
################################################################################

sub lockfile
{

	# get input variables
	my ($fh, $flag, $timeout) = @_;

	# simply lock with blocking when no timeout given
	return flock($fh, $flag) unless defined $timeout;

	# this is an alternative locking mechanism with timeout
	# it has the disadvantage that while we are waiting in the
	# select call another process might get the lock before us
	# my $time = time; while($time + $timeout > time) {
	# 	return 1 if(flock($fh, $lock | LOCK_NB));
	# select(undef, undef, undef, $intervall) }

	# eval in perl is a bit like try/catch
	eval
	{

		# die needs the "\n" to not append trace
		local $SIG{ALRM} = sub { die "alarm\n" };

		# setup the alarm
		alarm $timeout;

		# try to lock the file
		flock($fh, $flag);

		# reset alarm
		alarm 0;

	};

	# there was an error
	if ($@)
	{

		# propagate unexpected errors
		die unless $@ eq "alarm\n";

		# return failure
		return 0;

	}

	# return success
	return 1;

}
# EO lock_file

################################################################################
# open a filehandle
################################################################################

sub open
{
	# get arguments
	my ($node, $mode) = @_;
	# resolve mode strings
	if ($mode eq 'r') { $mode = '<'; }
	elsif ($mode eq 'w') { $mode = '>'; }
	elsif ($mode eq 'rw') { $mode = '<+'; }
	# we only support some open modes
	# else { die "invalid open mode $mode"; }
	# try to open the filehandle with mode
	my $rv = open(my $fh, $mode, $node->path);
	# report errors back when opening failed
	die "could not open " . $node->path unless $rv;
	# aquire a file lock (wait for a certain amount of time)
	$rv = lockfile($fh, $mode eq '<' ? LOCK_SH : LOCK_EX, 4);
	# error out if we could not aquire a lock in time
	die "could not aquire file lock for ", $node->dpath, "\n" unless $rv;
	# do not change data
	$fh->binmode(':raw');
	# return filehandle
	return $fh;
}

################################################################################
# read file path into scalar
################################################################################

sub load
{
	my ($data, $pos);
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
		# restore offset position from header sniffing
		$pos = ${*$atomic}{'io_atomicfile_pos'} || 0;
	}
	# read from the disk
	else
	{
		# open readonly filehandle
		my $fh = $node->open('r');
		# implement proper error handling
		die "error ", $path unless $fh;
		# store filehandle offset after sniffing
		$pos = ${*$fh}{'io_atomicfile_off'} = tell $fh;
		# read in the whole content event if we should discharge
		seek $fh, 0, 0 or Carp::croak "could not seek $path: $!";
		# slurp the while file into memory and decode unicode
		# $fh->binmode(sprintf(':raw:encoding(%s)', $node->encoding));
		my $raw = $node->{'loaded'} = join('', <$fh>);
		# now decode to loaded data into encoding
		my $content = decode($node->encoding, $raw);
		# attach written scalar to atomic instance
		$data = ${*$fh}{'io_atomicfile_data'} = \ $content;
		# store handle as atomic handle
		# disallow changes from this point
		$node->atomic($path, $fh);
		# story a copy to our object
		$node->{'readed'} = \ $content;
		# return scalar reference
		$data = \ "$content";
	}
	# create and store the checksum
	$node->{'crc'} = $node->md5sum($data);
	# print "== ", $node->{'crc'}, "\n";
	# remove leading file header
	substr(${$data}, 0, $pos) = '';
	# return reference
	return $data;
}

################################################################################
# read and import file
################################################################################

sub read
{
	# get arguments
	my ($node) = @_;
	# load from disk
	my $data = &load;
	# call the importer
	$node->import($data);
	# call the processors
	$node->process($data);
	# return reference
	return $data;
}

################################################################################
# same as read but cached
################################################################################

sub contents
{
	# log action to console
	$_[0]->logFile('contents');
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
	die "error\nwriting to non existent directory: ", $node->dpath unless (-d $node->dirname);
	die "error\nwriting to unwriteable directory: ", $node->dpath unless (-w $node->dirname);

	# call the processors
	$node->process($data);
	# alter data for output
	$node->export($data);
	# finalize for writing
	$node->finalize($data);
	# create output checksum
	$node->checksum($data);

	# get atomic entry if available
	my $atomic = $node->atomic($path);

	# check if commit is pending
	if (defined $atomic)
	{
		$_[0]->logFile('write[a]');
		# reset the offset for sniffed headers
		${*$atomic}{'io_atomicfile_pos'} = 0;
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
		die "could not open ", $_[0]->path, "\n$!" unless $fh;
		# truncate the file and ensure encoding
		$fh->truncate(0); $fh->binmode(':raw');
		# attach written scalar to atomic instance
		${*$atomic}{'io_atomicfile_data'} = $data;
		# attach atomic instance to scope
		$node->atomic($path, $atomic);
		# also set the read cache
		$node->{'written'} = $data;
		# encode the data for raw output handle
		${$data} = encode($node->encoding, ${$data});
		# update the checksum (have raw data)
		$node->{'crc'} = $node->md5sum($data, 1);
		# print to raw handle
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
	my ($node, $quiet) = @_;
	# get path from node
	my $path = $node->path;
	# read from disk next time
	delete $node->{'loaded'};
	delete $node->{'readed'};
	delete $node->{'written'};
	# get atomic entry if available
	my $atomic = $node->atomic($path);
	# silently return if node is unknown
	return 1 if $quiet && !$atomic;
	# die if there is nothing to revert
	die "file never written: $path" unless $atomic;
	# also call on possible children
	$_->revert foreach $node->children;
	# revert changes
	my $rv = $atomic->delete;
}

################################################################################
# commit any changes written
################################################################################

sub commit
{
	# get arguments
	my ($node, $quiet) = @_;
	# get path from node
	my $path = $node->path;
	# read from disk next time
	delete $node->{'loaded'};
	delete $node->{'readed'};
	delete $node->{'written'};
	# get atomic entry if available
	my $atomic = $node->atomic($path);
	# silently return if node is unknown
	return 1 if $quiet && !$atomic;
	# die if there is nothing to revert
	die "file never written: $path" unless $atomic;
	# also call on possible children
	$_->commit foreach $node->children;
	# commit changes
	my $rv = $atomic->close
}

################################################################################
use Digest::MD5;
###############################################################################
use Encode qw(encode_utf8 decode_utf8);
###############################################################################

sub md5sum
{
	# get the file node
	my ($node, $data, $raw) = @_;
	# create a new digest object
	my $md5 = Digest::MD5->new;
	# read from node if no data is passed
	$data = $node->contents unless $data;
	# convert data into encoding if we have no raw data
	$data = \ encode($node->encoding, ${$data}) unless $raw;
	# add raw data and return final digest
	return uc($md5->add(${$data})->hexdigest);
}

sub md5short
{
	# get the optionaly configured fingerprint length
	my $len = $_[0]->config('fingerprint-length') || 12;
	# return a short configurable length md5sum
	return substr($_[0]->md5sum($_[1], $_[2]), 0, $len);
}

###############################################################################
# is different from md5sum for css files
# as we remove the charset declaration on load
###############################################################################

sub crc { &load unless $_[0]->{'crc'}; $_[0]->{'crc'} }

###############################################################################
# return path with added fingerprint
###############################################################################
OCBNET::Webmerge::options('fingerprint', 'fingerprint|f=s', 'q');
OCBNET::Webmerge::options('fingerprint-length', 'fingerprint-length=s', 8);
###############################################################################

sub fingerprint
{

	# get passed variables
	my ($node, $target, $data) = @_;

	# get the fingerprint config option if not explicitly given
	my $technique = lc substr $node->config(join('-', 'fingerprint', $target)), 0, 1;

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

sub level
{
	return 0;
}

sub log
{
	print " " x shift->level, @_, "\n";
}

sub logBlock
{
	print " " x shift->level, @_, "\n";
}

sub logFile
{
	print " " x $_[0]->level;
	printf "% 10s: %s\n", $_[1], $_[0]->dpath;
}

sub logAction
{
	print " " x $_[0]->level;
	printf "% 10s: %s\n", $_[1], $_[0]->dpath;
}

sub logSuccess
{
	# print $_[1] ? "ok\n" : "err\n";
}

sub path {	$_[0]->{'path'} }

sub dpath { $_[0]->path }

sub export { return $_[1] }
sub process { return $_[1] }
sub checksum { return $_[1] }
sub finalize { return $_[1] }

sub parent {}
sub collect {}
sub children {}

################################################################################
################################################################################
1;