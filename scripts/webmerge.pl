#!/usr/bin/perl
################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################

use Carp;
use strict;
use warnings;

################################################################################

# use FindBin to find the path to the script
# from here the config file for be relative
# this is not true if config path is absolute
use FindBin qw($Bin);

# insert our module directory to lib search directory
# we want to keep our modules local and not install global
BEGIN { unshift @INC, "$Bin/modules"; }

################################################################################

use RTP::Webmerge::Input;
use RTP::Webmerge::Input::CSS;

# load spriteset library
use OCBNET::Spritesets;

# load local modules
use RTP::Webmerge;
use RTP::Webmerge::IO;
use RTP::Webmerge::Path;
use RTP::Webmerge::Config;
use RTP::Webmerge::Finish;
use RTP::Webmerge::Prepare;
use RTP::Webmerge::Merge;
use RTP::Webmerge::HeadInc;
use RTP::Webmerge::Embedder;
use RTP::Webmerge::Optimize;
use RTP::Webmerge::Checksum;
use RTP::Webmerge::Watchdog;
use RTP::Webmerge::Webserver;

# load additional modules (no import)
use RTP::Webmerge::Compile::JS qw();
use RTP::Webmerge::Compile::CSS qw();
use RTP::Webmerge::Process::JS qw();
use RTP::Webmerge::Process::CSS qw();
use RTP::Webmerge::Process::CSS::SASS qw();

# load optimizer modules (no import)
use RTP::Webmerge::Optimize::TXT qw();
use RTP::Webmerge::Optimize::GIF qw();
use RTP::Webmerge::Optimize::JPG qw();
use RTP::Webmerge::Optimize::PNG qw();
use RTP::Webmerge::Optimize::MNG qw();
use RTP::Webmerge::Optimize::ZIP qw();
use RTP::Webmerge::Optimize::GZ qw();

################################################################################
# get the mother pid
################################################################################

my $pid = $$;

################################################################################
# warn strings (for sprintf)
################################################################################

my $warn_dis_step = "Disable step: %s\n";
my $warn_dis_dup = "Disable duplicate id: %s\n";

################################################################################
# declare and init configuration options
################################################################################

my $config = new RTP::Webmerge::Config();
my $default = new RTP::Webmerge::Config();

$default->apply({

	# where is you htdocs root directory
	# this is needed to create absolute urls
	# default is relative to the config file
	'webroot' => '{CONF}/..',

	# define a current working directory
	# you can adjust this also in the xml config
	# it's also possible to change it only for a block
	'directory' => '{WWW}',

	# default configuration file relative from our webroot
	# this is the main source for all other configuration options
	'configfile' => 'conf/webmerge.conf.xml',

	# header to prepend to all generated merge output files
	'headtmpl' => "/* autogenerated by webmerge (%s context) */\n",

	# doctype to render includes
	'doctype' => 'html5',

	# debug mode
	'debug' => 0,

	# generic blocks
	'action' => 1,
	# preapre blocks
	'prepare' => 1,
	# optimizer blocks
	'optimize' => 0,
	# optimize level
	'level' => 2,
	# merge blocks
	'merge' => 1,
	# finish blocks
	'finish' => 1,
	# specific merge blocks
	'js' => 1, 'css' => 1,
	# headinc blocks
	'headinc' => 0,
	# embedder blocks
	'embedder' => 0,
	# start watchdog
	'watchdog' => 0,

	# license stuff
	'license' => 1,
	# compile stuff
	'compile' => 1,
	# minify stuff
	'minify' => 1,
	# join stuff
	'join' => 1,
	# dev stuff
	'dev' => 1,

	# do end crc-check
	'crc-check' => 0,

	# various crc features
	'crc-file' => 1,
	'crc-comment' => 1,

	# referer for downloads
	'referer' => undef,

	# parallel jobs
	'jobs' => 2,

	# start webserver
	'webserver' => 0,

	# the order in which to prefer to include stuff
	'incorder' =>
	{
		'dev' => ['dev', 'join', 'minify', 'compile'],
		'live' => ['compile', 'minify', 'join', 'dev']
	}

});
# EO config

################################################################################
# get config options from the command line
################################################################################

# load commandline option fetcher
use Getopt::Long qw(GetOptions);

# load help message generator
use Pod::Usage qw(pod2usage);

# command line only options
# cannot be overriden by config
my ($man, $help, $opts) = (0, 0, 0);

