###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
###################################################################################################
package RTP::Webmerge::Webserver;
###################################################################################################

use Carp;
use strict;
use warnings;

###################################################################################################

# define our version string
BEGIN { $RTP::Webmerge::Webserver::VERSION = "0.9.0" }

# load exporter and inherit from it
BEGIN { use Exporter qw(); our @ISA = qw(Exporter) }

# define our functions to be exported
BEGIN { our @EXPORT = qw(webserver); }

###################################################################################################

# load core io module
use RTP::Webmerge::IO;
# load core path module
use RTP::Webmerge::Path;

use RTP::Webmerge::Webserver::Server;

# webserver
sub webserver ($)
{

	# get input variables
	my ($config) = @_;

	my $server = RTP::Webmerge::Webserver::Server->new($config);

	$server->run();

}

###################################################################################################

# extend the configurator
use RTP::Webmerge qw(@initers);

# register initializer
push @initers, sub
{

	# get input variables
	my ($config) = @_;

	# default webserver port
	$config->{'webport'} = 8000;

	# fork a simple webserver to host project
	$config->{'webserver'} = undef;

	# return additional get options attribute
	return (
		'webport=i' => \ $config->{'cmd_webport'},
		'webserver!' => \$config->{'cmd_webserver'}
	);

};
# EO plugin initer

###################################################################################################

# webserver
sub webserver3 ($)
{

	# get input variables
	my ($config) = @_;

	require HTTP::Daemon;
	require HTTP::Status;

	require LWP::MediaTypes;

	LWP::MediaTypes::add_type('text/html', 'shtml');

	local $SIG{'INT'} = undef;

	use File::Spec::Functions;
	use File::Spec::Functions qw(rel2abs);

	my $d = HTTP::Daemon->new(
		LocalPort => $config->{'port'} || 8000,
		# LocalAddr => '127.0.0.1',
	) || die "Fatal: ", $!;

	while (my $c = $d->accept)
	{
#		my $pid = fork();
# if ($pid == 0)
  {

  			print "new connection\n";
		while (my $r = $c->get_request)
		{
			print "new request\n";
			if ($r->method eq 'GET' || $r->method eq 'POST')
			{
				print "new request uri\n";
				use URI::Escape qw(uri_unescape);
				my $wwwpath = uri_unescape($r->uri->path);
				my $path = canonpath(uri_unescape($r->uri->path));
				my $root = canonpath(check_path($config->{'webroot'}));
				my $file = canonpath(catfile($root, $path));
				die "hack attempt" unless $file =~ m /^\Q$root\E/;
				print $r->method, " ", $wwwpath, "\n";
				if (-d $file && -e join('/', $file, 'index.html'))
				{ $file = join('/', $file, 'index.html'); }
				if (-d $file)
				{
					# check for end slash
					# otherwise redirect ua
					unless ($wwwpath =~ m/\/$/)
					{
						$c->send_redirect( $wwwpath.'/' );
					}
					else
					{

						my $content = "<!doctype html><html><head><title>Directory Listening</title><style>BODY,UL,LI{ font-family: verdana; }</style></head><body><h1>".$path."</h1>";
						opendir(my $dh, $file);
						if ($dh)
						{
							$content .= "<ul>";
							$content .= sprintf '<li><a href="%1$s">%1$s</a></li>', '..' unless $wwwpath =~ m/^\/*$/;
							$content .= sprintf '<li><a href="%1$s">%1$s</a></li>', $_ foreach grep { !m/^\.{1,2}$/ } readdir($dh);
							$content .= "</ul>";
						}
						else
						{
							$content .= "error opening directory: $!";
						}

						$content .= "</body></html>";
						my $response = HTTP::Response->new( 200 );
						$response->content( $content );
						$response->header( "Content-Type" => "text/html" );

						$c->send_response( $response );
					}
				}
				elsif (-e $file)
				{
					print "send file response\n";
					$c->send_file_response($file);
					print "sent file response\n";
				}
				else
				{
					$c->send_error(HTTP::Status::RC_FORBIDDEN())
				}
			}
			else
			{
				$c->send_error(HTTP::Status::RC_FORBIDDEN())
			}
			# needed?
			#$c->close;
			$c->flush ;
		}
		print "close connection\n";
		$c->close;
		undef($c);
    core::exit(0);
  }

  	}

	exit;

}
# EO sub webserver

###################################################################################################
###################################################################################################
1;


