###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
###################################################################################################
package RTP::Webmerge::Merge::JS;
###################################################################################################

use Carp;
use strict;
use warnings;

###################################################################################################

# define our version string
BEGIN { $RTP::Webmerge::Merge::JS::VERSION = "0.7.0" }

# load exporter and inherit from it
BEGIN { use Exporter qw(); our @ISA = qw(Exporter) }

# define our functions to be exported
BEGIN { our @EXPORT = qw(); }

# define our functions to be exported
BEGIN { our @EXPORT_OK = qw(); }

###################################################################################################

# parse license from code
sub getLicense
{
	# map out the licenses from inputs
	return
		# remove everything but the very first comment (first line!)
		${$_->{'data'}} =~m /\A\s*(\/\*(?:\n|\r|.)+?\*\/)\s*(?:\n|\r|.)*\z/m
			# return header with given input path and license or nothing
			? ( '/* license for ' . $_->{'web_path'} . ' */', $1, '' ) : ();
}

###################################################################################################

use RTP::Webmerge::Merge qw(%joiner %includer);
use RTP::Webmerge::Merge qw(%prefixer %processor %suffixer);
use RTP::Webmerge::Merge qw(%reader %writer %importer %exporter);

###################################################################################################

# headJS bit to overwrite
# default JavaScript loader
my $headJS = "

// change loadJS to head.js
webmerge.loadJS = head.hs;

";

###################################################################################################

# define joiner string
$joiner{'js'} = ";\n";

# load IO functions
use RTP::Webmerge::IO::JS;

# assign IO functions
$reader{'js'} = \&readJS;
$importer{'js'} = \&importJS;
$exporter{'js'} = \&exportJS;
$writer{'js'} = \&writeJS;

use RTP::Webmerge::Merge::Include;

$includer{'js'} =
{
	'dev' => sub { includeJS($_) },
	'join' => sub { ${$_->{'data'}} },
	'minify' => sub { ${$_->{'data'}} },
	'compile' => sub { ${$_->{'data'}} },
	'license' => sub { getLicense($_) }
};

$processor{'js'} =
{
	'minify' => sub
	{
		require JavaScript::Minifier;
		&JavaScript::Minifier::minify;
	},
	'compile' => sub
	{
		require RTP::Webmerge::Compile::JS;
		&RTP::Webmerge::Compile::JS::compileJS;
	}
};

$prefixer{'js'} =
{
	'dev' => sub
	{
		# get passed input variables
		my ($data, $merge, $config) = @_;
		# check if the merged file has been set to load deferred
		# my $deferred = $merge->{'defer'} && lc $merge->{'defer'} eq 'true';
		# assertion that we have at least one defered include, otherwise
		# it may never fire the ready event (happens with head.js)
		# $deferred = 0 if scalar $collect->('input') == 0;
		# insert the javascript header
		my $prefix = $js_dev_header . ";\n";
		# overwrite loader with defered head.js loader
		# $prefix .= $headJS if $deferred;
		# prefix the new header to data
		${$data} = $prefix . ${$data};
	}
};

###################################################################################################
###################################################################################################
1;