# create the options array
my @opts = (

	# the main config file (only from cmd line)
	'configfile|f=s' => \$default->{'configfile'},

	# enable/disable debug mode
	'debug|dbg!' => \$default->{'cmd_debug'},

	# maybe change these in the config file
	'webroot=s' => \$default->{'cmd_webroot'},
	'doctype|d=s' => \$default->{'cmd_doctype'},

	# enable/disable base operations
	'action!' => \$default->{'cmd_action'},
	'finish|p!' => \$default->{'cmd_finish'},
	'prepare|p!' => \$default->{'cmd_prepare'},
	'optimize|o!' => \$default->{'cmd_optimize'},
	'level|l=o' => \$default->{'cmd_level'},
	'merge|m!' => \$default->{'cmd_merge'},
	'css!' => \$default->{'cmd_css'},
	'js!' => \$default->{'cmd_js'},
	'headinc|i!' => \$default->{'cmd_headinc'},
	'embedder|e!' => \$default->{'cmd_embedder'},
	'watchdog|w!' => \$default->{'cmd_watchdog'},
	'crc-check|c!' => \$default->{'cmd_crc-check'},

	# various crc features
	'crc-file!' => \$default->{'cmd_crc-file'},
	'crc-comment!' => \$default->{'cmd_crc-comment'},

	# enable/disable stage operations
	'license!' => \$default->{'cmd_license'},
	'compile!' => \$default->{'cmd_compile'},
	'minify!' => \$default->{'cmd_minify'},
	'join!' => \$default->{'cmd_join'},
	'dev!' => \$default->{'cmd_dev'},

	# referer http header for downloads
	'referer|r=s' => \$default->{'cmd_referer'},

	# header tempalte to prepend to files
	'headtmpl|h=s' => \$default->{'cmd_headtmpl'},

	# number of commands to run simultaneously
	'jobs|j=i' => \$default->{'cmd_jobs'},

	# usage/help options
	'help|?' => \$help,
	'opts' => \$opts,
	'man' => \$man,

	# init config will prepare additional configuration
	# returns additional options to be fetched from cmd
	initConfig($default)

);
# EO @options

# get options from commandline
GetOptions(@opts) or pod2usage(2);

################################################################################

# uncomment if you want to see all options
if ($opts)
{
	print join("\n", map {
		s/(?:\!|\=.*?)$//;
		join(', ', map { '-' . $_ } split /\|/);
	} sort keys %{ { @opts } });
}

################################################################################

# show help page
pod2usage(1) if $help;

# show man page if requested by command line
pod2usage(-exitval => 0, -verbose => 2) if $man;

################################################################################
# read the configuration file
################################################################################

# load xml module
use XML::Simple;

# search for the config file
my $configfile = 'webmerge.conf.xml';

# register extension path within our path modules for later use
$RTP::Webmerge::Path::extroot = check_path(join('/', $Bin, '..'));

# helper sub to check file for existence
sub checkFile { defined $_[0] && -e $_[0] ? $_[0] : undef; }

# check if
unless
(
	# no configfile is defined
	defined $default->{'configfile'}
	# or if empty string was given
	&& $default->{'configfile'} ne ''
)
{
	die "Usage: webmerge.pl -f config.xml\n";
}

