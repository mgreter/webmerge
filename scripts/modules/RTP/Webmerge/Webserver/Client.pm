###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
###################################################################################################
package RTP::Webmerge::Webserver::Client;
###################################################################################################

use Carp;
use strict;
use warnings;

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

sub newXX
{

	my ($pkg, $client, $server, @args) = @_;
die $client;
	${*$client}{'io_client'} = {
		'state' => 0, 'rbuf' => '', 'wbuf' => ''
	};
	${*$client}{'io_server'} = $server;

	bless $client, $pkg;

	return $client;

}

my @readers;


$readers[0] = sub
{

	my ($sock) = @_;

	my $client = ${*$sock}{'io_client'};
	my $server = ${*$sock}{'io_server'};

	my $buf = $client->{'rbuf'};

	# ignore leading blank lines
	$client->{'rbuf'} =~ s/^(?:\015?\012)+//;

	# potential, has at least one line
	if ($client->{'rbuf'} =~ /\012/)
	{
		if ($client->{'rbuf'} =~ /^\w+[^\012]+HTTP\/\d+\.\d+\015?\012/)
		{
			if ($client->{'rbuf'} =~ /\015?\012\015?\012/)
			{
				# print "reader 0 -> 1\n";
				return 1;
			}
			elsif (length($client->{'rbuf'}) > 16*1024)
			{
				die "REQUEST_ENTITY_TOO_LARGE";
				$sock->send_error(413);
				$sock->reason("Very long header");
				return -1;
			}
		}
		else
		{
			# HTTP/0.9 client
# print "reader 0 -> 1\n";
			return 1;
		}
	}
	elsif (length($client->{'rbuf'}) > 16*1024)
	{
		die "REQUEST_URI_TOO_LARGE";
		$sock->send_error(414);
		$sock->reason("Very long first line");
		return -1;
	}

	return 0;

};
use URI;
use HTTP::Request;
$HTTP::URI_CLASS = "URI";
$readers[1] = sub
{

	my ($sock) = @_;

	my $client = ${*$sock}{'io_client'};
	my $server = ${*$sock}{'io_server'};

	if ($client->{'rbuf'} !~ s/^(\S+)[ \t]+(\S+)(?:[ \t]+(HTTP\/\d+\.\d+))?[^\012]*\012//)
	{
		die "BAD_REQUEST ", $client->{'rbuf'};
		${*$sock}{'httpd_client_proto'} = _http_version("HTTP/1.0");
		$sock->send_error(400);  # BAD_REQUEST
		$sock->reason("Bad request line: " . $client->{'rbuf'});
		return -1;
	}

	$client->{'method'} = $1;
	$client->{'uri'} = $2;
	$client->{'proto'} = $3 || "HTTP/0.9";

	$client->{'uri'} = "http://" . $client->{'uri'} if $client->{'method'} eq "CONNECT";
	$client->{'uri'} = $HTTP::URI_CLASS->new($client->{'uri'}); #, $sock->daemon->url);
	$client->{'request'} = HTTP::Request->new($client->{'method'}, $client->{'uri'});

	$client->{'request'}->protocol($client->{'proto'});

	${*$sock}{'httpd_client_proto'} = $client->{'proto'} = _http_version($client->{'proto'});
	${*$sock}{'httpd_head'} = ($client->{'method'} eq "HEAD");

	return 1;

};

$readers[2] = sub
{

	my ($sock) = @_;

	my $client = ${*$sock}{'io_client'};
	my $server = ${*$sock}{'io_server'};

	my $buf = \ $client->{'rbuf'};
	my $req = $client->{'request'};
	my $proto = $client->{'proto'};

	if ($proto >= $HTTP_1_0) {

		# print "hi $buf\n";
		# we expect to find some headers
		my($key, $val);

		while ($client->{'rbuf'} =~ s/^([^\012]*)\012//) {
			my $data = $1;
			$data =~ s/\015$//;
			if ($data =~ /^([^:\s]+)\s*:\s*(.*)/)
			{
				# print "push header $key $val\n" if $key;
				$req->push_header($key, $val) if $key;
				($key, $val) = ($1, $2);
			}
			elsif ($data =~ /^\s+(.*)/)
			{
				$val .= " $1";
			}
			else
			{
				last;
			}
		}
		#print "push header $key $val\n" if $key;
		$req->push_header($key, $val) if $key;
	}

	return 1;

};

sub client
{

	my ($sock) = @_;

	return ${*$sock}{'io_client'};

}

$readers[3] = sub
{

	my ($sock) = @_;

	my $client = ${*$sock}{'io_client'};
	my $server = ${*$sock}{'io_server'};

	my $buf = $client->{'rbuf'};
	my $req = $client->{'request'};
	my $proto = $client->{'proto'};

	my $conn = $req->header('Connection');
	# print "CONN $conn\n";
	if ($proto >= $HTTP_1_1) {
		# ${*$self}{'httpd_nomore'}++
		die "close 1" if $conn && lc($conn) =~ /\bclose\b/;
	}
	else {
		# ${*$self}{'httpd_nomore'}++
		die "close 2" unless $conn &&
		                                       lc($conn) =~ /\bkeep-alive\b/;
	}

 # Find out how much content to read
	#my $te  = $req->header('Transfer-Encoding');
	#my $ct  = $req->header('Content-Type');
	#my $len = $req->header('Content-Length');

	#print "$te $ct $len\n";

	return 1;

};

$readers[4] = sub
{

	my ($sock) = @_;

	my $client = ${*$sock}{'io_client'};
	my $server = ${*$sock}{'io_server'};

	my $buf = $client->{'rbuf'};
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
		print "CHUNKED\n";
		# Handle chunked transfer encoding
		my $body = "";
		CHUNK:
		while (1) {
			print STDERR "Chunked\n" if $DEBUG;
			if ($client->{'rbuf'} =~ s/^([^\012]*)\012//) {
				my $chunk_head = $1;
				unless ($chunk_head =~ /^([0-9A-Fa-f]+)/) {
					$self->send_error(400);
					$self->reason("Bad chunk header $chunk_head");
					return;
				}
				my $size = hex($1);
				last CHUNK if $size == 0;
				my $missing = $size - length($client->{'rbuf'}) + 2; # 2=CRLF at chunk end
				# must read until we have a complete chunk
				while ($missing > 0) {
					print STDERR "Need $missing more bytes\n" if $DEBUG;
					return 0;
					# my $n = $self->_need_more($client->{'rbuf'}, $timeout, $fdset);
					# return unless $n;
					# $missing -= $n;
				}
				$body .= substr($client->{'rbuf'}, 0, $size);
				substr($client->{'rbuf'}, 0, $size+2) = '';
			}
			else {
				# need more data in order to have a complete chunk header
				return 0;
				# return unless $self->_need_more($client->{'rbuf'}, $timeout, $fdset);
			}
		}
		$r->content($body);

		# pretend it was a normal entity body
		$r->remove_header('Transfer-Encoding');
		$r->header('Content-Length', length($body));

		my($key, $val);
		while (1) {
			if ($client->{'rbuf'} !~ /\012/) {
				# need at least one line to look at
				return 0;
				# return unless $self->_need_more($client->{'rbuf'}, $timeout, $fdset);
			}
			else {
				$client->{'rbuf'} =~ s/^([^\012]*)\012//;
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
print "foobar\n";
		$self->send_error(501); 	# Unknown transfer encoding
		$self->reason("Unknown transfer encoding '$te'");
		return;
	}
	elsif ($len) {
		# Plain body specified by "Content-Length"
		my $missing = $len - length($client->{'rbuf'});
		print "plain upload $len\n";
		while ($missing > 0) {
			print "Need $missing more bytes of content\n" if $DEBUG;
			return 0;
			# my $n = $self->_need_more($client->{'rbuf'}, $timeout, $fdset);
			# return unless $n;
			# $missing -= $n;
		}
		if (length($client->{'rbuf'}) > $len) {
			$r->content(substr($client->{'rbuf'},0,$len));
			substr($client->{'rbuf'}, 0, $len) = '';
		}
		else {
			$r->content($client->{'rbuf'});
			$client->{'rbuf'}='';
		}
	}
#	elsif ($ct && $ct =~ m/^multipart\/\w+\s*;.*boundary\s*=\s*(\"?)(\w+)\1/i) {
	elsif ($ct && $ct =~ m/^multipart\/(?:\w|-)+\s*;.*boundary\s*=\s*(?:\"((?:\w|-)+)\"|((?:\w|-)+))/i) {
		# print "multipart upload \"$1\" $2\n";
		# Handle multipart content type
		my $boundary = "--" . ($1 || $2) . "--";
		my $index;
		while (1) {
			# print "reading ", length($client->{'rbuf'}), "\n";
			$index = index($client->{'rbuf'}, $boundary);
			# print "search for $boundary ==> $index\n", $client->{'rbuf'}, "\n";
			# die "last" if $index >= 0;
			last if $index >= 0;
			# end marker not yet found
			return 0;
			# return unless $self->_need_more($client->{'rbuf'}, $timeout, $fdset);
		}
		# print "im out of this?\n";
		$index += length($boundary);
		$r->content(substr($client->{'rbuf'}, 0, $index));
		substr($client->{'rbuf'}, 0, $index) = '';
	}
	else
	{
		# no upload at all
		# print "damn\n";
	}
	${*$self}{'httpd_rbuf'} = $client->{'rbuf'};

	return 1;
};

sub canRead
{

	my ($sock) = @_;

	my $client = ${*$sock}{'io_client'};
	my $server = ${*$sock}{'io_server'};

#	print "client can read now ", length($client->{'rbuf'}), "\n";

	my $rv = sysread($sock, $client->{'rbuf'}, 1024 * 16, length($client->{'rbuf'}));

# 	print "client has readed now $rv -> ", length($client->{'rbuf'}), "\n";
# print $client->{'rbuf'}, "\n";
	$server->captureRead($sock);

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
	while (1)
	{
# print "readers $client->{'state'}\n";

		last unless $readers[$client->{'state'}];

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
if ( $client->{'state'} >= 5)
{

	# now we have the request
	my $req = $client->{'request'};
use HTTP::Response;
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
				if (-d $file && -e join('/', $file, 'index.html'))
				{ $file = join('/', $file, 'index.html'); }

				if (-e $file)
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

#	$response->content( "Hello World" );
#	$response->header( "Content-Type" => "text/html" );

#	$sock->send_response( $response );

#	die $req;


	# if $rv eq -1

}

sub canWrite
{

	# print "client can write\n";

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
        print $self "Content-Type: text/html$CRLF";
	print $self "Content-Length: " . length($mess) . $CRLF;
        print $self $CRLF;
    }
    print $self $mess unless $self->head_request;
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
	local(*F);
	sysopen(F, $file, 0) or
	  return $self->send_error(RC_FORBIDDEN);
	binmode(F);
	my($ct,$ce) = guess_media_type($file);
	my($size,$mtime) = (stat _)[7,9];
	unless ($self->antique_client) {
	    $self->send_basic_header;
	    print $self "Content-Type: $ct$CRLF";
	    print $self "Content-Encoding: $ce$CRLF" if $ce;
	    print $self "Content-Length: $size$CRLF" if $size;
	    print $self "Last-Modified: ", time2str($mtime), "$CRLF" if $mtime;
	    print $self $CRLF;
	}
	$self->send_file(\*F) unless $self->head_request;
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
    $self->send_error(RC_NOT_IMPLEMENTED);
}


sub send_file
{
    my($self, $file) = @_;
    my $opened = 0;
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
	print $self $buf;
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
		print $self $res->headers_as_string($CRLF);
		print $self $CRLF;  # separates headers and content
	}
	if ($self->head_request) {
		# no content
	}
	elsif (ref($content) eq "CODE") {
		while (1) {
			my $chunk = &$content();
			last unless defined($chunk) && length($chunk);
			if ($chunked) {
				printf $self "%x%s%s%s", length($chunk), $CRLF, $chunk, $CRLF;
			}
			else {
				print $self $chunk;
			}
		}
		print $self "0$CRLF$CRLF" if $chunked;  # no trailers either
	}
	elsif (length $content) {
		print $self $content;
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

sub send_status_line
{
    my($self, $status, $message, $proto) = @_;
    return if $self->antique_client;
    $status  ||= RC_OK;
    $message ||= status_message($status) || "";
    $proto   ||= $HTTP::Daemon::PROTO || "HTTP/1.1";
    print $self "$proto $status $message$CRLF";
}
sub send_basic_header
{
    my $self = shift;
    return if $self->antique_client;
    $self->send_status_line(@_);
    print $self "Date: ", time2str(time), $CRLF;
    my $product = $self->product_tokens;
    print $self "Server: $product$CRLF" if $product;
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
