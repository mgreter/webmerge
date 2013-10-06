###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
###################################################################################################
package RTP::Webmerge::Embedder::JS;
###################################################################################################

use Carp;
use strict;
use warnings;

###################################################################################################

# define our version string
BEGIN { $RTP::Webmerge::Embedder::JS::VERSION = "0.70" }

###################################################################################################

# use module to dump js data
use JSON qw(to_json);

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

sub embedder
{

	# get variables and collections from parent
	my ($domains, $contents, $features, $detects, $config) = @_;

	# create switcher code
	my $switcher = '';

	# process all header detect entries
	foreach my $detect (@{$detects || [] })
	{

		# get options for this detection
		my $target = $detect->{'target'};
		my $enabled = $detect->{'enabled'};
		my $disabled = $detect->{'disabled'};

		# class is a reserved keyword in js
		$target = 'klass' if $target eq 'class';

		unless ( defined $detect->{'feature'} )
		{ die 'detect without feature id found'; }

		my $id = $detect->{'feature'};
		my $feature = $features->{$id};

		unless ($feature || is_enabled($detect->{'optional'}))
		{ die "feature detection <$id> not available"; }

		$switcher .= '		' . '// default feature setting' . EOL;
		$switcher .= '		' . 'var enabled = null;' . EOL;

		# process all header detect entries
		foreach my $test (@{$feature->{'test'} || [] })
		{

			my $types = lc $test->{'type'};

			foreach my $type (split(/\s*,\s*/, $types))
			{

				my $var;

				unless (defined $type) { $var = 'webmerge.SERVER'; }
				elsif ($type eq 'env') { $var = 'webmerge.ENV'; }
				elsif ($type eq 'get') { $var = 'webmerge.GET'; }
				elsif ($type eq 'post') { $var = 'webmerge.POST'; }
				elsif ($type eq 'server') { $var = 'webmerge.SERVER'; }
				elsif ($type eq 'cookie') { $var = 'webmerge.COOKIE'; }
				elsif ($type eq 'session') { $var = 'webmerge.SESSION'; }
				elsif ($type eq 'request') { $var = 'webmerge.REQUEST'; }
				else { die "Fatal: unknown test type <$type>"; }

				my ($enabled, $disabled) = ('true', 'false');

				$switcher .=  EOL;
				$switcher .= "		// make sure the variable exists" . EOL;
				$switcher .= "		if (typeof $var == 'undefined') $var = {};" . EOL;

				if (exists $test->{'enable'} && scalar(@{$test->{'enable'}}))
				{
					$enabled = '(' . $var . '[\'' . $test->{'key'} . '\'] || \'\').' .
						'match(/^(?:' . join( '|', @{$test->{'enable'}} ) . ')$/)';
				}

				if (exists $test->{'disable'} && scalar(@{$test->{'disable'}}))
				{
					$disabled = '(' . $var . '[\'' . $test->{'key'} . '\'] || \'\').' .
						'match(/^(?:' . join( '|', @{$test->{'disable'}} ) . ')$/)';
				}

				$switcher .= EOL;
				$switcher .= '		' . '	// sniff for useragent' . EOL;
				$switcher .= '		' . 'if (\'' . $test->{'key'} . '\' in ' . $var . ') {' . EOL;
				$switcher .= '			' . 'enabled = ( enabled || ( ' . $enabled . ' )) && ! ' . $disabled . ';' . EOL;
				$switcher .= '		' . '}' . EOL;

			}

		}

		$switcher .= EOL;
		$switcher .= '		' . '	// change ' . $target . ' if feature is enabled' . EOL;
		$switcher .= '		' . 'if (enabled === true) { ' . $target .' = \'' . $enabled . '\'; }'. EOL if (defined $enabled);
		$switcher .= '		' . 'if (enabled === false) { ' . $target .' = \'' . $disabled . '\'; }'. EOL if (defined $disabled);

	};
	# EO each detect

	# load the template (readfile will resolve path)
	my $tmpl = readfile($config->{'tmpl-embed-js'});

	# create data for template
	my %data =
	(
		'switcher' => $switcher,
		'includes' => to_json(
			$contents,
			{ pretty => 1 }
		),
	);

	# insert data into loaded template
	${$tmpl} =~ s/%%([a-z]+)%%/$data{$1}/eg;

	# return tmpl pointer
	return $tmpl;

}
# EO sub embedder

###################################################################################################

# register this embedder type to parent module
RTP::Webmerge::Embedder::register('js', \&embedder);

###################################################################################################
###################################################################################################
1;