###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
###################################################################################################
# http://optipng.sourceforge.net/pngtech/optipng.html
# pngrewrite, pngcrush, OptiPNG, AdvanceCOMP (advpng), PNGOut
###################################################################################################
package RTP::Webmerge::Optimize::PNG;
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
	$ENV{'WEBMERGE_ADVPNG'} = 1 unless exists $ENV{'WEBMERGE_ADVPNG'};
	$ENV{'WEBMERGE_OPTIPNG'} = 1 unless exists $ENV{'WEBMERGE_OPTIPNG'};
	$ENV{'WEBMERGE_ZOPFLIPNG'} = 1 unless exists $ENV{'WEBMERGE_ZOPFLIPNG'};
}

###################################################################################################

# define our version string
BEGIN { $RTP::Webmerge::Optimize::PNG::VERSION = "0.9.0" }

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
	$config->{'optimize-png'} = undef;

	# connect each tmpl variable with the getOpt option
	return ('optimize-png|png!', \ $config->{'cmd_optimize-png'});

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
	{ $config->{'optimize-png'} = 0; }

	# do nothing if feature is disabled
	return unless $config->{'optimize-png'};

	my $level = $config->{'level'};
	# get the optimization level (1 to 4/6)
	my $lvl = '-' . range($level, 1, 5, 4);
	my $olvl = '-o' . range($level, 0.5, 6.5, 9);
	my $iter = '--iterations=' . range($level, 0, 150, 150, 2);

	# define executables to optimize pngs
	$executables{'optipng'} = ['pngopt', "$olvl --quiet \"%s\"", 1] if $ENV{'WEBMERGE_OPTIPNG'};
	$executables{'advpng'}  = ['pngopt', "-z $lvl --quiet \"%s\"", 2] if $ENV{'WEBMERGE_ADVPNG'};
	$executables{'advdef[png]'}  = ['pngopt', "-z $lvl --quiet \"%s\"", 2] if $ENV{'WEBMERGE_ADVDEF'};
	$executables{'zopflipng'}  = ['pngopt', "-y $iter --filters=01234mepb --lossy_8bit --lossy_transparent \"%s\" \"%s\"", 2] if $ENV{'WEBMERGE_ZOPFLIPNG'};

};
# EO push checker

###################################################################################################

# now create a new file optimizer subroutine and hook it into our optimizers
$RTP::Webmerge::Optimize::optimizer{'png'} = RTP::Webmerge::Optimize::optimize('png');

###################################################################################################
###################################################################################################
1;
