###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
###################################################################################################
package OCBNET::Webmerge::Runner::Webserver::Listener;
###################################################################################################

use Carp;
use strict;
use warnings;

###################################################################################################

# define our version string
BEGIN { $OCBNET::Webmerge::Runner::Webserver::Listener::VERSION = "0.9.0" }

# load exporter and inherit from it
BEGIN { use Exporter qw(); our @ISA = qw(Exporter) }

# define our functions to be exported
BEGIN { our @EXPORT = qw(); }

use base 'IO::Socket::INET';


use OCBNET::Webmerge::Runner::Webserver::Client;
###################################################################################################

# load core io module
# use OCBNET::Webmerge::Runner::IO;
# load core path module
# use OCBNET::Webmerge::Runner::Path;

###################################################################################################

sub new
{

	my ($pkg, $server, $config, @args) = @_;

	unless ($config->{'webport'})
	{ $config->{'webport'} = 8000; }
	my $port = $config->{'webport'};

	print "listening on port ", $port, "\n";

	# call parent to create object
	my $sock = ref $pkg ? $pkg
	            : $pkg->SUPER::new(
	              	Listen => 5,
	              	LocalPort => $port,
	              	Proto => 'tcp'
	            ) or die $!;

	${*$sock}{'io_server'} = $server;

	bless $sock, $pkg unless ref $pkg;

	return $sock;

}

###################################################################################################

sub canRead
{

	my ($sock) = @_;

	my $server = ${*$sock}{'io_server'};

	my $handle = $sock->accept("OCBNET::Webmerge::Runner::Webserver::Client");


	${*$handle}{'test_wbuf'} = '';

	${*$handle}{'io_client'} = {
		'state' => 0
	};

	${*$handle}{'io_server'} = $server;

	$handle->rbuf = '';
	$handle->wbuf = '';


#print "client ", $client->fileno, "\n";
	# my $handle = OCBNET::Webmerge::Runner::Webserver::Client->new($client, $server);
# print "handle ", $handle->fileno, "\n";

	$server->addHandle($handle);

	$server->captureRead($handle);
	$server->captureError($handle);

}

sub canWrite
{

	print "listener can write\n";

}

sub hasError
{

	print "listener has error\n";

}

###################################################################################################
###################################################################################################
1;
