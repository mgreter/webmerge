###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
####################################################################################################
# TODO: improve and test handling with invalid formated files
####################################################################################################
package OCBNET::Spritesets::CSS::Parser;
####################################################################################################

use strict;
use warnings;

####################################################################################################

# define our version string
BEGIN { $OCBNET::Spritesets::CSS::Base::VERSION = "0.70"; }

# load exporter and inherit from it
BEGIN { use Exporter qw(); our @ISA = qw(Exporter); }

# define our functions that will be exported
BEGIN { our @EXPORT = qw($parse_blocks $parse_declarations); }

# define our functions than can be exported
BEGIN { our @EXPORT_OK = qw($parse_bracket); }

####################################################################################################

use OCBNET::Spritesets::CSS::Base qw($re_apo $re_quot);

####################################################################################################

our $parse_blocks;
our $parse_bracket;
our $parse_declarations;

####################################################################################################

my $re_closer =
{
	"" => qr/\A\z/,
	"\(" => qr/\A(\)|\z)/,
	"\[" => qr/\A(\]|\z)/,
	"\{" => qr/\A(\}|\z)/,
	"\"" => qr/\A(\"|\z)/,
	"\'" => qr/\A(\'|\z)/
};

####################################################################################################

# parse all declaration in given data
# usefull to parse css selector blocks
# also used to parse spriteset comments
# ******************************************************************************
$parse_declarations = sub
{

	# get stylesheet
	my ($data) = @_;

	# array of rules
	my @declarations;

	# loop until no more data
	while (${$data} ne '')
	{
		# consume data
		if (${$data} =~
			s/^
			(
				(?:
					# escaped char
					(?: \\ .)+ |
					# comment or only a slash
					\/+ (?:\*+ .*? \*+ \/+)? |
					# a string in delimiters
					\" $re_quot \" | \' $re_apo \' |
					# not the delimiter
					[^\:\;\/]+
				)*
			)
			(
				(?:\:
					# escaped char
					(?: \\ .)+ |
					# comment or only a slash
					\/+ (?:\*+ .*? \*+ \/+)? |
					# a string in delimiters
					\" $re_quot \" | \' $re_apo \' |
					# not the delimiter
					[^\;\/]+
				)*
				(?:\;|\z)
			)
			//xs
		)
		{

			# store the name and the config
			# create a copy for stripped version
			my $declaration = [$1, $2, $1, $2];

			# strip comments from declaration copy
			$declaration->[2] =~ s/\/\*\s*.*?\s*\*\///gs;
			$declaration->[3] =~ s/\/\*\s*.*?\s*\*\///gs;

			# store in order into array
			push @declarations, $declaration;

		}
		else
		{
			# this should not happen, investigate further
			die "Fatal: CSS parse error: ", substr(${$data}, 0, 110);
		}
	}

	# return parsed declarations
	return \ @declarations;

};
# EO sub $parse_declarations

####################################################################################################

# parse the css into blocks
$parse_blocks = sub
{

	# get passed input arguments
	my ($data, $parent, $clause) = @_;

	# create new block node with the given parent
	my $block = OCBNET::Spritesets::CSS::Block->new($parent);

	# parse the new block as normal bracket block
	$parse_bracket->($data, $block, '', $clause);

	# return object
	return $parent;

};

####################################################################################################

# parse a bracket block
$parse_bracket = sub
{

	# get passed input arguments
	my ($data, $block, $opener, $clause) = @_;

	# add opener to head if defined
	$block->{'head'} .= $opener if $opener;

	# repeat until all the data is parsed
	# be sure to include an abort clause
	while(1)
	{

		# simpler grammars
		if (${$data} =~ s/^(
			# escaped char
			(?: \\ .)+ |
			# comment or only a slash
			\/+ (?:\* .*? \*\/+)? |
			# a string in delimiters
			\" $re_quot \" | \' $re_apo \'
		)//xs)
		{
			# just store the match
			$block->{'head'} .= $1;
		}

		# check if we found our exit clause
		elsif (${$data} =~ s/^($clause)//s)
		{
			# add closer to head if defined
			$block->{'head'} .= $1 if $opener;
			# return the block node
			return $block;
		}

		# parse an inner block recursive
		elsif (${$data} =~ s/^(\{)//s)
		{
			# parse this one block body
			$parse_blocks->($data, $block, qr/^(\})/);
			# create new block node with the given parent
			$block = OCBNET::Spritesets::CSS::Block->new($block->{'parent'});
		}

		# parse further for a bracket
		elsif (${$data} =~ s/^(\(|\[)//s)
		{
			# parse a default bracket block
			$parse_bracket->($data, $block, $1, $re_closer->{$1});
		}

		# parse unimportant chars in this context
		elsif (${$data} =~ s/^([^\{\}\[\]\(\)\"\'\/]+)//s)
		{
			$block->{'head'} .= $1;
		}

		# invalid parsing
		else
		{
			# this should not happen, investigate further
			die "Fatal: CSS parse error: ", substr(${$data}, 0, 10);
		}

	}
	# EO while 1

	# this should not happen, investigate further
	die "Fatal: Escaped endless parse loop?";

};

####################################################################################################

sub new
{

	my ($pckg) = @_;

	my $self = {
		'head' => '',
		'blocks' => []
	};

	return bless $self, $pckg;

}

####################################################################################################

sub parse
{

	my ($self, $data) = @_;

	# parse all blocks and end when all is parsed
	$parse_blocks->($data, $self, qr/\A\z/);

	# assertion in any case (should not happen - dev)
	die "not everything parsed" unless ${$data} eq '';

	# return object
	return $self;

}

####################################################################################################
1;
