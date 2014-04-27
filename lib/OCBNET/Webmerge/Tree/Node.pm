################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
# Node is the base class for all children nodes
# Only tags are real dom nodes and text will be merged
# You will not be able to access comments or text nodes
################################################################################
package OCBNET::Webmerge::Tree::Node;
################################################################################
use base qw(OCBNET::Webmerge::Object);
################################################################################

use strict;
use warnings;

################################################################################
use Scalar::Util qw(weaken);
################################################################################
# object mixin initialisation
################################################################################

sub initialize
{

	# get input arguments
	my ($node, $parent) = @_;

	# attach more data
	$node->{'tag'} = '';
	$node->{'data'} = '';
	$node->{'text'} = '';

	# nodes may have children
	$node->{'children'} = [];

	# connect child and parent
	if (defined $parent)
	{
		# assign reference to parent
		$node->{'parent'} = $parent;
		# add ourself to parents children
		push @{$parent->{'children'}}, $node;
	}

	# weaken the parent ref
	# for garbage collector
	weaken $node->{'parent'};

}

################################################################################
# accessor methods
################################################################################

# return node type
sub type { 'NODE' }

# return the id
sub id { $_[0]->attr('id') }

# return the tag name
sub tag { $_[0]->{'tag'} || $_[0]->type }

# return the node data
sub data { $_[0]->{'data'} }

# return the node text
sub text { $_[0]->{'text'} }

# get connected parent node
sub parent { $_[0]->{'parent'} }

# return number of childrens
sub length { scalar $_[0]->children }

# return a list with all child nodes
sub children { @{$_[0]->{'children'}} }

# return child by given index number
sub child { $_[0]->{'children'}->[$_[1]] }

# get attribute value for given key
sub attr : lvalue { $_[0]->{'attr'}->{$_[1]} }

# check if the block is disabled
sub disabled { ison $_[0]->attr('disabled') }


################################################################################
# basic logging methods
################################################################################

sub log { shift; print "log: ", @_, "\n" }
sub err { shift; print "err: ", @_, "\n" }

################################################################################
# count number of parent levels
################################################################################

sub level { $_[0]->parent->level(1 + ($_[1] || 0)) }

################################################################################
# check if we are a child of a certain parent
################################################################################

sub hasParent { $_[0]->parent eq $_[1] || $_[0]->parent->hasParent($_[1]) }

################################################################################
# find children by tagname
################################################################################

sub find { grep { lc ($_->tag) eq lc ($_[1]) } $_[0]->children }

################################################################################
# collect children by tagname (recursive)
################################################################################

sub collect { $_[0]->find($_[1]), map { $_->collect($_[1]) } $_[0]->children }

################################################################################
# find closest parent by tag name regexp
################################################################################

sub closest { $_[0]->tag =~ $_[1] ? $_[0] : $_[0]->parent->closest($_[1]) }

################################################################################
# return a list of nodes that are not children of any other node
################################################################################

sub roots
{
	my @roots;
	# remove root
	my $root = shift;
	# process the list from behind
	my $n = scalar(@_); while ($n--)
	{
		# status variable
		my $has_parent = 0;
		# process the list from behind
		my $i = scalar(@_); while ($i--)
		{
			# dont test yourself
			next if $i == $n;
			# check if the node has a known parent
			$has_parent = $_[$n]->hasParent($_[$i]);
			# abort the loop now
			last if $has_parent;
		}
		# only collect nodes that have no parent
		push @roots, $_[$n] unless $has_parent;
	}
	# return nodes
	return @roots;
}

################################################################################
# remove node from parent
################################################################################

sub remove
{
	# get arguments
	my ($node) = @_;
	# get parent node and its children
	my $parent = $node->{'parent'};
	my $children = $parent->{'children'};
	# remove this node from parents children
	@{$children} = grep { $_ != $node } @{$children};
	# reset parent node link
	$node->{'parent'} = undef
}

################################################################################
# cascade scope up to childern
################################################################################

sub revert { $_->revert(@_) foreach shift->children }
sub commit { $_->commit(@_) foreach shift->children }
sub execute { $_->execute(@_) foreach shift->children }

################################################################################
# setup path resolving
################################################################################

