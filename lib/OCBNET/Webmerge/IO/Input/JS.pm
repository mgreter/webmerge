################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::IO::Input::JS;
################################################################################
use base qw(OCBNET::Webmerge::IO::File::JS);
use base qw(OCBNET::Webmerge::IO::Input);

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
################################################################################
1;
