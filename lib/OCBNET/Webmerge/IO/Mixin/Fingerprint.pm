################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::IO::Mixin::Fingerprint;
################################################################################

use strict;
use warnings;

###############################################################################
use OCBNET::Webmerge qw(options);
###############################################################################
options('fingerprint', '=s', 'q');
options('fingerprint-dev', '=s', 'q');
options('fingerprint-live', '=s', 'q');
options('fingerprint-length', '=s', 8);
###############################################################################

sub fingerprint
{

	# get passed variables
	my ($file, $target, $data) = @_;

	# debug assertion to report unwanted input
	warn "undefined target" unless defined $target;

	# get the fingerprint config option if not explicitly given
	my $technique = lc substr $file->option(join('-', 'fingerprint', $target)), 0, 1;

	# do not add a fingerprint at all if feature is disabled
	return $file->path unless $file->option('fingerprint') && $technique;

	# simply append the fingerprint as a unique query string
	return join('?', $file->path, $file->md5short($data)) if $technique eq 'q';

	# insert the fingerprint as a (virtual) last directory to the given path
	# this will not work out of the box - you'll need to add some rewrite directives
	return join('/', $file->dirname, $file->md5short($data), $file->basename) if $technique eq 'd';
	return join('/', $file->dirname, $file->md5short($data) . '-' . $file->basename) if $technique eq 'f';

	# exit and give an error message if technique is not known
	die 'fingerprint technique <', $technique, '> not implemented', "\n";

	# at least return something
	return $file->path;

}

################################################################################
################################################################################
1;

