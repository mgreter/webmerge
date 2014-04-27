################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::IO::File::JS;
################################################################################
use base qw(OCBNET::Webmerge::IO::File);
################################################################################

use strict;
use warnings;

################################################################################

sub ftype { 'js' }

################################################################################
################################################################################
1;
__DATA__

################################################################################

# define the template for the script includes
# don't care about doctype versions, dev only
our $js_include_tmpl = 'webmerge.includeJS(\'%s\');' . "\n";

################################################################################
# generate a js include (@import)
# add support for data or reference id
################################################################################

sub include
{

	# get arguments
	my ($input, $output) = @_;

	# get a unique path with added fingerprint
	# is guess target is always dev here, or is it?
	my $path = $input->fingerprint($output->target);

	# return the script include string
	return sprintf($js_include_tmpl, $input->path);

}

sub check
{
 die "ja";
}

################################################################################
# extract the top comment
################################################################################

sub license
{

	# get input arguments
	my ($input, $output) = @_;

	# read the data
	my $data = $input->read;

	# remove everything but the very first comment (first line!)
	${$data} =~m /\A\s*(\/\*(?:\n|\r|.)+?\*\/)\s*(?:\n|\r|.)*\z/m
		# return header with given input path and license or nothing
		? ( \ '/* license for ' . $input->weburl . ' */', $1, '' ) : ();

}

################################################################################

use strict;
use warnings;

################################################################################
# accessor methods
################################################################################

# return node type
sub type { 'FILE::JS' }

################################################################################
################################################################################
1;
