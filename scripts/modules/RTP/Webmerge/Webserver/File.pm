###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
###################################################################################################
package RTP::Webmerge::Webserver::File;
###################################################################################################

use Carp;
use strict;
use warnings;

###################################################################################################

# define our version string
BEGIN { $RTP::Webmerge::Webserver::File::VERSION = "0.9.0" }

# load exporter and inherit from it
BEGIN { use Exporter qw(); our @ISA = qw(Exporter) }

# define our functions to be exported
BEGIN { our @EXPORT = qw(); }

###################################################################################################

use base 'IO::File';

###################################################################################################

sub new
{

	my ($pkg, $client, $server, $conn, @args) = @_;

	my $self = $pkg->SUPER::new(@args);

	${*$self}{'io_server'} = $server;
	${*$self}{'io_client'} = $client;
	${*$self}{'io_conn'} = $conn;

	return $self;

}

sub canRead
{

	my ($fh) = @_;

	my $conn = ${*$fh}{'io_conn'};
	my $client = ${*$fh}{'io_client'};
	my $server = ${*$fh}{'io_server'};

	my $rv = sysread($fh, $conn->wbuf, 1024 * 16, length($conn->wbuf));

	$server->captureWrite($conn);

# print "file has read now $rv\n";

	die "file read error" unless defined $rv;

	unless ($rv)
	{
		# print "!!!!!! file read closed\n";
		${*$conn}{'io_stream'} = undef;
		$fh->close;
		return 1;
	}

	die "file read closed" unless $rv;

}

sub canWrite
{

	die "canWrite\n";

}

sub hasError
{

	die "hasError\n";

}

###################################################################################################
###################################################################################################
1;