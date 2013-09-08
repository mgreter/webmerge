###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
###################################################################################################
package RTP::Webmerge::Fingerprint;
###################################################################################################

use Carp;
use strict;
use warnings;

###################################################################################################

# define our version string
BEGIN { $RTP::Webmerge::Fingerprint::VERSION = "0.70" }

# load exporter and inherit from it
BEGIN { use Exporter qw(); our @ISA = qw(Exporter) }

# define our functions to be exported
BEGIN { our @EXPORT = qw(md5sum md5short fingerprint); }

###################################################################################################

# import registered processors
use RTP::Webmerge qw(@initers);

# register initializer
push @initers, sub
{

	# getopt config
	my (@options);

	# get input variables
	my ($config) = @_;

	# file fingerprints
	$config->{'fingerprint'} = 0;
	# technique used by context
	$config->{'fingerprint-dev'} = 'query';
	$config->{'fingerprint-live'} = 'query';

	# collect all command line options for getopt call
	push(@options, 'fingerprint|fp!', \ $config->{'cmd_fingerprint'} );
	push(@options, 'fingerprint-dev|fp-dev=s', \ $config->{'cmd_fingerprint-dev'} );
	push(@options, 'fingerprint-live|fp-live=s', \ $config->{'cmd_fingerprint-live'} );

	# return additional get options attribute
	return @options;

};
# EO plugin initer

###################################################################################################

# use md5 digest for checksum
use Digest::MD5 qw();

# use core modules for path handling
use File::Basename qw(dirname basename);

# load core webmerge io functions
use RTP::Webmerge::IO qw(readfile);

###################################################################################################

sub md5sum
{
	#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
	my ($data) = @_;
	#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
	my $md5 = Digest::MD5->new;
	#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
	$md5->add(${$data});
	#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
	return uc($md5->hexdigest);
	#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
}

sub md5short
{
	#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
	return substr(md5sum($_[0]), 0, 12); # 32
	#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
}

###################################################################################################

sub fingerprint
{

	# get passed variables
	my ($config, $context, $path, $data) = @_;

	# get the fingerprint config option if not explicitly given
	my $technique = $config->{join('-', 'fingerprint', $context)};

	# do not add a fingerprint at all if feature is disabled
	return $path unless $config->{'fingerprint'} && $technique;

	# read the file from the disk if a data reference is not passed
	$data = readfile $path, $config->{'atomic'} unless (defined $data);

	# simply append the fingerprint as a unique query string
	return join('?', $path, md5short($data)) if $technique eq 'q';

	# insert the fingerprint as a (virtual) last directory to the given path
	# this will not work out of the box - you'll need to add some rewrite directives
	return join('/', dirname($path), md5short($data), basename($path)) if $technique eq 'd';
	return join('/', dirname($path), md5short($data) . '-' . basename($path)) if $technique eq 'f';

	# exit and give an error message if technique is not known
	die 'fingerprint technique <', $technique, '> not implemented', "\n";

	# at least return something
	return $path;

}

###################################################################################################
###################################################################################################
1;