################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
# Settings may overrule certain configs
################################################################################
package OCBNET::Webmerge::CmdOption;
################################################################################
use base qw(OCBNET::Webmerge::Object);
use base qw(OCBNET::Webmerge::Config);
################################################################################
use base qw(OCBNET::Webmerge::Tree::Root);
################################################################################

use strict;
use warnings;

################################################################################
# parse command line options via Getopt::Long
################################################################################
use OCBNET::Webmerge qw(options %longopts %defaults %values);
################################################################################

sub parse
{

	# get passed input arguments
	my ($config, $longopts, $args) = @_;

	# check if we have a config file
	if (exists $longopts->{'configfile'})
	{
		# assign config file option first to load plugins
		$values{'configfile'} = $longopts->{'configfile'};
	}

	# try to load our main config file
	# this may load additional plugins
	$config->SUPER::parse;

	# collect longopts and assign variables to options
	my %options = (%{$config->{'options'}}, %{$longopts});
	$values{$_} = $options{$_} foreach keys %options;

	# simply store the arguments
	$config->{'args'} = [ @{$args || []} ];

	# return object
	return $config;

}

# just show all registered options
# basically only usefull for debug
# but you can be sure these exist
# ******************************************************************************
sub opts
{
	# print all names
	print join("\n", map {
		s/(?:\!|\=.*?)$//;
		join(', ', map { '-' . $_ } split /\|/);
	} sort keys %longopts);
	# exit ok
	exit 0;
}

################################################################################
# accessor methods
################################################################################

# return node type
sub type { 'CMDOPTIONS' }

################################################################################
################################################################################
1;
