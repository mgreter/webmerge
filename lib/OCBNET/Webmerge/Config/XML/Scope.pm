################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
# XML scope is a node that connects to a config scope
# Config scopes inherit settings from parent scopes
################################################################################
package OCBNET::Webmerge::Config::XML::Scope;
################################################################################
use base qw(
	OCBNET::Webmerge::Config::XML::Node
	OCBNET::Webmerge::IO::Atomic
);
################################################################################

use strict;
use warnings;

################################################################################
# constructor
################################################################################

sub new
{

	# get input arguments
	my ($pkg, $parent) = @_;

	# create a new node hash object
	my $node = $pkg->SUPER::new($parent);

	# call new for additional class initialization
	$node->OCBNET::Webmerge::IO::Atomic::new($parent);

	# create the config hash
	$node->{'config'} = {};

	# return object
	return $node;

}

################################################################################
# get absolute path of current working directory
################################################################################
my $err_placeholder_cwd = "directory must not contain CWD placeholder";
my $err_placeholder_www = "webroot must not contain WWW placeholder";
################################################################################

sub directory
{

	# use cached value if available
	if (exists $_[0]->{'directory'})
	{ return $_[0]->{'directory'} }

	# get directory from current config scope
	my $path = $_[0]->{'config'}->{'directory'};
	# get webroot from parent node
	my $root = $_[0]->parent->directory;

	# use root if path is not passed
	$path = '.' unless defined $path;
	# assertion for some disallowed placeholders
	$path =~ s/^\{CWD\}/$_[0]->parent->directory/;
	# path is defined .. force into absolute path
	$path = $_[0]->abspath($path, $root);

	# assertion for some disallowed placeholders
	die $err_placeholder_www if $path =~ /^\{WWW\}/;
	die $err_placeholder_cwd if $path =~ /^\{CWD\}/;

	# cache the result for repeated calls
	$_[0]->{'directory'} = $_[0]->respath($path);

	# return the now cached result
	die unless $_[0]->{'directory'};
	return $_[0]->{'directory'};
}

################################################################################
# get absolute path of current webserver document root
################################################################################

sub webroot
{

	# use cached value if available
	if (exists $_[0]->{'webroot'})
	{ return $_[0]->{'webroot'} }

	# get directory from current config scope
	my $path = $_[0]->{'config'}->{'webroot'};
	# get webroot from parent node
	my $root = $_[0]->parent->webroot;

	# use root if path is not passed
	$path = '.' unless defined $path;
	# assertion for some disallowed placeholders
	$path =~ s/^\{WWW\}/$_[0]->parent->webroot/;
	# create absolute path from base root
	$path = $_[0]->abspath($path, $root);

	# assertion for some disallowed placeholders
	die $err_placeholder_www if $path =~ /^\{WWW\}/;
	die $err_placeholder_cwd if $path =~ /^\{CWD\}/;

	# cache the result for repeated calls
	$_[0]->{'webroot'} = $_[0]->respath($path);

	# return the now cached result
	die unless $_[0]->{'webroot'};
	return $_[0]->{'webroot'};

}

################################################################################
# some accessor methods
################################################################################

# return node type
sub type { 'SCOPE' }

# return ourself
sub scope { $_[0] }

################################################################################
# get config from our scope
# or cascade to parent scope
# or give warning about missing option
# add default and commandline handling
################################################################################

sub config
{
	# get arguments
	my ($node, $key) = @_;
	# check if config key exists here
	if (exists $node->{'config'}->{$key})
	{ return $node->{'config'}->{$key}; }
	# otherwise try to pass to parent
	elsif (defined $node->parent)
	{ $node->parent->scope->config($key); }
	# issue a warning about missing config
	else { warn "no config for $key"; () }
}

################################################################################
# execute event
################################################################################

sub execute
{
	print " " x $_[0]->level;
	print "exec ", $_[0]->tag, "\n";
	shift->SUPER::execute(@_);
}

################################################################################
################################################################################
1;