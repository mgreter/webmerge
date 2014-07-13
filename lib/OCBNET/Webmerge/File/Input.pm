################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::File::Input;
################################################################################
use base qw(OCBNET::Webmerge::File::Files);
################################################################################

use strict;
use warnings;

################################################################################
# load additional modules
################################################################################
use OCBNET::Webmerge qw(isset);
################################################################################

# require OCBNET::Webmerge::Input::JS;
# require OCBNET::Webmerge::Input::CSS;
# require OCBNET::Webmerge::Input::HTML;

################################################################################
# render input for output (target)
################################################################################

sub render
{

	# get arguments
	my ($input, $output) = @_;

	# get the target for the include
	my $target = lc ($output->target || 'join');

	if (isset $input->attr('path'))
	{
		# implement some special target handling
		return \ $input->include($output) if ($target eq 'dev');
		return \ $input->license($output) if ($target eq 'license');
	}

	# return scalar ref and source map
	($input->contents, $input->srcmap);

}

sub srcmap
{

	my ($input) = @_;

	my $data = $input->contents;

	my $srcmap = OCBNET::SourceMap::V3->new;

	# maybe we can read an existing source map for the source?
	# check if defined at the end of the file (also remove from input!)

#print "===========\n";
	$srcmap->init2($data, $input->path) or die "could not init source map";
#print ${$data};
#use Data::Dumper;
	#die Dumper($srcmap);

	return $srcmap;

}

################################################################################
# accessor methods
################################################################################

# return node type
sub type { 'INPUT' }

################################################################################
################################################################################
1;
