################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge;
################################################################################
use base OCBNET::Webmerge::Config::XML::Root;
################################################################################

use strict;
use warnings;

################################################################################
# get or set options
################################################################################
our (%longopts, %defaults, %values);
################################################################################

sub options
{
	$longopts{$_[0]} = $_[1];
	$defaults{$_[0]} = $_[2];
	$values{$_[0]} = $_[2];
}

################################################################################
# return command line option
################################################################################

sub option
{
	# get from command line options
	if ( exists $values{$_[1]} )
	{ return $values{$_[1]}; }
	# or get from node config
	my $rv = $_[0]->config($_[1]);
	# or use defaults value
	unless ( defined $rv )
	{ $rv = $defaults{$_[1]}; }
	# return result
	return $rv;
}

################################################################################

# allow low-level access
sub values { \%values }
sub longopts { \%longopts }
sub defaults { \%defaults }

################################################################################

sub config { $values{$_[1]} }

################################################################################
use OCBNET::Webmerge::Config::XML;
################################################################################

################################################################################
# modules need to register stuff to configure
# they also need to define/pass a default value
# certain cmdline options will just be valid
# for initial while other overrule always
################################################################################

################################################################################
# constructor
################################################################################

sub new
{

	# get input arguments
	my ($pkg, $parent) = @_;

	# create a new node hash object
	my $node = $pkg->SUPER::new($parent);

	# create the config hash
	$node->{'processors'} = {};
	$node->{'options'} = {};

	# return object
	return $node;

}

################################################################################
# get or set processors
################################################################################

sub processor
{

	# get arguments (most optional)
	my ($webmerge, $name, $fn) = @_;

	# has a function
	if (scalar(@_) > 2)
	{
		# register the processor by name
		$webmerge->{'processors'}->{$name} = $fn;
	}
	# name is given
	elsif (scalar(@_) > 1)
	{
		# return the processor by name
		$webmerge->{'processors'}->{$name};
	}
	else
	{
		# return the hash ref
		$webmerge->{'processors'};
	}

}

################################################################################
# load a config file
################################################################################

sub load
{

	# get arguments
	my ($webmerge, $configfile) = @_;

	# create a new parser object (throw away)
	my $parser = OCBNET::Webmerge::Config::XML->new;

	# parse the config file and fill webmerge config tree
	return $parser->parse_file($configfile, $webmerge);

}


################################################################################
use Getopt::Long qw(GetOptions);
use Pod::Usage qw(pod2usage);
################################################################################
use List::MoreUtils qw(uniq);
################################################################################

sub main
{

	# main entrance
	my $configfile;

	# first only parse the configfile option
	# we may need to load plugin before first
	Getopt::Long::Configure("pass_through");
	GetOptions ("configfile|f=s", \$configfile)
	or die("Error in command line arguments\n");

	# create a new main webmerge object
	my $webmerge = OCBNET::Webmerge->new;

	# try to load our main config file
	$webmerge->load($configfile);

	# connect long opts, final scalars and defaults together;
	my %options = (%{$webmerge->{'options'}}, %OCBNET::Webmerge::longopts);
	my @options = map { ($options{$_}, \$values{$_}) } keys %options;

	# warn user about unknown options
	Getopt::Long::Configure("default");
	# get all options from commandline
	GetOptions(@options) or pod2usage(2);

die $webmerge->getById('po')->option('fingerprint');

	# collect block to be executed
	my @blocks = grep { $_ } map { $webmerge->getById($_) } @ARGV;
	push @blocks, $webmerge unless scalar(@blocks) + scalar(@ARGV);

	# call execute on all unique blocks
	$_->execute foreach (uniq @blocks);

}

################################################################################
################################################################################
1;
