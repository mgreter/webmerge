################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::IO::Mixin::SourceMap;
################################################################################

use strict;
use warnings;

################################################################################
# write sourcemap
################################################################################
use  OCBNET::Webmerge::IO::MAP;
################################################################################

sub sourcemap
{

	# get passed input arguments
	my ($file, $data, $smap, $options) = @_;

	# assertion for valid source map
	return unless defined $smap;

	# create a new source map file handle with us as parent
	$options->{'srcmap_fh'} = OCBNET::Webmerge::IO::MAP->new($file);

	# already render the data (will be used later, but needed for checksum)
	$options->{'srcmap_data'} = \ $smap->render($options->{'srcmap_fh'}->path);

	# finally write the source map to the disk (atomically)
	$options->{'srcmap_fh'}->write($options->{'srcmap_data'});

	${$data} .= "\n"; # link the source map into the original output data
	${$data} .= sprintf "//# sourceMappingCRC=%s\n", $options->{'srcmap_fh'}->crc;
	${$data} .= sprintf "//# sourceMappingURL=%s\n", $options->{'srcmap_fh'}->basename;

}

################################################################################
################################################################################
1;
