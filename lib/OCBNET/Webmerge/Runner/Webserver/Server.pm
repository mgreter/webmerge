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

	# create listener socket for clients to connect
	# ToDo: Maybe move this out to a generic method
	my $listener = OCBNET::Webmerge::Runner::Webserver::Listener->new($server, $config);

	# let the server handle it
	$server->addHandle($listener);
	# waiting for something to read
	$server->captureRead($listener);
	$server->captureError($listener);

	# return object
	return $server;

}

###################################################################################################
# add a socket object to server
###################################################################################################

sub addHandle
{

	# get input arguments
	my ($server, $handle) = @_;

	# add handle to array (not sure why i prefetch fileno)
	push(@{$server->{'fds'}}, [$handle->fileno, $handle]);

	# return object
	return $server;

}

###################################################################################################
# remove a socket object from server
###################################################################################################

sub removeHandle
{

	# get input arguments
	my ($server, $handle) = @_;

	# revoke all interests
	$server->uncaptureRead($handle);
	$server->uncaptureWrite($handle);
	$server->uncaptureError($handle);

	# fetch file handle nr
	my $fd = $handle->fileno;

	# remove from array
	@{$server->{'fds'}} =
		grep { $_->[0] ne $fd }
			@{$server->{'fds'}};

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

	# get arguments
	my ($server) = @_;

	# event loop
	while (1)
	{

		# make a copy of the data
		my $rbit = $server->{'rbit'};
		my $wbit = $server->{'wbit'};
		my $ebit = $server->{'ebit'};

		# printf "in rbit %0*v8b\n", " ", $rbit;
		# printf "in wbit %0*v8b\n", " ", $wbit;
		# printf "in ebit %0*v8b\n", " ", $ebit;

		# wait for handles with action
		my $rv = select($rbit, $wbit, $ebit, 0.25);

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
	# EO event loop

}

###################################################################################################
# resolve a uri to an actual file
# lookup in various resource dirs
###################################################################################################
use File::Spec::Functions qw(rel2abs catfile);
###################################################################################################

sub webresolve
{

	# get input arguments
	my ($server, $path) = @_;

	# get resource roots from config (too tight coupled!)
	my $roots = $server->{'config'}->config('webresources');

	# get webroot from config (too tight coupled!)
	my $webroot = $server->{'config'}->webroot;

	# make sure that we have an array reference
	$roots = [$roots || '.'] if (ref $roots ne "ARRAY");

	# die with a fatal error if the api is not used correctly
	die "relative path given for webresolve" if ! $path =~ m/^[\/\\]/;

	# loop each root until found
	foreach my $root (@{$roots})
	{
		# relative roots are under webroot
		$root = rel2abs($root, $webroot);
		# path is always relative to root
		my $file = rel2abs('./' . $path, $root);
		# return if the path actually exists
		return ($root, $file) if -e $file;
	}

	# return default result
	return ($webroot, catfile($webroot, $path));

}

###################################################################################################
###################################################################################################
1;
