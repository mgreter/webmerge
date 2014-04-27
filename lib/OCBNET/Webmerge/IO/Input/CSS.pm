################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::IO::Input::CSS;
################################################################################
use base qw(OCBNET::Webmerge::IO::File::CSS);
use base qw(OCBNET::Webmerge::IO::Input);

################################################################################
# invalidate the cached sheet
################################################################################

sub revert
{
	# shift context
	my $file = shift;
	# call parent class
	$file->SUPER::revert(@_);
	# remove cached items
	delete $file->{'sheet'};
}

sub commit
{
	# shift context
	my $file = shift;
	# call parent class
	$file->SUPER::commit(@_);
	# remove cached items
	delete $file->{'sheet'};
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
################################################################################
1;
