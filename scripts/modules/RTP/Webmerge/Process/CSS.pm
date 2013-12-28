###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
###################################################################################################
package RTP::Webmerge::Process::CSS;
###################################################################################################

use Carp;
use strict;
use warnings;

###################################################################################################

# define our version string
BEGIN { $RTP::Webmerge::Process::CSS::VERSION = "0.9.0" }

###################################################################################################

# load the additional submodules
use RTP::Webmerge::Process::CSS::Lint qw();
use RTP::Webmerge::Process::CSS::SCSS qw();
use RTP::Webmerge::Process::CSS::SASS qw();
use RTP::Webmerge::Process::CSS::Spritesets qw();
use RTP::Webmerge::Process::CSS::Inlinedata qw();

###################################################################################################
###################################################################################################
1;