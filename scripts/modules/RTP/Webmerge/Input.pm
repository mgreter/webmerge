###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
###################################################################################################
package RTP::Webmerge::Input;
###################################################################################################

use Cwd qw(abs_path);
use URI;
use Carp;
use strict;
use warnings;

###################################################################################################

# define our version string
BEGIN { $RTP::Webmerge::Input::VERSION = "0.9.0" }

###################################################################################################

# shared
our %types;

# load file io functions
use RTP::Webmerge::IO qw(readfile);

###################################################################################################
use File::Basename qw(fileparse);
use RTP::Webmerge::IO::CSS qw(wrapURL);
use RTP::Webmerge::Path qw(dirname basename);
use RTP::Webmerge::Path qw(exportURI importURI $directory);

###################################################################################################

# constructor
sub new
{

	# get input variables
	my ($pkg, $uri, $config) = @_;

	# remove hash tag and query string from URI
	my $append = $uri =~ s/([\;\?\#].*?)$// ? $1 : '';

	# find out the file suffix for object type
	my $type = $uri =~ m/\.([a-zA-Z]+)$/ ? $1 : undef;

	my $path = eval { abs_path($uri); };
	Carp::confess $@ if $@;

	# parse again, suffix may has changed (should be quite cheap)
	my ($name, $dir, $suffix) = fileparse($path, 'scss', 'css');

	# create instance
	my $self = {

		# store source path
		path => $uri,

		# raw content
		raw => undef,

		# dependencie	s
		deps => undef,

		# store config block
		config => $config

	};

	# default suffix is css
	$suffix = $suffix || 'css';

	# store value to object
	$self->{'name'} = $name;
	$self->{'suffix'} = $suffix;
	$self->{'directory'} = $dir;

	# change current working directory so we are able
	# to find further includes relative to the directory
	$dir = RTP::Webmerge::Path->chdir(dirname($self->{'path'}));

	# bless into specific class
	# determined by file extension
	bless $self, $types{$type} || $pkg;

	# return object
	return $self;

}
# EO constructor

sub init {}

# return processed source content
# either with or without includes
sub content
{

	# get instance
	my ($self) = @_;

	# first get raw content
	my $data = $self->raw;

	# return data
	return $data;

}
# EO sub content

# return raw source content
# this must not be mangled
sub raw
{

	# get instance
	my ($self) = @_;

	# return cache if available
	if (defined $self->{'raw'})
	{ return $self->{'raw'}; }

	# read the file via the atomic IO/file layer
	my $raw = readfile($self->{'path'}, $self->{'config'}->{'atomic'});

	# create a cached copy of data
	$self->{'raw'} = $raw;

	# process raw data
	# mainly get deps
	$self->initialize;

	# return data
	return $raw;

}
# EO sub raw

# return dependencies
# i.e. imports for css
sub dependencies
{

	# no implementation
	return [];

}

sub assets
{

	# get instance
	my ($self) = @_;

	# collect all assets
	my @assets = ($self);

	# collect all assets of all dependencies
	foreach my $deps (@{$self->dependencies})
	{ push @assets, ref $deps ? $deps->assets : { 'path' => $deps }; }

	# return list
	return @assets;

}

###################################################################################################

# method: configuration getter
sub config { $_[0]->{'config'}->{$_[1]} }

###################################################################################################
###################################################################################################
1;