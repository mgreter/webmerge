################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::Include;
################################################################################
use base qw(OCBNET::Webmerge::Object);
################################################################################

use strict;
use warnings;

sub initialize
{

	$_[0]->{'options'} = {};

}

################################################################################
# get configuration filename and basedir
################################################################################
use File::Basename qw();
################################################################################

# enables the file to be loaded automatically
sub includefile : lvalue { $_[0]->{'includefile'} }

# just return the base directory of includefile
sub incdir { File::Basename::dirname($_[0]->includefile) }

################################################################################
# accessor methods
################################################################################

# return node type
sub type { 'INCLUDE' }

################################################################################
# generic parser for configfile (xml only so far)
################################################################################
use File::Basename qw(fileparse);
################################################################################

sub parse
{

	# get arguments
	my ($config) = @_;

	# register config filename directly at the object
	# we do not want other configuration to mess with it
	# $config->configfile = $config->setting('configfile');
	# $config->includefile = $config->setting('configfile');
	# get configfile option (might been set by cmd line)

#die $config->setting('configfile');

	my $configfile = $config->respath($config->includefile);
	# parse the configfile into all different parts (mainly for ext)
	my ($basename, $dirname, $ext) = fileparse($configfile, '.xml');


	# handle according to file extension
	if (lc $ext eq '.xml')
	{
		# load the xml config namespace now
		require OCBNET::Webmerge::XML;
		# add parser to our inheritance tree
		push @OCBNET::Webmerge::Config::ISA,
		     'OCBNET::Webmerge::XML::Tree::Root';
		# try to parse the config file into this scope
		# maybe we can reuse an existing parser instance
		OCBNET::Webmerge::XML->new->parse($config);
		# remove parser from inheritance tree
		pop @OCBNET::Webmerge::Config::ISA;
	}
	# die with a message if we cannot handle the extension
	else { die "cannot handle ", $basename, $ext, " config (need xml)\n"; }

	# return reference
	return $config;

}

################################################################################
################################################################################
1;
