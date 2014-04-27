################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
# Settings may overrule certain configs
################################################################################
package OCBNET::Webmerge::CmdLine;
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
use Getopt::Long qw(GetOptions); use Pod::Usage qw(pod2usage);
################################################################################

sub parse
{

	# get arguments
	my ($config) = @_;

	# only parse the config file option
	# load plugins first for more options
	Getopt::Long::Configure("pass_through");

	if (exists $longopts{'configfile'})
	{
		# call options reader only to fetch config file
		GetOptions ($longopts{'configfile'}, \$values{'configfile'})
		or die("Strange error while command line argument parsing\n");
	}

	# try to load our main config file
	# this may load additional plugins
	$config->SUPER::parse;

	# collect longopts and assign variables to options
	my %options = (%{$config->{'options'}}, %longopts);
	my @options = map { ($options{$_}, \$values{$_}) } keys %options;

	# warn user about unknown options
	Getopt::Long::Configure("default");
	# get all options from commandline
	GetOptions(@options) or pod2usage(2);

	# show help page if request by cmdline
	$config->opts if $config->option('opts');
	# show help page if request by cmdline
	$config->help if $config->option('help');
	# show man page if requested by cmdline
	$config->man if $config->option('man');

	# simply store the arguments
	$config->{'args'} = [ @ARGV ];

	# return object
	return $config;

}
################################################################################
# pod2usage takes its info from calling script
# implement documentation in the runner script
################################################################################

# show the help via pod2usage
# ******************************************************************************
sub help { pod2usage(1) }

# show the man page via pod2usage
# ******************************************************************************
sub man { pod2usage(-exitval => 0, -verbose => 2) }

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
sub type { 'CMDLINE' }

################################################################################
################################################################################
1;
