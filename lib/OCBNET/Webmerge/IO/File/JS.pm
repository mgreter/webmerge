################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::IO::File::JS;
################################################################################
use base qw(OCBNET::Webmerge::IO::Mixin::SourceMap);
################################################################################
use base qw(OCBNET::Webmerge::IO::File::TXT);
################################################################################

use strict;
use warnings;

################################################################################
# implement for file interface
# find out why this cannot be in IO::File
# has def to do with multiple inheritance
################################################################################

# sub include { return $_[1] }
# sub resolve { return $_[1] }
# sub importer { return $_[1] }
# sub exporter { return $_[1] }

################################################################################

sub ftype { 'js' }

sub prefix
{
	die "ja";
}

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

	# return the script include string (make it relative to output)
	return sprintf($js_include_tmpl, $input->weburl(1));

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
