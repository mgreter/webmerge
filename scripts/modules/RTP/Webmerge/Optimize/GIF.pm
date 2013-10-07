###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
###################################################################################################
package RTP::Webmerge::Optimize::GIF;
###################################################################################################

use Carp;
use strict;
use warnings;

###################################################################################################

# setup some global settings
BEGIN
{
	# enable (or disable) different optimizer executables
	$ENV{'WEBMERGE_GIFSICLE'} = 1 unless exists $ENV{'WEBMERGE_GIFSICLE'};
}

###################################################################################################

# define our version string
BEGIN { $RTP::Webmerge::Optimize::GIF::VERSION = "0.70" }

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
	$config->{'optimize-gif'} = undef;

	# connect each tmpl variable with the getOpt option
	return ('optimize-gif|gif!', \ $config->{'cmd_optimize-gif'});

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
	{ $config->{'optimize-gif'} = 0; }

	# do nothing if feature is disabled
	return unless $config->{'optimize-gif'};

	# get the optimization level (1 to 3)
	my $lvl = '-O' . range($config->{'level'}, 1, 4, 3);

	# define executables to optimize gifs
	$executables{'gifsicle'} = ['gifopt', "$lvl -o \"%s\" \"%s\""] if $ENV{'WEBMERGE_GIFSICLE'};

};
# EO push checker

###################################################################################################

# now create a new file optimizer subroutine and hook it into our optimizers
$RTP::Webmerge::Optimize::optimizer{'gif'} = RTP::Webmerge::Optimize::optimize('gif');

###################################################################################################
###################################################################################################
1;
