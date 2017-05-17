###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
###################################################################################################
package RTP::Webmerge::Optimize::WOFF;
###################################################################################################

use Carp;
use strict;
use warnings;

###################################################################################################

# setup some global settings
BEGIN
{
	# enable (or disable) main optimizer executables
	$ENV{'WEBMERGE_WOFF'} = 1 unless exists $ENV{'WEBMERGE_WOFF'};
}

###################################################################################################

# define our version string
BEGIN { $RTP::Webmerge::Optimize::WOFF::VERSION = "0.9.0" }

###################################################################################################

# load webmberge module variables to hook into
use RTP::Webmerge qw(@initers @checkers %executables range);

###################################################################################################

# push to initers
# return for getOpts
push @initers, sub
{

	# get config
	my ($config) = @_;

	# create config variable to be available
	$config->{'optimize-woff'} = undef;

	# connect each tmpl variable with the getOpt option
	return ('optimize-woff|woff!', \ $config->{'cmd_optimize-woff'});

};
# EO push initer

###################################################################################################

# push to checkers
push @checkers, sub
{

	# get config
	my ($config) = @_;

	# disable if not optimizing
	unless ($config->{'optimize'})
	{ $config->{'optimize-woff'} = 0; }

	# do nothing if feature is disabled
	return unless $config->{'optimize-woff'};

	# get the optimization level (1 to 4/6)
	my $lvl = '-' . range($config->{'level'}, 1, 5, 4);
	my $olvl = '-o' . range($config->{'level'}, 0.5, 6.5, 9);

	# define executables to optimize woff
	$executables{'woff-compress'} = ['woffopt', "\"%s\"", 1] if $ENV{'WEBMERGE_WOFF'};

};
# EO push checker

###################################################################################################

# now create a new file optimizer subroutine and hook it into our optimizers
$RTP::Webmerge::Optimize::optimizer{'woff'} = RTP::Webmerge::Optimize::optimize('woff');

###################################################################################################
###################################################################################################
1;
