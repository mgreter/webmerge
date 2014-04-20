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
