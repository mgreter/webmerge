###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
###################################################################################################
package OCBNET::Webmerge::Optimize::MNG;
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
	$ENV{'WEBMERGE_ADVMNG'} = 1 unless exists $ENV{'WEBMERGE_ADVMNG'};
}

###################################################################################################
use OCBNET::Webmerge qw(options);
###################################################################################################

options('optimize-zip', 'zip!', undef);

###################################################################################################
use OCBNET::Webmerge qw(range);
###################################################################################################

sub advmng
{
	# get the optimization level (1 to 9)
	my $lvl = range($_[0]->option('level'), 1, 5, 4);
	# return commandline for process
	return sprintf("-z -%d --quiet \"%s\"", $lvl, $_[0]->path);
}

sub advdef
{
	# get the optimization level (1 to 9)
	my $lvl = range($_[0]->option('level'), 1, 5, 4);
	# return commandline for process
	return sprintf("-z -%d --quiet \"%s\"", $lvl, $_[0]->path);
}

###################################################################################################
use OCBNET::Webmerge qw(optimizers);
###################################################################################################

optimizers('mngopt', 'advmng', \ &advmng, 1) if $ENV{'WEBMERGE_ADVDEF'};
optimizers('mngopt', 'advdef', \ &advdef, 2) if $ENV{'WEBMERGE_ADVMNG'};

###################################################################################################
###################################################################################################
1;