# check if configfile is given as relative path
unless ( $default->{'configfile'} =~ m/^\// )
{
	# search for the config file
	$default->{'configfile'} =
		# first try from current directory
		checkFile(check_path($default->{'configfile'}));
}

# abort if the configuration file was not found
unless (
	defined $default->{'configfile'}
	&& $default->{'configfile'} ne ''
)
{
	die "please specify a config file\n";
}

# create the config path from config file ...
$default->{'configpath'} = $default->{'configfile'};
# ... and remove the trailing filename
$default->{'configpath'} =~ s/\/[^\/]+$//;

# register path within our path modules for later use
$RTP::Webmerge::Path::confroot = $default->{'configpath'};


################################################################################
# xml helper function for the include directive
################################################################################

# returns xml fragment as string
# read the given file and do includes
sub get_xml
{

	# get the filenname
	my ($file, $import) = @_;

	# resolve the file path
	$file = check_path($file);

	# read the complete xml file
	my $data = readfile($file) || return;

	# init header and footer strings
	my $header = "\n"; my $footer = "\n";

	# custom config if imported
	# includes are just inserted
	if ($import)
	{
		$header .= "\n<block>\n";
		$header .= "  <config>\n";
		$header .= sprintf "    <configfile>%s</configfile>\n", $file;
		$header .= "  </config>\n";
		$footer .= "\n</block>\n";
	}
	# EO if imported

	# replace include tags with the real content of the file to be included
	${$data} =~ s/<include\s+src=(?:\'([^\']+)\'|\"([^\"]+)\"|(\w+))\s*\/?>/get_xml($1||$2||$3)/egm;
	${$data} =~ s/<import\s+src=(?:\'([^\']+)\'|\"([^\"]+)\"|(\w+))\s*\/?>/get_xml($1||$2||$3, 1)/egm;

	# parse and create the xml document
	my $xml = XMLin(${$data}, 'ForceArray' => 1, 'KeyAttr' => []);

	# return the xml fragment
	return $header . XMLout($xml, 'KeyAttr' => [], 'RootName' => undef) . $footer;

}
# EO get_xml


# returns xml document as object
# read the given file and do includes
sub read_xml
{

	# get the filenname
	my ($file) = @_;

	# resolve the file path
	$file = check_path($file);

	# read the complete xml file
	my $data = readfile($file) || return;

	# die if config file is empty (without line number)
	die "config file is empty:\n<$file>\n" if ${$data} eq "";

	# replace include tags with the real content of the file to be included
	${$data} =~ s/<include\s+src=(?:\'([^\']+)\'|\"([^\"]+)\"|(\w+))\s*\/?>/get_xml($1||$2||$3)/egm;
	${$data} =~ s/<import\s+src=(?:\'([^\']+)\'|\"([^\"]+)\"|(\w+))\s*\/?>/get_xml($1||$2||$3, 1)/egm;

	# parse and create the xml document
	my $xml = XMLin(${$data}, 'ForceArray' => 1, 'KeyAttr' => []);

	# return XML doc
	return $xml;

}
# EO read_xml


################################################################################
# read and parse the xml configuration
################################################################################

# parse the xml configuration file
my $xml = read_xml($default->{'configfile'})
	or die 'error while reading config file, aborting';


################################################################################
# apply the configuration from the xml to the config hash
################################################################################

# apply the xml configuration and finalize
$config->apply($default)->xml($xml)->finalize;


################################################################################
# change die handler to confess if in debug mode
################################################################################

local $SIG{__DIE__} = \&Carp::confess if $config->{'debug'};


################################################################################
# setup teardown handlers before main program
################################################################################

# exit on ctrl+c, this make sure
# that the end handler is called
local $SIG{'INT'} = sub { exit; };

# this will always be called
# when the main script exists
END
{
	# only mother takes care of this
	if ($pid == $$)
	{
		# delete all temporarily created files
		foreach (@{$config->{'temps'} || []}) { unlink $_ if -e $_; }
		# delete all atomic temporarily files (struct: [data, blessed])
		foreach (values %{$config->{'atomic'} || {}}) { $_->[1]->delete; }
	}
	# EO if mother
}


################################################################################
# check the configuration before goind to execute main program
################################################################################

# check config will assert the configuration
# call after you have read command line options
checkConfig($config) or die "config check failed";


################################################################################
# Experimental webserver
################################################################################

# merge if not starting watchdog
webserver $config if $config->{'webserver'};


################################################################################
# remove xml for not mentioned steps
################################################################################

# create regular expression to match steps
my $re_argv = join('|', @ARGV);


################################################################################
# setup config for the complete tree
# store a copy of config on each block
# also collect all ids in a lookup object
################################################################################

# setup blocks
sub setupBlocks
{

	# get input variables
	# independent for each type
	my ($config, $xml, $type) = @_;

	# create lexical config scope
	my $scope = $config->scope($xml);

	# remember the current config
	$xml->{'_config'} = $config;
	$xml->{'_conf'} = { %{$scope} };

	# have input arguments and a step name
	if ($xml->{'step'} && scalar(@ARGV))
	{
		# step must be named within arguments
		unless ($xml->{'step'} =~ m/^(?:$re_argv)$/)
		{
			# give a debug message to console
			warn sprintf $warn_dis_step, $xml->{'step'} if $config->{'debug'};
			# disable this block completely
			$xml->{'disabled'} = 'true';
		}
	}
	# EO if step and arguments

	# have input arguments and a step name
	if ($xml->{'id'} && $config->{'ids'}->{$type}->{$xml->{'id'}})
	{
		# check if current block is not registered one
		if ($config->{'ids'}->{$type}->{$xml->{'id'}} ne $xml)
		{
			# give a debug message to console
			warn sprintf $warn_dis_dup, $xml->{'id'} if $config->{'debug'};
			# disable this block completely
			$xml->{'disabled'} = 'true';
		}
	}
	# EO if id and already known

	# get nodes to process
	foreach my $item
	(
		([ 'js', $xml->{'js'} || [] ]),
		([ 'css', $xml->{'css'} || [] ]),
		([ 'block', $xml->{'block'} || [] ]),
		([ 'merge', $xml->{'merge'} || [] ]),
		([ 'finish', $xml->{'finish'} || [] ]),
		([ 'prepare', $xml->{'prepare'} || [] ]),
		([ 'headinc', $xml->{'headinc'} || [] ]),
		([ 'feature', $xml->{'feature'} || [] ]),
		([ 'embedder', $xml->{'embedder'} || [] ]),
		([ 'optimize', $xml->{'optimize'} || [] ]),
	)
	{

		# get variables from item
		my ($type, $nodes) = @{$item};

		# loop from behind so we can splice items out
		for (my $i = $#{$nodes}; $i != -1; -- $i)
		{
			# setup blocks recursively
			setupBlocks($config, $nodes->[$i], $type);
		}

	}
	# EO each item

}
# EO sub setupBlocks

################################################################################
# setup webmerge actions
################################################################################

# action handlers
my %actions = (
	'finish' => \&finish,
	'prepare' => \&prepare,
	'headinc' => \&headinc,
	'embedder' => \&embedder,
	'optimize' => \&optimizer
);

# additional merger types
foreach my $type (keys %merger)
{ $actions{$type} = $merger{$type}; }


################################################################################
# process an xml block
################################################################################

# call initial process
# recursive on chdir blocks
sub process
{

	# get input arguments
	my ($config, $xml, $action) = @_;

	# create lexical config scope
	my $scope = $config->scope($xml);

	# should we commit filesystem changes?
	my $commit = $xml->{'commit'} || 0;

	# commit all changes to the filesystem if configured
	$config->{'atomic'} = {} if $commit =~ m/^\s*(?:bo|be)/i;

	# do not process if disabled attribute is given and set to true
	unless ($xml->{'disabled'} && lc $xml->{'disabled'} eq 'true')
	{

		# pass on to recursively process blocks
		foreach my $block ( @{$xml->{'block'} || []} )
		{ &process($config, $block, $action); }

		# check if enabled
		if (
			$xml->{$action} &&
			$config->{$action} &&
			$config->{'action'}
		)
		{
			# check for merge config option
			if ($config->{'merge'} || !$merger{$action})
			{
				# process each given block
				foreach my $block ( @{$xml->{$action}} )
				{
					# create lexical config scope
					my $scoped = $config->scope($block);

					# print some debug information for merger
					if ($config->{'debug'} && $merger{$action})
					{
						# print delimiter line
						print '=' x 78, "\n";
						# print info about the block to be processed
						print sprintf "processing block %s (%s)\n",
						      $block->{'id'} || '', $action;
						# print delimiter line
						print '-' x 78, "\n";
					}

					# call the prepare step first
					if ($block->{'prepare'} && ref($block->{'prepare'}) eq "ARRAY")
					{ &{$actions{'prepare'}}($config, $_) foreach @{$block->{'prepare'}}; };

					# pass execution over to action handler
					&{$actions{$action}}($config, $block);

					# call the finish step last
					if ($block->{'finish'} && ref($block->{'finish'}) eq "ARRAY")
					{ &{$actions{'finish'}}($config, $_) foreach @{$block->{'finish'}}; };

				}
				# EO each block
			}
			# EO if merge enabled
		}
		# EO if action enabled

		# pass on to recursively process blocks
		foreach my $block ( @{$xml->{'merge'} || []} )
		{ &process($config, $block, $action); }

	}
	# EO unless disabled

	# commit all changes to the filesystem if configured
	$config->{'atomic'} = {} if $commit =~ m/^\s*(?:bo|af)/i;

};
# EO sub process

################################################################################
# main webmerge routine
################################################################################

# call the prepare step first
# this will create directories
process($config, $xml, 'prepare');

# setup all context blocks
setupBlocks($config, $xml, 'xml');

# merge if not starting watchdog
unless ($config->{'watchdog'})
{

	# call the optimization step next
	# this will change some source files
	process($config, $xml, 'optimize');

	# next we will continue with the merge step
	# this will write generated and processed files
	process($config, $xml, $_) foreach sort keys %merger;

	# call the finish step last
	# this can copy and create files
	process($config, $xml, 'finish');

	# call headinc function to generate headers
	# these can be included as standalone files
	# they have includes for all the css and js files
	process($config, $xml, 'headinc');

	# call embedder to create standalone embedder code
	# this code will sniff the environment to choose
	# the correct headinc to be included in the html
	process($config, $xml, 'embedder');

}
# EO unless watchdog

################################################################################
# now commit all changes
################################################################################

# reset atomic operations
# this will commit all changes
$config->{'atomic'} = {};

# delete all temporarily created files
foreach (@{$config->{'temps'} || []})
{ unlink $_ if -e $_; }

# reset temporarily files
$config->{'temps'} = [];

################################################################################
# start the watchdog at the end to monitor changes
################################################################################

# call watchdog to watch for file changes
# will call merge directly if something changes
# also takes care of atomic and temps operations
# attention: watchdog will never return control
watchdog($config) if ($config->{'watchdog'});

################################################################################
# check for data integrity after commiting changes
################################################################################

# call crc check function to ensure integrity
crcCheck($config) if ($config->{'crc-check'});

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

__END__


=head1 NAME

webmerge - Asset manager for js/css and related files

=head1 SYNOPSIS

webmerge [options] [steps]

 Options:
   -f, --configfile       main xml configuration
   -d, --doctype          how to render includes [html|xhtml|html5]
   -j, --jobs             number of jobs (commands) to run simultaneously

   -w, --watchdog         start the watchdog process (quit with ctrl+c)
   -webserver             start the webserver process (quit with ctrl+c)
   -webport               port number for the webserver to listen to

   --webroot              webroot directory to render absolute urls
   --absoluteurls         export urls as absolute urls (from webroot)

   --import-css           inline imported css files into stylesheet
   --import-scss          inline imported scss files into stylesheet
   --rebase-urls-in-css   adjust urls in css files to parent stylesheet
   --rebase-urls-in-scss  adjust urls to scss files to parent stylesheet
   --rebase-imports-css   adjust import urls for css files (only if not imported)
   --rebase-imports-scss  adjust import urls for scss files (only if not imported)

   --referer              optional referer url for external downloads
   --inlinedataexts       file extensions to inline (comma separated)
   --inlinedatamax        maximum file sizes to inline into stylesheets

   --crc-check            run crc check before exiting
   --crc-file             write crc file beside generated files
   --crc-comment          append crc comment into generated files

   --fingerprint          add fingerprints to includes (--fp)
   --fingerprint-dev      for dev context [query|directory|file] (--fp-dev)
   --fingerprint-live     for live context [query|directory|file] (--fp-live)

   --txt-type             text type [nix|mac|win]
   --txt-remove-bom       remove superfluous utf boms
   --txt-normalize-eol    normalize line endings to given type
   --txt-trim-trailing    trim trailing whitespace in text files

   --headtmpl             text to prepend to generated files
   --jsdeferer            javascript loader for defered loading
   --tmpl-embed-js        template for js embedder generator
   --tmpl-embed-php       template for php embedder generator

       --action           use to disable all actions
   -p, --prepare          enable/disable prepare blocks
   -o, --optimize         enable/disable optimizer blocks
   -m, --merge            use to disable all merge blocks
       --css              enable/disable css merge blocks
       --js               enable/disable js merge blocks
   -i, --headinc          enable/disable headinc blocks
   -e, --embedder         enable/disable embedder blocks

   -l, --level            set optimization level (0-9)

   --dev                  enable/disable dev targets
   --join                 enable/disable join targets
   --minify               enable/disable minify targets
   --compile              enable/disable compile targets
   --license              enable/disable license targets

   --optimize-txt         enable/disable optimizer for text files (--txt)
   --optimize-jpg         enable/disable optimizer for jpg images (--jpg)
   --optimize-gif         enable/disable optimizer for gif images (--gif)
   --optimize-png         enable/disable optimizer for png images (--png)
   --optimize-mng         enable/disable optimizer for mng images (--mng)
   --optimize-zip         enable/disable optimizer for zip archives (--zip)
   --optimize-gz          enable/disable optimizer for gz archive files (--gz)

   -dbg, --debug          enable/disable debug mode

   --man                  full documentation
   --opts                 list command line options
   -?, --help             brief help message with options

 Steps:
   Just process certain steps in configuration

=head1 OPTIONS

=over 8

=item B<-man>

Prints the manual page and exits.

=item B<-opts>

Print a sorted list of command line options and exits.

=item B<-help>

Print a brief help message with options and exits.

=back

=head1 DESCRIPTION

B<This program> merges and optimizes assets for front end web developement.

=cut