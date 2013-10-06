###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
###################################################################################################
package RTP::Webmerge::Merge;
###################################################################################################

use Carp;
use strict;
use warnings;

###################################################################################################

# define our version string
BEGIN { $RTP::Webmerge::Merge::VERSION = "0.70" }

# load exporter and inherit from it
BEGIN { use Exporter qw(); our @ISA = qw(Exporter) }

# define our functions to be exported
BEGIN { our @EXPORT = qw(merger); }

# define our functions to be exported
BEGIN { our @EXPORT_OK = qw (
	merge %reader %writer %importer %exporter
	%joiner %includer %prefixer %processor %suffixer
); }

###################################################################################################

# load local modules
use RTP::Webmerge qw(callProcessor);

# load our local modules
use RTP::Webmerge::IO;
use RTP::Webmerge::Path;
use RTP::Webmerge::Fingerprint;

###################################################################################################
# implement atomic operations
###################################################################################################

# module for atomic ops
use RTP::IO::AtomicFile;

# use core mdoules for path handling
use File::Basename qw(dirname);

# override core glob (case insensitive)
use File::Glob qw(:globally :nocase bsd_glob);

# import global webroot variable
use RTP::Webmerge::Path qw($webroot exportURI);

###################################################################################################

# load flags for file functions
use Fcntl qw(O_RDONLY LOCK_EX);

###################################################################################################

sub data { ${$_->{'data'}} };

###################################################################################################

use RTP::Webmerge::IO::JS;
use RTP::Webmerge::IO::CSS;

use RTP::Webmerge::Merge::JS;
use RTP::Webmerge::Merge::CSS;

###################################################################################################

# load minifier libraries and define subroutines
# maybe make these dependencies dynamic as they are
# normally only used as backup if the default methods fail

use RTP::Webmerge::Merge::Include;

###################################################################################################

# define various handlers for all the different actions
our (%reader, %writer, %importer, %exporter);

# define joiner for mutliple block parts
# processors for prepend, input and append
our (%joiner, %includer, %prefixer, %processor, %suffixer);

###################################################################################################

# write merged data to disk
# also create checksums etc.
# ***********************************************************************************************
sub writer
{

	# get input variables
	my ($type, $config, $output, $data, $collection) = @_;

	# get needed paths from object
	my $output_path = $output->{'outputpath'};
	my $checksum_path = $output->{'checksumpath'};

	# call processors (will return if nothing is set)
	callProcessor($output->{'process'}, $data, $config, $output);

	# assertion if the paths have been defined
	die "no output path given to write merged file" unless $output_path;
	die "no crc output path given to write merged file" unless $checksum_path;

	# join all input crcs and list all crcs
	my $crc_joined = ''; my $crc_listning = '';

	# create md5sum for each item of each kind
	foreach my $kind (sort keys %{$collection})
	{
		# process all items for this kind of input
		foreach my $item (@{$collection->{$kind}})
		{
			# create the md5 sum for this item (only do this once for each path)
			# $item->{'md5sum'} = md5sum($item->{'data'}) unless ($item->{'md5sum'});
			# create a relative path from the current checksum file
			my $rel_path = exportURI($item->{'local_path'}, dirname($checksum_path));
			# append checksum for every input file to be appended to our crc file
			$crc_listning .= join(': ', $rel_path, $item->{'md5sum'}) . "\n";
			# concatenate md5sums of all items
			$crc_joined .= $item->{'md5sum'};
		}
	}

	# write the real output file ...
	$exporter{$type}->($output_path, $data, $config)
		or die "could not export <$output_path>: $!";

	# calculate md5sum of joined md5sums
	my $md5_joined = md5sum(\ $crc_joined);

	# append the crc of all joined checksums
	${$data} .= "\n/* crc: " . $md5_joined . " */\n" if $config->{'crc-comment'};

	# now calculate the output md5sum
	my $crc = md5sum($data) . "\n";

	# add checksum for joined input file checksums
	$crc .= "\n" . $md5_joined . "\n";

	# add list of crcs of all sources
	$crc .= $crc_listning;

	# write the real output file ...
	my $rv = $writer{$type}->($output_path, $data, $config)
		or die "could not write <$output_path>: $!";

	# maybe we do not want to write a checksum
	return $rv unless $config->{'crc-file'};

	# ... and then write the md5 checksum file
	return $rv && writefile($checksum_path, \ $crc, $config->{'atomic'}, 1)
		or die "could not write <$checksum_path>: $!";

}
# EO sub mergeOutput

###################################################################################################

