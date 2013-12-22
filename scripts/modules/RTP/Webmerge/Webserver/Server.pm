###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
###################################################################################################
package RTP::Webmerge::Webserver::Server;
###################################################################################################

use Carp;
use strict;
use warnings;

###################################################################################################

# define our version string
BEGIN { $RTP::Webmerge::Webserver::Server::VERSION = "0.9.0" }

# load exporter and inherit from it
BEGIN { use Exporter qw(); our @ISA = qw(Exporter) }

# define our functions to be exported
BEGIN { our @EXPORT = qw(); }

###################################################################################################

# load core io module
use RTP::Webmerge::IO;
# load core path module
use RTP::Webmerge::Path;

use RTP::Webmerge::Webserver::Listener;

###################################################################################################

sub new
{

	my ($pkg, $config) = @_;

	my $self = {

		'fds' => [],
		'rbit' => '',
		'wbit' => '',
		'ebit' => '',
		'config' => $config,

	};

	bless $self, $pkg;

	my $listener = RTP::Webmerge::Webserver::Listener->new($self);

	$self->addHandle($listener);

	$self->captureRead($listener);
	$self->captureError($listener);

	return $self;

}

###################################################################################################

sub removeHandle
{

	my ($self, $handle) = @_;

	$self->uncaptureRead($handle);
	$self->uncaptureWrite($handle);
	$self->uncaptureError($handle);

	my $fd = $handle->fileno;

	@{$self->{'fds'}} = grep {

		$_->[0] ne $fd

	} @{$self->{'fds'}};

}

sub addHandle
{

	my ($self, $handle) = @_;

	push(@{$self->{'fds'}}, [$handle->fileno, $handle]);

	return $handle;

}

###################################################################################################

# register/unregister interest in the events
sub captureRead { vec($_[0]->{'rbit'}, $_[1]->fileno, 1) = 1 }
sub captureWrite { vec($_[0]->{'wbit'}, $_[1->fileno], 1) = 1 }
sub captureError { vec($_[0]->{'ebit'}, $_[1]->fileno, 1) = 1 }
sub uncaptureRead { vec($_[0]->{'rbit'}, $_[1]->fileno, 1) = 0 }
sub uncaptureWrite { vec($_[0]->{'wbit'}, $_[1]->fileno, 1) = 0 }
sub uncaptureError { vec($_[0]->{'ebit'}, $_[1]->fileno, 1) = 0 }

###################################################################################################

sub run
{

	my ($self) = @_;

	while (1)
	{

		# make a copy of the data
		my $rbit = $self->{'rbit'};
		my $wbit = $self->{'wbit'};
		my $ebit = $self->{'ebit'};

		# enable fd in vector table
		# vec(my $rbit = '', $fileno, 1) = 1;

		# print "going for select call\n";

		# printf "in rbit %0*v8b\n", " ", $rbit;
		# printf "in wbit %0*v8b\n", " ", $wbit;
		# printf "in ebit %0*v8b\n", " ", $ebit;

		# wait for handles with action
		my $rv = select($rbit, $wbit, $ebit, 3);

		# print "select returns $rv $!\n";

		# get fd numbers array
		my $fds = $self->{'fds'};

		# printf "out rbit %0*v8b\n", " ", $rbit;
		# printf "out wbit %0*v8b\n", " ", $wbit;
		# printf "out ebit %0*v8b\n", " ", $ebit;

		# collect actions
		foreach my $fd (@{$fds})
		{
			last;

			if (ref($fd->[1]) eq "RTP::Webmerge::Webserver::Client")
			{
				use Socket;
				my $hersockaddr = getpeername($fd->[1]);
				my ($port, $iaddr) = sockaddr_in($hersockaddr);

				print $fd->[0], " : ", $fd->[1]->client->{'state'}, " -- ", $fd->[1]->client->{'rbuf'}, " \@ ", $port, "\n";

			}
			else
			{
				print $fd->[0], " : ", ref($fd->[1]), "\n";
			}
		}

		# collect actions
		foreach my $fd (@{$fds})
		{

			# collect all handles with action bit set
			$fd->[1]->canRead if vec($rbit, $fd->[0], 1);
			$fd->[1]->canWrite if vec($wbit, $fd->[0], 1);
			$fd->[1]->hasError if vec($ebit, $fd->[0], 1);

			$fd->[1]->flush;
		}

		# sleep 1;

	}

}


###################################################################################################
###################################################################################################
1;
