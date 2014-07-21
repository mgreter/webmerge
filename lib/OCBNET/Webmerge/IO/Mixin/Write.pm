################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::IO::Mixin::Write;
################################################################################

use strict;
use warnings;

################################################################################
# take care of implementation order
# use other mixins before to overload
################################################################################

# sub exporter {}
sub checksum {}
sub sourcemap {}
sub signature {}

################################################################################
# write scalar atomic
################################################################################
use IO::AtomicFile qw();
################################################################################

sub write
{

	# get passed input arguments
	my ($file, $data, $srcmap) = @_;

	# get resolved path from file node
	my $path = $file->respath($file->path);

	# force relative again
	# extend by other bases
	$path =~ s/^\/+// if $^O ne 'MSWin32';
	$path =~ s/^[\/\\]+// if $^O eq 'MSWin32';

	# create an absolute path again
	$path = $file->abspath($path);

	# do some checking before writing to give usefull error messages
	die "error\nwriting to non existing directory: ", $file->path unless (-d $file->dirname);
	die "error\nwriting to write protected directory: ", $file->path unless (-w $file->dirname);

	# create shared options for hooks
	my $options = { 'path' => $path };

	# ie. export css urls from absolute to relative
	$file->exporter($data, $srcmap, $options) if $file->can('exporter');
	# call the processors chain (remap source maps)
	$file->process($data, $srcmap, $options) if $file->can('process');

	# use OCBNET::SourceMap::Utils; use File::Slurp qw(write_file); warn "======== write ", $file->path . '.dbg.html', "\n" if $srcmap;
	# write_file($file->path . '.map.html', { binmode => ':encoding(utf8)' }, OCBNET::SourceMap::Utils::debugger($data, $srcmap)) if $srcmap;

	# create checksums and comment to source data
	$file->checksum($data, $srcmap, $options) if $file->can('checksum');
	# create and write source map and add link to source data
	$file->sourcemap($data, $srcmap, $options) if $file->can('sourcemap');
	# create checksum signature (no more modifications to source data)
	$file->signature($data, $srcmap, $options) if $file->can('signature');

	# get atomic entry if available
	my $atomic = $file->atomic($path);

	# check if commit is pending
	if (defined $atomic)
	{

		# reset the offset for sniffed headers
		${*$atomic}{'io_atomicfile_pos'} = 0;

		# check if the new data matches the previous commit
		if (${$data} eq ${${*$atomic}{'io_atomicfile_data'}})
		{ warn "warning: rewriting ", $file->dpath, "\n"; }
		else { die "error: rewriting ", $file->dpath, "\n"; }

	}
	# check if file has been read
	elsif ($file->{'readed'})
	{

		# check if the new data matches the previous commit
		if (${$data} eq ${$file->{'readed'}})
		{ warn "warning: overwriting ", $file->dpath, "\n"; }
		else { die "error: overwriting ", $file->dpath, "\n"; }

	}
	# write to the disk
	else
	{

		# create a new atomic instance
		$atomic = IO::AtomicFile->new;

		# add specific webmerge suffix to temp files
		${*$atomic}{'io_atomicfile_suffix'} = '.webmerge';

		# some more options you could fetch via glob
		# my $temp = ${*$atomic}{'io_atomicfile_temp'};
		# my $path = ${*$atomic}{'io_atomicfile_path'};
		# my $closed = ${*$atomic}{'io_atomicfile_closed'};

		# open a new writeable file handle
		my $fh = $atomic->open($path, 'w+');

		# error out if we could not open the file
		die "could not open ", $_[0]->path, "\n$!" unless $fh;

		# truncate the file and ensure encoding
		$fh->truncate(0); $fh->binmode(':raw');

		# attach written scalar to atomic instance
		${*$atomic}{'io_atomicfile_data'} = $data;

		# attach atomic instance to scope
		$file->atomic($path, $atomic);

		# also set the read cache
		$file->{'written'} = $data;

		# encode the data for raw output handle
		${$data} = ${$file->encode($data)};

		# update the checksum (have raw data)
		$file->{'crc'} = $file->md5sum($data, 1);

		# print to raw handle
		print $fh ${$data};

	}

	# return atomic instance
	return $atomic;
}

################################################################################
################################################################################
1;

