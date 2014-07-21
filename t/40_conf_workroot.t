# -*- perl -*-
################################################################################
################################################################################

use strict;
use warnings;

################################################################################
use Test::More tests => 67;
################################################################################
BEGIN { use_ok('OCBNET::Webmerge::CmdOption') };
################################################################################
my $webmerge = OCBNET::Webmerge::CmdOption->new;
################################################################################

my (%longopts, @ids);

################################################################################

$webmerge->parse({ 'configfile' => 't/conf/t-01.conf.xml' }, \@ids);

ok       $webmerge->getById('outer'),                                                    'find outer by id';
ok       $webmerge->getById('inner'),                                                    'find inner by id';

isa_ok   $webmerge->getById('outer'),            'OCBNET::Webmerge::XML::Tree::Scope',   'outer is Webmerge::XML::Tree::Scope';
isa_ok   $webmerge->getById('outer'),            'OCBNET::Webmerge::XML::Tree::Node',    'outer is OCBNET::Webmerge::XML::Tree::Node';
isa_ok   $webmerge->getById('outer'),            'OCBNET::Webmerge::Tree::Scope',        'outer is OCBNET::Webmerge::Tree::Scope';
isa_ok   $webmerge->getById('outer'),            'OCBNET::Webmerge::Tree::Node',         'outer is OCBNET::Webmerge::Tree::Node';
isa_ok   $webmerge->getById('outer'),            'OCBNET::Webmerge::Object',             'outer is OCBNET::Webmerge::Object';

isa_ok   $webmerge->getById('inner'),            'OCBNET::Webmerge::XML::Tree::Scope',   'inner is Webmerge::XML::Tree::Scope';
isa_ok   $webmerge->getById('inner'),            'OCBNET::Webmerge::XML::Tree::Node',    'inner is OCBNET::Webmerge::XML::Tree::Node';
isa_ok   $webmerge->getById('inner'),            'OCBNET::Webmerge::Tree::Scope',        'inner is OCBNET::Webmerge::Tree::Scope';
isa_ok   $webmerge->getById('inner'),            'OCBNET::Webmerge::Tree::Node',         'inner is OCBNET::Webmerge::Tree::Node';
isa_ok   $webmerge->getById('inner'),            'OCBNET::Webmerge::Object',             'inner is OCBNET::Webmerge::Object';

isa_ok   $webmerge->getById('outer'),            'HASH',                                 'inner is HASH';
isa_ok   $webmerge->getById('inner'),            'HASH',                                 'inner is HASH';

is       $webmerge->getById('outer')->id,        'outer',                                'outer id is correct';
is       $webmerge->getById('inner')->id,        'inner',                                'inner id is correct';

################################################################################
use File::Spec::Functions qw(rel2abs);
################################################################################

my $outer = $webmerge->getById('outer');
my $inner = $webmerge->getById('inner');

is       $outer->workdir,                       'src/js',                                'outer workdir is correct';
is       $inner->workdir,                       'jquery',                                'inner workdir is correct';
is       $outer->basedir,                       'src/js',                                'outer workroot is correct';
is       $inner->basedir,                       'jquery',                                'inner workroot is correct';
is       $outer->webdir,                        'src/js',                                'outer workdir is correct';
is       $inner->webdir,                        'jquery',                                'inner workdir is correct';
is       $outer->confdir,                       undef,                                   'outer workdir is correct';
is       $inner->confdir,                       undef,                                   'inner workdir is correct';
is       $outer->incdir,                        undef,                                   'outer workdir is correct';
is       $inner->incdir,                        undef,                                   'inner workdir is correct';