# collect all files
# return result hash
# ***********************************************************************************************
sub collect
{

	# get input variables
	my ($config, $merge, $type) = @_;

	# init data collection
	my %data =
	(
		'prefix' => [], # prepend text unaltered
		'prepend' => [], # prepend but dont minify
		'input' => [], # main input to be minified
		'append' => [], # append but dont minify
		'suffix' => [], # append text unaltered
	);

	# process all kind of input methods
	foreach my $kind (sort keys %data)
	{

		# make sure that option is an array
		if(ref $merge->{$kind} eq 'HASH')
		{ $merge->{$kind} = [$merge->{$kind}]; }

		# check if the merged file has been set to load deferred
		# my $deferred = $merge->{'defer'} && lc $merge->{'defer'} eq 'true';

		# process all items for this merge kind
		foreach my $item (@{$merge->{$kind} || []})
		{

			# maybe get input from a script
			# the script output should be static
			if (ref $item && $item->{'script'} && $item->{'path'})
			{

				# create absolute path to store the script output
				my $path = check_path $item->{'path'};

				# create absolute path to execute the script
				my $script = check_path $item->{'script'};

				# shebang should be given by configuration
				# otherwise the script must have execute permission
				my $shebang = $item->{'shebang'} ? $item->{'shebang'} . ' ' : '';

				# open the file to put the script output into
				# this is needed so we can include the file in dev mode
				open my $fh_out, ">", $path or die 'could not open generator output - ' . $path;

				# execute the script and open the stdout for us
				open my $fh_in, "-|", $shebang . $script or die 'could not execute generator script - ' . $script;

				# always read/write in bin mode
				binmode $fh_in; binmode $fh_out;

				# read script output and write to output file
				while(defined(my $line = <$fh_in>)) { print $fh_out $line; }

			}
			# EO if script && path

			# input from path
			elsif (ref $item && $item->{'path'})
			{

				# resolve the path via glob (allow filename expansion)
				foreach my $local_path (bsd_glob(check_path $item->{'path'}))
				{

					# create absolute path from the web root
					my $web_path = exportURI $local_path;

					# readfile will return a string reference (pointer to the file content)
					my $data = $reader{$type}->($local_path, $config) or die "could not read <$local_path>: $!";

					# get the md5sum of the unaltered data (otherwise crc may not be correct)
					my $md5sum = md5sum(my $org = \ "${$data}") or die "could not get md5sum from data: $!";

					# importer can alter the data after the checksum has been taken
					$importer{$type}->($data, $local_path, $config) or die "could not import <$local_path>: $!";

					# call processors (will return if nothing is set)
					callProcessor($item->{'process'}, $data, $config, $item);

					# put all informations
					# on to our data array
					push(@{$data{$kind}}, {
						'org' => $org,
						'data' => $data,
						'item' => $item,
						'md5sum' => $md5sum,
						'web_path' => $web_path,
						'local_path' => $local_path,
						# 'deferred' => $deferred,
					});

				}
				# EO foreach path

			}
			# EO if path

			# include webmerge id
			# use other merge as input
			elsif (ref $item && $item->{'id'})
			{

				# get the id to include
				my $id = $item->{'id'};

				# check if referenced id has been merged
				unless (exists $config->{'merged'}->{$id})
				{ die "id <$id> has not been merged, fatal\n"; }

				# put all informations on to our data array
				# we just copy the entry from previous merge
				push(@{$data{$kind}}, $config->{'merged'}->{$id});

			}
			# EO if id

			elsif (defined $item)
			{

				# get the md5sum of the unaltered data (otherwise crc may not be correct)
				my $md5sum = md5sum(\ $item) or die "could not get md5sum for item: $!";
				push(@{$data{$kind}}, { 'data' => \ $item, 'md5sum' => $md5sum });

			}

			# we have no valid options
			else
			{

				# die with error message
				die "no path or id found for input";

			}
			# EO if not path

		}
		# EO foreach item

	}
	# EO foreach kind

	# result hash
	return \%data;

}
# EO sub collect

###################################################################################################
###################################################################################################

###################################################################################################
# this function does all the joining, minifying and compiling
# it is very generic and both js and css work as plugins for it
###################################################################################################

