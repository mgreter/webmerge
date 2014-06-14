################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::IO::Output::CSS;
################################################################################
# this might change again?
# needed so the processor is run!
# yeah, output wants to add more processors
################################################################################
use base qw(OCBNET::Webmerge::IO::File::CSS);
use base qw(OCBNET::Webmerge::IO::Output);
################################################################################

# load the core module
# require File::Basename;

# fix the basedir for output to the actual output path
sub basedir2 { File::Basename::dirname shift->path(@_) }

sub processors { &OCBNET::Webmerge::IO::Output::processors }

################################################################################
################################################################################
1;
