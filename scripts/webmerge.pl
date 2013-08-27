#!/usr/bin/perl

use Carp;
use strict;
use warnings;

# XML::Parser

################################################################################

# use FindBin to find the path to the script
# from here the config file for be relative
# this is not true if config path is absolute
use FindBin qw($Bin);

# insert our module directory to lib search directory
# we want to keep our modules local and not install global
BEGIN { push @INC, "$Bin/modules"; }

################################################################################

# load local modules
use RTP::Webmerge;
use RTP::Webmerge::IO;
use RTP::Webmerge::Path;
use RTP::Webmerge::Merge;
use RTP::Webmerge::Prepare;
use RTP::Webmerge::HeadInc;
use RTP::Webmerge::Embeder;
use RTP::Webmerge::Optimize;
use RTP::Webmerge::Checksum;
use RTP::Webmerge::Watchdog;

# load additional modules (no import)
use RTP::Webmerge::Compile::JS qw();
use RTP::Webmerge::Compile::CSS qw();
use RTP::Webmerge::Process::JS qw();
use RTP::Webmerge::Process::CSS qw();

# load optimizer modules (no import)
use RTP::Webmerge::Optimize::TXT qw();
use RTP::Webmerge::Optimize::GIF qw();
use RTP::Webmerge::Optimize::JPG qw();
use RTP::Webmerge::Optimize::PNG qw();

################################################################################
# declare and init configuration options
################################################################################

my $config =
{

	# where is you htdocs root directory
	# this is needed to create absolute urls
	# default is relative to the config file
	'webroot' => '{CONF}/../../..',

	# define a current working directory
	# you can adjust this also in the xml config
	# it's also possible to change it only for a block
	'directory' => '{WWW}/fileadmin',

	# default configuration file relative from our webroot
	# this is the main source for all other configuration options
	'configfile' => '{EXT}/../../../fileadmin/admin/webmerge/webmerge.conf.xml',

	# doctype to render includes
	'doctype' => 'html5',

	# preapre stuff
	'prepare' => 0,
	# optimize stuff
	'optimize' => 0,
	# merge configured stuff
	'merge' => 0,
	# create head includes
	'headinc' => 0,
	# create embeder
	'embeder' => 0,
	# start watchdog
	'watchdog' => 0,

	# do end crc-check
	'crc-check' => 0,

	# referer for downloads
	'referer' => undef,

	# parallel jobs
	'jobs' => 2,

	# the order in which to prefer to include stuff
	'incorder' =>
	{
		'dev' => ['dev', 'join', 'minify', 'compile'],
		'live' => ['compile', 'minify', 'join', 'dev']
	}

};
# EO config


################################################################################
# get config options from the command line
################################################################################

# load commandline option fetcher
use Getopt::Long qw(GetOptions);

# get options from commandline
GetOptions(

	# the main config file (only from cmd line)
	'configfile|f=s' => \$config->{'configfile'},

	# maybe change these in the config file
	'webroot=s' => \$config->{'cmd_webroot'},
	'doctype|d=s' => \$config->{'cmd_doctype'},

	# enable/disable base operations
	'prepare|p!' => \$config->{'cmd_prepare'},
	'optimize|o!' => \$config->{'cmd_optimize'},
	'merge|m!' => \$config->{'cmd_merge'},
	'headinc|i!' => \$config->{'cmd_headinc'},
	'embeder|e!' => \$config->{'cmd_embeder'},
	'watchdog|w!' => \$config->{'cmd_watchdog'},
	'crc-check|c!' => \$config->{'cmd_crc-check'},

	# referer http header for downloads
	'referer|r=s' => \$config->{'cmd_referer'},

	# number of commands to run simultaneously
	'jobs|j=i' => \$config->{'cmd_jobs'},

	# init config will prepare additional configuration
	# returns additional options to be fetched from cmd
	initConfig($config)

);


################################################################################
# read the configuration file
################################################################################

# load xml module
use XML::Simple;

# search for the config file
my $configfile = 'webmerge.conf.xml';

# register extension path within our path modules for later use
$RTP::Webmerge::Path::extroot = res_path(join('/', $Bin, '..'));

