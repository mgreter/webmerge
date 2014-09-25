package OCBNET::Plack::App::SHTML;
use strict;
use parent qw(Plack::Middleware);
use Plack::Util::Accessor qw(agent);

sub call {
	my($self, $env) = @_;
	warn "shtml";
	$self->app->($env);
};

1;