################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
# Parse and connect blocks and contexts
################################################################################
package OCBNET::Webmerge::Config::XML;
################################################################################
use XML::Parser; use base "XML::Parser";
################################################################################
require OCBNET::Webmerge::Config::XML::Node;
require OCBNET::Webmerge::Config::XML::Root;
require OCBNET::Webmerge::Config::XML::Echo;
require OCBNET::Webmerge::Config::XML::Eval;
require OCBNET::Webmerge::Config::XML::File;
require OCBNET::Webmerge::Config::XML::Merge;
require OCBNET::Webmerge::Config::XML::Scope;
require OCBNET::Webmerge::Config::XML::Input;
require OCBNET::Webmerge::Config::XML::Output;
require OCBNET::Webmerge::Config::XML::Action;
require OCBNET::Webmerge::Config::XML::Config;
require OCBNET::Webmerge::Config::XML::Include;
require OCBNET::Webmerge::Config::XML::Optimize;
################################################################################

use strict;
use warnings;

################################################################################
# constructor
################################################################################

sub new
{

	# get arguments
	my ($pkg) = @_;

	# create the xml parser object
	my $parser = new XML::Parser(
		# call methods
		Style => 'Subs',
		# show context lines
		ErrorContext => 3
	);

	# bless into our own class
	return bless $parser, $pkg;

}

################################################################################
# parse a file into the given scope
# return scope (might created myself)
################################################################################

sub parse_file
{

	# get method arguments
	my ($parser, $filename, $scope) = @_;

	# create a new and empty root config scope if none is passed
	$scope = new OCBNET::Webmerge::Config::XML::Root unless $scope;

	# create options
	my $webmerge = {
		'nodes' => [ $scope ],
		'scopes' => [ $scope ],
		'filename' => $filename
	};

	# setup xml parser handlers
	$parser->setHandlers(
		'End' => \&end,
		'Char' => \&char,
		'Start' => \&start
	);

	# try to open the filehandle
	if (open(my $fh, '<', $filename))
	{
		# parse the document (pass webmerge options)
		$parser->parse($fh, 'webmerge' => $webmerge);
	}
	else
	{
		# die with a simple error message
		die "could not open $filename\n";
	}

	# return xml scope
	return $scope;

}
# EO parse_file

################################################################################
# route parser methods to the specific instances
################################################################################

sub start { $_[0]->{'webmerge'}->{'nodes'}->[-1]->start(@_); }
sub char { $_[0]->{'webmerge'}->{'nodes'}->[-1]->char(@_); }
sub end { $_[0]->{'webmerge'}->{'nodes'}->[-1]->end(@_); }

################################################################################
################################################################################
1;
