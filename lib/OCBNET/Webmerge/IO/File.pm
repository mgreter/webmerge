################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::IO::File;
################################################################################
use base qw(OCBNET::Webmerge::Tree::Node);
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
# check agains saved checksum
################################################################################
use File::Spec::Functions qw(catfile);
################################################################################

sub check
{

	# get arguments
	my ($output, $crc) = @_;

	# split checksum file content into lines
	my @crcs = split(/\s*(?:\r?\n)+\s*/, ${$crc});

	# remove leading checksums
	my $checksum_result = shift(@crcs);
	my $checksum_joined = shift(@crcs);

	# check if the generated content changed
	if ($output->crc ne $checksum_result)
	{
		printf "FAIL - dst: %s\n", substr($output->path, - 45);
		printf "=> expect: %s\n", $checksum_result;
		printf "=> gotten: %s\n", $output->crc;
	}
	else
	{
		printf "PASS - dst: %s\n", substr($output->path, - 45);
	}

	# declare local variable
	my @md5sums;

	# process all source files
	foreach my $source (@crcs)
	{

		# split the line into path and checksum
		my ($path, $checksum) = split(/:\s*/, $source, 2);

		# path is always relative to the checksum
		$path = catfile($output->dirname, $path);

		# load the css file with the given path name
		my $input = OCBNET::Webmerge::IO::File->new;
		# set the path on the attribute
		$input->{'attr'}->{'path'} = $path;
		# loosely couple the nodes together
		$input->{'parent'} = $output;

		push @md5sums, $input->crc;

		# check against stored value
		if ($input->crc ne $checksum)
		{
			printf "  FAIL - src: %s\n", substr($input->path, - 45);
			printf "  => expect: %s\n", $checksum;
			printf "  => gotten: %s\n", $input->crc;
		}
		else
		{
			printf "  PASS - src: %s\n", substr($input->path, - 45);
		}

	}

	if ($output->md5sum(\join('::', @md5sums)) ne $checksum_joined)
	{
		printf "FAIL - all: %s\n", substr($output->path, - 45);
	}
	else
	{
		printf "PASS - all: %s\n", substr($output->path, - 45);
	}

}

################################################################################
# return absolute path for the given output file
################################################################################

sub attr { $_[0]->{'attr'}->{$_[1]} }

sub path { return $_[0]->abspath($_[0]->respath($_[0]->attr('path'))) }

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
# dummy implementations
################################################################################

sub importer { return $_[1] }
sub exporter { return $_[1] }
sub include { return $_[1] }
sub resolve { return $_[1] }
sub checksum2 {
	die $_[0];
	return $_[1] }
# sub finalize { return $_[1] }

################################################################################
use Encode qw(encode decode);
################################################################################

sub encoding : lvalue { $_[0]->{'encoding'} }

################################################################################
# calculate checksum
################################################################################
use Digest::MD5 qw();
################################################################################

sub md5sum
{
	# get the file node
	my ($file, $data, $raw) = @_;
	# create a new digest object
	my $md5 = Digest::MD5->new;
	# read from node if no data is passed
	$data = $file->contents unless $data;
	# convert data into encoding if we have no raw data
	$data = \ encode($file->encoding, ${$data}) unless $raw;
	# add raw data and return final digest
	return uc($md5->add(${$data})->hexdigest);
}

sub md5short
{
	# get the optionaly configured fingerprint length
	my $len = $_[0]->option('fingerprint-length') || 12;
	# return a short configurable length md5sum
	return substr($_[0]->md5sum($_[1], $_[2]), 0, $len);
}

###############################################################################
# is different from md5sum for css files
# as we remove the charset declaration on load
###############################################################################

sub crc { &load unless $_[0]->{'crc'}; $_[0]->{'crc'} }

###############################################################################
use OCBNET::Webmerge qw(options);
###############################################################################
options('fingerprint', '=s', 'q');
options('fingerprint-dev', '=s', 'q');
options('fingerprint-live', '=s', 'q');
options('fingerprint-length', '=s', 8);
###############################################################################

