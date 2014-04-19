################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
# XML node is the base class for all xml dom nodes
# Only tags are real dom nodes and text will be merged
# You will not be able to access comments or text nodes
################################################################################
package OCBNET::Webmerge::Config::XML::Node;
################################################################################
use Scalar::Util qw(weaken);
################################################################################
use FindBin qw($Bin);
use File::Spec qw();
################################################################################

use strict;
use warnings;

################################################################################

sub enabled
{
	return 1;
}

################################################################################
# constructor
################################################################################

sub new
{

	# get input arguments
	my ($pkg, $parent) = @_;

	# create a new node hash object
	my $node =
	{
		'data' => '',
		'tag' => '[NA]',
		'children' => []
	};

	# connect child and parent
	if (defined $parent)
	{
		# assign reference to parent
		$node->{'parent'} = $parent;
		# add ourself to parents children
		push @{$parent->{'children'}}, $node;
	}

	# weaken the ref scalar
	weaken $node->{'parent'};

	# bless into package
	bless $node, $pkg;

	# return object
	return $node;

}

################################################################################
# destructor
################################################################################

sub DESTROY { }

################################################################################
################################################################################

sub log
{
	print " " x shift->level, @_, "\n";
}

sub logBlock
{
	print " " x shift->level, @_, "\n";
}

sub logFile
{
	print " " x $_[0]->level;
	printf "% 10s: %s\n", $_[1], $_[0]->dpath;
}

sub logAction
{
	print " " x $_[0]->level;
	printf "% 10s: %s\n", $_[1], $_[0]->dpath;
}

sub logSuccess
{
	# print $_[1] ? "ok\n" : "err\n";
}


sub dpath { $_[0]->type }

################################################################################
# some accessor methods
################################################################################

# return node type
sub type { 'NODE' }

# return the id
sub id { $_[0]->attr('id') }

# return the tag name
sub tag { $_[0]->{'tag'} }

# return the node data
sub data { $_[0]->{'data'} }

# return the node text
sub text { $_[0]->{'text'} }

# get connected parent node
sub parent { $_[0]->{'parent'} }

# get connected parent node
sub document { $_[0]->parent->document }

# return number of childrens
sub length { scalar $_[0]->children }

# return a list with all child nodes
sub children { @{$_[0]->{'children'}} }

# get attribute value for given key
sub attr : lvalue { $_[0]->{'attr'}->{$_[1]} }

################################################################################
# simply pass call to children
################################################################################

sub revert { $_->revert(@_) foreach shift->children }
sub commit { $_->commit(@_) foreach shift->children }

################################################################################
# count number of parent levels
################################################################################

sub level { $_[0]->parent->level(1 + ($_[1] || 0)) }

################################################################################
# cascade scope down to parent node
################################################################################

sub scope { shift->parent->scope(@_) }
sub webroot { shift->parent->webroot(@_) }
sub confroot { shift->parent->confroot(@_) }
sub directory { shift->parent->directory(@_) }


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
# get node by id (or undef if not found)
################################################################################

sub getById { $_[0]->document->{'ids'}->{$_[1]} }

################################################################################
# check if we are a child of a certain parent
################################################################################

sub hasParent { $_[0]->parent eq $_[1] || $_[0]->parent->hasParent($_[1]) }

################################################################################
# find children by tagname
################################################################################

sub find { grep { lc $_->{'tag'} eq lc $_[1] } $_[0]->children }

################################################################################
# find closest parent by tag name regexp
################################################################################

sub closest { $_[0]->tag =~ $_[1] ? $_[0] : $_[0]->parent->closest($_[1]) }

################################################################################
# call method on all children
################################################################################

sub deps { map { $_->deps } $_[0]->children }
sub execute {
	$_[0]->log("execute " . $_[0]->type);
	$_->execute foreach $_[0]->children;
}

################################################################################
# resolve path placeholders
################################################################################

my $respath = {
	'cwd' => sub { $_[0]->directory },
	'www' => sub { $_[0]->parent->webroot }
};

################################################################################
# return resolved path
################################################################################

sub respath
{
	# get arguments
	my ($node, $path) = @_;
	# resolve some specific placeholders
	$path =~ s/^\{(EXT|BIN)\}/$Bin/ig;
	# avoid resolving the directory multiple times
	$path =~ s/^\{(CWD|WWW)\}/$respath->{lc$1}->($node)/eig;
	# return path if no more parent
	return $path unless $node->parent;
	# resolve path via parent nodes
	return $node->parent->respath($path);
}

