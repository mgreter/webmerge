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


################################################################################
# return command line option or node config
################################################################################

sub setting
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
# return config for root block or setting
################################################################################

sub option
{
	# config on most outer block overrules it
	if ( exists $_[0]->{'config'}->{$_[1]} )
	{ return $_[0]->{'config'}->{$_[1]}; }
	else { return $_[0]->setting($_[1]); }
}

################################################################################

# allow low-level access
sub values { \%values }
sub longopts { \%longopts }
sub defaults { \%defaults }

################################################################################

sub config { $values{$_[1]} }

################################################################################
use OCBNET::Webmerge::CRC;
use OCBNET::Webmerge::Tool;
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
# get the mother pid
################################################################################

my $pid = $$;

################################################################################
# setup teardown handlers before main program
################################################################################

# main instance
our $webmerge;

# clean up
sub cleanup
{
	# kill webmerge if still living
	if ($pid == $$ && $webmerge)
	{ undef $webmerge; exit 1; }
	# call exit
	exit 0;
}

# exit on ctrl+c, this make sure
# that the end handler is called
# seems not to work on windows
$SIG{'INT'} = \&cleanup;

# this will always be called
# when the main script exists
END { &cleanup }


################################################################################
use Getopt::Long qw(GetOptions);
use Pod::Usage qw(pod2usage);
################################################################################
use List::MoreUtils qw(uniq);
################################################################################

sub main
{

	# main entrance
	my $configfile = 'webmerge.conf.xml';

	# only parse the config file option
	# load plugins first for more options
	Getopt::Long::Configure("pass_through");
	GetOptions ("configfile|f=s", \$configfile)
	or die("Error in command line arguments\n");

	# create a new main webmerge object
	$webmerge = OCBNET::Webmerge->new;

	# try to load our main config file
	# this may load additional plugins
	$webmerge->load($configfile);

	# collect longopts and assign variables to options
	my %options = (%{$webmerge->{'options'}}, %OCBNET::Webmerge::longopts);
	my @options = map { ($options{$_}, \$values{$_}) } keys %options;

	# warn user about unknown options
	Getopt::Long::Configure("default");
	# get all options from commandline
	GetOptions(@options) or pod2usage(2);

	# collect block to be executed (ids from argv or all)
	my @blocks = grep { $_ } map { $webmerge->getById($_) } @ARGV;
	push @blocks, $webmerge unless scalar(@blocks) + scalar(@ARGV);

	# pass execution to tool module (run all tools)
	OCBNET::Webmerge::Tool::run($webmerge, \@blocks);

}

################################################################################
# change behaviour if you want to force the
# user to call commit explicitly by himself
################################################################################

# sub DESTROY { $_[0]->revert; }

################################################################################
################################################################################
1;