sub fingerprint
{

	# get passed variables
	my ($file, $target, $data) = @_;

	# debug assertion to report unwanted input
	warn "undefined target" unless defined $target;

	# get the fingerprint config option if not explicitly given
	my $technique = lc substr $file->option(join('-', 'fingerprint', $target)), 0, 1;

	# do not add a fingerprint at all if feature is disabled
	return $file->path unless $file->option('fingerprint') && $technique;

	# simply append the fingerprint as a unique query string
	return join('?', $file->path, $file->md5short) if $technique eq 'q';

	# insert the fingerprint as a (virtual) last directory to the given path
	# this will not work out of the box - you'll need to add some rewrite directives
	return join('/', $file->dirname, $file->md5short, $file->basename) if $technique eq 'd';
	return join('/', $file->dirname, $file->md5short . '-' . $file->basename) if $technique eq 'f';

	# exit and give an error message if technique is not known
	die 'fingerprint technique <', $technique, '> not implemented', "\n";

	# at least return something
	return $file->path;

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
# open the path
################################################################################

sub open
{
	my ($rv, $fh);
	die "asd" if $fh;
	# get arguments
	my ($file, $mode) = @_;

	if (defined $file->attr('path'))
	{
		# resolve mode strings
		if ($mode eq 'r') { $mode = '<'; }
		elsif ($mode eq 'w') { $mode = '>'; }
		elsif ($mode eq 'rw') { $mode = '<+'; }
		# create a new file handle of the given file type
		$fh = join('::', 'OCBNET::IO::File', uc $file->ftype)->new;
		# try to open the filehandle with mode
		$rv = $fh->open($file->path, $mode);
		# copy encoding from handle to object
		$file->encoding = $fh->encoding if $fh->encoding;
		# aquire a file lock (wait for a certain amount of time)
		$rv = lockfile($fh, $mode eq '<' ? LOCK_SH : LOCK_EX, 4);
		# error out if we could not aquire a lock in time
		die "could not aquire file lock for ", $file->path, "\n" unless $rv;
		# do not change data
		$fh->binmode(':raw');
		# return filehandle
		return $fh;
	}
	else
	{
		die "open no";
	}
}


################################################################################
# read file path into scalar
################################################################################
use OCBNET::Webmerge qw(isset);
################################################################################

sub load
{
	# get arguments
	my ($file) = @_;
	# get path from node
	my $path = $file->path;
	# declare local variables
	my ($pos, $data) = (0);

	if (isset $file->attr('script'))
	{

		# create absolute path to store the script output
		# my $path = $file->respath($file->path);

		# get and resolve the script executable path
		my $script = $file->respath($file->attr('script'));

		# shebang should be given by configuration
		# otherwise the script must have execute permission
		my $shebang = $file->attr('shebang') ? $file->attr('shebang') . ' ' : '';

		# execute the script and open the stdout for us
		my $rv = CORE::open my $fh_in, "-|", $shebang . $script;

		# check if we got a valid result from open
		die "error executing $script" unless $rv;

		# read raw data
		binmode $fh_in;

		# set data to script output
		$data = \ join('', <$fh_in>);

	}
	elsif (isset $file->attr('path'))
	{
		# get atomic entry if available
		my $atomic = $file->atomic($path);
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
			my $fh = $file->open('r');
			# implement proper error handling
			die "error ", $path unless $fh;
			# store filehandle offset after sniffing
			$pos = ${*$fh}{'io_atomicfile_off'} = tell $fh;
			# read in the whole content event if we should discharge
			seek $fh, 0, 0 or Carp::croak "could not seek $path: $!";
			# slurp the while file into memory and decode unicode
			my $raw = $file->{'loaded'} = join('', <$fh>);
			# attach written scalar to atomic instance
			$data = ${*$fh}{'io_atomicfile_data'} = \ $raw;
			# store handle as atomic handle
			$file->atomic($path, $fh);
		}
	}


	else
	{
		die "no path for input";
	}

	# story a copy to our object
	$file->{'loaded'} = ${$data};
	# create and store the checksum
	$file->{'crc'} = $file->md5sum($data);
	# now decode the raw data into encoding
	$data = \ decode($file->encoding, ${$data});
	# story a copy to our object
	$file->{'readed'} = ${$data};

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
	my ($file) = @_;
	# load from disk
	my $data = &load;
	# call the importer
	$file->importer($data);
	# call the resolver
	# resolve imports/inclues
	$file->resolve($data);
	# call the processors
	$file->process($data);
	# convert if needed
	# $file->exporter($data);
	# $file->importer($data);
	# return reference
	return $data;
}

################################################################################
# same as read but cached
################################################################################

