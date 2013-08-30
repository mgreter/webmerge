#!/usr/bin/perl

###################################################################################################
package RTP::Webmerge::IO;
###################################################################################################

use Carp;
use strict;
use warnings;

###################################################################################################

# define our version string
BEGIN { $RTP::Webmerge::IO::VERSION = "0.70" }

# load exporter and inherit from it
BEGIN { use Exporter qw(); our @ISA = qw(Exporter) }

# define our functions to be exported
BEGIN { our @EXPORT = qw(readfile writefile); }

# define our functions to be exported
BEGIN { our @EXPORT_OK = qw(processfile filelist); }

###################################################################################################

# resolve filepath
use File::Basename;

# override core glob (case insensitive)
use File::Glob qw(:globally :nocase);

# load flags for the system file operation calls
use Fcntl qw(O_RDWR O_RDONLY LOCK_EX SEEK_SET LOCK_UN);

# load webmerge core path module
use RTP::Webmerge::Path qw(res_path);

###################################################################################################

# lock file exclusive
# return false if lock could not be
# aquired after the given timeout (in s)
sub lock_file
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

###################################################################################################

# read file and return data (flocked)
sub readfile ($;$$)
{

	# get input variables
	my ($file, $atomic, $binary) = @_;

	# check if file has already beed written
	if ($atomic && exists $atomic->{$file})
	{ return $atomic->{$file}->[0]; }

	# check if file does exist
	# res_path may bail otherwise
	if (-e $file)
	{

		# resolve path and make absolute
		$file = res_path($file) || $file;

	} else {

		# parse into filename and path
		# the path must exists at this point
		my ($name, $path) = fileparse($file);

		# resolve path and make absolute
		$path = res_path($path) || $path;

		# re-join the complete file uri
		$file = join('/', $path, $name);

	}

	# check if file has already beed written
	if ($atomic && exists $atomic->{$file})
	{ return $atomic->{$file}->[0]; }

	# declare local variables
	my $rv, my $data = '';

	# open the file
	croak "could not open $file: $!" unless sysopen(my $fh, $file, O_RDONLY);

	# aquire exclusive lock on the file (will block)
	croak "could not lock $file: $!" unless lock_file($fh, LOCK_EX, 4);

	# read the whole file buffer by buffer
	while($rv = sysread($fh, my $buffer, 4096)) { $data .= $buffer; }

	# check for error conditions
	croak "read error: $!" unless defined $rv;
	croak "unknown read error: $!" unless $rv == 0;

	# close the file (this should probably never error)
	croak "could not close input file: $!" unless close $fh;

	# remove unwanted utf8 boms
	# this must not be protected
	# we seldomly use the data again
	# if it is not a text type
	$data =~ s/^\xEF\xBB\xBF// unless $binary;

	# return a data ref
	# this will safe memory
	return \$data

}
# EO sub readfile

###################################################################################################

