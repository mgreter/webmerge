################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::Config;
################################################################################
use base qw(OCBNET::Webmerge::Object);
use base qw(OCBNET::Webmerge::Include);
################################################################################
# require OCBNET::Webmerge::Config::Tree::Node;
# require OCBNET::Webmerge::Config::Tree::Root;
# require OCBNET::Webmerge::Config::Tree::Scope;
################################################################################
# require OCBNET::Webmerge::Config::Makro::Echo;
# require OCBNET::Webmerge::Config::Makro::Eval;
################################################################################
# require OCBNET::Webmerge::Config::Merge::ANY;
# require OCBNET::Webmerge::Config::Merge::CSS;
# require OCBNET::Webmerge::Config::Merge::JS;
################################################################################

use strict;
use warnings;

################################################################################
# get configuration filename and basedir
################################################################################
use File::Basename qw();
################################################################################

# enables the file to be loaded automatically
sub configfile { $_[0]->setting('configfile') }

# just return the base directory of configfile
sub confdir { File::Basename::dirname($_[0]->configfile) }

################################################################################
# overwrite includefile with configfile
################################################################################

# enables the file to be loaded automatically
sub includefile { $_[0]->configfile }

# just return the base directory
sub incdir { $_[0]->confdir }

################################################################################
# accessor methods
################################################################################

# return node type
sub type { 'CONFIG' }

################################################################################
# use base 'OCBNET::Webmerge::Runner';
################################################################################
require OCBNET::Webmerge::Runner;
################################################################################

sub run
{

	# get arguments
	my ($config) = @_;

	# create our arguments array
	# comes from real argv if CmdLine
	my @ARGV = @{$config->{'args'} || []};

	# collect blocks to be executed (ids from argv or all)
	my @blocks = grep { $_ } map { $config->getById($_) } @ARGV;
	push @blocks, $config unless scalar(@blocks) + scalar(@ARGV);

	# execute to runners (for blocks)
	OCBNET::Webmerge::Runner::run(@blocks);

	# commit all changes
	$config->commit(1);

	# return reference
	return $config;

}

################################################################################
################################################################################
1;

__DATA__

