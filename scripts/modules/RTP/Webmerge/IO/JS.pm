###################################################################################################
package RTP::Webmerge::IO::JS;
###################################################################################################

use Carp;
use strict;
use warnings;

###################################################################################################

# define our version string
BEGIN { $RTP::Webmerge::IO::JS::VERSION = "0.70" }

# load exporter and inherit from it
BEGIN { use Exporter qw(); our @ISA = qw(Exporter) }

# define our variables to be exported
BEGIN { our @EXPORT = qw(readJS importJS exportJS writeJS); }

# define our functions to be exported
BEGIN { our @EXPORT_OK = qw(); }

###################################################################################################

# load webmerge file reader
use RTP::Webmerge::IO qw(readfile writefile);

###################################################################################################

# read a js file from the disk
sub readJS
{

	# get input variables
	my ($jsfile) = @_;

	# read complete css file
	my $data = readfile($jsfile);

	# die with an error message that css file is not found
	die "js file <$jsfile> could not be read: $!\n" unless $data;

	# return as string
	return $data;

}
# EO importJS

# mangle JS
sub importJS
{
	return 1;
}
# EO importJS

# mangle JS
sub exportJS
{
	return 1;
}
# EO exportJS

###################################################################################################

# write a js file to the disk
sub writeJS
{

	# get input variables
	my ($path, $data, $config) = @_;

	# write the content to the file and return result
	return writefile($path, $data, $config->{'atomic'})

}
# EO writeJS

###################################################################################################
###################################################################################################
1;
