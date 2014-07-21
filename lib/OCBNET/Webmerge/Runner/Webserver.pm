################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::Runner::Webserver;
################################################################################

use strict;
use warnings;

################################################################################
# implement webserver
################################################################################

sub webserver
{

	# create the config
	my ($context) = @_;

	# load the webserver modules, instantiate and run
	require OCBNET::Webmerge::Runner::Webserver::Server;

	OCBNET::Webmerge::Runner::Webserver::Server->new($context)->run();

	# webserver should never return I guess?
	die "fatal: webserver should have exited";

}

################################################################################
# register our tool within the main module
################################################################################

OCBNET::Webmerge::Runner::register('webserver|s', \&webserver, - 20, 0);

################################################################################
################################################################################
1;
