###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
###################################################################################################
package OCBNET::Webmerge::Runner::Webserver::File;
###################################################################################################

use Carp;
use strict;
use warnings;

# inherits from io file
use base 'IO::File';

###################################################################################################
# create a new file handle
###################################################################################################

sub new
{

	# get input arguments for new file provider
	my ($pkg, $client, $server, $conn, @args) = @_;

	# call new on parent class for object
	my $self = $pkg->SUPER::new(@args);

	# attach variables to glob
	${*$self}{'io_server'} = $server;
	${*$self}{'io_client'} = $client;
	${*$self}{'io_conn'} = $conn;

	# return object
	return $self;

}

###################################################################################################
# can read from file (fill the write buffer)
###################################################################################################

sub canRead
{

	# get handle
	my ($fh) = @_;

	# get variables from glob
	my $conn = ${*$fh}{'io_conn'};
	my $client = ${*$fh}{'io_client'};
	my $server = ${*$fh}{'io_server'};

	# read from file handle into write buffer (append to it)
	my $rv = sysread($fh, $conn->wbuf, 1024 * 16, length($conn->wbuf));

	# would like to write data
	$server->captureWrite($conn);

	# assertion for unexpected behaviour
	# need to verify correct handling first
	die "file read error" unless defined $rv;

	# end of file
	unless ($rv)
	{
		# disconnect the data stream
		${*$conn}{'io_stream'} = undef;
		# close the handle
		$fh->close;
	}

	# return success
	return 1;

}

###################################################################################################
# just in case - should never be called
###################################################################################################

sub canWrite { print "file could write\n" }
sub hasError { print "file reported error\n" }

###################################################################################################
###################################################################################################
1;