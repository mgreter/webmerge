################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Process::Win32;
################################################################################

use strict;
use warnings;

################################################################################

# declare for exporter
our (@EXPORT, @EXPORT_OK);

# load exporter and inherit from it
BEGIN { use Exporter qw(); our @ISA = qw(Exporter); }

# define our functions that will be exported
BEGIN { push @EXPORT, qw(start suspend resume wait kill prio errmsg) }

################################################################################
# load core windows modules
################################################################################

use Win32; use Win32::Process;

################################################################################
# load additional modules
################################################################################

sub start
{

	warn "start ", $_[0]->cmd, " ", $_[0]->args, "\n";

	my $retval =
	# start the process
	Win32::Process::Create
	(
		my $proc, # container
		$_[0]->cmd, # appname
		# fixes a bug (IMO)
		' ' . $_[0]->args, # cmdline
		0, # iflags
		$_[0]->prio, # cflags
		$_[0]->cwd # curdir
	);

	# assign proc to pid
	$_[0]->{'pid'} = $proc;

	# return value
	return $retval;

}

################################################################################
# implement interface
################################################################################

sub wait { shift->{'pid'}->Wait(@_) }
sub resume { shift->{'pid'}->Resume(@_) }
sub suspend { shift->{'pid'}->Suspend(@_) }

################################################################################
#
################################################################################

sub errmsg
{
	die "errmsg";
}

sub prio
{
	NORMAL_PRIORITY_CLASS
}

################################################################################
################################################################################
1;
