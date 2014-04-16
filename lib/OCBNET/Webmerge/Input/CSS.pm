################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::Input::CSS;
################################################################################
# use base 'OCBNET::Webmerge::IO::Input';
################################################################################
use OCBNET::CSS3;
################################################################################

use strict;
use warnings;

################################################################################
# some accessor methods
################################################################################

sub merge
{

	my ($node, $context) = @_;
	my $src = $node->attr('src');

}

sub deps
{
	my ($node) = @_;

	my $sheet = OCBNET::CSS3->new;

	$sheet->parse(${$node->read});


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


	die $sheet->render eq ${$node->read} ? "ok" : "Nok";

	die "i have deps";
}

# return node type
sub type { 'INPUT::CSS' }


################################################################################
################################################################################
1;