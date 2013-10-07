###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
###################################################################################################
package RTP::Webmerge::HeadInc;
###################################################################################################

use Carp;
use strict;
use warnings;

###################################################################################################

# define our version string
BEGIN { $RTP::Webmerge::HeadInc::VERSION = "0.9.0" }

# load exporter and inherit from it
BEGIN { use Exporter qw(); our @ISA = qw(Exporter) }

# define our functions to be exported
BEGIN { our @EXPORT = qw(headinc); }

###################################################################################################

# make absolute paths
use RTP::Webmerge::Path;

use RTP::Webmerge::IO qw(writefile);
use RTP::Webmerge::Fingerprint qw(fingerprint);

###################################################################################################

# import registered processors
use RTP::Webmerge qw(@initers);

# register initializer
push @initers, sub
{

	# get input variables
	my ($config) = @_;

	# assign default value to variable
	$config->{'jsdeferer'} = 'head.js';

	# return additional get options attribute
	return ( 'jsdeferer=s' => \ $config->{'cmd_jsdeferer'} );

};
# EO plugin initer

###################################################################################################

# declare templates
my $tmpl =
{

	'xhtml' =>
	{
		'js' => '<script type="text/javascript" src="%1$s"></script>',
		'css' => '<link rel="stylesheet" type="text/css" href="%1$s"/>',
		'script' => '<script type="text/javascript">%1$s</script>',
		'jsdefer' => '<script type="text/javascript">%3$s({ \'%2$s\' : \'%1$s\' });</script>'
	},

	'html' =>
	{
		'js' => '<script type="text/javascript" src="%1$s"></script>',
		'css' => '<link rel="stylesheet" type="text/css" href="%1$s">',
		'script' => '<script type="text/javascript">%1$s</script>',
		'jsdefer' => '<script type="text/javascript">%3$s({ \'%2$s\' : \'%1$s\' });</script>'
	},

	'html5' =>
	{
		'js' => '<script src="%1$s"></script>',
		'css' => '<link rel="stylesheet" href="%1$s">',
		'script' => '<script>%1$s</script>',
		'jsdefer' => '<script>%3$s({ \'%2$s\' : \'%1$s\' });</script>'
	}

};

###################################################################################################

###################################################################################################

# create header include files
# containing scripts/links nodes
sub headinc
{

	# get input variables
	my ($config, $headinc) = @_;

	# collect output paths
	# collectOutputs($config);

	# get local variables from config
	my $atomic = $config->{'atomic'};
	my $doctype = $config->{'doctype'};
	my $incorder = $config->{'incorder'};
	my $outpaths = $config->{'outpaths'};

	# test if current header has been disabled
	return if exists $headinc->{'disabled'} &&
		lc $headinc->{'disabled'} eq 'true';

	# put the arrays into local variables
	my $inputs = $headinc->{'input'} || [];
	my $outputs = $headinc->{'output'} || [];

	# change directory (restore previous state after this block)
	my $dir = RTP::Webmerge::Path->chdir($headinc->{'chdir'});

	# process all header output entries
	foreach my $output (@{$outputs || [] })
	{

		# collect includes
		my @includes;

		# get the class name for this output
		my $class = $output->{'class'} || 'default';

		# assert that the path has been given for this output
		die 'no path given for output' unless $output->{'path'};
		# assert that the context has been given for this output
		die 'no context given for output' unless $output->{'context'};

		print "creating header for class=", $class, " and context=", $output->{'context'}, "\n";

		# get into local variable
		my $path = $output->{'path'};
		my $context = $output->{'context'};

		# assert that context is a valid token
		# I will choose the most appropriate include
		unless ($context eq 'live' || $context eq 'dev')
		{ die 'context must be live or dev for head include'; }

		# process all header input entries
		foreach my $input (@{$inputs || [] })
		{

			# we have a text node
			unless (ref($input))
			{

				# add text as is (you must not add script tags yourself)
				push(@includes, sprintf $tmpl->{$doctype}->{'script'}, $input);

			}

			# source is given completely, just render include
			elsif (exists $input->{'src'} && $input->{'src'})
			{

				# get local variables
				my $id = $input->{'id'} || die "no id given for src head include";
				my $type = $input->{'type'} || die "no type given for src head include";
				my $incpath = $input->{'src'} || die "no src given for src head include";

				# use special include if load is defered
				my $defer = $input->{'defer'} || 'false';

				# disable defering in dev mode
				# XXX - find a way to use it anyway
				$defer = 'false' if $context eq 'dev';

				# get the include type wheter include is defered or not
				my $inctype = lc $defer eq 'true' ? $type . 'defer' : $type;

				# generate and add the include by using sprintf and the given template
				push(@includes, sprintf $tmpl->{$doctype}->{$inctype}, $incpath, $id, $config->{'jsdeferer'});

			}

			# if we have an id we should include the file
			elsif (exists $input->{'merged'} && $input->{'merged'})
			{

				# get into local variable
				my $id = $input->{'merged'};

				# assertion that the referenced id is a defined item
				die "referenced input <$id> is invalid" unless exists $outpaths->{$id};

				# get the media type for this input
				my $type = $outpaths->{$id}->{'type'};

				# use special include if load is defered
				my $defer = $input->{'defer'} || 'false';

				# disable defering in dev mode
				# XXX - find a way to use it anyway
				$defer = 'false' if $context eq 'dev';

				# search the output path for this context
				# will search all generated contexts for best match
				my $outpath;

				# classpaths to be searched
				foreach my $classpaths
				(
					$outpaths->{$id}->{'out'}->{$class} || {},
					$outpaths->{$id}->{'out'}->{'default'} || {}
				)
				{

					# loop all targets from the include order
					foreach my $target (@{$incorder->{$context}})
					{

						# skip this target if no output has been defined
						next unless (exists $classpaths->{$target});

						# assign the output path
						$outpath = $classpaths->{$target};

						# break if we have a valid one
						last if defined $outpath;

					}

					# break if we have a valid one
					last if defined $outpath;

				}
				# EO unless outpath

				# assert that we have found a valid output file
				die 'output path invalid for head include' unless $outpath;

				# get the include type wheter include is defered or not
				my $inctype = lc $defer eq 'true' ? $type . 'defer' : $type;

				# add the fingerprint to the include path
				# this include always uses query string technique
				my $incpath = fingerprint($config, 'live', $outpath);

				# remove hash tag and query string for URI
				my $suffix = $incpath =~ s/([\;\?\#].*?)$// ? $1 : '';

				# create the absolute web include path
				$incpath = exportURI($outpath, undef, 1) . $suffix;

				# generate and add the include by using sprintf and the given template
				push(@includes, sprintf $tmpl->{$doctype}->{$inctype}, $incpath, $id, $config->{'jsdeferer'});

			}

			# otherwise we include the text node
			else
			{

				# easy but not yet implemented
				die "unsupported input configuration for headinc";

			}

		}
		# EO each input

		# create path to store this generated output
		my $output_path = check_path $output->{'path'};

		# create the include code to be written
		my $output_code = join("\n", @includes) . "\n";

		# write the include code now (atomic operation)
		writefile($output_path, \ $output_code, $atomic);

		# give a success message to the console
		print " created <", $output->{'path'}, ">\n";

	}
	# EO each output

}
# EO sub headerIncludes

###################################################################################################

1;