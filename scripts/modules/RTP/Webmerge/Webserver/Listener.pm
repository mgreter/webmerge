###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
###################################################################################################
package RTP::Webmerge::Webserver::Listener;
###################################################################################################

use Carp;
use strict;
use warnings;

###################################################################################################

# define our version string
BEGIN { $RTP::Webmerge::Webserver::Listener::VERSION = "0.9.0" }

# load exporter and inherit from it
BEGIN { use Exporter qw(); our @ISA = qw(Exporter) }

# define our functions to be exported
BEGIN { our @EXPORT = qw(); }

use base 'IO::Socket::INET';


use RTP::Webmerge::Webserver::Client;
###################################################################################################

# load core io module
use RTP::Webmerge::IO;
# load core path module
use RTP::Webmerge::Path;

###################################################################################################

sub new
{

	my ($pkg, $server, @args) = @_;
print "CREATING ", , "\n";
	# call parent to create object
	my $sock = ref $pkg ? $pkg
	            : $pkg->SUPER::new(
	              	Listen => 5,
	              	LocalPort => '8080',
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

	my $handle = $sock->accept("RTP::Webmerge::Webserver::Client");

	${*$handle}{'io_client'} = {
		'state' => 0, 'rbuf' => '', 'wbuf' => ''
	};
	${*$handle}{'io_server'} = $server;


#print "client ", $client->fileno, "\n";
	# my $handle = RTP::Webmerge::Webserver::Client->new($client, $server);
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
