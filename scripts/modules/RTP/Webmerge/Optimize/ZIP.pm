#!/usr/bin/perl

###################################################################################################
package RTP::Webmerge::Optimize::ZIP;
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
	$ENV{'WEBMERGE_ADVZIP'} = 1 unless exists $ENV{'WEBMERGE_ADVZIP'};
}

###################################################################################################

# define our version string
BEGIN { $RTP::Webmerge::Optimize::ZIP::VERSION = "0.70" }

###################################################################################################

# load webmberge module variables to hook into
use RTP::Webmerge qw(@initers @checkers %executables);

###################################################################################################

# push to initers
# return for getOpts
push @initers, sub
{

	# get config
	my ($config) = @_;

	# create config variable to be available
	$config->{'cmd_optimize-zip'} = 1;

	# connect each tmpl variable with the getOpt option
	return ('optimize-zip|zip!', \ $config->{'cmd_optimize-zip'});

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
	{ $config->{'optimize-zip'} = 0; }

	# do nothing if feature is disabled
	return unless $config->{'optimize-zip'};

	# define executables to optimize zips
	$executables{'advzip'}  = ['zipopt', '-z -4 --quiet "%s"', 2] if $ENV{'WEBMERGE_ADVZIP'};
	$executables{'advdef[zip]'}  = ['zipopt', '-z -4 --quiet "%s"', 2] if $ENV{'WEBMERGE_ADVDEF'};

};
# EO push checker

###################################################################################################

# now create a new file optimizer subroutine and hook it into our optimizers
$RTP::Webmerge::Optimize::optimizer{'zip'} = RTP::Webmerge::Optimize::fileOptimizer('zip');

###################################################################################################
###################################################################################################
1;
