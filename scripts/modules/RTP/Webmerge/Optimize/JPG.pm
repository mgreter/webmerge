###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
###################################################################################################
package RTP::Webmerge::Optimize::JPG;
###################################################################################################

use Carp;
use strict;
use warnings;

###################################################################################################

# setup some global settings
BEGIN
{
	# enable (or disable) different optimizer executables
	$ENV{'WEBMERGE_JPEGTRAN'} = 1 unless exists $ENV{'WEBMERGE_JPEGTRAN'};
	$ENV{'WEBMERGE_JPEGOPTIM'} = 1 unless exists $ENV{'WEBMERGE_JPEGOPTIM'};
}

###################################################################################################

# define our version string
BEGIN { $RTP::Webmerge::Optimize::JPG::VERSION = "0.70" }

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
	$config->{'optimize-jpg'} = undef;

	# connect each tmpl variable with the getOpt option
	return ('optimize-jpg|jpg!', \ $config->{'cmd_optimize-jpg'});

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
	{ $config->{'optimize-jpg'} = 0; }

	# do nothing if feature is disabled
	return unless $config->{'optimize-jpg'};

	# define executables to optimize jpgs
	$executables{'jpegoptim'}  = ['jpgopt', "--quiet \"%s\""] if $ENV{'WEBMERGE_JPEGOPTIM'};
	$executables{'jpegtran'} = ['jpgopt', '-copy none -optimize -outfile "%s" "%s"'] if $ENV{'WEBMERGE_JPEGTRAN'};

};
# EO push checker

###################################################################################################

# now create a new file optimizer subroutine and hook it into our optimizers
$RTP::Webmerge::Optimize::optimizer{'jpg'} = RTP::Webmerge::Optimize::optimize('jpg');

###################################################################################################
###################################################################################################
1;
