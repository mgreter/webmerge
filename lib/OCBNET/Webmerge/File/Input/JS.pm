################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::File::Input::JS;
################################################################################
use base qw(OCBNET::Webmerge::IO::File::JS);
use base qw(OCBNET::Webmerge::File::Input);

################################################################################
# force newline at the end of the content
################################################################################

sub contents
{
	# get result from parent implementation
	my $content = shift->SUPER::contents(@_);
	# return result if content is undefined
	return $content unless defined $content;
	# return result if content is empty
	return $content unless length $content;
	# return if there is a newline at the end
	return $content if $content =~ m/^\s*\z/;
	# add newline to original and return
	${$content} .= "\n"; return $content;
}

sub read
{

	# get the content from parent class
	my $content = $_[0]->SUPER::read;

	${$content} .= ";\n" unless (${$content} =~ m/(?:;|\n)\s*\Z/);

	return $content;
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
