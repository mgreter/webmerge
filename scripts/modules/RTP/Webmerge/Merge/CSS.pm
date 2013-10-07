###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
###################################################################################################
package RTP::Webmerge::Merge::CSS;
###################################################################################################

use Carp;
use strict;
use warnings;

###################################################################################################

# define our version string
BEGIN { $RTP::Webmerge::Merge::CSS::VERSION = "0.7.0" }

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

use RTP::Webmerge::Merge qw(%reader %writer %importer %exporter);
use RTP::Webmerge::Merge qw(%joiner %includer %processor);

###################################################################################################

# define joiner string
$joiner{'css'} = "\n";

# load IO functions
use RTP::Webmerge::IO::CSS;

# assign IO functions
$reader{'css'} = \&readCSS;
$importer{'css'} = \&importCSS;
$exporter{'css'} = \&exportCSS;
$writer{'css'} = \&writeCSS;

use RTP::Webmerge::Include::CSS;

$includer{'css'} =
{
	'dev' => sub { includeCSS($_) },
	'join' => sub { ${$_->{'data'}} },
	'minify' => sub { ${$_->{'data'}} },
	'compile' => sub { ${$_->{'data'}} },
	'license' => sub { getLicense($_) }
};

$processor{'css'} =
{
	'minify' => sub
	{
		require CSS::Minifier;
		&CSS::Minifier::minify('input' => $_[0]);
	},
	'compile' => sub
	{
		require RTP::Webmerge::Compile::CSS;
		&RTP::Webmerge::Compile::CSS::compileCSS;
	}
};

###################################################################################################
###################################################################################################
1;