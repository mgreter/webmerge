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
}

###################################################################################################

# define our version string
BEGIN { $RTP::Webmerge::Optimize::PNG::VERSION = "0.70" }

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
	$config->{'cmd_optimize-png'} = 0;

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

	# define executables to optimize pngs
	$executables{'optipng'} = ['pngopt', '-o3 --quiet "%s"', 1] if $ENV{'WEBMERGE_OPTIPNG'};
#	$executables{'advpng'}  = ['pngopt', '-z -4 --quiet "%s"', 2] if $ENV{'WEBMERGE_ADVPNG'};
#	$executables{'advdef[png]'}  = ['pngopt', '-z -4 --quiet "%s"', 2] if $ENV{'WEBMERGE_ADVDEF'};

};
# EO push checker

###################################################################################################

# now create a new file optimizer subroutine and hook it into our optimizers
$RTP::Webmerge::Optimize::optimizer{'png'} = RTP::Webmerge::Optimize::fileOptimizer('png');

###################################################################################################
###################################################################################################
1;
