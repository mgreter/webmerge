################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
# XML node is the base class for all xml dom nodes
# Only tags are real dom nodes and text will be merged
# You will not be able to access comments or text nodes
################################################################################
package OCBNET::Webmerge::XML::Tree::Node;
################################################################################
use base qw(OCBNET::Webmerge::Tree::Node);
################################################################################

use strict;
use warnings;

################################################################################
# xml parser implementation
################################################################################

sub started
{
	# get arguments from parser
	my ($node, $webmerge) = @_;
	# push node to the stack array
	push @{$webmerge->{'nodes'}}, $node;
}

sub ended
{
	# get arguments from parser
	my ($node, $webmerge) = @_;
	# pop node off the stack array
	pop @{$webmerge->{'nodes'}};
}

################################################################################
# helper methods for parser
################################################################################
use OCBNET::Webmerge qw(notset);
################################################################################

# append more data (called by parser)
# ******************************************************************************
sub char { $_[0]->{'data'} .= $_[2] }

# new tag is beeing opened
# ******************************************************************************
sub start
{

	# get arguments from parser
	my ($node, $expat, $tag, %attr) = @_;

	# normalize tag (asume undef means root)
	$tag = defined $tag ? lc $tag : 'root';

	# get webmerge object from parser
	my $webmerge = $expat->{'webmerge'};

	# get current webmerge parser state
	my $nodes = $webmerge->{'nodes'};

	# get perl class name from tag name
	my $class = $node->classByTag($tag);

	# get current node
	my $current = $nodes->[-1];

	# check if tag is known
	if (defined $class)
	{
		# create a new (child) config block
		my $child = $class->new($current);
		# store vars on node
		$child->{'tag'} = $tag;
		$child->{'attr'} = \%attr;
		# call started method on object
		$child->started($webmerge);
	}
	else
	{
		die "unknown tag <$tag> in xml";
	}

}
# EO start


# our tag is beeing closed
# ******************************************************************************
sub end
{

	# get arguments from parser
	my ($node, $expat, $tag) = @_;

	# normalize tag (asume undef means root)
	$tag = defined $tag ? lc $tag : 'root';

	# get webmerge object from parser
	my $webmerge = $expat->{'webmerge'};

	# get current webmerge parser state
	my $nodes = $webmerge->{'nodes'};

	# get perl class name from tag name
	my $class = $node->classByTag($tag);

	# ignore include closer
	if ($tag eq 'include') {}
	# call ended method on object
	elsif (defined $class)
	{ $node->ended($webmerge); }
	else { die "unknown tag </$tag> in xml"; }

	# assign data to text (clean it)
	$node->{'text'} = $node->{'data'};

	# normalize whitespace for text
	$node->{'text'} =~ s/\s+/ /g;
	$node->{'text'} =~ s/\A\s+//;
	$node->{'text'} =~ s/\s+\z//;

	# normalize whitespace for text
	# $node->{'text'} =~ s/[ 	]+/ /g;
	# $node->{'text'} =~ s/\A(?:[ 	]*[\n\r]+)*//;
	# $node->{'text'} =~ s/(?:[\n\r]+[ 	]*)*\z/\n/;

	# ids have to be unique, remove any
	# previous id from the tree. Thus it
	# allows you to overwrite named blocks.
	if (defined (my $id = $node->attr('id')))
	{
		# get the document root
		my $document = $node->document;
		# remove if id is known already
		if (exists $document->{'ids'}->{$id})
		{
			# but only if not removing myself
			if ($document->{'ids'}->{$id} ne $node)
			{ $document->{'ids'}->{$id}->remove; }
		}
		# store node by given id on document
		else { $document->{'ids'}->{$id} = $node; }
	}

}
# EO end

################################################################################
# register additional xml tags
################################################################################

$OCBNET::Webmerge::XML::parser{'js'} = __PACKAGE__;
$OCBNET::Webmerge::XML::parser{'css'} = __PACKAGE__;
$OCBNET::Webmerge::XML::parser{'xml'} = __PACKAGE__;

################################################################################
# return class by given tag name (resolve via main module)
################################################################################

sub classByTag { $OCBNET::Webmerge::XML::parser{$_[1]} }

################################################################################
################################################################################
1;
