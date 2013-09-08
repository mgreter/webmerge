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
BEGIN { our @EXPORT = qw(merge); }

# define our functions to be exported
BEGIN { our @EXPORT_OK = qw(mergeEntry); }

###################################################################################################

# load local modules
use RTP::Webmerge qw(callProcessor);

# load our local modules
use RTP::Webmerge::IO;
use RTP::Webmerge::Path;
use RTP::Webmerge::Fingerprint;
use RTP::Webmerge::Compile::JS;
use RTP::Webmerge::Compile::CSS;

# import global webroot variable
use RTP::Webmerge::Path qw($webroot exportURI);

###################################################################################################
# implement atomic operations
###################################################################################################

# module for atomic ops
use RTP::IO::AtomicFile;

# store atomic file handles
# commit/revert all at the end
# remember temp files to remove
# my $atomic = {}, my $temp = [];

# use core mdoules for path handling
use File::Basename qw(dirname);
use File::Spec::Functions qw(abs2rel rel2abs);

# override core glob (case insensitive)
use File::Glob qw(:globally :nocase bsd_glob);

###################################################################################################

# load flags for file functions
use Fcntl qw(O_RDONLY LOCK_EX);

###################################################################################################

# default template for the js includer function (can be adjusted for defered loading)
my $fn_include_js = 'function (src)
{
	if (typeof webmerge != "undefined" && webmerge.webroot)
	{ src = [webmerge.webroot, src].join("/"); }
	document.write(\'<script src="\' + src + \'"></script>\');
}';

###################################################################################################

use RTP::Webmerge::IO::JS;
use RTP::Webmerge::IO::CSS;

my %reader = (
	'js' => \&readJS,
	'css' => \&readCSS
);

my %importer = (
	'js' => \&importJS,
	'css' => \&importCSS
);

my %exporter = (
	'js' => \&exportJS,
	'css' => \&exportCSS
);

my %writer = (
	'js' => \&writeJS,
	'css' => \&writeCSS
);

###################################################################################################

# write merged data to disk
# also create checksums etc.
sub mergeWrite
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
			my $rel_path = abs2rel($item->{'local_path'}, dirname($checksum_path));
			# normalize windows paths and other anomalies
			$rel_path =~ s/\\+/\//g; $rel_path =~ s/\/+/\//g;
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
	my $md5_joined = md5sum(\$crc_joined);

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
	return $rv && writefile($checksum_path, \$crc, $config->{'atomic'}, 1)
		or die "could not write <$checksum_path>: $!";

}
# EO sub mergeOutput

###################################################################################################

