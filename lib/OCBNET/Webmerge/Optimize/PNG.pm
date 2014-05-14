###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
###################################################################################################
# http://optipng.sourceforge.net/pngtech/optipng.html
# pngrewrite, pngcrush, OptiPNG, AdvanceCOMP (advpng), PNGOut
###################################################################################################
package OCBNET::Webmerge::Optimize::PNG;
###################################################################################################
use base qw(OCBNET::Webmerge::Optimize::ANY);
###################################################################################################

use strict;
use warnings;

###################################################################################################

BEGIN
{
	# enable optimizer executables if not explicitly disabled
	$ENV{'WEBMERGE_ADVDEF'} = 1 unless exists $ENV{'WEBMERGE_ADVDEF'};
	$ENV{'WEBMERGE_ADVPNG'} = 1 unless exists $ENV{'WEBMERGE_ADVPNG'};
	$ENV{'WEBMERGE_OPTIPNG'} = 1 unless exists $ENV{'WEBMERGE_OPTIPNG'};
}

###################################################################################################
use OCBNET::Webmerge qw(options);
###################################################################################################

options('optimize-png', 'png!', undef);

###################################################################################################
use OCBNET::Webmerge qw(range);
###################################################################################################

sub optipng
{
	# get the optimization level (1 to 9)
	my $olvl = range($_[0]->option('level'), 0.5, 6.5, 9);
	# return commandline for process
	return sprintf("-o%d --quiet \"%s\"", $olvl, $_[0]->path);
	#
}

sub advpng
{
	# get the optimization level (1 to 4)
	my $lvl = range($_[0]->option('level'), 1, 5, 4);
	# return commandline for process
	return sprintf("-z -%d --quiet \"%s\"", $lvl, $_[0]->path);
}

sub advdef
{
	# get the optimization level (1 to 4)
	my $lvl = range($_[0]->option('level'), 1, 5, 4);
	# return commandline for process
	return sprintf("-z -%d --quiet \"%s\"", $lvl, $_[0]->path);
}

###################################################################################################
use OCBNET::Webmerge qw(optimizers);
###################################################################################################

optimizers('pngopt', 'optipng', \ &optipng, 1) if $ENV{'WEBMERGE_OPTIPNG'};
optimizers('pngopt', 'advpng', \ &advpng, 2) if $ENV{'WEBMERGE_ADVPNG'};
optimizers('pngopt', 'advdef', \ &advdef, 2) if $ENV{'WEBMERGE_ADVDEF'};

###################################################################################################
###################################################################################################
1;