# check if configfile is given as relative path
unless ( $config->{'configfile'} =~ m/^\// )
{
	# search for the config file
	$config->{'configfile'} =
		# first try from current directory
		res_path($config->{'configfile'}) ||
		# then try by from our script root
		res_path(join('/', $Bin, $config->{'configfile'})) ||
		# then try by from our script root parent
		res_path(join('/', $Bin, '..', $config->{'configfile'}));
}

# abort if the configuration file was not found
die "configfile not found" unless $config->{'configfile'};

# create the config path from config file ...
$config->{'configpath'} = $config->{'configfile'};
# ... and remove the trailing filename
$config->{'configpath'} =~ s/\/[^\/]+$//;

# register path within our path modules for later use
$RTP::Webmerge::Path::confroot = $config->{'configpath'};


################################################################################
# xml helper function for the include directive
################################################################################

# returns xml fragment as string
# read the given file and do includes
sub get_xml
{

	# get the filenname
	my ($file, @config) = @_;

	# resolve the file path
	$file = resolve_path($file);

	# read the complete xml file
	my $data = readfile($file) || return;

	# replace include tags with the real content of the file to be included
	${$data} =~ s/<include\s+src=(?:\'([^\']+)\'|\"([^\"]+)\"|(\w+))\s*\/?>/get_xml($1||$2||$3)/egm;

	# parse and create the xml document
	my $xml = XMLin(${$data}, 'ForceArray' => 1, 'KeyAttr' => []);

	# return the xml fragment
	return XMLout($xml, 'KeyAttr' => [], 'RootName' => undef);

}
# EO get_xml


# returns xml document as object
# read the given file and do includes
sub read_xml
	{

	# get the filenname
	my ($file, @config) = @_;

	# resolve the file path
	$file = resolve_path($file);

	# read the complete xml file
	my $data = readfile($file) || return;

	# replace include tags with the real content of the file to be included
	${$data} =~ s/<include\s+src=(?:\'([^\']+)\'|\"([^\"]+)\"|(\w+))\s*\/?>/get_xml($1||$2||$3)/egm;

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
my $xml = read_xml($config->{'configfile'})
	or die 'error while reading config file, aborting';


################################################################################
# apply the configuration from the xml to the config hash
################################################################################

# process all config nodes in config file
foreach my $cfg (@{$xml->{'config'} || []})
{

	# process all given configuration keys
	foreach my $key (keys %{$cfg || {}})
	{

		# do not create unknown config keys
		next unless exists $config->{$key};

		# assign the value from the first item
		$config->{$key} = $cfg->{$key}->[0];

	}
	# EO each xml config key

}
# EO each xml config

# store xml reference
$config->{'xml'} = $xml;


################################################################################
# apply overruling command line options after xml has been applied
################################################################################

# search all config keys for /^cmd_/
# options from command line overrule
# all other configuration options
foreach my $key (keys %{$config})
{

	# only process cmd keys
	next unless $key =~ s/^cmd_//;

	# only process valid cmd keys
	next unless defined $config->{'cmd_'.$key};

	# overrule the option from cmd line
	$config->{$key} = $config->{'cmd_'.$key};

	# remove cmd option from config
	delete $config->{'cmd_'.$key};

}
# EO each config key

################################################################################
# setup some paths to be used by all other functions
################################################################################

# set htdocs root directory and current working directory
$RTP::Webmerge::Path::webroot = res_path($config->{'webroot'} || '.');
$RTP::Webmerge::Path::directory = res_path($config->{'directory'} || '.');

################################################################################

# only allow directory or query option to be given for fingerprinting
if ($config->{'fingerprint-dev'} && !($config->{'fingerprint-dev'} =~ m/^[qfn]/i))
{ die "invalid fingerprinting set for dev: <" .  $config->{'fingerprint-dev'} . ">"; }
if ($config->{'fingerprint-live'} && !($config->{'fingerprint-live'} =~ m/^[qfn]/i))
{ die "invalid fingerprinting set for live: <" .  $config->{'fingerprint-live'} . ">"; }

# normalize fingerprint configuration to the first letter (lowercase)
$config->{'fingerprint-dev'} = lc substr($config->{'fingerprint-dev'}, 0, 1);
$config->{'fingerprint-live'} = lc substr($config->{'fingerprint-live'}, 0, 1);
# disable the fingerprint option if the given value is no or none
$config->{'fingerprint-dev'} = undef if $config->{'fingerprint-dev'} eq 'n';
$config->{'fingerprint-live'} = undef if $config->{'fingerprint-live'} eq 'n';


################################################################################
# setup configuration for external downloads
# so far this can only be set by the config file
################################################################################

# init the config array
$config->{'external'} = [];

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
		unshift @{$config->{'external'}},
		{
			'enabled' => $enabled,
			'href' => $ext->{'href'},
			'referer' => $ext->{'referer'},
		};

	}
	# EO each external

}
# EO each xml config


################################################################################
# declare status variables and attach to config hash
################################################################################

# store atomic operations
$config->{'atomic'} = {};

# store temporarily files
$config->{'temps'} = [];


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
	# delete all temporarily created files
	foreach (@{$config->{'temps'} || []}) { unlink $_ if -e $_; }
	# delete all atomic temporarily files (struct: [data, blessed])
	foreach (values %{$config->{'atomic'} || {}}) { $_->[1]->delete; }
}


################################################################################
# check the configuration before goind to execute main program
################################################################################

# check config will assert the configuration
# call after you have read command line options
checkConfig($config) or die "config check failed";


################################################################################
# remove xml for not mentioned steps
################################################################################

# if some arguments are given we only want to merge given steps
# therefore remove all other steps from the configuration file
if (scalar(@ARGV))
{

	# create regular expression to match steps
	my $re_argv = join('|', @ARGV);

	# loop all operation nodes (which could have an step)
	foreach my $node
	(
		@{$xml->{'merge'} || []},
		@{$xml->{'prepare'} || []},
		@{$xml->{'headinc'} || []},
		@{$xml->{'embeder'} || []},
		@{$xml->{'optimize'} || []},
	)
	{

		# get all subnodes from the main operation nodes
		my @subnodes = grep { ref($_) eq 'ARRAY' } values %{$node};

		# should we keep the root node
		# otheriwse it may be disabled
		my $keep_root = 0;

		# keep all subnodes if the root node should be generated
		my $keep_sub = $node->{'step'} && $node->{'step'} =~ m/^(?:$re_argv)$/;

		# process each subnode
		foreach my $subnode (map { @{$_} } @subnodes)
		{

			# abort loop if we want to keep all subnodes
			# othwerwise it may be disabled if step doesn't match
			next if $keep_sub || ref($subnode) ne 'HASH';

			# only can remove items with step
			next unless $subnode->{'step'};

			# test if we should disable this node from the xml
			unless ($subnode->{'step'} =~ m/^(?:$re_argv)$/)
			{

				# simply disable this subnode
				$subnode->{'disabled'} = 'true';

			}
			else
			{

				# keep this root node
				$keep_root = 1;

			}
			# EO if step matches argv

		}
		# EO each subnode

		# abort loop if we want to keep the root node
		# othwerwise it may be disabled if step doesn't match
		next if $keep_root;

		# only can remove items with step
		next unless $node->{'step'};

		# test if we should disable this node from the xml
		unless ($node->{'step'} =~ m/^(?:$re_argv)$/)
		{

			# simply disable this node
			$node->{'disabled'} = 'true';

		}
		# EO if disable node

	}
	# EO foreach nodes

}
# EO input arguments


################################################################################
# remove xml for dublicate ids (only use last)
################################################################################

# get nodes arrays to clean
foreach my $nodes
(
	($xml->{'prepare'} || []),
	($xml->{'headinc'} || []),
	($xml->{'feature'} || []),
	($xml->{'embeder'} || []),
	($xml->{'optimize'} || []),
	(map { $_->{'js'} || [] } @{$xml->{'merge'} || []}),
	(map { $_->{'css'} || [] } @{$xml->{'merge'} || []})
)
{

	# count block occurences
	# blocks identified by id
	my %known_id;

	# loop from behind so we can splice items out
	for (my $i = $#{$nodes}; $i != -1; -- $i)
	{

		# the the id of this block (skip if undefined)
		my $id = $nodes->[$i]->{'id'} || next;

		# increment id counter
		# will init automatically
		$known_id{$id} += 1;

		# always keep the first node
		# the loop is going from behind
		# so this is actually the last node
		next if ($known_id{$id} == 1);

		# splice out all other nodes with
		# the same type and identifier
		splice(@{$nodes}, $i, 1);

	}

}
# EO loop arrays to clean


################################################################################
# main execution of the operations
################################################################################

unless ($config->{'watchdog'})
{

	# call the action step first
	# this will create directories
	if ($config->{'prepare'} && $xml->{'prepare'})
	{ prepare($config, $_) foreach @{$xml->{'prepare'}}; }

	# call the optimization step next
	# this will change some source files
	if ($config->{'optimize'} && $xml->{'optimize'})
	{ optimize($config, $_) foreach @{$xml->{'optimize'}}; }

	# next we will continue with the merge step
	# this will write generated and processed files
	if ($config->{'merge'} && $xml->{'merge'})
	{ merge($config, $_) foreach @{$xml->{'merge'}}; }

	# call headinc function to generate headers
	# these can be included as standalone files
	# they have includes for all the css and js files
	if ($config->{'headinc'} && $xml->{'headinc'})
	{ headinc($config, $_) foreach @{$xml->{'headinc'}}; }

	# call embeder to create standalone embeder code
	# this code will sniff the environment to choose
	# the correct headinc to be included in the html
	if ($config->{'embeder'} && $xml->{'embeder'})
	{ embeder($config, $_) foreach @{$xml->{'embeder'}}; }

}

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
# check for data integrity after commiting changes
################################################################################

# call crc check function to ensure integrity
crcCheck($config) if ($config->{'crc-check'});

################################################################################
# start the watchdog at the end to monitor changes
################################################################################

# call watchdog to watch for file changes
# will call merge directly if something changes
# also takes care of atomic and temps operations
# attention: watchdog will never return control
watchdog($config) if ($config->{'watchdog'});

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