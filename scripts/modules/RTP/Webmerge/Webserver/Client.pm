###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
###################################################################################################
package RTP::Webmerge::Webserver::Client;
###################################################################################################

use Carp;
use strict;
use warnings;
use CGI::SHTML;

###################################################################################################

# define our version string
BEGIN { $RTP::Webmerge::Webserver::Client::VERSION = "0.9.0" }

# load exporter and inherit from it
BEGIN { use Exporter qw(); our @ISA = qw(Exporter) }

# define our functions to be exported
BEGIN { our @EXPORT = qw(); }

use base 'IO::Socket::INET';

###################################################################################################

# load core io module
use RTP::Webmerge::IO;
# load core path module
use RTP::Webmerge::Path;

###################################################################################################

use HTTP::Request  ();
use HTTP::Response ();
use HTTP::Status;
use HTTP::Date qw(time2str);
use LWP::MediaTypes qw(guess_media_type);
use Carp ();

my $CRLF = "\015\012";   # "\r\n" is not portable
my $HTTP_1_0 = _http_version("HTTP/1.0");
my $HTTP_1_1 = _http_version("HTTP/1.1");

###################################################################################################

sub rbuf : lvalue { my $self = $_[0]; ${*$self}{'httpc_rbuf'} }
sub wbuf : lvalue { my $self = $_[0]; ${*$self}{'httpc_wbuf'} }
sub state : lvalue { my $self = $_[0]; ${*$self}{'httpc_state'} }

sub client : lvalue { my $self = $_[0]; ${*$self}{'io_client'} }
sub server : lvalue { my $self = $_[0]; ${*$self}{'io_server'} }

sub proto : lvalue { my $self = $_[0]; ${*$self}{'io_proto'} }
sub request : lvalue { my $self = $_[0]; ${*$self}{'io_request'} }

###################################################################################################

my @readers;

# read complete header
push @readers, sub
{

	my ($conn) = @_;

	if (${*$conn}{'httpd_nomore'}) {
        die "No more";
        #$conn->reason("No more requests from this connection");
	return -1;
    }

 	# ignore leading blank lines
	$conn->rbuf =~ s/^(?:\015?\012)+//;

	# check for a complete line
	if ($conn->rbuf =~ /\012/)
	{
		# check for valid http header with method, uri and version
		if ($conn->rbuf =~ /^\w+[^\012]+HTTP\/\d+\.\d+\015?\012/)
		{
			# check if we have readed the complete header
			return 1 if $conn->rbuf =~ /\015?\012\015?\012/;
			# protect us from reading more than reasonable
			if (length($conn->rbuf) > 1024 * 64)
			{
				die "REQUEST_ENTITY_TOO_LARGE";
				$conn->send_error(413);
				$conn->reason("Very long header");
				return -1;
			}
		}
		else
		{
			# HTTP/0.9 client
			return 1;
		}
	}
	# the first line is not yet finished
	# protect us from reading more than reasonable
	elsif (length($conn->rbuf) > 1024 * 16)
	{
		die "REQUEST_URI_TOO_LARGE";
		$conn->send_error(414);
		$conn->reason("Very long first line");
		return -1;
	}

	# want more
	return 0;

};


use URI;
use HTTP::Request;
$HTTP::URI_CLASS = "URI";

###################################################################################################

