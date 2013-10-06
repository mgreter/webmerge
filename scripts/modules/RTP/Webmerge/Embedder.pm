###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
###################################################################################################
package RTP::Webmerge::Embedder;
###################################################################################################

use Carp;
use strict;
use warnings;

###################################################################################################

# define our version string
BEGIN { $RTP::Webmerge::Embedder::VERSION = "0.70" }

# load exporter and inherit from it
BEGIN { use Exporter qw(); our @ISA = qw(Exporter) }

# define our functions to be exported
BEGIN { our @EXPORT = qw(embedder); }

###################################################################################################

# load our local modules
use RTP::Webmerge qw(@initers);
use RTP::Webmerge::IO qw(writefile readfile);

# use core mdoules for path handling
use RTP::Webmerge::Path qw(dirname check_path exportURI importURI);

###################################################################################################

our (%embedder, %tmpl);

sub register
{

	my ($type, $embedder) = @_;

	$type = lc $type;

	if (exists $embedder{$type} && $embedder{$type} != $embedder)
	{ printf 'embedder type <%s> already registered', $type; exit; }

	$embedder{$type} = $embedder;

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

	# process each embedder type
	foreach my $type (keys %embedder)
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
sub embedder
{

	# get input variables
	my ($config, $embedder) = @_;

	# get local variables from config
	my $atomic = $config->{'atomic'};

	# test if current header has been disabled
	return if exists $embedder->{'disabled'} &&
		lc $embedder->{'disabled'} eq 'true';

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
				$domains{$rootid}->{$context}->{$class} = check_path $output->{'path'};

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
	my $detects = $embedder->{'detect'} || [];
	my $outputs = $embedder->{'output'} || [];

	# process all output (different types)
	foreach my $output (@{$outputs || [] })
	{

		# get options for this output
		my $path = $output->{'path'};
		my $types = $output->{'type'};

		# make lowercase
		$types = lc $types;

		# resolve path to absolute path
		$path = check_path $path;

		# create new hash so we can
		# manipulate it for this output
		my %includes; my %contents;

		# load all include files content
		# to the generated embedder script
		foreach my $did (keys %domains)
		{
			# define new objects
			$includes{$did} = {};
			$contents{$did} = {};
			# process each context in domain id
			foreach my $context (keys %{$domains{$did}})
			{
				# define new objects
				$includes{$did}->{$context} = {};
				$contents{$did}->{$context} = {};
				# process each class in domain id context
				foreach my $class (keys %{$domains{$did}->{$context}})
				{
					# get the filepath to load/include
					my $file = $domains{$did}->{$context}->{$class};
					# load the content of the include file
					my $data = readfile($file, $atomic);
					# make include paths relative to output
					$file = exportURI($_, dirname($path));
					# assert that the file could be loaded
					die "could not load $file" unless defined $data;
					# store filepath and the content for later
					$includes{$did}->{$context}->{$class} = $file;
					$contents{$did}->{$context}->{$class} = ${$data};
				}
			}
		}
		# EO foreach include

		# types may be a comma separated list
		foreach my $type (split(/\s*\,\s*/, $types))
		{

			# check if embedder type is registered
			if (exists $embedder{$type})
			{

				# get the embedder code for this given type (i.e. php or perl)
				my $code = $embedder{lc$type}(\%includes, \%contents, \%features, $detects, $config);

				# give debug message about creating the embedder code
				print "creating standalone embedder for $type\n";

				# write the include code now
				writefile($path, $code, $atomic);

				# give a success message to the console
				print " created <", $output->{'path'}, ">\n";

			}
			else
			{

				# die with an error if type is unknown
				# maybe you forgot to load the type module
				die "unknown embedder output type <$type>\n"

			}

		}

	};
	# EO each output

}
# EO sub embedder

###################################################################################################

# load implementations
use RTP::Webmerge::Embedder::JS;
use RTP::Webmerge::Embedder::PHP;

###################################################################################################
####################################################################################################
1;