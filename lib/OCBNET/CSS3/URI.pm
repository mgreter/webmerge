###################################################################################################
# Copyright 2013/2014 by Marcel Greter
# This file is part of OCBNET-CSS3 (GPL3)
####################################################################################################
package OCBNET::CSS3::URI;
####################################################################################################

use strict;
use warnings;

####################################################################################################

# load exporter and inherit from it
BEGIN { use Exporter qw(); our @ISA = qw(Exporter); }

# define our functions that will be exported
BEGIN { our @EXPORT_OK = qw(importWrapUrl exportWrapUrl); }

# define our functions that will be exported
BEGIN { our @EXPORT = qw(wrapUrl fromUrl importUrl exportUrl); }

####################################################################################################
use Cwd qw();
use File::Spec qw();
use File::Basename qw();
####################################################################################################

sub new
{

	# get arguments
	my ($pkg, $url, $base) = @_;

	# unwrap all css variants
	my $uri = $pkg->unwrap($url);

	# default base to current directory
	$base = Cwd::getcwd unless defined $base;

	# add base to uri if not already absolute
	unless (File::Spec->file_name_is_absolute($uri))
	{ $uri = File::Spec->catfile($base, $uri) if $base; }
	# otherwise just normalize the given uri
	else { $uri = File::Spec->canonpath($uri); }

	# create the object with the arguments
	my $self = { 'uri' => $uri, 'base' => $base };

	# bless our object into package
	return bless $self, ref $pkg || $pkg;

}

# return relative to base
sub export
{

	my ($node, $base) = @_;

	unless (File::Spec->file_name_is_absolute($base))
	{ die "base for css uri must be absolute"; }

	$node->wrap(File::Spec->abs2rel( $node->uri, $base ));


}

####################################################################################################
# simple accessor methods
####################################################################################################

sub uri : lvalue { $_[0]->{'uri'} }
sub path : lvalue { $_[0]->{'uri'} }

####################################################################################################

####################################################################################################
# map to basename functions
####################################################################################################

sub dirname { File::Basename::dirname(shift->path, @_) }
sub basename { File::Basename::basename(shift->path, @_) }

####################################################################################################
# helper functions
####################################################################################################

# parse an url
#**************************************************************************************************
sub unwrap
{
	# get argument
	my ($pkg, $url) = @_;
	# check for css url pattern (call again to unwrap quotes)
	$url = $1 while $url =~ s/\A\s*url\(\s*(.*?)\s*\)\s*\z//m;
	# unwrap quotes if there are any found
	return $1 if $url =~ m/\A\"(.*?)\"\z/m;
	return $1 if $url =~ m/\A\'(.*?)\'\z/m;
	# return same as given
	return $url;
}

# wrap an url
#**************************************************************************************************
sub wrap
{
	# get url from arguments
	my $url = $_[1] || $_[0]->uri;
	# change slashes
	$url =~ s/\\/\//g;
	# escape quotes
	$url =~ s/\"/\\\"/g;
	# return wrapped url
	return 'url("' . $url . '")';
}

################################################################################
use File::Spec::Functions qw(rel2abs abs2rel);
################################################################################

sub importUrl ($;$$)
{

	# get arguments
	my ($path, $base, $root) = @_;

	die "cannot import fs path: $path" if $path =~ m/\\/i;
	die "cannot import fs path: $path" if $path =~ m/^[a-z]\:/i;

	# add root to path if it is already absolute
	if (File::Spec->file_name_is_absolute($path))
	{ $path = File::Spec->catfile($root, $path) if $root; }
	elsif ($path =~ m/^(?:[a-z]+:)?\/\//i) { return $path; }

	# make path absolute from base
	my $url = rel2abs($path, $base);

	# replace backward with forward slashes
	$url =~ s/\\/\//g if $^O eq 'MSWin32';

	# return url (without host)
	return 'file:///' . $url;

}

################################################################################

sub exportUrl ($;$$)
{

	# get arguments
	my ($path, $base, $abs) = @_;

	# remove optional file proto
	$path =~ s/^file\:\/\/\///i;

	# check for protocol uri
	if ($path =~ /^(?:\w+\:)?\/\//)
	{

		# just return
		return $path;

	}
	else
	{

		# make path relative to base
		my $url = abs2rel($path, $base);

		# replace backward with forward slashes
		$url =~ s/\\/\//g if $^O eq 'MSWin32';

		# return relative url now
		return $url unless $abs;

		# check if outside base
		if ($url =~ m/^\.\.\//)
		{
			# give a warning to the console
			warn "error exporting absolute url\n";
			warn "url is not inside base dir\n";
			warn "path: ", $path, "\n";
			warn "base: ", $base, "\n";
			warn "=url: ", $url, "\n";
			# handle as fatal error
			# die "invalid absolute url";
		}
		else
		{
			# make url absolute
			$url = '/' . $url;
		}

		# return url
		return $url;

	}

}

####################################################################################################

sub importWrapUrl { wrapUrl(importUrl(fromUrl($_[0]), $_[1], $_[2])) }
sub exportWrapUrl { wrapUrl(exportUrl(fromUrl($_[0]), $_[1], $_[2])) }

####################################################################################################

sub wrapUrl { __PACKAGE__->wrap($_[0]) }
sub fromUrl { __PACKAGE__->unwrap($_[0]) }

####################################################################################################
####################################################################################################
1;
