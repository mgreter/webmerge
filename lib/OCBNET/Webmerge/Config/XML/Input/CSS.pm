################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::Config::XML::Input::CSS;
################################################################################
use base qw(
	OCBNET::Webmerge::Input::CSS
	OCBNET::Webmerge::Config::XML::Input
);
################################################################################

use strict;
use warnings;

################################################################################
# route some method to specific packages
# otherwise they would be consumed by others
################################################################################

sub new { &OCBNET::Webmerge::Config::XML::Input::new }
sub path { &OCBNET::Webmerge::Config::XML::Input::path }
sub parent { &OCBNET::Webmerge::Config::XML::Input::parent }

sub directory {

my ($dirname, $basename, $ext) = File::Basename::fileparse($_[0]->{'path'}|| $_[0]->{'attr'}->{'path'}, '.scss', '.css');

	return $_[0]->SUPER::directory if lc $ext eq '.css' && ! $_[0]->config('rebase-urls-in-css');
	return $_[0]->SUPER::directory if lc $ext eq '.scss' && ! $_[0]->config('rebase-urls-in-scss');

	File::Spec->rel2abs(File::Basename::dirname($_[0]->{'path'} || $_[0]->{'attr'}->{'path'}), $_[0]->SUPER::directory);

}

################################################################################
# some accessor methods
################################################################################

# return node type
sub type { 'INPUT::CSS' }

################################################################################
################################################################################
1;