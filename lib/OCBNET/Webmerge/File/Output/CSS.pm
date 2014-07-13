################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::File::Output::CSS;
################################################################################
use base qw(OCBNET::Webmerge::IO::Mixin::SourceMap);
use base qw(OCBNET::Webmerge::IO::Mixin::Checksum);
################################################################################
# this might change again?
# needed so the processor is run!
# yeah, output wants to add more processors
################################################################################
use base qw(OCBNET::Webmerge::IO::File::CSS);
use base qw(OCBNET::Webmerge::File::Output);
################################################################################

# load the core module
# require File::Basename;

# fix the basedir for output to the actual output path
sub basedir2 { die "kooala"; File::Basename::dirname shift->path(@_) }

# sub processors { die "joo"; &OCBNET::Webmerge::File::Output::processors }

################################################################################
# nothing to implement for css
# includes are always relative
################################################################################

sub prefix { "" }
sub suffix { "" }

################################################################################
################################################################################
1;
