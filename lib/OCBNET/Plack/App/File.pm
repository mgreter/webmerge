package OCBNET::Plack::App::File;
use parent qw(Plack::App::File);

use strict;
use warnings;

use OCBNET::Plack::Filter::SHTML;

my @handlers = (
	[qr{^(?:text/|application/s?h?tml?\z)}, 'OCBNET::Plack::Filter::SHTML']
);

sub call
{

	my ($self, $env) = @_;

	return $self->response_cb($self->SUPER::call($env), sub
	{

		my $res = shift;
		my $headers = Plack::Util::headers($res->[1]);
		my $content_type = $headers->get('Content-Type') || '';

		foreach my $handler (@handlers)
		{
			if ($content_type =~ m/$handler->[0]/)
			{ return $handler->[1]->new($self, $env) }
		}

		# do nothing
		return;

	});

}

1;