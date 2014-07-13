###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
###################################################################################################
package OCBNET::Webmerge::Runner::Webserver::Listener;
###################################################################################################

use Carp;
use strict;
use warnings;

# inherits from network socket
use base 'IO::Socket::INET';

###################################################################################################
# create a new listener socket (accept new clients)
###################################################################################################
use OCBNET::Webmerge::Runner::Webserver::Client;
###################################################################################################

sub new
{

	# get input arguments for new listener
	my ($pkg, $server, $config, @args) = @_;

	# apply default if not specified
	unless ($config->{'webport'})
	{ $config->{'webport'} = 8000; }
	my $port = $config->{'webport'};

	# print a debug message to the console
	print "listening on port ", $port, "\n";

	# call parent to create object
	my $sock = ref $pkg ? $pkg
	            : $pkg->SUPER::new(
	                  Listen => 5,
	                  LocalPort => $port,
	                  Proto => 'tcp'
	            ) or die $!;

	# attach the object to the socket
	${*$sock}{'io_server'} = $server;

	# bless object into package
	bless $sock, $pkg unless ref $pkg;

	# new socket
	return $sock;

}

###################################################################################################
# called when server socket has a new connection
###################################################################################################

sub canRead
{

	# input arguments
	my ($sock) = @_;

	# get server object from the socket
	my $server = ${*$sock}{'io_server'};

	# call accept and bless the returned handle into given package
	my $handle = $sock->accept("OCBNET::Webmerge::Runner::Webserver::Client");

	# initialize the client state object
	${*$handle}{'io_client'} = { 'state' => 0 };

	# connect the server to the handle
	# ToDo: should be done by addHandle?
	${*$handle}{'io_server'} = $server;

	# init buffers
	$handle->rbuf = '';
	$handle->wbuf = '';
	# let the server handle it
	$server->addHandle($handle);
	# waiting for something to read
	$server->captureRead($handle);
	$server->captureError($handle);

}

###################################################################################################
# just in case - should never be called
###################################################################################################

sub canWrite { print "listener could write\n" }
sub hasError { print "listener reported error\n" }

###################################################################################################
###################################################################################################
1;
