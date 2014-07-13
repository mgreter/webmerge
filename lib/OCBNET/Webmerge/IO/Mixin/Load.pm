################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::IO::Mixin::Load;
################################################################################

use strict;
use warnings;

################################################################################
use Encode qw(decode);
################################################################################
# read file path into scalar
################################################################################
use OCBNET::Webmerge qw(isset);
################################################################################

sub load
{

	# get arguments
	my ($file) = @_;

	# get path from node
	my $path = $file->path;

	# declare local variables
	my ($pos, $data) = (0, undef);

	# check if script has valid data
	if (isset $file->attr('script'))
	{

		# get and resolve the script executable path
		my $script = $file->respath($file->attr('script'));

		# shebang should be given by configuration
		# otherwise the script must have execute permission
		my $shebang = $file->attr('shebang') ? $file->attr('shebang') . ' ' : '';

		# execute the script and open the stdout for us
		my $rv = CORE::open my $fh_in, "-|", $shebang . $script;

		# check if we got a valid result from open
		die "error executing $script" unless $rv;

		# read raw data
		binmode $fh_in;

		# set data to script output
		$data = \ join('', <$fh_in>);

	}
	# EO isset script

	# check if path has valid data
	elsif (isset $file->attr('path'))
	{

		# get atomic entry if available
		my $atomic = $file->atomic($path);

		# check if commit is pending
		if (defined $atomic)
		{

			# simply return the last written data
			$data = ${*$atomic}{'io_atomicfile_data'};

			# restore offset position from header sniffing
			$pos = ${*$atomic}{'io_atomicfile_pos'} || 0;

		}
		# read from the disk
		else
		{

			# open readonly filehandle
			my $fh = $file->open('r');

			# implement proper error handling
			die "error ", $path unless $fh;

			# store filehandle offset after sniffing
			$pos = ${*$fh}{'io_atomicfile_off'} = tell $fh;

			# read in the whole content event if we should discharge
			seek $fh, 0, 0 or Carp::croak "could not seek $path: $!";

			# slurp the while file into memory and decode unicode
			my $raw = $file->{'loaded'} = join('', <$fh>);

			# attach written scalar to atomic instance
			$data = ${*$fh}{'io_atomicfile_data'} = \ $raw;

			# store handle as atomic handle
			$file->atomic($path, $fh);

		}

	}
	# EO isset path

	# use inline text
	else
	{

		# get data from inline text
		$data = \ $file->text;

	}
	# EO inline text

	# story a copy to our object
	$file->{'loaded'} = ${$data};

	# create and store the raw data checksum
	$file->{'crc'} = $file->md5sum($data, 1);

	# remove file heading (UTF BOM)
	substr(${$data}, 0, $pos) = '';

	# now decode the raw data into our encoding
	$data = \ decode($file->encoding, ${$data});

	# story a copy to our object
	# $file->{'readed'} = \ "${$data}";

	# return reference
	return $data;

}

################################################################################
################################################################################
1;
