#!/usr/bin/perl

use strict;
use warnings;

###################################################################################################
package RTP::Webmerge::Embeder;
###################################################################################################

# define our version string
BEGIN { $RTP::Webmerge::Embeder::VERSION = "0.70" }

# load exporter and inherit from it
BEGIN { use Exporter qw(); our @ISA = qw(Exporter) }

# define our functions to be exported
BEGIN { our @EXPORT = qw(embeder); }

###################################################################################################

# load our local modules
use RTP::Webmerge qw(@initers);
use RTP::Webmerge::IO qw(writefile);
use RTP::Webmerge::Path qw(res_path);

###################################################################################################

# use cwd module to normalize paths
use Cwd qw(abs_path fast_abs_path);

# use core mdoules for path handling
use File::Basename qw(dirname);
use File::Spec::Functions qw(abs2rel);

###################################################################################################

our (%embeder, %tmpl);

sub register
{

	my ($type, $embeder) = @_;

	$type = lc $type;

	if (exists $embeder{$type} && $embeder{$type} != $embeder)
	{ printf 'embeder type <%s> already registered', $type; exit; }

	$embeder{$type} = $embeder;

}
# EO sub register

# push to initers
# return for getOpts
push @initers, sub
{

	# get config
	my ($config) = @_;

	# declare variables
	my (@options);

	# process each embeder type
	foreach my $type (keys %embeder)
	{
		# create config variable to be available
		$config->{'tmpl-embed-' . $type} = undef;
		# connect each tmpl variable with the getOpt option
		push(@options, 'tmpl-embed-' . $type . '=s'); # key
		push(@options, \ $config->{'cmd_tmpl-embed-' . $type}); # value
	}

	# return getOpt options
	return @options;

};
# EO push initer

###################################################################################################

# create header include files
# containing scripts/links nodes
sub embeder
{

	# get input variables
	my ($config, $embeder) = @_;

	# get local variables from config
	my $atomic = $config->{'atomic'};

	# test if current header has been disabled
	return if exists $embeder->{'disabled'} &&
		lc $embeder->{'disabled'} eq 'true';

	# get local variables from config
	# my $webpath = $config->{'webpath'};
	# my $webroot = $config->{'webroot'};

	# collect information
	my (%features, %domains);

	# collect all features and their detectors
	my $includes = $config->{'xml'}->{'headinc'};
	my $features = $config->{'xml'}->{'feature'};

	# collect all features by names (reverse order)
	foreach my $feature (reverse @{$features || []})
	{
		unless ( defined $feature->{'id'} )
		{ die 'feature without id found'; }
		$features{$feature->{'id'}} = $feature;
	}
	# EO each feature

	# collect all includes by domain
	foreach my $include (@{$includes || []})
	{

		# change directory (restore previous state after this block)
		my $dir = RTP::Webmerge::Path->chdir($include->{'chdir'});

		# get variables from include
		my $id = $include->{'id'};
		my $rootids = $include->{'rootid'};

		# rootid may contain a comma separated list
		foreach my $rootid (split(/\s*,\s*/, $rootids))
		{

			# create data structure for this domain entry
			$domains{$rootid} = { 'dev' => {}, 'live' => {} };

			# collect all outputs by context/class
			foreach my $output (@{$include->{'output'} || []})
			{

				# get variables from output
				my $class = $output->{'class'};
				my $context = $output->{'context'};

				# store the absolute path to the output file for include
				$domains{$rootid}->{$context}->{$class} = res_path $output->{'path'};

				# remove leading webroot path for each include file
				# this will make the whole process better deployable
				# $domains{$rootid}->{$context}->{$class} =~ s/^\Q$webroot\E\/+//;

			}
			# EO each output

		}
		# EO each rootid

	}
	# EO each include

	# put the arrays into local variables
	my $detects = $embeder->{'detect'} || [];
	my $outputs = $embeder->{'output'} || [];

	# process all output (different types)
	foreach my $output (@{$outputs || [] })
	{

		# get options for this output
		my $path = $output->{'path'};
		my $types = $output->{'type'};

		# make lowercase
		$types = lc $types;

		# resolve path to absolute path
		$path = res_path $path;

		# create new hash so we can
		# manipulate it for this output
		my %includes = %domains;

		# make all include paths relative
		# to the generated embeder script
		foreach my $did (keys %includes)
		{
			foreach my $context (keys %{$includes{$did}})
			{
				foreach (values %{$includes{$did}->{$context}})
				{
					$_ = abs2rel($_, dirname($path));
				}
			}
		}
		# EO foreach include

		# types may be a comma separated list
		foreach my $type (split(/\s*\,\s*/, $types))
		{

			# check if embeder type is registered
			if (exists $embeder{$type})
			{

				# get the embeder code for this given type (i.e. php or perl)
				my $code = $embeder{lc$type}(\%includes, \%features, $detects, $config);

				# give debug message about creating the embeder code
				print "creating standalone embeder for $type\n";

				# write the include code now
				writefile($path, $code, $atomic);

				# give a success message to the console
				print " created <", $output->{'path'}, ">\n";

			}
			else
			{

				# die with an error if type is unknown
				# maybe you forgot to load the type module
				die "unknown embeder output type <$type>\n"

			}

		}

	};
	# EO each output

}
# EO sub embeder

###################################################################################################

# load implementations
use RTP::Webmerge::Embeder::PHP;

###################################################################################################

1;

