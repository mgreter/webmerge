###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
###################################################################################################
package RTP::Webmerge::Process::CSS::Inlinedata;
###################################################################################################

use Carp;
use strict;
use warnings;

###################################################################################################

# define our version string
BEGIN { $RTP::Webmerge::Process::CSS::Inlinedata::VERSION = "0.70" }

# load exporter and inherit from it
BEGIN { use Exporter qw(); our @ISA = qw(Exporter) }

# define our functions to be exported
BEGIN { our @EXPORT = qw(inlinedata); }

###################################################################################################

# wrap as IO Object
use IO::Scalar;

# use perl default base64 converter
use MIME::Base64 qw(encode_base64);

# use mimeinfo to detect mimetypes
use File::MimeInfo::Magic qw(mimetype);

# load spriteset preprocessor (experimental)
use RTP::Webmerge::Process::CSS::Spritesets qw();

###################################################################################################

# import functions from IO module
use RTP::Webmerge::IO qw(readfile);

use RTP::Webmerge::IO::CSS qw($re_url wrapURL);

use RTP::Webmerge::Path qw(res_path);

###################################################################################################

# parse urls out of the css file
# do a lousy match for better performance
# my $re_url = qr/url\s*\([\"\']?([^\)]+?)[\"\']?\)/x;

# some handy regular expressions
# my $re_apo = qr/(?:[^\'\\]+|\\.)*/s;
# my $re_quot = qr/(?:[^\"\\]+|\\.)*/s;

###################################################################################################

# cache all downloaded urls
my $downloaded = {};

###################################################################################################

# init to byte factors
my %bytefactors = (
	'B' => 1024 ** 0,
	'KB' => 1024 ** 1,
	'MB' => 1024 ** 2,
	'GB' => 1024 ** 3
);

# helper function
sub getbytes
{

	# get the byte string
	my ($string) = @_;

	# match a floating point number and the measure unit
	if ($string =~ m/([-+]?(?:[0-9]*\.[0-9]+|[0-9]+))\s*(B|KB|MB|GB)?/i)
	{
		# multiply number by factor
		return $1 * $bytefactors{uc$2};
	}

	# return original
	return $string;

}
# EO getbytes

###################################################################################################

# replace jquery calls with simple dollar signs
# this way we can have best code compatibility
# and still use the dollar sign when possible
sub inlinedata
{

	# get input variables
	my ($data, $config) = @_;

	# declare lexical variables
	my $info = {};

	# start search and replace
	${$data} =~ s/(?:(\/\*.*?\*\/)|$re_url)/$1 || &inline_url($config, $info, $2)/gme;

	# create lexical variables
	my @duplicates, my $replaced = 0;

	# do some statistics about the replacement
	foreach my $url (keys %{$info->{'seen'}})
	{
		if ($info->{'seen'}->{$url} > 1)
		{ push(@duplicates, $url); }
		$replaced ++;
	}

	# print warnings if we have duplicates
	# this can only be optimized manually
	if (scalar(@duplicates))
	{
		printf "\nINFO: replaced %d images\n", $replaced;
		print "\nWARNING: some urls have been included multiple times\n";
		print "Please try to reference each urls only once in the style sheet!\n";
		print "It could be possible to merge the selectors of all identical urls!\n";
		print "\n  ", join("\n  ", map { substr($_, - 65) . " (" . $info->{'seen'}->{$_} . ")" } @duplicates) , "\n\n";
	}

	# return success
	return 1;

}
# EO sub dejquery

###################################################################################################