# parse request header
push @readers, sub
{

	my ($conn) = @_;

	my $client = ${*$conn}{'io_client'};
	my $server = ${*$conn}{'io_server'};

	if ($conn->rbuf !~ s/^(\S+)[ \t]+(\S+)(?:[ \t]+(HTTP\/\d+\.\d+))?[^\012]*\012//)
	{
		die "BAD_REQUEST ", $conn->rbuf;
		${*$conn}{'httpd_client_proto'} = _http_version("HTTP/1.0");
		$conn->send_error(400);  # BAD_REQUEST
		$conn->reason("Bad request line: " . $conn->rbuf);
		return -1;
	}

	# declare and assign local variables
	my ($method, $uri, $proto) = ($1, $2, $3 || "HTTP/0.9");
	# fixes a sepecific bug
	$uri =~ s/\/+/\//g;
	# create the final uri to access actually
	$uri = "http://" . $uri if $method eq "CONNECT";
	$uri = $HTTP::URI_CLASS->new($uri); #, $conn->daemon->url);

	# create the request object
	my $request = HTTP::Request->new($method, $uri);

	# set the request protocol
	$request->protocol($proto);

	${*$conn}{'httpd_client_proto'} = $proto = _http_version($proto);
	${*$conn}{'httpd_head'} = ($method eq "HEAD");

	# assign some variables
	$client->{'uri'} = $uri;
	$client->{'proto'} = $proto;
	$client->{'method'} = $method;
	$client->{'request'} = $request;




	my $req = $client->{'request'};
	# my $proto = $client->{'proto'};

	# parse headers for HTTP/1.1
	if ($proto >= $HTTP_1_0)
	{

		# declare variables
		my ($key, $val);

		# process each line by itself
		while ($conn->rbuf =~ s/^([^\012]*)\012//)
		{

			# create copy
			my $data = $1;
			# remove carriage returns
			$data =~ s/\015$//;

			# check for key : value delmited line
			if ($data =~ /^([^:\s]+)\s*:\s*(.*)/)
			{
				# push the current/old key to header
				$req->push_header($key, $val) if $key;
				# next key with value
				($key, $val) = ($1, $2);
			}
			# append all other data
			elsif ($data =~ /^\s+(.*)/)
			{
				# append to value
				$val .= " $1";
			}
			# empty line
			else
			{
				# delimiter
				last;
			}

		}
		# EO each line

		# push the current/old key to header
		$req->push_header($key, $val) if $key;

	}
	# EO if proto > 1.0

	# test if we close connection
	my $fin = $req->header('Connection');

	# protocol specific
	if ($proto >= $HTTP_1_1)
	{
		# close connection when set to close (HTTP/1.1)
		$conn->fin if $fin && $fin =~ /\bclose\b/i;
	}
	else
	{
		# close connection when not set to keep-alive (HTTP/1.0)
		$conn->fin unless $fin && $fin =~ /\bkeep-alive\b/i;
		# Can't locate object method "fin" via package "RTP::Webmerge::Webserver::Client"
	}

	return 1;

};
# EO parse header

###################################################################################################

# read request body
push @readers, sub
{

	my ($sock) = @_;

	my $client = ${*$sock}{'io_client'};
	my $server = ${*$sock}{'io_server'};

	my $req = $client->{'request'};
	my $proto = $client->{'proto'};


my $r = $req;
my $self = $sock;
my $DEBUG = 1;

	# Find out how much content to read
	my $te  = $r->header('Transfer-Encoding');
	my $ct  = $r->header('Content-Type');
	my $len = $r->header('Content-Length');
		# print "READ PPOST DATA $ct $len\n";

	# Act on the Expect header, if it's there
	for my $e ( $r->header('Expect') ) {
		if( lc($e) eq '100-continue' ) {
			$self->send_status_line(100);
			$self->send_crlf;
		}
		else {
			$self->send_error(417);
			$self->reason("Unsupported Expect header value");
		print "bad\n";
			return;
		}
	}

	if ($te && lc($te) eq 'chunked')
	{
		die "CHUNKED ENCODING\n";
		# Handle chunked transfer encoding
		my $body = "";
		CHUNK:
		while (1) {
			print STDERR "Chunked\n" if $DEBUG;
			if ($sock->rbuf =~ s/^([^\012]*)\012//) {
				my $chunk_head = $1;
				unless ($chunk_head =~ /^([0-9A-Fa-f]+)/) {
					$self->send_error(400);
					$self->reason("Bad chunk header $chunk_head");
					return;
				}
				my $size = hex($1);
				last CHUNK if $size == 0;
				my $missing = $size - length($sock->rbuf) + 2; # 2=CRLF at chunk end
				# must read until we have a complete chunk
				while ($missing > 0) {
					print STDERR "Need $missing more bytes\n" if $DEBUG;
					return 0;
					# my $n = $self->_need_more($sock->rbuf, $timeout, $fdset);
					# return unless $n;
					# $missing -= $n;
				}
				$body .= substr($sock->rbuf, 0, $size);
				substr($sock->rbuf, 0, $size+2) = '';
			}
			else {
				# need more data in order to have a complete chunk header
				return 0;
				# return unless $self->_need_more($sock->rbuf, $timeout, $fdset);
			}
		}
		$r->content($body);

		# pretend it was a normal entity body
		$r->remove_header('Transfer-Encoding');
		$r->header('Content-Length', length($body));

		my($key, $val);
		while (1) {
			if ($sock->rbuf !~ /\012/) {
				# need at least one line to look at
				return 0;
				# return unless $self->_need_more($sock->rbuf, $timeout, $fdset);
			}
			else {
				$sock->rbuf =~ s/^([^\012]*)\012//;
				$_ = $1;
				s/\015$//;
				if (/^([\w\-]+)\s*:\s*(.*)/) {
					$r->push_header($key, $val) if $key;
					($key, $val) = ($1, $2);
				}
				elsif (/^\s+(.*)/) {
					$val .= " $1";
				}
				elsif (!length) {
					last;
				}
				else {
					$self->reason("Bad footer syntax");
					return;
				}
			}
		}
		$r->push_header($key, $val) if $key;
	}
	elsif ($te) {
		$self->send_error(501); 	# Unknown transfer encoding
		$self->reason("Unknown transfer encoding '$te'");
		return -1;
	}
	elsif ($len) {
		# Plain body specified by "Content-Length"
		my $missing = $len - length($sock->rbuf);
		# print "Plain body specified by Content-Length (missing: $missing of $len)\n" .  $sock->rbuf . "\n";
		while ($missing > 0) {
			#print "Need $missing more bytes of content\n" if $DEBUG;
			return 0;
			# my $n = $self->_need_more($sock->rbuf, $timeout, $fdset);
			# return unless $n;
			# $missing -= $n;
		}
		if (length($sock->rbuf) > $len) {
			$r->content(substr($sock->rbuf,0,$len));
			substr($sock->rbuf, 0, $len) = '';
		}
		else {
			$r->content($sock->rbuf);
			$sock->rbuf = '';
		}
	}
#	elsif ($ct && $ct =~ m/^multipart\/\w+\s*;.*boundary\s*=\s*(\"?)(\w+)\1/i) {
	elsif ($ct && $ct =~ m/^multipart\/(?:\w|-)+\s*;.*boundary\s*=\s*(?:\"((?:\w|-)+)\"|((?:\w|-)+))/i) {
		#print "multipart upload \"$1\" $2\n";
		# Handle multipart content type
		my $boundary = "--" . ($1 || $2) . "--";
		my $index;
		while (1) {
			# print "reading ", length($sock->rbuf), "\n";
			$index = index($sock->rbuf, $boundary);
			# print "search for $boundary ==> $index\n", $sock->rbuf, "\n";
			# die "last" if $index >= 0;
			last if $index >= 0;
			# end marker not yet found
			return 0;
			# return unless $self->_need_more($sock->rbuf, $timeout, $fdset);
		}
		# print "im out of this?\n";
		$index += length($boundary);
		$r->content(substr($sock->rbuf, 0, $index));
		substr($sock->rbuf, 0, $index) = '';
	}
	else
	{
		# no upload at all
		# print "damn\n";
	}
	${*$self}{'httpd_rbuf'} = $sock->rbuf;

	return 1;
};

sub canRead
{

	my ($sock) = @_;

	my $client = ${*$sock}{'io_client'};
	my $server = ${*$sock}{'io_server'};

#	print "client can read now ", length($sock->rbuf), "\n";

	my $rv = sysread($sock, $sock->rbuf, 1024 * 16, length($sock->rbuf));

 	# print "client has readed now $rv -> ", length($sock->rbuf), "\n";
	# print $sock->rbuf, "\n";
	# $server->captureRead($sock);

	unless ($rv)
	{
		print "!!!!!! client read closed\n";
		$server->removeHandle($sock);
		$sock->close;
		return 1;
	}

	die "client read error" unless defined $rv;
	die "client read closed" unless $rv;

	# check if this is a valid reading step
	# $client->{'state'} = 0 unless $readers[$client->{'state'}];

	# read as much as possible
	while ($readers[$client->{'state'}])
	{

		# call the reader function for current state
		$rv = $readers[$client->{'state'}]->($sock);

		# go to next reading step
		# we may have enough buffer
		$client->{'state'} ++ if $rv eq 1;

		# reader tells us it needs more data
		last if $rv eq 0;

		# reader tells us that we have an error
		last if $rv eq -1;

	}

	use File::Spec::Functions;
	use File::Spec::Functions qw(rel2abs);

# print "out ", $client->{'state'}, "\n";
	if ( $rv eq 1 && $client->{'state'} >= scalar(@readers))
	{

		use HTTP::Response;
		eval "use HTTP::Body;";

		# now we have the request
		my $req = $client->{'request'};

		my $content_type   = $req->header('Content-Type');
		my $content_length = $req->header('Content-Length');
		my $body           = HTTP::Body->new( $content_type, $content_length );

		$client->{'body'} = $body;

		$client->{'body'}->add($req->{'_content'});

		my $response = HTTP::Response->new( 200 );

		my $r = $req;
		# print "new request uri\n";
		use URI::Escape qw(uri_unescape);
		my $wwwpath = uri_unescape($r->uri->path);
		my $path = canonpath(uri_unescape($r->uri->path));
		my $config = $server->{'config'};
		my $root = canonpath(check_path($config->{'webroot'}));
		my $file = canonpath(catfile($root, $path));
		die "hack attempt" unless $file =~ m /^\Q$root\E/;
		print $r->method, " ", $wwwpath, "\n";
		if ($wwwpath eq '/dump/request')
		{
			my $response = HTTP::Response->new( 200 );

			my $content = '<h1>Dump request</h1>';

			$content .= '<STYLE>
				BODY, TABLE { font-size: 12px; }
				BODY { font-family: verdana, arial; }
				TD { padding: 2px 4px; }
				TD { border: 1px solid #333; }
				TD:first-child { text-align: right; }
			</STYLE>';

			$content .= '<h3>' . localtime . '</h3>';

			$content .= '<h2>Post params</h2><TABLE border=1>';
			my %occurence;
			foreach my $param (@{$body->{'param_order'}})
			{
				my $value = $body->{'param'}->{$param};

				if (ref($value) eq 'ARRAY')
				{
					unless (exists $occurence{$param})
					{
						$occurence{$param} = 0;
					}
					else
					{
						$occurence{$param} ++;
					}
					$value = $value->[$occurence{$param}];
				}


				$content .= '<TR>';
				$content .= '<TD><STRONG>' . $param . '</STRONG></TD>';
				$content .= '<TD>' . $value . '</TD>';
				$content .= '</TR>';
			}
			$content .= '</TABLE>';

			$response->content( $content );

			# $response->content(Data::Dumper->Dump([$r]));
			# $response->content(Data::Dumper->Dump([$client->{'body'}]));

			$response->header( "Content-Type" => "text/html" );
			$sock->send_response( $response );
		}
		elsif (-d $file && not $r->uri->path =~ m/\/$/)
		{
			my $url = "http://" . $sock->sockhost;
			$url .= ':' . $sock->sockport if ($sock->sockport ne 80);
			# $url .= ':' . $config->{'webport'} if ($config->{'webport'} ne 80);
			$sock->send_redirect($url . $r->uri->path.'/');

		}
		elsif (-d $file && -e join('/', $file, 'index.html'))
		{ $file = join('/', $file, 'index.html'); }

		if (-f $file && $file =~ m/\.s?html?(?:\Z|\?|\#)/)
		{
			$file =~ s/\//\\/gm;
			$ENV{'SERVER_PORT'} = $sock->sockport;
			$ENV{'HTTP_HOST'} = $req->header('Host');
			$ENV{'HOSTNAME'} = $req->header('Host');
			$ENV{'DOCUMENT_ROOT'} = canonpath(check_path($config->{'webroot'}));
			$CGI::SHTML::ROOTDIR = $ENV{'DOCUMENT_ROOT'};
			chdir dirname $file;
			use Encode qw(encode decode);
			use IO::HTML qw(html_file_and_encoding);
			my ($fh, $enc, $bom) = html_file_and_encoding($file);
			my $cgi = CGI::SHTML->new;
			$fh->open($file, "r") or
			  return $sock->send_error(RC_FORBIDDEN);
			my($ct,$ce) = guess_media_type($file);
			warn "cannot guess media type?" if ($ct ne 'text/html');
			print "HTML with encoding charset: $enc\n" if $config->{'debug'};
			$cgi->{'debug'} = $config->{'debug'};
			my($size,$mtime) = (stat $file)[7,9];
			my $content = join('', <$fh>);
			my $response = HTTP::Response->new( 200 );
			$content = decode($enc, $content);
			$content = $cgi->parse_shtml($content);
			$content = encode($enc, $content);
			$response->content( $content );
			$response->header("Content-Type" => $ct) if $ct;
			# $response->header("Content-Encoding" => $ce) if $ce;
			$response->header("Content-Length" => $size) if defined $size;
			$sock->send_response( $response );

		}
		elsif (-e $file)
		{
			# print "send file response\n";
			$sock->send_file_response($file);
			# print "sent file response\n";
		}
		else
		{
			$sock->send_error(HTTP::Status::RC_FORBIDDEN());
			warn "request not found $file\n";
		}

		$client->{'state'} = 0;

	}

}

sub print
{

	my ($sock, @str) = @_;

	my $client = ${*$sock}{'io_client'};
	my $server = ${*$sock}{'io_server'};

	$sock->wbuf .= join("", @str);

	# set file reader according to buffer size
	# if (length($sock->wbuf) < 1024 * 16) {}

	$server->captureWrite($sock);

	return 1;

}

sub printf
{

	my ($sock, $tmpl, @str) = @_;

	my $client = ${*$sock}{'io_client'};
	my $server = ${*$sock}{'io_server'};

	$sock->wbuf .= sprintf($tmpl, @str);

	# set file reader according to buffer size
	# if (length($sock->wbuf) < 1024 * 16) {}

	$server->captureWrite($sock);

	return 1;

}

sub stream
{

	my ($sock, $stream) = @_;

	my $client = ${*$sock}{'io_client'};
	my $server = ${*$sock}{'io_server'};
	${*$sock}{'io_stream'} = $stream;

	$stream->canRead();

}

sub canWrite
{

	my ($sock) = @_;

	my $client = ${*$sock}{'io_client'};
	my $server = ${*$sock}{'io_server'};


	my $rv = syswrite($sock, $sock->wbuf, 1024 * 64);

	# print "client has written now ", $rv, "\n";

	warn "client write error: $!" unless defined $rv;
	warn "client write closed: $!" unless $rv;

	if ($rv)
	{

		substr($sock->wbuf, 0, $rv) = "";

		while (${*$sock}{'io_stream'} && length($sock->wbuf) < 1024 * 16 * 4)
		{
			# print "Buf 1: ", length($sock->wbuf), "\n";
			my $stream = ${*$sock}{'io_stream'};
			$stream->canRead();
			# print "Buf 2: ", length($sock->wbuf), "\n";
		}

	}

	if (length($sock->wbuf) eq 0)
	{
		$server->uncaptureWrite($sock);
	}

	# print "client has written $rv -> left: ", length($sock->wbuf), "\n";

}

sub hasError
{

	my ($sock) = @_;

	my $client = ${*$sock}{'io_client'};
	my $server = ${*$sock}{'io_server'};

	# print "client has error\n";

	$server->removeHandle($sock);

	${*$sock}{'io_client'} = undef;
	${*$sock}{'io_server'} = undef;

	$sock->close;

	undef $sock;

}

sub send_redirect
{
    my($self, $loc, $status, $content) = @_;
    $status ||= RC_MOVED_PERMANENTLY;
    Carp::croak("Status '$status' is not redirect") unless is_redirect($status);
    $self->send_basic_header($status);
    $loc = $HTTP::URI_CLASS->new($loc) unless ref($loc);
    $self->print("Location: $loc$CRLF");
    if ($content) {
	my $ct = $content =~ /^\s*</ ? "text/html" : "text/plain";
	$self->print("Content-Type: $ct$CRLF");
    }
    $self->print($CRLF);
    $self->print($content) if $content && !$self->head_request;
    $self->force_last_request;  # no use keeping the connection open
}

sub send_error
{
    my($self, $status, $error) = @_;
    $status ||= RC_BAD_REQUEST;
    Carp::croak("Status '$status' is not an error") unless is_error($status);
    my $mess = status_message($status);
    $error  ||= "";
    $mess = <<EOT;
<title>$status $mess</title>
<h1>$status $mess</h1>
$error
EOT
    unless ($self->antique_client) {
        $self->send_basic_header($status);
        $self->print("Content-Type: text/html$CRLF");
	$self->print("Content-Length: " . length($mess) . $CRLF);
        $self->print($CRLF);
    }
    $self->print($mess) unless $self->head_request;
    $status;
}


sub send_file_response
{
    my($self, $file) = @_;
    if (-d $file) {
	$self->send_dir($file);
    }
    elsif (-f _) {

	# plain file
	my $client = ${*$self}{'io_client'};
	my $server = ${*$self}{'io_server'};

use RTP::Webmerge::Webserver::File;
my $fh = RTP::Webmerge::Webserver::File->new($client, $server, $self);

	$fh->open($file, "r") or
	  return $self->send_error(RC_FORBIDDEN);
	# $fh->binmode;
	my($ct,$ce) = guess_media_type($file);
	my($size,$mtime) = (stat _)[7,9];
	unless ($self->antique_client) {
	    $self->send_basic_header;
	    $self->print("Content-Type: $ct$CRLF");
	    # $self->print("Connection: Close$CRLF");
	    # $self->print("Content-Encoding: $ce$CRLF") if $ce;
	    $self->print("Content-Length: $size$CRLF") if defined $size;
	    $self->print("Last-Modified: ", time2str($mtime), "$CRLF") if $mtime;
	    $self->print($CRLF);
	}
	#$self->send_file(\*F) unless $self->head_request;
# print "open filehandle ", $fh->fileno, "\n";
$self->stream($fh);
# not on windows
# select only sockets
#$server->addHandle($fh);
#$server->captureRead($fh);
#$server->uncaptureWrite($self);
#$server->captureError($fh);
	return RC_OK;
    }
    else {
	$self->send_error(RC_NOT_FOUND);
    }
}


sub send_dir
{
    my($self, $dir) = @_;
    $self->send_error(RC_NOT_FOUND) unless -d $dir;
    # $self->send_error(RC_NOT_IMPLEMENTED);

	my $content = "<!doctype html><html><head><title>Directory Listening</title><style>BODY,UL,LI{ font-family: verdana; }</style></head><body><h1>".$dir."</h1>";
	opendir(my $dh, $dir);
	if ($dh)
	{
		$content .= "<ul>";
		$content .= sprintf '<li><a href="%1$s">%1$s</a></li>', '..' unless $dir =~ m/^\/*$/;
		$content .= sprintf '<li><a href="%1$s">%1$s</a></li>', $_ foreach map { -d join('/', $dir, $_) ? $_ . '/' : $_  } grep { !m/^\.{1,2}$/ } readdir($dh);
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

	$self->send_response( $response );

}


sub send_file
{
    my($self, $file) = @_;
    my $opened = 0;
	my $client = ${*$self}{'io_client'};
	my $server = ${*$self}{'io_server'};

use RTP::Webmerge::Webserver::File;
my $fh = RTP::Webmerge::Webserver::File->new($client, $server);
print "go open $file\n";
$fh->open($file) || die $!;

die $server;
    local(*FILE);
    if (!ref($file)) {
	open(FILE, $file) || return undef;
	binmode(FILE);
	$file = \*FILE;
	$opened++;
    }
    my $cnt = 0;
    my $buf = "";
    my $n;
    while ($n = sysread($file, $buf, 8*1024)) {
	last if !$n;
	$cnt += $n;
	$self->print($buf);
    }
    close($file) if $opened;
    $cnt;
}
sub send_response
{
	my $self = shift;
	my $res = shift;
	if (!ref $res) {
		$res ||= RC_OK;
		$res = HTTP::Response->new($res, @_);
	}
	my $content = $res->content;
	my $chunked;
	unless ($self->antique_client)
	{
		my $code = $res->code;
		$self->send_basic_header($code, $res->message, $res->protocol);
		if ($code =~ /^(1\d\d|[23]04)$/) {
			# make sure content is empty
			$res->remove_header("Content-Length");
			$content = "";
		}
		elsif ($res->request && $res->request->method eq "HEAD") {
			# probably OK
		}
		elsif (ref($content) eq "CODE") {
			if ($self->proto_ge("HTTP/1.1")) {
				$res->push_header("Transfer-Encoding" => "chunked");
				$chunked++;
			}
			else {
				$self->force_last_request;
			}
		}
		elsif (length($content)) {
			$res->header("Content-Length" => length($content));
		}
		else {
			$self->force_last_request;
			$res->header('connection','close');
		}
		$self->print($res->headers_as_string($CRLF));
		$self->print($CRLF);  # separates headers and content
	}

	if ($self->head_request) {
		# no content
	}
	elsif (ref($content) eq "CODE") {
		while (1) {

			my $chunk = &$content();
			last unless defined($chunk) && length($chunk);
			if ($chunked) {
				$self->printf("%x%s%s%s", length($chunk), $CRLF, $chunk, $CRLF);
			}
			else {
				$self->print($chunk);
			}
		}
		$self->print("0$CRLF$CRLF") if $chunked;  # no trailers either
	}
	elsif (length $content) {
		$self->print($content);
	}
}


sub daemon
{
	my $self = shift;
	${*$self}{'io_server'};
}

sub _http_version
{
    local($_) = shift;
    return 0 unless m,^(?:HTTP/)?(\d+)\.(\d+)$,i;
    $1 * 1000 + $2;
}

sub antique_client
{
    my $self = shift;
    ${*$self}{'io_client'}->{'proto'} < $HTTP_1_0;
}

sub force_last_request
{
    my $self = shift;
    ${*$self}{'httpd_nomore'}++;
}
sub proto_ge
{
    my $self = shift;
    ${*$self}{'httpd_client_proto'} >= _http_version(shift);
}
sub send_status_line
{
    my($self, $status, $message, $proto) = @_;
    return if $self->antique_client;
    $status  ||= RC_OK;
    $message ||= status_message($status) || "";
    $proto   ||= $HTTP::Daemon::PROTO || "HTTP/1.1";
    $self->print("$proto $status $message$CRLF");
}
sub send_basic_header
{
    my $self = shift;
    return if $self->antique_client;
    $self->send_status_line(@_);
    $self->print("Date: ", time2str(time), $CRLF);
    my $product = $self->product_tokens;
    $self->print("Server: $product$CRLF") if $product;
}
sub product_tokens
{
    "libwww-perl-daemon/0.00";
}
sub head_request
{
    my $self = shift;
    ${*$self}{'httpd_head'};
}
###################################################################################################
###################################################################################################
1;
