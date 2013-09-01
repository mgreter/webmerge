#!/usr/bin/perl

use strict;
use warnings;

###################################################################################################
package RTP::Webmerge::Embeder::PHP;
###################################################################################################

# define our version string
BEGIN { $RTP::Webmerge::Embeder::PHP::VERSION = "0.70" }

###################################################################################################

# use module to dump php data
use Data::Dump::PHP qw(dump_php);

# load our local modules
use RTP::Webmerge::IO;

# end of line in code
use constant EOL => "\n";

###################################################################################################

sub is_enabled ($)
{
	return 0 unless (defined $_[0]);
	return 1 if (lc $_[0] eq 'true');
	return 1 if (lc $_[0] eq 'enabled');
	return 0;
}

sub embeder
{

	# get variables and collections from parent
	my ($domains, $features, $detects, $config) = @_;

	# create switcher code
	my $switcher = '';

	# process all header detect entries
	foreach my $detect (@{$detects || [] })
	{

		# get options for this detection
		my $target = $detect->{'target'};
		my $enabled = $detect->{'enabled'};
		my $disabled = $detect->{'disabled'};

		unless ( defined $detect->{'feature'} )
		{ die 'detect without feature id found'; }

		my $id = $detect->{'feature'};
		my $feature = $features->{$id};

		unless ($feature || is_enabled($detect->{'optional'}))
		{ die "feature detection <$id> not available"; }

		$switcher .= '		' . '	// default feature setting' . EOL;
		$switcher .= '		' . '$enabled = NULL;' . EOL;

		# process all header detect entries
		foreach my $test (@{$feature->{'test'} || [] })
		{

			my $types = lc $test->{'type'};

			foreach my $type (split(/\s*,\s*/, $types))
			{

				my $var;

				unless (defined $type) { $var = '$_SERVER'; }
				elsif ($type eq 'env') { $var = '$_ENV'; }
				elsif ($type eq 'get') { $var = '$_GET'; }
				elsif ($type eq 'post') { $var = '$_POST'; }
				elsif ($type eq 'server') { $var = '$_SERVER'; }
				elsif ($type eq 'cookie') { $var = '$_COOKIE'; }
				elsif ($type eq 'session') { $var = '$_SESSION'; }
				elsif ($type eq 'request') { $var = '$_REQUEST'; }
				else { die "Fatal: unknown test type <$type>"; }

				my ($enabled, $disabled) = ('true', 'false');

				if (exists $test->{'enable'} && scalar(@{$test->{'enable'}}))
				{
					$enabled = 'preg_match(\'/^(?:'
						. join( '|', @{$test->{'enable'}} )
						. ')$/\', ' . $var . '[\'' . $test->{'key'} . '\'])';
				}

				if (exists $test->{'disable'} && scalar(@{$test->{'disable'}}))
				{
					$disabled = 'preg_match(\'/^(?:'
						. join( '|', @{$test->{'disable'}} )
						. ')$/\', ' . $var . '[\'' . $test->{'key'} . '\'])';
				}

				$switcher .= EOL;
				$switcher .= '		' . '	// sniff for useragent' . EOL;
				$switcher .= '		' . 'if (array_key_exists(\'' . $test->{'key'} . '\', ' . $var . ')) {' . EOL;
				$switcher .= '			' . '$enabled = ( $enabled || ( ' . $enabled . ' )) && ! ' . $disabled . ';' . EOL;
				$switcher .= '		' . '}' . EOL;

			}

		}

		$switcher .= EOL;
		$switcher .= '		' . '	// change ' . $target . ' if feature is enabled' . EOL;
		$switcher .= '		' . 'if ($enabled === TRUE) { $' . $target .' = \'' . $enabled . '\'; }'. EOL if (defined $enabled);
		$switcher .= '		' . 'if ($enabled === FALSE) { $' . $target .' = \'' . $disabled . '\'; }'. EOL if (defined $disabled);

	};
	# EO each detect

	# load the template (readfile will resolve path)
	my $tmpl = readfile($config->{'tmpl-embed-php'});

	# create data for template
	my %data =
	(
		'switcher' => $switcher,
		'includes' => dump_php($domains),
	);

	# insert data into loaded template
	${$tmpl} =~ s/%%([a-z]+)%%/$data{$1}/eg;

	# return tmpl pointer
	return $tmpl;

}
# EO sub embeder

###################################################################################################

# register this embeder type to parent module
RTP::Webmerge::Embeder::register('php', \&embeder);

###################################################################################################
###################################################################################################
1;