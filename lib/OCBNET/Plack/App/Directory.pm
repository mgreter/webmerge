package OCBNET::Plack::App::Directory;
use parent qw(OCBNET::Plack::App::File);

use strict;
use warnings;

sub call {

	my $rv = [200, [], ["asd"]];

	my($self, $env) = @_;

	foreach my $root (@{$self->{'roots'}})
	{
		$self->{'root'} = $root;
		$env->{'DOCUMENT_ROOT'} = $root;
		$rv = $self->SUPER::call($env);
		last if $rv->[0] eq 200;
	}

	return $rv;

};

use Plack::Util;
use HTTP::Date;
use Plack::MIME;
use DirHandle;
use URI::Escape;
use List::MoreUtils qw(uniq);

# Stolen from rack/directory.rb
my $dir_file = "<tr><td class='name'><a href='%s'>%s</a></td><td class='size'>%s</td><td class='type'>%s</td><td class='mtime'>%s</td></tr>";
my $dir_page = <<PAGE;
<html><head>
  <title>%s</title>
  <meta http-equiv="content-type" content="text/html; charset=utf-8" />
  <style type='text/css'>
table { width:100%%; }
.name { text-align:left; }
.size, .mtime { text-align:right; }
.type { width:11em; }
.mtime { width:15em; }
  </style>
</head><body>
<h1>%s</h1>
<hr />
<table>
  <tr>
    <th class='name'>Name</th>
    <th class='size'>Size</th>
    <th class='type'>Type</th>
    <th class='mtime'>Last Modified</th>
  </tr>
%s
</table>
<hr />
</body></html>
PAGE

sub should_handle {
    my($self, $file) = @_;
    return -d $file || -f $file;
}

sub return_dir_redirect {
    my ($self, $env) = @_;
    my $uri = Plack::Request->new($env)->uri;
    return [ 301,
        [
            'Location' => $uri . '/',
            'Content-Type' => 'text/plain',
            'Content-Length' => 8,
        ],
        [ 'Redirect' ],
    ];
}
sub serve_path {
    my($self, $env, $dir, $fullpath) = @_;

    if (-f $dir) {
        return $self->SUPER::serve_path($env, $dir, $fullpath);
    }

    my $dir_url = $env->{SCRIPT_NAME} . $env->{PATH_INFO};

    if ($dir_url !~ m{/$}) {
        return $self->return_dir_redirect($env);
    }

    my %children;

    my @files = ([ "../", "Parent Directory", '', '', '' ]);

foreach my $root (@{$self->{'roots'}})
{
    my $dh = DirHandle->new($root);

    next unless defined $dh;
    while (defined(my $ent = $dh->read)) {
        next if $ent eq '.' or $ent eq '..';
        next if exists $children{$ent};
        $children{$ent} = $root;
    }

}

    for my $basename (sort { $a cmp $b } keys %children) {
        my $file = join "/", $children{$basename}, $basename;
        my $url = $dir_url . $basename;

        my $is_dir = -d $file;
        my @stat = stat _;

        $url = join '/', map {uri_escape($_)} split m{/}, $url;

        if ($is_dir) {
            $basename .= "/";
            $url      .= "/";
        }

        my $mime_type = $is_dir ? 'directory' : ( Plack::MIME->mime_type($file) || 'text/plain' );
        push @files, [ $url, $basename, $stat[7], $mime_type, HTTP::Date::time2str($stat[9]) ];
    }

    my $path  = Plack::Util::encode_html("Index of $env->{PATH_INFO}");
    my $files = join "\n", map {
        my $f = $_;
        sprintf $dir_file, map Plack::Util::encode_html($_), @$f;
    } @files;
    my $page  = sprintf $dir_page, $path, $path, $files;

    return [ 200, ['Content-Type' => 'text/html; charset=utf-8'], [ $page ] ];
}
1;