################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::XML::Include;
################################################################################
use base qw(OCBNET::Webmerge::Include);
# use base qw(OCBNET::Webmerge::XML::File);
use base qw(OCBNET::Webmerge::XML::Tree::Node);
################################################################################

use strict;
use warnings;

################################################################################

# require OCBNET::Webmerge::Config::XML::Include::JS;
# require OCBNET::Webmerge::Config::XML::Include::CSS;
# require OCBNET::Webmerge::Config::XML::Include::HTML;
# require OCBNET::Webmerge::Config::XML::Include::ANY;

################################################################################
use OCBNET::Webmerge qw(notset);
################################################################################

sub started
{
	# get arguments from parser
	my ($node, $webmerge) = @_;
	# get configfile from src attribute
	my $includefile = $node->attr('src');
	# check if the required file path has been set
	die "include without path" if notset $includefile;
	# resolve includefile path now to abspath
	$includefile = $node->fullpath($includefile);
	# register filename directly on object
	$node->includefile = $includefile;
	# create a new parser object on the fly
	# parse include url into current tree node
	OCBNET::Webmerge::XML->new->parse($node);
}

################################################################################
# just connect the namespaces
################################################################################

$OCBNET::Webmerge::XML::parser{'include'} = __PACKAGE__;

################################################################################
################################################################################
1;