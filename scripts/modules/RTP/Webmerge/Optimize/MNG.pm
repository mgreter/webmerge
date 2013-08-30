#!/usr/bin/perl

###################################################################################################
# http://optipng.sourceforge.net/pngtech/optipng.html
# pngrewrite, pngcrush, OptiPNG, AdvanceCOMP (advpng), PNGOut 
###################################################################################################
package RTP::Webmerge::Optimize::MNG;
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
	$ENV{'WEBMERGE_ADVMNG'} = 1 unless exists $ENV{'WEBMERGE_ADVMNG'};
}

###################################################################################################

# define our version string
BEGIN { $RTP::Webmerge::Optimize::MNG::VERSION = "0.70" }

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
	$config->{'cmd_optimize-mng'} = 0;

	# connect each tmpl variable with the getOpt option
	return ('optimize-mng|mng!', \ $config->{'cmd_optimize-mng'});

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
	{ $config->{'optimize-mng'} = 0; }

	# do nothing if feature is disabled
	return unless $config->{'optimize-mng'};

	# define executables to optimize mngs
	$executables{'advmng'}  = ['mngopt', '-z -4 --quiet "%s"', 2] if $ENV{'WEBMERGE_ADVMNG'};
	$executables{'advdef[mng]'}  = ['mngopt', '-z -4 --quiet "%s"', 2] if $ENV{'WEBMERGE_ADVDEF'};

};
# EO push checker

###################################################################################################

# now create a new file optimizer subroutine and hook it into our optimizers
$RTP::Webmerge::Optimize::optimizer{'mng'} = RTP::Webmerge::Optimize::fileOptimizer('mng');

###################################################################################################
###################################################################################################
1;