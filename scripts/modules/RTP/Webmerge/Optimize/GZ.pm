###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
###################################################################################################
package RTP::Webmerge::Optimize::GZ;
###################################################################################################

use Carp;
use strict;
use warnings;

###################################################################################################

# setup some global settings
BEGIN
{
	# enable (or disable) different optimizer executables
	$ENV{'WEBMERGE_ADVDEF'} = 1 unless exists $ENV{'WEBMERGE_ADVDEF'};
}

###################################################################################################

# define our version string
BEGIN { $RTP::Webmerge::Optimize::GZ::VERSION = "0.70" }

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
	$config->{'optimize-gz'} = 1;

	# connect each tmpl variable with the getOpt option
	return ('optimize-gz|gz!', \ $config->{'cmd_optimize-gz'});

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
	{ $config->{'optimize-gz'} = 0; }

	# do nothing if feature is disabled
	return unless $config->{'optimize-gz'};

	# get the optimization level (1 to 4)
	my $lvl = '-' . range($config->{'level'}, 1, 5, 4);

	# define executables to optimize gz archives
	$executables{'advdef[gz]'}  = ['gzopt', "-z $lvl --quiet \"%s\"", 2] if $ENV{'WEBMERGE_ADVDEF'};

};
# EO push checker

###################################################################################################

# now create a new file optimizer subroutine and hook it into our optimizers
$RTP::Webmerge::Optimize::optimizer{'gz'} = RTP::Webmerge::Optimize::fileOptimizer('gz');

###################################################################################################
###################################################################################################
1;
