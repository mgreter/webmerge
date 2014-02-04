###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
###################################################################################################
package RTP::Webmerge::Webserver;
###################################################################################################

use Carp;
use strict;
use warnings;

###################################################################################################

# define our version string
BEGIN { $RTP::Webmerge::Webserver::VERSION = "0.9.0" }

# load exporter and inherit from it
BEGIN { use Exporter qw(); our @ISA = qw(Exporter) }

# define our functions to be exported
BEGIN { our @EXPORT = qw(webserver); }

###################################################################################################

# load core io module
use RTP::Webmerge::IO;
# load core path module
use RTP::Webmerge::Path;

use RTP::Webmerge::Webserver::Server;

# webserver
sub webserver ($)
{

	# get input variables
	my ($config) = @_;

	my $server = RTP::Webmerge::Webserver::Server->new($config);

	$server->run();

}

###################################################################################################

# extend the configurator
use RTP::Webmerge qw(@initers);

# register initializer
push @initers, sub
{

	# get input variables
	my ($config) = @_;

	# default webserver port
	$config->{'webport'} = 8000;

	# fork a simple webserver to host project
	$config->{'webserver'} = undef;

	# return additional get options attribute
	return (
		'webport=i' => \ $config->{'cmd_webport'},
		'webserver!' => \$config->{'cmd_webserver'}
	);

};
# EO plugin initer

###################################################################################################
###################################################################################################
1;


