###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
###################################################################################################
package RTP::Webmerge::Process::JS;
###################################################################################################

use Carp;
use strict;
use warnings;

###################################################################################################

# define our version string
BEGIN { $RTP::Webmerge::Process::JS::VERSION = "0.70" }

# load exporter and inherit from it
BEGIN { use Exporter qw(); our @ISA = qw(Exporter) }

# define our functions to be exported
BEGIN { our @EXPORT = qw(dejquery); }

###################################################################################################

use RTP::Webmerge qw(%processors);

###################################################################################################

# replace jquery calls with simple dollar signs
# this way we can have best code compatibility
# and still use the dollar sign when possible
sub dejquery
{

	# get input variables
	my ($data, $config) = @_;

	# replace "jquery(" and "jquery."
	${$data} =~ s/jQuery([\(\.])/\$$1/gm;

	# return success
	return 1;

}
# EO sub dejquery

###################################################################################################

# register the processor function
$processors{'dejquery'} = \& dejquery;

###################################################################################################
###################################################################################################
1;