# collect all files
# return result hash
sub mergeCollect
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
		my $deferred = $merge->{'defer'} && lc $merge->{'defer'} eq 'true';

		# process all items for this merge kind
		foreach my $item (@{$merge->{$kind} || []})
		{

			# maybe get input from a script
			# the script output should be static
			if (ref $item && $item->{'script'} && $item->{'path'})
			{

				# create absolute path to store the script output
				my $path = resolve_path $item->{'path'};

				# create absolute path to execute the script
				my $script = resolve_path $item->{'script'};

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
				foreach my $local_path (bsd_glob(resolve_path $item->{'path'}))
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
						# 'path' => $path,
						'item' => $item,
						'md5sum' => $md5sum,
						'deferred' => $deferred,
						'web_path' => $web_path,
						'local_path' => $local_path,
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
				my $md5sum = md5sum(\$item) or die "could not get md5sum for item: $!";
				push(@{$data{$kind}}, { 'data' => \$item, 'md5sum' => $md5sum });

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

# called via array map
sub includeCSS
{

	# get passed variables
	my ($config) = @_;

	# magick map variable
	my $data = $_;

	# define the template for the script includes (don't care about doctype versions, dev only)
	my $css_include_tmpl = '@import url(\'%s\');' . "\n";

	# get a unique path with added fingerprint (query or directory)
	my $path = fingerprint($config, 'dev', $data->{'local_path'}, $data->{'org'});

	# return the script include string
	return sprintf($css_include_tmpl, $path);

}
# EO sub includeCSS

###################################################################################################


###################################################################################################

# called via array map
sub includeJS
{

	# get passed variables
	my ($config) = @_;

	# magick map variable
	my $data = $_;

	# define the template for the script includes
	my $js_include_tmpl = 'includeJS(\'%s\');' . "\n";

	# get a unique path with added fingerprint (query or directory)
	my $path = fingerprint($config, 'dev', $data->{'local_path'}, $data->{'org'});

	# return the script include string
	return sprintf($js_include_tmpl, $path);

}
# EO includeJS

###################################################################################################

use CSS::Minifier qw();
sub minifyCSS { &CSS::Minifier::minify }

use JavaScript::Minifier qw();
sub minifyJS { &JavaScript::Minifier::minify }

###################################################################################################

# define various handlers for all the different actions
my %minifier = ( 'js' => \&minifyJS, 'css' => \&minifyCSS, );
my %compiler = ( 'js' => \&compileJS, 'css' => \&compileCSS );
my %includer = ( 'js' => \&includeJS, 'css' => \&includeCSS );


###################################################################################################
# this function does all the joining, minifying and compiling
# it is very generic and both js and css work as plugins for it
###################################################################################################

# main merge function
sub mergeEntry
{

	# get input variables
	my ($config, $merge, $type) = @_;

	# test if the merge has been disabled
	return if exists $merge->{'disabled'} &&
		lc $merge->{'disabled'} eq 'true';

	# change directory (restore previous state after this block)
	my $dir = RTP::Webmerge::Path->chdir($merge->{'chdir'});

	# collect all data (files) for this merge
	my $collection = mergeCollect($config, $merge, $type);

	# make sure that option is an array
	if(ref $merge->{'output'} eq 'HASH')
	{ $merge->{'output'} = [$merge->{'output'}]; }

	# process all files to be written for this merge
	foreach my $output (@{$merge->{'output'} || []})
	{

		# make webroot local to this block and reset if configured
		local $webroot = resolve_path $output->{'webroot'} if $output->{'webroot'};

		# create path to store this generated output
		my $output_path = resolve_path $output->{'path'};

		# create path to store checksum of this output
		my $checksum_path = join('.', $output_path, 'md5');

		# add these paths to our object
		$output->{'outputpath'} = $output_path;
		$output->{'checksumpath'} = $checksum_path;

		# get path to be resolved
		my $web_path = exportURI $output_path;

		# create a header for joined content (do that for all)
		my $joined = sprintf($config->{'headtmpl'}, 'join');

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
				{ $output->{'target'} eq $_->{'item'}->{'target'}; }
				# target is live - include if not dev
				else { $output->{'target'} ne 'dev'; }
			}
			@{$collection->{$_[0]} || []};
		};

		# add everything as data/text unaltered
		$joined .= join("\n", map { ${$_->{'data'}} } $collect->('prefix'));
		$joined .= join("\n", map { ${$_->{'data'}} } $collect->('prepend'));
		$joined .= join("\n", map { ${$_->{'data'}} } $collect->('input'));
		$joined .= join("\n", map { ${$_->{'data'}} } $collect->('append'));
		$joined .= join("\n", map { ${$_->{'data'}} } $collect->('suffix'));

		# store joined output by id for later use
		# this id may be referenced by other inputs
		$config->{'merged'}->{$merge->{'id'}} =
		{
			# 'path' => $output->{'path'},
			'data' => \ $joined,
			'web_path' => $web_path,
			'local_path' => $output_path,
		};


		# create joined output for live
		if ($config->{'join'} && $output->{'target'} eq 'join')
		{

			printf "creating %s joined <%s>\n", $type, $output->{'path'};
			callProcessor($output->{'preprocess'}, \$joined, $config, $output);
			my $rv = mergeWrite($type, $config, $output, \$joined, $collection);
			printf " created %s joined <%s> - %s\n", $type, $output->{'path'}, $rv ? 'ok' : 'error';

		}

		# create output for development
		if ($config->{'dev'} && $output->{'target'} eq 'dev')
		{

			printf "creating %s dev <%s>\n", $type, $output->{'path'};

			# create a header for this output file
			my $code = sprintf($config->{'headtmpl'}, 'dev');

			if ($type eq 'js')
			{
				# check if the merged file has been set to load deferred
				my $deferred = $merge->{'defer'} && lc $merge->{'defer'} eq 'true';
				# assertion that we have at least one defered include, otherwise
				# it may never fire the ready event (happens with head.js)
				$deferred = 0 if scalar $collect->('input') == 0;
				# insert the javascript loader function above all other includes
				$code .= "\n" . 'var includeJS = ' . ($deferred ? 'head.js' : $fn_include_js) . ";\n\n";
			}

			# prepend the data/text unaltered
			$code .= join("\n", map { ${$_->{'data'}} } $collect->('prefix'));

			# append the data/text unaltered
			$code .= join("\n", map { &{$includer{$type}} } $collect->('prepend'));
			$code .= join("\n", map { &{$includer{$type}} } $collect->('input'));
			$code .= join("\n", map { &{$includer{$type}} } $collect->('append'));

			# append the data/text unaltered
			$code .= join("\n", map { ${$_->{'data'}} } $collect->('suffix'));

			my $rv = mergeWrite($type, $config, $output, \$code, $collection);
			printf " created %s dev <%s> - %s\n", $type, $output->{'path'}, $rv ? 'ok' : 'error';

		}

		# create minified output for live
		elsif ($config->{'minify'} && $output->{'target'} eq 'minify')
		{

			my $joiner = $type eq 'js' ? ";\n" : "";

			# get content to be minified
			my $minify = join($joiner, map { ${$_->{'data'}} } $collect->('input'));

			# call processors (will return if nothing is set)
			callProcessor($output->{'preprocess'}, \$minify, $config, $output);

			printf "creating %s minified <%s>\n", $type, $output->{'path'};

			# create a header for this output file
			my $code = sprintf($config->{'headtmpl'}, 'minify');

			# add everything as data/text unaltered
			$code .= join($joiner, map { ${$_->{'data'}} } $collect->('prefix'));
			$code .= join($joiner, map { ${$_->{'data'}} } $collect->('prepend'));
			$code .= $minifier{$type}->(input => $minify);
			$code .= join($joiner, map { ${$_->{'data'}} } $collect->('append'));
			$code .= join($joiner, map { ${$_->{'data'}} } $collect->('suffix'));

			my $rv = mergeWrite($type, $config, $output, \$code, $collection);
			printf " created %s minified <%s> - %s\n", $type, $output->{'path'}, $rv ? 'ok' : 'error';

		}

		# create minified output for live
		elsif ($config->{'compile'} && $output->{'target'} eq 'compile')
		{

			my $joiner = $type eq 'js' ? ";\n" : "";

			printf "creating %s compiled <%s>\n", $type, $output->{'path'};

			# create a header for this output file
			my $code = sprintf($config->{'headtmpl'}, 'compile');

			# get the code to be compiled from already readed data
			# we will only compile the stuff registered as input items
			my $compile = join($joiner, map { ${$_->{'data'}} } $collect->('input'));

			# call processors (will return if nothing is set)
			callProcessor($output->{'preprocess'}, \$compile, $config, $output);

			# should we pretty print the compiled code
			$config->{'pretty'} = $output->{'pretty'};

			# add everything as data/text unaltered
			$code .= join($joiner, map { ${$_->{'data'}} } $collect->('prefix'));
			$code .= join($joiner, map { ${$_->{'data'}} } $collect->('prepend'));
			$code .= $compiler{$type}->($compile, $config);
			$code .= join($joiner, map { ${$_->{'data'}} } $collect->('append'));
			$code .= join($joiner, map { ${$_->{'data'}} } $collect->('suffix'));

			# write the final output file to the disk
			my $rv = mergeWrite($type, $config, $output, \$code, $collection);
			printf " created %s compiled <%s> - %s\n", $type, $output->{'path'}, $rv ? 'ok' : 'error';

		}

		# create minified output for live
		elsif ($config->{'license'} && $output->{'target'} eq 'license')
		{

			# map out the licenses from inputs
			my $licenses = join("\n", map
				{
					# remove everything but the very first comment (first line!)
					${$_->{'data'}} =~m /\A\s*(\/\*(?:\n|\r|.)+?\*\/)\s*(?:\n|\r|.)*\z/m
						# return map result or nothing
						? ( '/* license for ' . $_->{'web_path'} . ' */', $1, '' ) : ();
				}
				# map the input collections
				(
					$collect->('prepend'),
					$collect->('input'),
					$collect->('append')
				)
			);

			printf "creating %s license <%s>\n", $type, $output->{'path'};
			my $rv = mergeWrite($type, $config, $output, \$licenses, $collection);
			printf " created %s license <%s> - %s\n", $type, $output->{'path'}, $rv ? 'ok' : 'error';

		}

	}

}

###################################################################################################

# define merger functions
# not really needed but still keept
# as it will ensure a valid type
my %mergers =
(
	'js' => \&mergeEntry,
	'css' => \&mergeEntry,
);

###################################################################################################

sub merge
{

	# get input variables
	my ($config, $merges) = @_;

	# should we commit filesystem changes?
	my $commit = $merges->{'commit'} || 0;

	# change directory (restore previous state after this block)
	my $dir = RTP::Webmerge::Path->chdir($merges->{'chdir'});

	# commit all changes to the filesystem if configured
	$config->{'atomic'} = {} if $commit =~ m/^\s*(?:bo|be)/i;

	# do not process if disabled attribute is given and set to true
	unless ($merges->{'disabled'} && lc $merges->{'disabled'} eq 'true')
	{

		foreach my $merge (@{$merges->{'css'} || []})
		{ mergeEntry($config, $merge, 'css'); }

		foreach my $merge (@{$merges->{'js'} || []})
		{ mergeEntry($config, $merge, 'js'); }

	}

	# commit all changes to the filesystem if configured
	$config->{'atomic'} = {} if $commit =~ m/^\s*(?:bo|af)/i;

}

###################################################################################################
###################################################################################################
1;