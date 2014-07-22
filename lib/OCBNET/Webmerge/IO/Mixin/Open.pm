################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::IO::Mixin::Open;
################################################################################

use strict;
use warnings;

################################################################################
# return false if lock could not be
# aquired after the given timeout (in s)
################################################################################
use Fcntl qw(O_RDWR O_RDONLY SEEK_SET);
use Fcntl qw(LOCK_SH LOCK_EX LOCK_UN LOCK_NB);
################################################################################

sub lock
{

	# get input variables
	my ($file, $flag, $timeout) = @_;
	# check if the filehandle is not closed
	return 0 if tell($file->{'handle'}) == -1;

	# get filehandle from the object
	my $fh = $file->{'handle'} || return;

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
# relase all locks
################################################################################

sub unlock
{

	# get arguments
	my ($file) = @_;

	# return if handle is not set
	return unless $file->{'handle'};
	# check if the filehandle is not closed
	return 0 if tell($file->{'handle'}) == -1;

	# call function to release lock
	flock($file->{'handle'}, LOCK_UN);

}

sub close
{

	# get arguments
	my ($file) = @_;

	# return if handle is not set
	return unless $file->{'handle'};
	# check if the filehandle is not closed
	return 0 if tell($file->{'handle'}) == -1;

	# call function to close
	$file->{'handle'}->close;

}

################################################################################
# open handle (path must be set)
################################################################################
use OCBNET::Webmerge qw(isset);
################################################################################

sub open
{

	# get arguments
	my ($file, $mode) = @_;

	# check if path has valid data
	if (isset $file->attr('path'))
	{

		# resolve mode strings
		if ($mode eq 'r') { $mode = '<'; }
		elsif ($mode eq 'w') { $mode = '>'; }
		elsif ($mode eq 'rw') { $mode = '<+'; }

		# create a new file handle of the given file type
		my $fh = join('::', 'OCBNET::IO::File', uc $file->ftype)->new;

		# try to open the filehandle with mode
		my $rv = $fh->open($file->path, $mode);

		# give an error message if open failed for any reason
		die "could not open ", $file->dpath, "\n" unless $rv;

		# store the handle to the object
		$file->{'handle'} = $fh if $fh;

		# copy encoding from handle to object
		$file->encoding = $fh->encoding if $fh->encoding;

		# aquire a file lock (wait for a certain amount of time)
		$rv = $file->lock($mode eq '<' ? LOCK_SH : LOCK_EX, 4);

		# error out if we could not aquire a lock in time
		die "could not aquire file lock for ", $file->path, "\n" unless $rv;

		# do not change data
		$fh->binmode(':raw');

		# return filehandle
		return $fh;

	}
	else
	{

		# error out with a reasonable message
		die "tried to open handle with no path";

	}

}

################################################################################
################################################################################
1;

