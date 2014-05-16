################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
# Optimizers work on files and not on data stream. They replace the file
# inplace and have therefore be executed before or after other merge steps.
# It is used to optimize images and/or text files (html/css/js), but it is
# also used by the spriteset generator (which optimizes the resulting png).
################################################################################
package OCBNET::Webmerge::Optimize;
################################################################################
use base 'OCBNET::Webmerge::Tree::Node';
################################################################################

use strict;
use warnings;

################################################################################
use OCBNET::Webmerge qw(options);
################################################################################

options('jobs', '|j=i', 2);
options('level', '|lvl=f', 2);
options('optimize', '|opt!', -1);

################################################################################

sub execute
{
	# check if the option is enabled
	return unless $_[0]->setting('optimize');
	# go on with the execution
	shift->SUPER::execute(@_);
}

################################################################################
# load additional modules
################################################################################

require OCBNET::Webmerge::Optimize::ANY;
require OCBNET::Webmerge::Optimize::GIF;
require OCBNET::Webmerge::Optimize::PNG;
require OCBNET::Webmerge::Optimize::ZIP;
require OCBNET::Webmerge::Optimize::MNG;
require OCBNET::Webmerge::Optimize::JPG;
require OCBNET::Webmerge::Optimize::GZ;

################################################################################
################################################################################
1;