################################################################################
# return absolute path
################################################################################
use FindBin qw($Bin);
use File::Spec qw();
################################################################################

sub abspath
{
	# get arguments
	my ($node, $path, $root) = @_;
	# assign default directory if no other base is given
	$root = $Bin unless defined $root && $_[0]->parent;
	$root = $_[0]->parent->directory unless defined $root;
	# resolve path placeholders
	$root = $node->respath($root);
	$path = $node->respath($path);
	# join relative path with given base directory
	unless (File::Spec->file_name_is_absolute($path))
	{ $path = File::Spec->join($root, $path); }
	# assertion to avoid any unexpected behavior
	unless (File::Spec->file_name_is_absolute($path))
	{ die "should not return relative path -> $root\n"; }
	# return absolute canonical path
	return File::Spec->canonpath($path);
}

################################################################################
# implement tags in different classes
################################################################################
# this should be more plugin friendly
################################################################################

my %parse = (
	'xml' => 'OCBNET::Webmerge::Config::XML::Include',
	'block' => 'OCBNET::Webmerge::Config::XML::Scope',
	'merge' => 'OCBNET::Webmerge::Config::XML::Scope',
	'config' => 'OCBNET::Webmerge::Config::XML::Config',
	'js' => 'OCBNET::Webmerge::Config::XML::Merge::JS',
	'css' => 'OCBNET::Webmerge::Config::XML::Merge::CSS',

	'echo' => 'OCBNET::Webmerge::Config::XML::Echo',
	'eval' => 'OCBNET::Webmerge::Config::XML::Eval',

	'file' => 'OCBNET::Webmerge::Config::XML::File',
	'input' => 'OCBNET::Webmerge::Config::XML::Input',
	'output' => 'OCBNET::Webmerge::Config::XML::Output',

	'finish' => 'OCBNET::Webmerge::Config::XML::Action',
	'prepare' => 'OCBNET::Webmerge::Config::XML::Action',

	'copy' => 'OCBNET::Webmerge::Config::XML::Action::Copy',
	'mkdir' => 'OCBNET::Webmerge::Config::XML::Action::Make',
	'optimize' => 'OCBNET::Webmerge::Config::XML::Optimize',
	'txt' => 'OCBNET::Webmerge::Config::XML::Optimize::TXT',
	'gif' => 'OCBNET::Webmerge::Config::XML::Optimize::GIF',
	'jpg' => 'OCBNET::Webmerge::Config::XML::Optimize::JPG',
	'png' => 'OCBNET::Webmerge::Config::XML::Optimize::PNG',

);

################################################################################
# return class by given tag name
################################################################################

sub classByTag { $parse{$_[1]} }

################################################################################
# webmerge xml parser implementation
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

# append more data (called by parser)
sub char { $_[0]->{'data'} .= $_[2] }

################################################################################
# xml parser implementation
################################################################################

# tag is opened
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

	# resolve includes
	if ($tag eq 'include')
	{
		# create a new parser object to parse include
		my $parser = OCBNET::Webmerge::Config::XML->new;
		# parse include url in src attribute and pass current scope
		my $rv = $parser->parse_file($attr{'src'}, $nodes->[-1]);
		# parse file should error out by itself, but just in case
		die "fatal error while parsing ", $attr{'src'} unless $rv;
	}

	# check if tag is known
	elsif (defined $class)
	{
		# create a new (child) config block
		my $child = $class->new($nodes->[-1]);
		# store vars on node
		$child->{'tag'} = $tag;
		$child->{'attr'} = \%attr;
		# call method on object
		$child->started($webmerge);
	}
	else
	{
		die "unknown tag <$tag> in xml";
	}

}
# EO start

# tag is closed
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
	{ $nodes->[-1]->ended($webmerge); }
	else { die "unknown tag </$tag> $node in xml"; }

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
		{ $document->{'ids'}->{$id}->remove; }
		# store node by given id on document
		$document->{'ids'}->{$id} = $node;
	}

}
# EO end

################################################################################
################################################################################

sub config { shift->parent->config(@_) }
sub option { shift->parent->option(@_) }
sub setting { shift->parent->setting(@_) }

################################################################################
################################################################################
1;