# main merge function
# ***********************************************************************************************
my $merger = sub
{

	# get input variables
	my ($config, $type, $merge) = @_;

	# test if the merge has been disabled
	return if exists $merge->{'disabled'} &&
		lc $merge->{'disabled'} eq 'true';

	# change directory (restore previous state after this block)
	my $dir = RTP::Webmerge::Path->chdir($merge->{'chdir'});

	# collect all data (files) for this merge
	my $collection = collect($config, $merge, $type);

	# make sure that option is an array
	if(ref $merge->{'output'} eq 'HASH')
	{ $merge->{'output'} = [$merge->{'output'}]; }

	# process all files to be written for this merge
	foreach my $output (@{$merge->{'output'} || []})
	{

		# make webroot local to this block and reset if configured
		local $webroot = check_path $output->{'webroot'} if $output->{'webroot'};

		# create path to store this generated output
		my $output_path = check_path $output->{'path'};

		# create path to store checksum of this output
		my $checksum_path = join('.', $output_path, 'md5');

		# add these paths to our object
		$output->{'outputpath'} = $output_path;
		$output->{'checksumpath'} = $checksum_path;

		# get path to be resolved
		my $web_path = exportURI $output_path;

		# get output target of block
		my $target = $output->{'target'};

		# local function to collect files to process
		# will filter out stuff according to given target
		# usefull for including stuff only in dev or live
		my $collect = sub
		{
			grep
			{
				# item has no target - include
				unless ($_->{'item'}->{'target'}) { 1; }
				# target is not live, it's a real context
				elsif ($_->{'item'}->{'target'} ne 'live')
				{ $target eq $_->{'item'}->{'target'}; }
				# target is live - include if not dev
				else { $target ne 'dev'; }
			}
			@{$collection->{$_[0]} || []};
		};

		# get different joiner for js or css
		my $joiner = $joiner{$type} || "\n";

		# create a header for joined content (do that for all)
		my @input = (sprintf($config->{'headtmpl'}, $target));
		my @prefix = (sprintf($config->{'headtmpl'}, $target));

		# add everything as data/text unaltered (just include data)
		push @input, join($joiner, grep { $_ } map data, $collect->('prefix'));
		push @input, join($joiner, grep { $_ } map data, $collect->('prepend'));
		push @input, join($joiner, grep { $_ } map data, $collect->('input'));
		push @input, join($joiner, grep { $_ } map data, $collect->('append'));
		push @input, join($joiner, grep { $_ } map data, $collect->('suffix'));

		# create final joined code
		my $input = join($joiner, grep { $_ } @input);

		# store joined output by id for later use
		# this id may be referenced by other inputs
		$config->{'merged'}->{$merge->{'id'}} =
		{
			'data' => \ $input,
			'web_path' => $web_path,
			'local_path' => $output_path,
			# 'path' => $output->{'path'},
		};

		# delcare additional input
		# use them for positioning
		# maybe add a prio to input
		my (@process, @suffix);

		# should we pretty print the compiled code
		$config->{'pretty'} = $output->{'pretty'};

		# assertion that we have a output target of block
		die "no target given for merge block" unless $target;

		# get processor variables for pre and post process
		my $includer = $includer{$type}->{$target} if $includer{$type};
		my $prefixer = $prefixer{$type}->{$target} if $prefixer{$type};
		my $processor = $processor{$type}->{$target} if $processor{$type};
		my $suffixer = $suffixer{$type}->{$target} if $suffixer{$type};

		# assertion that we have a includer for the given type and target
		die sprintf "no includer for %s/%s\n", $type, $target unless $includer;
		# die sprintf "no processor for %s/%s\n", $type, $target unless $processor;

		# is feature enabled
		if ($config->{$target})
		{

			# print a message to the console about the current status
			printf "creating %s %s <%s>\n", $type, $target, $output->{'path'};

			# add everything as data/text unaltered
			push @prefix, map data, $collect->('prefix');
			push @process, map &{$includer}, $collect->('prepend');
			push @process, map &{$includer}, $collect->('input');
			push @process, map &{$includer}, $collect->('append');
			push @suffix, map data, $collect->('suffix');

			# create code fragment to process
			my $prefix = join($joiner, grep { $_ } @prefix);
			my $process = join($joiner, grep { $_ } @process);
			my $suffix = join($joiner, grep { $_ } @suffix);

			# call processors (will return immediately if nothing is set)
			callProcessor($output->{'preprocess'}, \ $prefix, $config, $output);
			callProcessor($output->{'preprocess'}, \ $process, $config, $output);
			callProcessor($output->{'preprocess'}, \ $suffix, $config, $output);

			# call target specific processor if available
			$process = $processor->($process, $config) if $processor;

			# call target prefix/suffix processor if available
			$prefix = $prefixer->(\ $prefix, $merge, $config) if $prefixer;
			$suffix = $suffixer->(\ $suffix, $merge, $config) if $suffixer;

			# create final joined code (prefix and suffix are unchanged)
			my $code = join($joiner, grep { $_ } ($prefix, $process, $suffix));

			# commit and write out the completely merged block
			my $rv = writer($type, $config, $output, \ $code, $collection);

			# print a message to the console about the current status
			printf " created %s %s <%s> -> %s\n", $type, $target, $output->{'path'}, $rv ? 'ok' : 'error';

		}
		# EO if target is enabled

	}
	# EO each output

};
# EO sub $merge

###################################################################################################

# merge all blocks in config
# ***********************************************************************************************
sub merger
{

	# get input variables
	my ($config, $block) = @_;

	# should we commit filesystem changes?
	my $commit = $block->{'commit'} || 0;

	# change directory (restore previous state after this block)
	my $dir = RTP::Webmerge::Path->chdir($block->{'chdir'});

	# commit all changes to the filesystem if configured
	$config->{'atomic'} = {} if $commit =~ m/^\s*(?:bo|be)/i;

	# do not process if disabled attribute is given and set to true
	unless ($block->{'disabled'} && lc $block->{'disabled'} eq 'true')
	{
		# process each type (js/css)
		foreach my $type ('css', 'js')
		{
			# process each merge block for type
			foreach my $merge (@{$block->{$type} || []})
			{
				# call sub to merge a single block
				$merger->($config, $type, $merge);
			}
		}
	}

	# commit all changes to the filesystem if configured
	$config->{'atomic'} = {} if $commit =~ m/^\s*(?:bo|af)/i;

}
# EO sub merge

###################################################################################################
###################################################################################################
1;