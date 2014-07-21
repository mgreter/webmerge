use 5.008;
use strict;
use warnings FATAL => 'all';
use Module::Build;
use Config;

if (-d ".git") { # Are we in our development tree? If so, create MANIFEST.
    my ($dir, $manifest);
    open $manifest, ">", "MANIFEST" or die "MANIFEST: $!";
    # print $manifest "MANIFEST\n";
    my @dir = `git ls-files` or die "Couldn't run git: $!";
    print $manifest $_, "\n" foreach grep { s/(?:\A\s*|\s*\z)//g } @dir;
}



my $builder = Module::Build->new(
    module_name         => 'OCBNET::Webmerge',
    license             => 'perl',
    dist_author         => q{Marcel Greter <marcel.greter@ocbnet.ch>},
    dist_abstract       => q{Frontend Asset Manager (CSS/JS/HTML)},
    dist_version_from   => 'lib/OCBNET/Webmerge.pm',
    release_status      => 'stable',
    create_license      => 1,
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Class::Accessor::Fast' => 0,
    },
    meta_merge => {
      resources => {
        repository  => 'https://github.com/mgreter/webmerge',
      },
    },
    add_to_cleanup     => [ 'OCBNET-Webmerge-*' ],
);

$builder->create_build_script();
