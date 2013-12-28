# render urls into base
sub render22
{

	# get instance
	my ($self, $parent, $paths) = @_;

	# get the config hash
	my $config = $self->{'config'};

	$paths = [ @{$paths} ] if $paths;

# set base according to config and self suffix (scss => pwd, css => parent)

	# get base argument from args
	# can be set to undef explicitly
#	$base = scalar(@_) > 1 ? $base :
#	        dirname($self->{'path'});

	my $base = '.';

	# rebase urls?
	$base = dirname($self->{'path'}) if $config->{'rebase-urls-in-css'} && $self->{'suffix'} eq 'css';
	$base = dirname($self->{'path'}) if $config->{'rebase-urls-in-scss'} && $self->{'suffix'} eq 'scss';


print "))))) base: $base\n";

	# enable rebase if option for specific file suffix is set
	push @{$paths}, '.' if $config->{'rebase-urls-in-css'} && $self->{'suffix'} eq 'css';
	push @{$paths}, '.' if $config->{'rebase-urls-in-scss'} && $self->{'suffix'} eq 'scss';
	push @{$paths}, dirname($self->{'path'}) if $config->{'rebase-urls-in-css'} && $self->{'suffix'} eq 'css';
	push @{$paths}, dirname($self->{'path'}) if $config->{'rebase-urls-in-scss'} && $self->{'suffix'} eq 'scss';

	push @{$paths}, '.';
	push @{$paths}, dirname($self->{'path'});

	# set rebase to undef to disable
	# stops touching any url occurences
	# $base = undef unless $rebase;

	# get raw data for css
	my $data = ${$self->raw};

	# change current working directory so we are able
	# to find further includes relative to the directory
	# defaults to current stylesheet if not explicitly undef
	# not rebasing to any other path => just rebase to current
	my $dir = RTP::Webmerge::Path->chdir(defined $base ? $base : '.');

	$dir = RTP::Webmerge::Path->chdir(dirname($self->{'path'})) if $config->{'rebase-urls-in-css'} && $self->{'suffix'} eq 'css';
	$dir = RTP::Webmerge::Path->chdir(dirname($self->{'path'})) if $config->{'rebase-urls-in-scss'} && $self->{'suffix'} eq 'scss';

print "render $base\n ", $directory, " - ", $self->{'path'}, " = $paths\n";

	# no specific import paths are given
	# try to load from current base directory
	$paths = [ $directory ] unless $paths;

		# file search sub
		my $resolve = sub
		{
			my ($name, $paths) = @_;
			# loop search paths
			$paths = [ @{$paths} ] if $paths;

			foreach my $root (@{$paths})
			{
				print "look in $root\n";
				# search for alternative names for sass partials
				# the order may not be 100% correct, need more tests
				# this adds some undocumented behaviour, dont abuse it
				foreach my $srch ('%s', '_%s.scss', '_%s', '%s.scss')
				{
					print "tst: ", catfile($root, sprintf($srch, $name)), "\n";
					if (-e catfile($root, sprintf($srch, $name)))
					{
						print "found: ", catfile($root, sprintf($srch, $name)), "\n";
						 use Cwd 'abs_path';
						return abs_path(catfile($root, sprintf($srch, $name))); }
				}
			}
			# EO each path
		};
		# EO sub $resolve

		# file search sub
		my $searchfor = sub
		{
			my ($file, $paths, $tmplts) = @_;
			# '%s', '_%s.scss', '_%s', '%s.scss'

			$paths = [ @{$paths} ] if $paths;

			my ($name, $path) = fileparse($file);

			# if path is absolute, it must be loaded from given path
			if ( $path =~ m /^(?:\/|[a-zA-Z]:)/ ) { $paths = [ $path ] }
			# add file path to all import search paths
			else { @{$paths} = map { $_ .= '/' . $path } @{$paths}; }

# print "searchfor $file\n";

			# loop search paths
			foreach my $root (@{$paths})
			{
				# print "2look in $root\n";
				# search for alternative names for sass partials
				# the order may not be 100% correct, need more tests
				# this adds some undocumented behaviour, dont abuse it
				foreach my $srch (@{$tmplts || ['%s']})
				{
					# print "2tst: ", catfile($root, sprintf($srch, $name)), "\n";
					if (-e catfile($root, sprintf($srch, $name)))
					{
						print "2found: ", catfile($root, sprintf($srch, $name)), "\n";
						return rel2abs(catfile($root, sprintf($srch, $name))); }
				}
			}
			# EO each path
		};
		# EO sub $resolve

	# import all relative urls to absolute paths
	$data =~ s/$re_url/

	print $self->{"path"}, "\n";
	print $base, "\n";
#	print "dadadad3: ", $searchfor->($1, $paths), "\n";
	#print "dadadad9: ", join(", ", @{$paths}), "\n";

my $uri = $1;

	unshift @{$paths}, $base if $self->{'suffix'} eq 'css';
	unshift @{$paths}, ${$dir} if $self->{'suffix'} eq 'scss';

my $inp = $searchfor->($1, $paths);

print "INPPPP: $inp\n";

	#asdasdasdasd
	if ( isabs($inp) ) { wrapURL($inp) }
	else {
		die "nono" unless $base;
		wrapURL(importURI($inp, $base)) }

	;

	/egm if defined $base;

	# add current directory if loading
	# NEEDED

	# if scss we also need to import from pwd

	# process imports
	my $importer = sub
	{
print "do @{$paths} ", ${$dir}, "\n";

		# store full match
		my $matched = $1;

		my $paths = [ @{$paths} ];

		# create tmpl with whitespace
		my $tmpl = '@import %s' . $7;

		# get from the various styles
		# either wrapped in url or string
		my $wrapped = $defined->($2, $3, $4);
		my $partial = $defined->($5, $6);
		my $import = $partial || $wrapped;

		# parse path and filename first (and also the suffix)
print "5\n";
		my ($name, $path, $suffix) = fileparse($partial || $wrapped, 'scss');
print "6\n";

		# remove possible dot from filename
		# undef suffix if no suffix is found
		$suffix = undef unless $name =~ s/\.$//;

		# if path is absolute, it must be loaded from given path
		if ( $path =~ m /^(?:\/|[a-zA-Z]:)/ ) { $paths = [ $path ] }
		# add file path to all import search paths
		else { @{$paths} = map { $_ .= '/' . $path } @{$paths}; }

		# resolve actual file to be imported
		# scss partial can be imported from pwd
		my $cssfile = $resolve->($name, $paths);
print "togo : $cssfile\n";
		# parse again, suffix may has changed (should be quite cheap)
		($name, $path, $suffix) = fileparse($cssfile, 'scss', 'css');
print "togo2 : $cssfile\n";

		# store value to object
		$self->{'name'} = $name;
		$self->{'suffix'} = $suffix;
		$self->{'directory'} = $path;

		my $wrap = 0;
		my $rbase = 0;
		my $include = 0;
		my $rebase = 0;
		my $rewrite = 0;

		if ($suffix eq 'scss')
		{
			$include = $wrapped ? $config->{'embed-scss-imports'} : $config->{'embed-scss-partials'};
			$wrap = $wrapped ? $config->{'import-wrap-scss-url'} : $config->{'import-wrap-scss-plain'};
			$rbase = $wrapped ? $config->{'rebase-scss-imports'} : $config->{'rebase-scss-partials'};
			$rebase = $wrapped ? $config->{'rebase-urls-in-scss-imports'} : $config->{'rebase-urls-in-scss-partials'};
			$rewrite = $wrapped ? $config->{'rewrite-urls-in-scss-imports'} : $config->{'rewrite-urls-in-scss-partials'};
		}
		else
		{
			$include = $wrapped ? $config->{'embed-css-imports'} : $config->{'embed-css-partials'};
			$wrap = $wrapped ? $config->{'import-wrap-css-url'} : $config->{'import-wrap-css-plain'};
			$rbase = $wrapped ? $config->{'rebase-css-imports'} : $config->{'rebase-css-partials'};
			$rebase = $wrapped ? $config->{'rebase-urls-in-css-imports'} : $config->{'rebase-urls-in-css-partials'};
			$rewrite = $wrapped ? $config->{'rewrite-urls-in-css-imports'} : $config->{'rewrite-urls-in-css-partials'};
		}


		if ($include)
		{

			# load the referenced stylesheet (don't parse yet)
			my $css = RTP::Webmerge::Input::CSS->new($cssfile, $config);

			# rebase all urls in imported stylesheet to the last base directory
			my $dir = $rebase ? RTP::Webmerge::Path->chdir(dirname($css->{'path'})) : $dir;

print "embed from $$dir\n";
print "embed now $cssfile\n";

			# render scss relative to old base
			return ${$css->render([
				'.',
				${$dir},
				dirname($css->{'path'}),
				dirname($self->{'path'}),
#				$parent ? dirname($parent->{'path'}) : '.',
			]
			)};

		}
		else
		{

			$import = exportURI(importURI($import)) if ($rbase);
 			die "import resolve error" unless $import;
			return sprintf $tmpl, wrapURL($import) if ($wrap);
			return sprintf $tmpl, '"' . $import . '"';


		}

		return $matched;

	};

	# process each import statement in data
	$data =~ s/

		(\@import\s+$re_import)

	/

		$importer->();

	/gmex;

	# export all absolute paths to relative urls again
	$data =~ s/$re_url/
	print "exp: \"$1\" $base\n";
	print "==== ", dirname($parent->{'path'}), "\n" if $parent;

my $match = $1;

my $out = $searchfor->($match, $paths);

# print "OUTPU: $out ($match, ", join(";", @{$paths}), ")\n";

# die "out error" unless $out;
	#asdasdasdasd
#	if ( isabs($inp) ) { wrapURL($inp) }
#	else { wrapURL(importURI($inp, $base)) }

$base = dirname(${$dir});

	wrapURL(exportURI($match, $base))

	/egm if defined $base;

	# return cached copy of data
	return \ $data;

}