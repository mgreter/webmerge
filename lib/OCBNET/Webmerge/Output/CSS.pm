################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::Output::CSS;
################################################################################
use base qw(
	OCBNET::Webmerge::Output
	OCBNET::Webmerge::IO::File::CSS
);
################################################################################

use strict;
use warnings;

################################################################################
use OCBNET::CSS3::Regex::Base qw($re_url);
################################################################################

sub export
{
	# get arguments
	my ($node, $data) = @_;
	# call export on parent class
	$node->SUPER::export($data);
	# get new export base dir
	my $base = $node->dirname;
	# alter all urls to paths relative to the base directory
	${$data} =~ s/($re_url)/OCBNET::CSS3::URI->new($1)->export($base)/ge;
}

################################################################################

sub compile
{

	# get input variables
	my ($output, $content) = @_;

	# print debug message
	$output->logAction('compile');

	# module is optional
	require OCBNET::CSS3::Minifier;

	# define options hash for minifier
	my $options = { 'level' => 9, 'pretty' => 0 };

	# minify via our own css minifyer
	OCBNET::CSS3::Minifier::minify($content, $options);

}

################################################################################

sub minify
{

	# get input variables
	my ($output, $content) = @_;

	# print debug message
	$output->logAction('minify');

	# module is optional
	require CSS::Minifier;

	# minify via the perl cpan minifyer
	CSS::Minifier::minify('input' => $content);

}

################################################################################
################################################################################
1;