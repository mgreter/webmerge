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
# register some default configs
################################################################################

options('help', 'help|?!', 0);
options('opts', 'opts!', 0);
options('man', 'man!', 0);

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

# sub value { $values{$_[1]} }

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

	# register our config filename
	$webmerge->{'filename'} = $configfile;

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

	# show all options
	if ($webmerge->option('opts'))
	{
		# print all names
		print join("\n", map {
			s/(?:\!|\=.*?)$//;
			join(', ', map { '-' . $_ } split /\|/);
		} sort keys %longopts);
		# exit ok
		exit 0;
	}

	# show help page if request by cmdline
	pod2usage(1) if $webmerge->option('help');
	# show man page if requested by cmdline
	pod2usage(-exitval => 0, -verbose => 2) if $webmerge->option('man');

	# collect blocks to be executed (ids from argv or all)
	my @blocks = grep { $_ } map { $webmerge->getById($_) } @ARGV;
	push @blocks, $webmerge unless scalar(@blocks) + scalar(@ARGV);

	# pass execution to tools (run blocks)
	OCBNET::Webmerge::Tool::run(@blocks);

	# commit all changes
	$webmerge->commit(1);

	# return the object
	return $webmerge;

}

################################################################################
# change behaviour if you want to force the
# user to call commit explicitly by himself
################################################################################

# sub DESTROY { $_[0]->revert; }

################################################################################
################################################################################
1;

__DATA__

################################################################################
################################################################################

# from mod_pagespeed src/net/instaweb/http/user_agent_matcher.cc
#
# const char* kImageInliningWhitelist[] = {
#  "*Android*",
#  "*Chrome/*",
#  "*Firefox/*",
#  "*iPad*",
#  "*iPhone*",
#  "*iPod*",
#  "*itouch*",
#  "*MSIE *",
#  "*Opera*",
#  "*Safari*",
#  "*Wget*",
#  // The following user agents are used only for internal testing
#  "google command line rewriter",
#  "webp",
# };
#
# const char* kImageInliningBlacklist[] = {
#  "*Firefox/1.*",
#  "*Firefox/2.*",
#  "*MSIE 5.*",
#  "*MSIE 6.*",
#  "*MSIE 7.*",
#  "*Opera?5*",
#  "*Opera?6*"
# };
