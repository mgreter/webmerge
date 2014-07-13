################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::IO::Mixin::URL;
################################################################################

use strict;
use warnings;

################################################################################
use OCBNET::CSS3::URI qw(exportUrl);
################################################################################

# return (absolute) url to current webroot or given base
# if relative or absolute depends on the current config
# ******************************************************************************
sub weburl
{

	# get arguments
	my ($file, $abs, $base) = @_;

	# use webroot if no specific based passed
	$base = $file->webroot unless defined $base;

	# allow to overwrite this flag
	$abs = 1 unless defined $abs;

	# call function with correct arguments
	return exportUrl($file->path, $base, $abs);

}

# return (relative) url current directory or given base
# if relative or absolute depends on the current config
# ******************************************************************************
sub localurl
{

	# get arguments
	my ($file, $base, $abs) = @_;

	# use webroot if no specific based passed
	$base = $file->workroot unless defined $base;

	# allow to overwrite this flag
	$abs = 0 unless defined $abs;

	# call function with correct arguments
	return exportUrl($file->path, $base, $abs);

}

################################################################################
################################################################################
1;