# write data to a file (flocked)
sub writefile ($$;$$)
{

	my $fh;

	# get input variables
	my ($file, $out, $atomic, $binary) = @_;

	# check if file does exist
	# res_path may bail otherwise
	if (-e $file)
	{

		# resolve path and make absolute
		$file = res_path($file) || $file;

	} else {

		# parse into filename and path
		# the path must exists at this point
		my ($name, $path) = fileparse($file);

		# resolve path and make absolute
		$path = res_path($path) || $path;

		# re-join the complete file uri
		$file = join('/', $path, $name);

	}

	# declare local variables
	my $rv = undef;

	# create a memory copy of content
	my $data = \(my $foo = ${$out});

	# convert from mac/win newlines to unix newlines
	${$data} =~ s/(?:\r\n|\n\r)/\n/gm unless $binary;

	# open the file via atomic interface
	# my $fh = RTP::IO::AtomicFile->open($file, 'w');

	my $dir = dirname $file;
	
	die "directory does not exist: ", $dir unless -d $dir;
	
	# looks like we already written this file
	# truncate, sync and unlock, then write again
	if (exists $atomic->{$file})
	{
	
		# get the stored old handle
		$fh = $atomic->{$file}->[1];
		# set the position to start
		$fh->seek(0, SEEK_SET);
		$fh->sysseek(0, SEEK_SET);
		# make the file empty
		$fh->truncate(0);
		# write out changes
		$fh->flush;
		# release file locks
		flock($fh, LOCK_UN);
	}
	else
	{
		# open the file via atomic interface
		$fh = RTP::IO::AtomicFile->new;
		# append another suffix as some optimizers
		# already use the same, be on the save side
		${*$fh}{'io_atomicfile_suffix'} = '.webmerge';
		# open the file via atomic interface
		$fh->open($file, 'w');
	}
	
	die "could not open file: $file: $!" unless defined $fh;

	# use binmode
	$fh->binmode;

	# error out if there was an error opening the file
	croak "could not open $file: $!" unless $fh;

	# aquire exclusive lock on the file (will block)
	croak "could not lock $file: $!" unless lock_file($fh, LOCK_EX, 4);

	# $file = ${*$fh}{'io_atomicfile_temp'} if ${*$fh}{'io_atomicfile_temp'};
	
	# only store if atomic is given
	$atomic->{$file} = [$out, $fh] if $atomic;

	if (defined(my $temp = ${*$fh}{'io_atomicfile_temp'}))
	{
		# only store if atomic is given
		$atomic->{$temp} = [$out, $fh] if $atomic;
	}

	# write the whole file buffer by buffer
	while($rv = syswrite($fh, ${$data}, 4096)) { substr(${$data}, 0, $rv, ''); }

	# check for error conditions
	croak "write error: $!" unless defined $rv;
	croak "unknown write error: $!" unless $rv == 0;

	flock($fh, LOCK_UN);
	
	# return file handle
	# store to block file
	return $fh

}
# EO sub writefile


###################################################################################################

# process a file on disk
# it does open the file first
# aquires an exclusive lock
# then reads the whole file
# call the processor on the data
# then write back the new data
# flush, close und release lock
sub processfile
{

	# get input variables
	my ($file, $processor) = @_;

	# resolve path
	$file = res_path($file);

	# declare local variables
	my $rv, my $data = '';

	# open the file in read write mode
	croak "could not open $file: $!" unless sysopen(my $fh, $file, O_RDWR);

	# aquire exclusive lock on the file (will block)
	croak "could not lock $file: $!" unless lock_file($fh, LOCK_EX, 1000);

	# read the whole file buffer by buffer
	while($rv = sysread($fh, my $buffer, 4096)) { $data .= $buffer; }

	# check for read error conditions
	croak "read error: $!" unless defined $rv;
	croak "unknown read error: $!" unless $rv == 0;

	# call the processor to change the content (check return value)
	croak "could not process content: $!" unless &{$processor}(\$data);

	# seek to the file begining after processing is done
	croak "could not seek $file: $!" unless sysseek($fh, 0, SEEK_SET);

	# then truncate the file to zero size (make it empty)
	croak "could not truncate $file: $!" unless truncate($fh, 0);

	# then write the complete content again to the file
	croak "could not write to $file: $!" unless print $fh $data;

	# close the file (this should probably never error)
	croak "could not close file: $!" unless close $fh;

}
# EO sub processfile

###################################################################################################

# get a list of files from a directory
sub filelist
{

	# get input variables
	my ($root, $file, $recursive) = @_;

	# resolve path
	$root = res_path($root);

	# declare local variables
	my @dirs = ($root), my @files;

	while(defined(my $root = shift(@dirs)))
	{

		# use glob function to match the files
		# could implement my own regex match, but
		# glob is much simpler and securer to use
		push(@files, glob(join('/', $root, $file)));

		# open the directory to read all entries
		opendir(my $dh, $root) or die "could not opendir $root: $!";

		# read all entries in this directory
		foreach my $entry (readdir($dh))
		{

			# dont handle directory pointers
			next if $entry eq '.' || $entry eq '..';

			# create the complete file path
			my $path = join('/', $root, $entry);

			# add directory to processings if recursive
			push(@dirs, $path) if -d $path && $recursive;

		}
		# EO each readdir

		# close directory
		closedir($dh);

	}
	# EO while readdir

	# return array ref
	return \ @files;

}
# EO sub filelist

###################################################################################################
###################################################################################################
1;
