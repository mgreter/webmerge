###################################################################################################
package RTP::Webmerge::Checksum;
###################################################################################################

use Carp;
use strict;
use warnings;

###################################################################################################

# define our version string
BEGIN { $RTP::Webmerge::Checksum::VERSION = "0.70" }

# load exporter and inherit from it
BEGIN { use Exporter qw(); our @ISA = qw(Exporter) }

# define our functions to be exported
BEGIN { our @EXPORT = qw(crcCheck); }

###################################################################################################

# use core mdoules for path handling
use File::Basename qw(dirname);
use File::Spec::Functions qw(abs2rel);

# load our local modules
use RTP::Webmerge::IO;
use RTP::Webmerge::Path;
use RTP::Webmerge::IO::CSS qw(readCSS);
use RTP::Webmerge::Fingerprint qw(md5sum);

###################################################################################################

sub crcCheckEntry
{

	# get input variables
	my ($config, $merge, $type) = @_;

	# test if the merge has been disabled
	return if exists $merge->{'disabled'} &&
		lc $merge->{'disabled'} eq 'true';

	# collect all data (files) for this merge
	# my $collection = mergeCollect($config, $merge, $type);

	# process all files to be written for this merge
	foreach my $output (@{$merge->{'output'} || []})
	{

		# test if the merge has been disabled
		return if exists $output->{'disabled'} &&
			lc $output->{'disabled'} eq 'true';

		# create the result hash for various checks
		my $result = { 'dst' => 0, 'src' => 0, 'srcs' => [] };

		# create path to store this generated output
		my $result_path = $output->{'outputpath'};

		# create path to store checksum of this output
		my $checksum_path = join('.', $result_path, 'md5');

		unless (-e $checksum_path)
		{

			print $checksum_path . " not found\n";

		}
		else
		{

			# read the whole checksum file
			my $crc = readfile($checksum_path);

			# split checksum file content into lines
			my @crcs = split(/\s*(?:\r?\n)+\s*/, ${$crc});

			# remove leading checksums
			my $checksum_result = shift(@crcs);
			my $checksum_joined = shift(@crcs);

			# read the previously created file
			my $content = readfile($result_path);

			# check if the generated content changed
			if (md5sum($content) ne $checksum_result)
			{
				printf "FAIL - dst: %s\n", substr(web_url($result_path), - 45);
				printf "=> %s vs %s\n", md5sum($content), $checksum_result;
			}
			else
			{
				printf "PASS - dst: %s\n", substr(web_url($result_path), - 45);
			}

			# declare local variable
			my $crcs_joined = '';

			# process all source files
			foreach my $source (@crcs)
			{

				# split the line into path and checksum
				my ($source_path, $source_crc) = split(/:\s*/, $source, 2);

				# source_path is always relative from the readed checksum file
				$source_path = res_path(join('/', dirname($checksum_path), $source_path));

				# read the previously created file
				my $subcontent = $type ne 'css' ?
				                 readfile($source_path) :
				                 readCSS($source_path, $config);

				$crcs_joined .= my $source_md5 = md5sum($subcontent) || 'na';

				# check against stored value
				if ($source_md5 ne $source_crc)
				{
					printf "  FAIL - src: %s\n", substr(web_url($source_path), - 45);
					printf "  => %s vs %s\n", $source_md5, $source_crc;
				}
				else
				{
					printf "  PASS - src: %s\n", substr(web_url($source_path), - 45);
				}

			}

			my $crc_joined = md5sum(\$crcs_joined);

			if ($crc_joined ne $checksum_joined)
			{
				printf "FAIL - tst: %s\n", substr(web_url(res_path($result_path)), - 45);
			}
			else
			{
				printf "PASS - tst: %s\n", substr(web_url(res_path($result_path)), - 45);
			}


		}



	}

}

# checksum various stuff
# only mkdir is implemented
sub crcCheck
{

	# get input variables
	my ($config) = @_;

	# get the xml config root
	my $xml = $config->{'xml'};

	foreach my $merges (@{$xml->{'merge'} || []})
	{

		# change directory (restore previous state after this block)
		my $dir = RTP::Webmerge::Path->chdir($merges->{'chdir'});

		# do not process if disabled attribute is given and set to true
		unless ($merges->{'disabled'} && lc $merges->{'disabled'} eq 'true')
		{

			foreach my $merge (@{$merges->{'css'} || []})
			{ crcCheckEntry($config, $merge, 'css'); }

			foreach my $merge (@{$merges->{'js'} || []})
			{ crcCheckEntry($config, $merge, 'js'); }

		}

	}


}
# EO sub prepare

###################################################################################################
###################################################################################################
1;