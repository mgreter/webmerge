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
# some accessor methods
################################################################################


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

################################################################################
use OCBNET::CSS3::Regex::Base qw($re_url wrapUrl fromUrl);
################################################################################


sub import
{

	my ($node) = @_; # , $data

	# check if cache exists
	if (exists $node->{'import'})
	{
		$node->logFile('  import[I]');
		return $node->{'import'};
	}
	# otherwise import format
	$node->logFile('  import[i]');
	# get import base dir
	my $base = $node->dirname;
	print $node, " - ", $base, "\n";
	# get data from parent class
	my $data = $node->content(@_);
	# alter all urls to absolute paths
	${$data} =~ s/($re_url)/OCBNET::CSS3::URI->new($1, $base)->wrap()/ge;
	# update cache and return altered data
	return $node->{'import'} = $data;
}



# return node type
sub type { 'INPUT::CSS' }


################################################################################
################################################################################
1;