###################################################################################################
# Copyright 2013/2014 by Marcel Greter
# This file is part of OCBNET-CSS3 (GPL3)
####################################################################################################
package OCBNET::CSS3::Styles;
####################################################################################################

use strict;
use warnings;

####################################################################################################
use Scalar::Util 'blessed';
####################################################################################################

our %matcher;
our %default;
our %list;

####################################################################################################

# static function only
# never call as object
sub register
{

	# get input arguments of static call
	my ($key, $matcher, $default, $list) = @_;

	# store the matcher by key
	$matcher{$key} = $matcher;

	# store the defaults by key
	$default{$key} = $default;

	# store list attribute
	# means we store as array
	# and can parse comma lists
	$list{$key} = $list;

}
# EO fn register

####################################################################################################

# create a new object
# ***************************************************************************************
sub new
{

	# package name
	my ($pckg, $node) = @_;

	# create a new instance
	my $self = { 'node' => $node, 'ids' => {} };

	# bless instance into package
	return bless $self, $pckg;

}
# EO constructor

####################################################################################################

# basic getter
# ***************************************************************************************
sub node { $_[0]->{'node'} }

####################################################################################################

# set key/value pair
# ***************************************************************************************
sub set
{

	# list variable
	# parse optional
	my %longhands;

	# get input arguments
	my ($self, $key, $value) = @_;

	# check if we have a matcher
	if (exists $matcher{$key})
	{

		# get the configured matcher
		# might be a shorthand value
		my $matcher = $matcher{$key};

		# rewrite longhand to shorthand
		if (ref($matcher) eq 'Regexp')
		{
			# must only match that single keys regex
			$matcher = { 'ordered' => [ [ $key ] ] };
		}

		# matcher is a shorthand
		if (ref($matcher) eq 'HASH')
		{

			# create arrays for all longhands
			$longhands{$_} = [] foreach @{$matcher->{'prefix'} || []};
			$longhands{$_->[0]} = [] foreach @{$matcher->{'ordered'} || []};
			# $longhands{$_} = [] foreach @{$matcher->{'postfix'} || []};

			# parse list
			# exit if not
			while (1)
			{

				# declare variables
				my ($prop);

				# get optional options from shorthand
				# create a copy of the array, so we can
				# manipulate them later for loop control
				my $prefix = [ @{$matcher->{'prefix'} || []} ];
				my $ordered = [ @{$matcher->{'ordered'} || []} ];
				# my $postfix = [ @{$matcher->{'postfix'} || []} ];

				# set defaults for all optional longhands
				push @{$longhands{$_}}, $default{$_} foreach @{$prefix};
				push @{$longhands{$_->[0]}}, $default{$_->[0]} foreach @{$ordered};
				# push @{$longhands{$_}}, $default{$_} foreach @{$postfix};

				# optional prefixes (can occur in any order)
				for (my $i = 0; $i < scalar(@{$prefix}); $i++)
				{

					# get property name
					my $prop = $prefix->[$i];

					# get the configured matcher
					# might be a shorthand value
					my $regex = $matcher{$prop};

					if (ref($regex) eq 'HASH')
					{ $regex = $regex->{'matcher'} }

					# test if we have found this property
					if ($value =~ s/\A\s*($regex)\s*//s)
					{
						# matches this property
						$longhands{$prop}->[-1] = $1;
						# remove from search and
						splice(@{$prefix}, $i, 1);
						# restart loop
						$i = -1; next;
					}
					# EO match regex

				}
				# EO each prefix

				# mandatory longhands
				foreach $prop (@{$ordered})
				{

					# get property name
					my $name = $prop->[0];
					# get optinal alternative
					# string: eval to this if nothing set
					# regexp: is optionally fallowed by this
					my $alt = $prop->[1];

					# get the configured matcher
					# might be a shorthand value
					my $regex = $matcher{$name};

					# optional alternative
					# delimited from property
					if (ref($alt) eq 'Regexp')
					{
						# test if we found the delimiter
						# if not the value is not mandatory
						next unless ($value =~ s/\A\s*($alt)\s*//s)
					}

					# test if we have found this property
					if ($value =~ s/\A\s*($regex)\s*//s)
					{
						# matches this property
						$longhands{$name}->[-1] = $1;
					}
					# EO match regex

					# has another alternative (string)
					elsif (defined $alt && ref($alt) eq '')
					{
						# eval to another longhand property
						# this property should be parsed already
						$longhands{$name}->[-1] = $longhands{$alt}->[-1];
					}

				}
				# EO each longhand

				# # optional postfixes (can occur in any order)
				# for (my $i = 0; $i < scalar(@{$postfix}); $i++)
				# {

				# 	# get property name
				# 	my $prop = $postfix->[$i];

				# 	# get the configured matcher
				# 	# might be a shorthand value
				# 	my $regex = $matcher{$prop};

				# 	# test if we have found this property
				# 	if ($value =~ s/\A\s*($regex)\s*//s)
				# 	{
				# 		# matches this property
				# 		$longhands{$prop}->[-1] = $1;
				# 		# remove from search and
				# 		splice(@{$postfix}, $i, 1);
				# 		# restart loop
				# 		$i = -1; next;
				# 	}
				# 	# EO match regex

				# }
				# # EO each postfix

				# check if we should parse in list mode
				# if we find a comma we will parse again
				next if $list{$key} && $value =~ s/\A\s*,\s*//s;

				# end loop
				last;

			}
			# EO while 1


		}
		# EO if HASH

		# assertion for hash type
		else { die "unknown type"; }

	}
	# EO while matcher

	# check if we have a new id
	if ($longhands{'css-id'})
	{
		# store all ids in our global hash
		foreach my $id (@{$longhands{'css-id'}})
		{ $self->node->root->{'ids'}->{$id} = $self->node; }
	}
	# EO if css-id

	#####################################################
	# implement action to setup styles
	#####################################################
	# print "x" x 40, "\n";
	# foreach my $name (keys %longhands)
	# { printf "%s => %s\n", $name, join(", ", @{$longhands{$name}}); }
	#####################################################

	# overwrite styles with longhands
	foreach my $name (keys %longhands)
	{
		# check if key is another shorthand
		if (ref($matcher{$name}) eq 'HASH')
		{
			# pass this "shorthand" value to parse longhands
			$self->set($name, join(',', @{$longhands{$name}}));
		}
		# this key is finally a longhand
		elsif (ref($matcher{$name}) eq 'Regexp')
		{
			# just store the parsed value
			$self->{$name} = $longhands{$name};
		}
	}
	# EO each longhand

	# return results
	return \ %longhands;

}
# EO sub set

####################################################################################################

# get value of a longhand
# traverse the virtual tree
# ***************************************************************************************
sub get
{

	# get input arguments
	my ($self, $key, $idx) = @_;

	# check if found in current styles
	if (exists $self->{$key}->[$idx || 0])
	{ return $self->{$key}->[$idx || 0]; }

	# nothing found
	return undef;

}

####################################################################################################
####################################################################################################
1;

__DATA__

# This code would make the "get" method resolve the
# virtual references. But we only could resolve for
# styles or options on the parent node. Since we cannot
# know which item from node->parent we are querying.
# So we cannot resolve the requested value safely.
# Therefore leave to parent class to be implemented.

# do not go recursive on certain keys
return undef if $key eq 'css-ref';
return undef if $key eq 'css-id';

# check if option references another id
if ($self->node->options->get('css-ref'))
{
	# get the reference to the other dom node
	my $id = $self->node->options->get('css-ref');
	# get the actual referenced dom dome (if any)
	my $ref = $self->node->root->{'ids'}->{$id};
	# give error message if reference was not found
	die "referenced id <$id> not found" unless $ref;
	# call reference dom node for key
	return $ref->styles->get($key, $idx);
}
 #EO if css-ref
