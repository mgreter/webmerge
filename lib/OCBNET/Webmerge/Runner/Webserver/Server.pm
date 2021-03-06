###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
###################################################################################################
package OCBNET::Webmerge::Runner::Webserver::Server;
###################################################################################################

use Carp;
use strict;
use warnings;

###################################################################################################
# create a new server object (main object)
###################################################################################################
use OCBNET::Webmerge::Runner::Webserver::Listener;
###################################################################################################

sub new
{

	# get input arguments
	my ($pkg, $config) = @_;

	# init object
	my $server = {

		'fds' => [],
		'rbit' => '',
		'wbit' => '',
		'ebit' => '',
		'config' => $config,

	};

	# bless into class
	bless $server, $pkg;

	# create listener socker for clients to connet
	# ToDo: Maybe move this out to a generic method
	my $listener = OCBNET::Webmerge::Runner::Webserver::Listener->new($server, $config);

	# let the server handle it
	$server->addHandle($listener);
	# waiting for something to read
	$server->captureRead($listener);
	$server->captureError($listener);

	# new server
	return $server;

}

###################################################################################################

sub removeHandle
{

	my ($server, $handle) = @_;

	$server->uncaptureRead($handle);
	$server->uncaptureWrite($handle);
	$server->uncaptureError($handle);

	my $fd = $handle->fileno;

	@{$server->{'fds'}} = grep {

		$_->[0] ne $fd

	} @{$server->{'fds'}};

}

sub addHandle
{

	my ($server, $handle) = @_;

# print "add handle $handle\n";

	push(@{$server->{'fds'}}, [$handle->fileno, $handle]);

	return $handle;

}

###################################################################################################

# register/unregister interest in the events
sub captureRead { vec($_[0]->{'rbit'}, $_[1]->fileno, 1) = 1 }
sub captureWrite { vec($_[0]->{'wbit'}, $_[1]->fileno, 1) = 1 }
sub captureError { vec($_[0]->{'ebit'}, $_[1]->fileno, 1) = 1 }
sub uncaptureRead { vec($_[0]->{'rbit'}, $_[1]->fileno, 1) = 0 }
sub uncaptureWrite { vec($_[0]->{'wbit'}, $_[1]->fileno, 1) = 0 }
sub uncaptureError { vec($_[0]->{'ebit'}, $_[1]->fileno, 1) = 0 }

###################################################################################################

sub run
{

	my ($server) = @_;

	while (1)
	{

		# make a copy of the data
		my $rbit = $server->{'rbit'};
		my $wbit = $server->{'wbit'};
		my $ebit = $server->{'ebit'};

		# enable fd in vector table
		# vec(my $rbit = '', $fileno, 1) = 1;

		# print "going for select call\n";

		# printf "in rbit %0*v8b\n", " ", $rbit;
		# printf "in wbit %0*v8b\n", " ", $wbit;
		# printf "in ebit %0*v8b\n", " ", $ebit;

		# wait for handles with action
		my $rv = select($rbit, $wbit, $ebit, 0.25);

		# print "select returns $rv $!\n";

		# get fd numbers array
		my $fds = $server->{'fds'};

		# printf "out rbit %0*v8b\n", " ", $rbit;
		# printf "out wbit %0*v8b\n", " ", $wbit;
		# printf "out ebit %0*v8b\n", " ", $ebit;

		# dispatch events to interested handlers
		foreach (@{$fds}) { $_->[1]->canRead if vec($rbit, $_->[0], 1) }
		foreach (@{$fds}) { $_->[1]->canWrite if vec($wbit, $_->[0], 1) }
		foreach (@{$fds}) { $_->[1]->hasError if vec($ebit, $_->[0], 1) }

	}

}


###################################################################################################
###################################################################################################
1;
