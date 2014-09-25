################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Plack::Filter::SHTML;
################################################################################

# helper function
sub new
{

	# get input arguments
	my($pkg, $self, $env) = @_;

	# create shtml processor
	my $cgi = CGI::SHTML->new;

	# content filter
	return sub {

		# check for valid chunk
		return unless defined $_[0];
		# re-create cgi environment
		local %ENV = (%ENV, %{$env});
		# call to parse fragments
		$cgi->{'_self'} = $self;
		$cgi->{'_env'} = $env;
		$cgi->parse_shtml_chunk($_[0]);

	};
	# EO content filter

}
# EO new

################################################################################
################################################################################
1;
