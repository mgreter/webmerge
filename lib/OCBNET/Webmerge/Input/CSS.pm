################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::Input::CSS;
################################################################################
use base qw(
	OCBNET::Webmerge::Input
	OCBNET::Webmerge::IO::File::CSS
);
################################################################################
use OCBNET::CSS3;
################################################################################

use strict;
use warnings;

################################################################################

# define the template for the script includes
# don't care about doctype versions, dev only
our $css_include_tmpl = '@import url(\'%s\');' . "\n";

################################################################################
# generate a css include (@import)
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
	return sprintf($css_include_tmpl, $path);

}

################################################################################
# helper to rebase a url
################################################################################

sub importURL ($;$) { OCBNET::CSS3::URI->new($_[0], $_[1])->wrap }
sub exportURL ($;$) { OCBNET::CSS3::URI->new($_[0])->export($_[1]) }

################################################################################
# import the css content
# resolve urls to abs paths
################################################################################
use OCBNET::CSS3::Regex::Base qw($re_url);
################################################################################

sub import
{
	# get arguments
	my ($node, $data) = @_;
	# otherwise import format
	$node->logFile('import');
	# get import base dir
	my $base = $node->dirname;
	# alter all urls to absolute paths
	${$data} =~ s/($re_url)/importURL $1, $base/ge;
	# update cache and return altered data
	return $data;
}

################################################################################
# some accessor methods
################################################################################

# return node type
sub type { 'INPUT::CSS' }


################################################################################
################################################################################
1;

__DATA__


sub deps
{
	my ($node) = @_;

	my $sheet = $node->sheet;



my @objects = ($sheet);
my @imports = ($node->path);

# process as long as we have objects
while (my $object = shift @objects)
{
# process children array
if ($object->{'children'})
{
# add object to counter arrays
push @objects, @{$object->{'children'}};
push @imports, $object->url if $object->type eq 'import';
}
}

return @imports;


	print $sheet->render eq ${$node->read} ? "ok" : "Nok";

	die "i have deps";
}
