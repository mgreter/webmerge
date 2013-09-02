###################################################################################################
package RTP::Webmerge::IO::CSS;
###################################################################################################

use Carp;
use strict;
use warnings;

###################################################################################################

# parse urls out of the css file
# do a lousy match for better performance
our $re_url = qr/url\(\s*[\"\']?((?!data:)[^\)]+?)[\"\']?\s*\)/x;

###################################################################################################

# define our version string
BEGIN { $RTP::Webmerge::IO::CSS::VERSION = "0.70" }

# load exporter and inherit from it
BEGIN { use Exporter qw(); our @ISA = qw(Exporter) }

# define our variables to be exported
BEGIN { our @EXPORT = qw(readCSS importCSS exportCSS writeCSS); }

# define our functions to be exported
BEGIN { our @EXPORT_OK = qw($re_url wrapURL exportURI importURI _importURI); }

###################################################################################################

# load perl core file functions
use File::Basename qw(dirname basename);
use File::Spec::Functions qw(rel2abs abs2rel canonpath);

# load webmerge file reader
use RTP::Webmerge::IO qw(readfile writefile);

use RTP::Webmerge::Path qw($webroot);

use RTP::Webmerge::Path qw(web_url web_path);

use Cwd qw(realpath);

###################################################################################################

# wrap url for css
# also makes it canonical
sub wrapURL
{

	# get uri
	my ($uri) = @_;

	# escape apostrophes
	$uri =~ s/\'/\\\'/g;

	# replace windows backslashed
	# with correct forward slashes
	$uri =~ s/\\/\//g if ($^O eq "MSWin32");

	# wrap and return escaped uri
	return sprintf("url('%s')", $uri);

}
# EO wrapURL

###################################################################################################

# check if url is available
# and make the path absolute
sub _importURI
{
	# get the url and css path
	my ($url, $csspath, $config) = @_;

	# check if url is absolute -> resolve from our webroot
	# if ($url =~ m/^\// && $config && $config->{'webroot'})
	# {
	# 	use RTP::Webmerge::Path qw(resolve_path);
	# 	$url = join('/', resolve_path($config->{'webroot'}), $url);
	# }

	# check if the url is actually
	# we never should have absolute urls from file system
	# we always want to have css urls here, so remove it
	# die $url if ($url =~ m/^(?:[a-zA-Z]+\:)?\/\//);

	# remove hash tag and query string
	# why is this needed for a static file?
	my $append = $url =~ s/([\?\#].*?)$// ? $1 : '';

	# create the path relative first
	# my $path = join('', $csspath, $url);

	# create absolute path from the url if exists
	my $path = $url =~ m/^\// ?
			   realpath(join('/', $webroot, dirname($url))) :
	           realpath(rel2abs(dirname($url), $csspath));

	# check path on filesystem and
	die "CSS url($url) in <$csspath> not found\n" unless ($path && -e dirname ($path));

	# now re attach the file name for the resource
	$path = join('/', $path, basename($url));

	# return the wrapped url
	return $path . $append;
}

sub importURI
{

	# return the wrapped url
	return wrapURL(&_importURI);

}
# EO importURI

###################################################################################################

# export url and make it relative
sub exportURI
{

	# get input variables
	my ($url, $csspath, $config) = @_;

	# get absolute or relative path
	my $path = $config->{'absoluteurls'}
	           ? '/' . abs2rel($url, $webroot)
	           : abs2rel($url, $csspath);

	# return the wrapped url
	return wrapURL($path);

}
# EO exportURI

###################################################################################################

# read a css file from the disk
sub incCSS
{

	# get input variables
	my ($cssfile, $config) = @_;

	# read complete css file
	my $data = readfile($cssfile);

	# die with an error message that css file is not found
	die "css import <$cssfile> could not be read: $!\n" unless $data;

	# resolve all css imports and include the data (also resolve the path)
	${$data} =~ s/\@import\s+$re_url/${incCSS(_importURI($1, dirname($cssfile), $config))}/gme if $config->{'import-css'};

	# change all relative urls in this css to absolute paths
	# also look for comments, but do not change them in the function
	${$data} =~ s/$re_url/importURI($1, dirname($cssfile), $config)/egm;

	# return as string
	return $data;

}

# read a css file from the disk
sub readCSS
{

	# get input variables
	my ($cssfile, $config) = @_;

	# read complete css file
	my $data = incCSS($cssfile, $config);

	# change all relative urls in this css to absolute paths
	# also look for comments, but do not change them in the function
	${$data} =~ s/$re_url/exportURI($1, $webroot, $config)/egm;

	# return as string
	return $data;

}
# EO importCSS

# read a css file from the disk
# resolve all file paths absolute
# http://www.w3.org/TR/CSS21/syndata.html#uri
sub importCSS
{

	# get input variables
	my ($data, $cssfile, $config) = @_;

	# change all relative urls in this css to absolute paths
	# also look for comments, but do not change them in the function
	${$data} =~ s/$re_url/importURI($1, $webroot, $config)/egm;

	# return as string
	return $data;

}
# EO importCSS

###################################################################################################

# write a css file to the disk
# resolve all file paths relative
# http://www.w3.org/TR/CSS21/syndata.html#uri
sub writeCSS
{

	# get input variables
	my ($path, $data, $config) = @_;

	# call io function to write the file atomically
	return writefile($path, $data, $config->{'atomic'}, 1)

}
# EO writeCSS

# mangle CSS
sub exportCSS
{

	# get input variables
	my ($file, $data, $config) = @_;

	# change all absolute urls in this css to relative paths
	# also look for comments, but do not change them in the function
	${$data} =~ s/$re_url/exportURI($1, dirname($file), $config)/egm;

	return 1;

}
# EO exportCSS

###################################################################################################

# extend the configurator
use RTP::Webmerge qw(@initers);

# register initializer
push @initers, sub
{

	# get input variables
	my ($config) = @_;

	# include imported css files
	$config->{'import-css'} = 1;

	# should we use absolute urls
	# otherwise includes will be relative
	# for this option we need to webroot path
	$config->{'absoluteurls'} = 0;

	# return additional get options attribute
	return (
		'import-css!' => \ $config->{'cmd_import-css'},
		'absoluteurls=i' => \ $config->{'cmd_absoluteurls'}
	);

};
# EO plugin initer

###################################################################################################
###################################################################################################
1;
