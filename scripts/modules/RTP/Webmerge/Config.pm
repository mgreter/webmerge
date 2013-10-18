###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
###################################################################################################
package RTP::Webmerge::Config;
###################################################################################################

use Carp;
use strict;
use warnings;

###################################################################################################

# global variables for various paths
# $webroot: absolute path to htdocs root
# $confroot: directory of the config file
# $directory: our current working directory
our ($webroot, $confroot, $extroot, $directory);

###################################################################################################

# define our version string
BEGIN { $RTP::Webmerge::Config::VERSION = "0.9.0" }

# load exporter and inherit from it
BEGIN { use Exporter qw(); our @ISA = qw(Exporter) }

# define our variables to be exported
BEGIN { our @EXPORT = qw(); }

# define our functions to be exported
BEGIN { our @EXPORT_OK = qw(); }

###################################################################################################

use RTP::Webmerge::Path;

###################################################################################################

my %stages;

###################################################################################################

# constructor
sub new
{

	# get input variables
	my ($pkg) = @_;

	# create and bless instance
	my $self = bless {}, ref $pkg || $pkg;

	# init stages array
	$stages{$self} = [];

	# return instance
	return $self;

}
# EO sub new

###################################################################################################

# stage more config
# return a new reference
# will update the current
sub stage
{

	# get input variables
	my ($self) = @_;

	# create new instance
	my $stage = $self->new;

	# push a copy of old data onto stages stack
	push @{$stages{$stage}}, [ $self, { %{$self} } ];

	# apply the old config
	$stage->apply($self);

	# return instance
	return $stage;

}
# EO sub stage

###################################################################################################

# apply cmdline options
sub cmdline
{

	# get instance
	my ($self) = @_;

	# search all config keys for /^cmd_/
	# options from command line overrule
	# all other configuration options
	foreach my $key (keys %{$self})
	{

		# only process cmd keys
		next unless $key =~ s/^cmd_//;

		# only process valid cmd keys
		next unless defined $self->{'cmd_'.$key};

		# overrule the option from cmd line
		$self->{$key} = $self->{'cmd_'.$key};

		# remove cmd option from config
		delete $self->{'cmd_'.$key};

	}
	# EO each config key

	# return instance
	return $self;

}
# EO apply

# apply cmdline options
sub finalize
{

	# get instance
	my ($self) = @_;

	# create the config path from config file ...
	$self->{'configpath'} = $self->{'configfile'};
	# ... and remove the trailing filename
	$self->{'configpath'} =~ s/\/[^\/]+$//;

	# register path within our path modules for later use
	$RTP::Webmerge::Path::confroot = $self->{'configpath'};

	# set htdocs root directory and current working directory
	$RTP::Webmerge::Path::webroot = check_path($self->{'webroot'} || '.');
	$RTP::Webmerge::Path::directory = check_path($self->{'directory'} || '.');

	# only allow directory or query option to be given for fingerprinting
	if ($self->{'fingerprint-dev'} && !($self->{'fingerprint-dev'} =~ m/^[qfn]/i))
	{ die "invalid fingerprinting set for dev: <" .  $self->{'fingerprint-dev'} . ">"; }
	if ($self->{'fingerprint-live'} && !($self->{'fingerprint-live'} =~ m/^[qfn]/i))
	{ die "invalid fingerprinting set for live: <" .  $self->{'fingerprint-live'} . ">"; }

	# normalize fingerprint configuration to the first letter (lowercase)
	$self->{'fingerprint-dev'} = lc substr($self->{'fingerprint-dev'}, 0, 1);
	$self->{'fingerprint-live'} = lc substr($self->{'fingerprint-live'}, 0, 1);
	# disable the fingerprint option if the given value is no or none
	$self->{'fingerprint-dev'} = undef if $self->{'fingerprint-dev'} eq 'n';
	$self->{'fingerprint-live'} = undef if $self->{'fingerprint-live'} eq 'n';

	# init the config array
	$self->{'external'} = [];

	# check if xml is attached
	if (my $xml = $self->{'xml'})
	{

		# process all config nodes in config file
		foreach my $cfg (@{$xml->{'config'} || []})
		{

			# process all given external options
			foreach my $ext (@{$cfg->{'external'} || []})
			{

				# get content from xml node
				my $enabled = $ext->{'content'};
				# enable when tag was self closing
				$enabled = 1 unless defined $enabled;
				# push hash object to config array
				unshift @{$self->{'external'}},
				{
					'enabled' => $enabled,
					'href' => $ext->{'href'},
					'referer' => $ext->{'referer'},
				};

			}
			# EO each external

		}
		# EO each xml config

	}
	# EO if xml

	# store atomic operations
	$self->{'atomic'} = {};

	# store temporarily files
	$self->{'temps'} = [];

	# return instance
	return $self;

}

###################################################################################################

# apply more config
sub apply
{

	# get instance
	my ($self, @config) = @_;

	# process each config block
	foreach my $config (@config)
	{
		# overwrite the current config
		%{$self} = (%{$self}, %{$config || {}});
	}

	# force commandline
	$self->cmdline();

	# return instance
	return $self;

}
# EO apply

###################################################################################################

# apply more config
sub xml
{

	# get instance
	my ($self, $xml) = @_;


	# process all config nodes in config file
	foreach my $cfg (@{$xml->{'config'} || []})
	{

		# process all given configuration keys
		foreach my $key (keys %{$cfg || {}})
		{

			# do not create unknown config keys
			next unless exists $self->{$key};

			# assign the value from the first item
			$self->{$key} = $cfg->{$key}->[0];

			# if we got a hash we had an empty tag
			if (ref($self->{$key}) eq 'HASH')
			{ $self->{$key} = ''; }

		}
		# EO each xml config key

	}
	# EO each xml config

	# store xml reference
	$self->{'xml'} = $xml;

	# force commandline
	$self->cmdline();

	# return instance
	return $self;

}
# EO apply

###################################################################################################

# object destructor
# restore the saved directory
sub DESTROY
{

	# destroy arguments
	my ($self) = @_;

	# check if we have some stage for us
	return unless scalar @{$stages{$self}};

	# get the stage object (config copy)
	my $stage = pop @{$stages{$self}};

	# make sure to release all memory we may consume
	delete $stages{$self} unless scalar @{$stages{$self}};

	# restore previous settings
	%{$stage->[0]} = %{$stage->[1]};

	# finalize again
	$stage->[0]->finalize;

}
# EO destructor

###################################################################################################
###################################################################################################
1;