# lookup hash
my %respath = (
	'INC' => 'incdir',
	'EXT' => 'extdir',
	'BIN' => 'bindir',
	'WWW' => 'webdir',
	'CWD' => 'workdir',
	'CONF' => 'confdir',
	'BASE' => 'basedir',
);

# regex for all possible replacements
my $re_respath = qr/(?:INC|EXT|BIN|WWW|CWD|CONF|BASE)/i;

# add correct delimiters for replacements
# on windows we also need to accept backslashes
$re_respath = qr/^\{($re_respath)\}(?=\/|\Z)/i unless $^O eq 'MSWin32';
$re_respath = qr/^\{($re_respath)\}(?=\/|\\|\Z)/i if $^O eq 'MSWin32';


################################################################################
# implement correct and save path resolving
################################################################################
use File::Spec::Functions qw(catfile file_name_is_absolute);
################################################################################

my $fullpath; $fullpath = sub
{
	# declare variables
	my ($dir, $abs, @parts);
	# get specific input arguments
	my ($node, $fn) = @_;
	return die unless defined $node;
	# create iterator
	my $iter = $node;
	# move up in tree until abs
	while ($iter and not $abs)
	{
		# get current directory
		if (ref $fn eq 'SCALAR')
		{
			# special case for "respath"
			$dir = ${$fn}; $fn = 'respath';
		}
		# this is actually the correct way to
		# call the method name stored in $fn
		else { $dir = $iter->$fn; }
		# only process valid
		if (defined $dir)
		{
			# check if it makes path absolute
			$abs = file_name_is_absolute $dir;
			# resolve all registered items
			$dir =~ s/$re_respath/
				# check if we resolve ourself
				if (defined $fn && $fn eq $respath{uc$1})
				# if so we should resolve it on the parent
				{ &{$fullpath}($iter->parent, $respath{uc$1}) }
				# otherwise we can resolve it on ourself
				else { &{$fullpath}($iter, $respath{uc$1}) }
			/eig unless $abs;
			# recheck if path is absolute now
			$abs = file_name_is_absolute $dir;
			# push dir to parts
			unshift @parts, $dir;
		}
		# move iterator up
		$iter = $iter->parent;
	}
	# return undef if nothing is found
	return undef unless scalar @parts;
	# concatenate parts
	return catfile(@parts);
};

################################################################################
# cascade up in tree
################################################################################

# final implementation on scope
# ******************************************************************************
sub scope { shift->parent->scope(@_) }

# final implementation on root
# ******************************************************************************
sub root { shift->parent->root(@_) }

my $parent = sub
{
	shift @_;
};

# final implementation on doc
# ******************************************************************************
sub atomic { &{$parent}->parent->atomic(@_) }
sub option { &{$parent}->parent->option(@_) }
sub config { &{$parent}->parent->config(@_) }
sub setting { &{$parent}->parent->setting(@_) }
sub getById { &{$parent}->parent->getById(@_) }
sub document { &{$parent}->parent->document(@_) }
sub readfile { &{$parent}->parent->readfile(@_) }
sub writefile { &{$parent}->parent->writefile(@_) }

################################################################################
# compile full path from parents until absolute
# <dir> functions must not call resolve themselve
################################################################################

sub respath { &{$fullpath}($_[0], \ $_[1]) }
sub binroot { &{$fullpath}($_[0], 'bindir') }
sub extroot { &{$fullpath}($_[0], 'extdir') }
sub webroot { &{$fullpath}($_[0], 'webdir') }
sub incroot { &{$fullpath}($_[0], 'incdir') }
sub confroot { &{$fullpath}($_[0], 'confdir') }
sub workroot { &{$fullpath}($_[0], 'workdir') }
sub baseroot { &{$fullpath}($_[0], 'basedir') }

################################################################################
# do not cascade <dir> up the tree
################################################################################

sub extdir { undef }
sub bindir { undef }
sub webdir { undef }
sub incdir { undef }
sub confdir { undef }
sub basedir { undef }
sub workdir { undef }

################################################################################
# create absolute paths
################################################################################
use File::Spec::Functions qw(rel2abs);
################################################################################

# create absolute path without resolving
# ******************************************************************************
sub abspath { rel2abs($_[1], $_[2] || $_[0]->workroot) }

# create absolute path with resolving
# ******************************************************************************
sub fullpath { rel2abs($_[0]->respath($_[1]), $_[2] || $_[0]->workroot) }

################################################################################
################################################################################
1;