sub contents
{
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
use IO::AtomicFile qw();
################################################################################

sub write
{
	# get arguments
	my ($file, $data) = @_;

	# get path from node
	my $path = $file->respath($file->path);

	# force relative again
	# extend by other bases
	$path =~ s/^\/+// if $^O ne 'MSWin32';
	$path =~ s/^[\/\\]+// if $^O eq 'MSWin32';

	$path = $file->abspath($path);

	# do some checking before writing to give good error messages
	die "error\nwriting to non existent directory: ", $file->path unless (-d $file->dirname);
	die "error\nwriting to unwriteable directory: ", $file->path unless (-w $file->dirname);

	# alter data for output
	$file->exporter($data);
	# call the processors
	$file->process($data);
	# create output checksum
	$file->checksum($data);
	# finalize for writing
	# $file->finalizer($data);

	# get atomic entry if available
	my $atomic = $file->atomic($path);

	# check if commit is pending
	if (defined $atomic)
	{
		# reset the offset for sniffed headers
		${*$atomic}{'io_atomicfile_pos'} = 0;
		# check if the new data matches the previous commit
		if (${$data} eq ${${*$atomic}{'io_atomicfile_data'}})
		{ warn "writing same content more than once"; }
		else { die "writing different content to the same file"; }
	}
	# check if file has been read
	elsif ($file->{'readed'})
	{
		# check if the new data matches the previous commit
		if (${$data} eq ${$file->{'readed'}})
		{ warn "overwriting same content more than once"; }
		else { die "overwriting different content to the same file"; }
	}
	# write to the disk
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
		# error out if we could not open the file
		die "could not open ", $_[0]->path, "\n$!" unless $fh;
		# truncate the file and ensure encoding
		$fh->truncate(0); $fh->binmode(':raw');
		# attach written scalar to atomic instance
		${*$atomic}{'io_atomicfile_data'} = $data;
		# attach atomic instance to scope
		$file->atomic($path, $atomic);
		# also set the read cache
		$file->{'written'} = $data;
		# encode the data for raw output handle
		# warn "encode ", $file->encoding;
		${$data} = encode($file->encoding, ${$data});
		# update the checksum (have raw data)
		$file->{'crc'} = $file->md5sum($data, 1);
		# print to raw handle
		print $fh ${$data};
	}
	# return atomic instance
	return $atomic;
}

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
# list all processors for this file
################################################################################

sub processors { split /(?:\s*\|\s*|\s+)/, $_[0]->attr('process') || '' }

################################################################################
# process the data/content and return result
################################################################################

sub process
{

	# get arguments
	my ($file, $data) = @_;

	# get data from file if not passed
	$data = $file->contents unless $data;

	# implement processing to alter the data
	foreach my $name ($file->processors)
	{
		# alternative name built via scope tag name
		my $alt = $file->scope->tag . '::' . $name;
		# get the processor by name from the document
		my $processor = $file->document->processor($alt) ||
		                $file->document->processor($name);
		# check if the processor name is valid
		# maybe you forgot to load some plugins
		die "processor $alt not found" unless $processor;
		# change working directory
		chdir $file->workroot;
		# execute processor and pass data
		$data = &{$processor}($file, $data);
		# check if processor returned with success
		die "processor $name had an error" unless $data;
	}
	# EO foreach processor name

	# return reference
	return $data;

}
# EO process

################################################################################
use OCBNET::CSS3::URI qw(exportUrl);
################################################################################

# return (absolute) url to current webroot or given base
# if relative or absolute depends on the current config
# ******************************************************************************
sub weburl
{

	# get arguments
	my ($file, $abs, $base) = @_;

	# use webroot if no specific based passed
	$base = $file->workroot unless defined $base;

	# allow to overwrite this flag
	$abs = 1 unless defined $abs;

	# call function with correct arguments
	return exportUrl($file->path, $base, $abs);

}

# return (relative) url current directory or given base
# if relative or absolute depends on the current config
# ******************************************************************************
sub localurl
{

	# get arguments
	my ($file, $base, $abs) = @_;

	# use webroot if no specific based passed
	$base = $file->workroot unless defined $base;

	# allow to overwrite this flag
	$abs = 0 unless defined $abs;

	# call function with correct arguments
	return exportUrl($file->path, $base, $abs);

}

################################################################################
# load additional modules
################################################################################

# require OCBNET::Webmerge::Output;

################################################################################
# accessor methods
################################################################################

# return node type
sub type { 'FILE' }

################################################################################
################################################################################
1;
