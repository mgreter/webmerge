################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::Input::JS;
################################################################################
use base qw(
	OCBNET::Webmerge::Input
	OCBNET::Webmerge::IO::File::JS
);
################################################################################

use strict;
use warnings;

################################################################################

# define the template for the script includes
# don't care about doctype versions, dev only
# define the template for the script includes
our $js_include_tmpl = 'webmerge.includeJS(\'%s\');' . "\n";

################################################################################
# generate a js include (@import)
# add support for data or reference id
################################################################################


sub importURL ($;$) { OCBNET::CSS3::URI->new($_[0], $_[1])->wrap }
sub exportURL ($;$$) { OCBNET::CSS3::URI->new($_[0])->export($_[1]) }

sub include
{

	# get arguments
	my ($input, $output) = @_;

	# get a unique path with added fingerprint
	# is guess target is always dev here, or is it?
	my $path = $input->fingerprint($output->target);
	# return the script include string
	return sprintf($js_include_tmpl, $input->absurl);

}

################################################################################
# some accessor methods
################################################################################

# return node type
sub type { 'INPUT::JS' }

################################################################################
################################################################################
1;