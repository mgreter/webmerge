################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::Runner::Webserver;
################################################################################

use strict;
use warnings;

################################################################################
# implement webserver
################################################################################

my %apps = (
	'file' => 'OCBNET::Plack::App::File',
	'echo' => 'OCBNET::Plack::App::Echo',
	'proxy' => 'OCBNET::Plack::App::Proxy',
	'directory' => 'OCBNET::Plack::App::Directory',
);

sub webserver
{
use File::chdir;
	# create the config
	my ($context) = @_;
use Data::Dumper;
	require Plack::Builder;
	require Plack::App::URLMap;
	require Plack::App::Proxy;
	require Plack::App::Directory;

	require OCBNET::Plack::App::SHTML;
	require OCBNET::Plack::App::File;
	require OCBNET::Plack::App::Echo;
	require OCBNET::Plack::App::Proxy;
	require OCBNET::Plack::App::Directory;

	# $CWD = $context->webroot;

	my $mounts = $context->config('webmounts');
	my $roots = $context->config('webresources');
	my $handlers = $context->config('webhandlers');


use File::Spec::Functions qw(rel2abs);

	@{$roots} = map {

		rel2abs ($_, $context->webroot)

	} @{$roots};

	my $urlmap = Plack::App::URLMap->new;

	$urlmap->map('/' => OCBNET::Plack::App::Directory->new({ roots => $roots })->to_app);

	foreach my $mount (@{$mounts || []})
	{

		my $path = $mount->{'data'};
		my $type = $mount->{'attr'}->{'type'};
		die "unknow type" unless exists $apps{$type};
		my $app = $apps{$type}->new($mount->{'attr'});
		$urlmap->map($path, $app);
	}

	my $app = $urlmap->to_app;

	require Plack::Runner;
	my $runner = Plack::Runner->new;
	# $runner->parse_options('--port', '8000');
	die $runner->run($app);
	die "hasd";
	return;

}

################################################################################
# register our tool within the main module
################################################################################

OCBNET::Webmerge::Runner::register('webserver|s', \&webserver, - 20, 0);

################################################################################
# configuration options for webserver
################################################################################
use OCBNET::Webmerge qw(options);
################################################################################

options('webport', '=i', my $webport);

################################################################################

my $classes = \ %OCBNET::Webmerge::XML::Config::classes;

$classes->{'webmounts'} = 'OCBNET::Webmerge::XML::Config::XML::Array';
$classes->{'webhandlers'} = 'OCBNET::Webmerge::XML::Config::XML::Array';
$classes->{'webresources'} = 'OCBNET::Webmerge::XML::Config::Array';

################################################################################
################################################################################
1;
