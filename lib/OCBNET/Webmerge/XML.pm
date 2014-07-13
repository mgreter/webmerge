################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
# Parse and connect blocks and contexts
# This module is special from the others
################################################################################
package OCBNET::Webmerge::XML;
################################################################################
# Use XML::Parser to get the job done
################################################################################
use XML::Parser; use base "XML::Parser";
################################################################################
require OCBNET::Webmerge::Config;
################################################################################

use strict;
use warnings;

################################################################################
# modules can register more tags
################################################################################

our %parser;

################################################################################

# load compatibility settings first
# ******************************************************************************
require OCBNET::Webmerge::XML::Compat;

# load modules for core features
# ******************************************************************************
require OCBNET::Webmerge::XML::Tree::Node;
require OCBNET::Webmerge::XML::Tree::Root;
require OCBNET::Webmerge::XML::Tree::Scope;
require OCBNET::Webmerge::XML::Tree::File;

# load modules for main features
# ******************************************************************************
require OCBNET::Webmerge::XML::Merge;
require OCBNET::Webmerge::XML::Config;
require OCBNET::Webmerge::XML::Include;

# load modules for additional features
# ******************************************************************************
require OCBNET::Webmerge::XML::Headinc;
require OCBNET::Webmerge::XML::Embedder;
require OCBNET::Webmerge::XML::Optimize;

# load modules for io features
# ******************************************************************************
require OCBNET::Webmerge::XML::File::Files;
require OCBNET::Webmerge::XML::File::Input;
require OCBNET::Webmerge::XML::File::Output;

# load modules for makro features
# ******************************************************************************
require OCBNET::Webmerge::XML::Makro::Eval;
require OCBNET::Webmerge::XML::Makro::Echo;

# load modules for action features
# ******************************************************************************
require OCBNET::Webmerge::XML::Action::Copy;
require OCBNET::Webmerge::XML::Action::Mkdir;

#require OCBNET::Webmerge::XML::Optimize;
#require OCBNET::Webmerge::XML::Merge;

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
# webmerge xml parser implementation
################################################################################

sub parse
{

	# get input arguments
	my ($parser, $scope) = @_;

	# create a new and empty root config scope if none is passed
	$scope = new OCBNET::Webmerge::XML::Tree::Root unless $scope;

	# get the include file and resolve to current scope
	 my $filename = $scope->respath($scope->includefile);

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
		$parser->SUPER::parse($fh, 'webmerge' => $webmerge);
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
# enable basic xml export for all configs
################################################################################
################################################################################
package OCBNET::Webmerge::Tree::Node;
################################################################################
use OCBNET::Webmerge qw(isset notset);
################################################################################

sub XML
{

	# get input arguments
	my ($node, $lvl) = @_;

	# local variables
	my $xml = '';
	# make configurable
	my $eol = "\n";
	my $indent = '  ';

	# indentation level
	$lvl = 0 unless $lvl;

	# get attribute hash from object
	my $attr = $node->{'attr'} || {};

	# test if node can be self closing
	my $has_text = isset $node->text;
	# check if we have children or text
	my $has_content = $has_text || $node->length;

	# print tag opener
	# with attributes
	$xml .= '  ' x $lvl;
	$xml .= ('<' . $node->tag .
	        (
	        	scalar(%{$attr || {}})
	        	? ' ' . join(" ", map {
	        			sprintf '%s="%s"', $_, $attr->{$_}
	        		} keys %{$attr}) : '')
	        );

	# add slash for self closing
	$xml .= ' /' unless $has_content;

	# closer plus newline
	$xml .= '>';

	# $xml .= " ($node)";

	$xml .= $eol;

	# add content off all childrens recursive
	$xml .= $_->XML($lvl + 1) foreach $node->children;

	# check if we have text
	if ($has_content)
	{
		if ($has_text)
		{
			# print text after children
			$xml .= $indent x ($lvl + 1);
			$xml .= $node->text;
			$xml .= $eol;
		}
		# add closing tag
		$xml .= $indent x $lvl;
		$xml .= '</' . $node->tag . '>';
		$xml .= $eol;
	}

	# return code
	return $xml;

}
# EO XML

################################################################################
################################################################################
1;