is       $outer->workroot,                      rel2abs('t/src/js'),                     'outer workroot is correct';
is       $inner->workroot,                      rel2abs('t/src/js/jquery'),              'inner workroot is correct';
is       $outer->baseroot,                      rel2abs('t/src/js'),                     'outer workroot is correct';
is       $inner->baseroot,                      rel2abs('t/src/js/jquery'),              'inner workroot is correct';
is       $outer->webroot,                       rel2abs('t/src/js'),                     'outer workroot is correct';
is       $inner->webroot,                       rel2abs('t/src/js/jquery'),              'inner workroot is correct';
is       $outer->confroot,                      rel2abs('t/conf'),                       'outer workroot is correct';
is       $inner->confroot,                      rel2abs('t/conf'),                       'inner workroot is correct';
is       $outer->incroot,                       rel2abs('t/conf'),                       'outer workroot is correct';
is       $inner->incroot,                       rel2abs('t/conf'),                       'inner workroot is correct';
is       $outer->binroot,                       rel2abs('t'),                            'outer workroot is correct';
is       $inner->binroot,                       rel2abs('t'),                            'inner workroot is correct';
is       $outer->extroot,                       rel2abs('.'),                            'outer workroot is correct';
is       $inner->extroot,                       rel2abs('.'),                            'inner workroot is correct';

################################################################################

my $rv = $webmerge->run;

################################################################################
# test css imports and correct context settings
################################################################################

my $css = $webmerge->getById('css');

ok       $css,                                                                           'find css block by id';

my @css_ins = $css->find('input');

is       $#css_ins,                             5,                                       'parsed correct amount of inputs';

my @css_incs = $css_ins[4]->find('file');

is       $#css_incs,                            0,                                       'parsed correct amount of import files';

my $css_inc_1 = $css_incs[0];

my @css_subincs = $css_inc_1->find('file');

is       $#css_subincs,                         1,                                       'parsed correct amount of import files';

my $css_subinc_1 = $css_subincs[0];
my $css_subinc_2 = $css_subincs[1];

################################################################################

is       $css_inc_1->baseroot,         rel2abs('t/src/css/50-widgets'),                  'test css import[0] baseroot';
is       $css_inc_1->confroot,         rel2abs('t/conf'),                                'test css import[0] confroot';
is       $css_inc_1->incroot,          rel2abs('t/conf'),                                'test css import[0] incroot';
is       $css_inc_1->workroot,         rel2abs('t'),                                     'test css import[0] workroot';
is       $css_inc_1->webroot,          rel2abs('t'),                                     'test css import[0] webroot';
is       $css_inc_1->binroot,          rel2abs('t'),                                     'test css import[0] binroot';
is       $css_inc_1->extroot,          rel2abs('.'),                                     'test css import[0] workroot';

is       $css_subinc_1->baseroot,      rel2abs('t/src/css/50-widgets/10-slider'),        'test css import[0][0] baseroot';
is       $css_subinc_1->confroot,      rel2abs('t/conf'),                                'test css import[0][0] confroot';
is       $css_subinc_1->incroot,       rel2abs('t/conf'),                                'test css import[0][0] incroot';
is       $css_subinc_1->workroot,      rel2abs('t'),                                     'test css import[0][0] workroot';
is       $css_subinc_1->webroot,       rel2abs('t'),                                     'test css import[0][0] webroot';
is       $css_subinc_1->binroot,       rel2abs('t'),                                     'test css import[0][0] binroot';
is       $css_subinc_1->extroot,       rel2abs('.'),                                     'test css import[0][0] workroot';

is       $css_subinc_2->baseroot,      rel2abs('t/src/css/50-widgets/10-slider'),        'test css import[0][1] baseroot';
is       $css_subinc_2->confroot,      rel2abs('t/conf'),                                'test css import[0][1] confroot';
is       $css_subinc_2->incroot,       rel2abs('t/conf'),                                'test css import[0][1] incroot';
is       $css_subinc_2->workroot,      rel2abs('t'),                                     'test css import[0][1] workroot';
is       $css_subinc_2->webroot,       rel2abs('t'),                                     'test css import[0][1] webroot';
is       $css_subinc_2->binroot,       rel2abs('t'),                                     'test css import[0][1] binroot';
is       $css_subinc_2->extroot,       rel2abs('.'),                                     'test css import[0][1] workroot';

################################################################################

my $js = $webmerge->getById('js');

ok       $js,                                                                            'find js block by id';

################################################################################
done_testing;
################################################################################