# process a local url
# return inline data
sub inline_url
{

	# get input variables
	my ($config, $info, $url) = @_;

	# store original url
	my $original = $url;

	# declare lexical variables
	my ($dataref, $mimetype);

	# file is an absolute link
	if ($url =~ m/^[a-z]+:\/\//)
	{

		# loop all external configurations
		foreach my $ext (@{$config->{'external'} || []})
		{

			# get configure href
			my $href = $ext->{'href'};

			# try http protocol if there is no expicit
			# protocol given in the link. Maybe this should
			# be configurable, but IMO this should suffice.
			$url = 'http:' . $url if $url =~ m/^\/\//;

			# test if given url matches this href
			if ($url =~ m/^([a-z]+:)?\Q$href\E/)
			{

				# do nothing if downloads of externals has been disabled
				return 'url(' . $original . ')' unless $ext->{'enabled'};

				# check if download is already cached
				unless (exists $downloaded->{$original})
				{

					# try to load the lwp module conditional
					unless (eval { require LWP::UserAgent; 1 })
					{ die "module LWP::UserAgent not found"; }

					# create a new user agent
					my $ua = new LWP::UserAgent;

					# fake an internet explorer 7 agent string
					$ua->agent('Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1)');

					# create the request
					my $request = new HTTP::Request 'GET', $original;

					# get referer from local or global options
					my $referer = $ext->{'referer'} || $config->{'referer'};

					# set referer for this request
					$request->referer($referer) if $referer;

					# do request synchronous and get response
					my $response = $ua->request($request);

					# check the return status
					die 'download of external data failed' if $response->code ne 200;

					# store to cached urls (only fetch each url once per webmerge run)
					$downloaded->{$original} = [\ $response->content, $response->header('content-type')];

				}

				# get variables from the cache
				$dataref = $downloaded->{$original}->[0];
				$mimetype = $downloaded->{$original}->[1];

				# exit foreach ext loop
				last;

			}
			# EO if url matches href

		}
		# EO each external config

	}
	# EO if remote url

	# file is local
	# relative to webroot
	else
	{

		# remove any query string
		# $url =~ s/\?.*?$//;

		# create pattern to decide which files to embed
		my @exts = map { quotemeta } split(/\s*,\s*/, $config->{'inlinedataexts'});
		my $embed_pattern = '\.(?:' . join('|', @exts) . ')$';
		my $re_embed_pattern = qr/$embed_pattern/;

		# only process usefull file extensions
		unless ($url =~ m/$re_embed_pattern/)
		{ return 'url(' . $original . ')'; }

		# get the filesize
		my $size = 0;

		# check if the file has already been written
		unless (exists $config->{'atomic'}->{$url}) { $size = -s $url; }
		else { $size = length(${$config->{'atomic'}->{$url}->[0]}); }

		# if size is not given
		unless (defined $size)
		{
			# the url probably would return error 404
			# we may could try to download it via url
			die "url $url is not accessible";
		}

		# only replace files inline if greater than 4KB
		if ($size > getbytes($config->{'inlinedatamax'}))
		{ return 'url(' . $original . ')'; }

		# get into lexical variable
		my $seen = $info->{'seen'} || {};

		# count url occurences
		unless (exists $seen->{$url})
		{ $seen->{$url} = 1; }
		else { $seen->{$url} ++; }

		# be sure to store it
		$info->{'seen'} = $seen;

		# read the linked url locally
		$dataref = readfile($url, $config->{'atomic'});

		# fix for windows and mime magic
		# most people will not have the db
		if($^O =~ m!MSWin32!i)
		{
			push @File::MimeInfo::DIRS,
			     res_path('{CONF}/mime'),
			     res_path('{EXT}/conf/mime');
		}

		# check if file was written atomic
		if ($config->{'atomic'}->{$url})
		{
			# get the current atomic object
			my $fh = $config->{'atomic'}->{$url}->[1];
			# retrieve the temporary filename
			$url = ${*$fh}{'io_atomicfile_temp'};
		}

		# get mimetype from file
		$mimetype = mimetype($url);

		# fail if we have no mimetype
		die "unknown file-type" unless $mimetype;

	}
	# EO if local url

	# check if we have an inline data representation
	return wrapURL($original) unless (defined $dataref && defined $mimetype);

	# return the inline data replacement
	return sprintf('url(data:%s;base64,%s)', $mimetype, encode_base64(${$dataref}, ''));

}
# EO sub inline_url

###################################################################################################

# import registered processors
use RTP::Webmerge qw(%processors @initers);

# register the processor function
$processors{'inlinedata'} = \& inlinedata;

# register initializer
push @initers, sub
{

	# get input variables
	my ($config) = @_;

	# assign default value to variable
	$config->{'inlinedatamax'} = 4096;

	# extensions to be embeded in css
	$config->{'inlinedataexts'} = 'gif,jpg,jpeg,png';

	# return additional get options attribute
	return (
		'inlinedatamax=i' => \ $config->{'cmd_inlinedatamax'},
		'inlinedataexts=s' => \ $config->{'cmd_inlinedataexts'}
	);

};
# EO plugin initer

###################################################################################################
###################################################################################################
1;
