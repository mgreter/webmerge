# -*- perl -*-
################################################################################
# test basic file copy modes
################################################################################

use strict;
use warnings;
use lib 'lib';

################################################################################
# define number of tests to be run
################################################################################

use Test::More tests => 39;

################################################################################
# load necessary modules
################################################################################

BEGIN { use_ok('OCBNET::File::Find') };
BEGIN { use_ok('OCBNET::File::Copy') };

################################################################################

# control arrays
my ($rcount, @read) = (0);
my ($wcount, @write) = (0);

# control functions to test if read/write is called correctly
sub read { is ($_[0], shift(@read), sprintf("correct input path (%s)", ++ $rcount)) }
sub write { is ($_[0], shift(@write), sprintf("correct output path (%s)", ++ $wcount)) }

################################################################################

my %options = ('read' => \&read, 'write' => \&write);
my %rename = ('rename' => [ qr/\.[A-Z]+$/i, sub { '.ext' } ]);

################################################################################
use File::Spec::Functions qw(rel2abs canonpath catfile);
################################################################################

push @read, rel2abs 't\src\js\bootstrap.page.js';
push @read, rel2abs 't\src\js\bootstrap.widget.js';
push @read, rel2abs 't\src\js\jquery\jquery-1.11.1.js';

push @write, catfile(rel2abs('.'), ('t\copy\t\src\js\bootstrap.page.js'));
push @write, catfile(rel2abs('.'), ('t\copy\t\src\js\bootstrap.widget.js'));
push @write, catfile(rel2abs('.'), ('t\copy\t\src\js\jquery\jquery-1.11.1.js'));

xcopy([ sort(find('*.js', 'base' => 't/src/js')) ], 't/copy', %options);

################################################################################

push @read, rel2abs 't\src\js\bootstrap.page.js';
push @read, rel2abs 't\src\js\bootstrap.widget.js';
push @read, rel2abs 't\src\js\jquery\jquery-1.11.1.js';

push @write, catfile(rel2abs('.'), ('t\copy\t\src\js\bootstrap.page.ext'));
push @write, catfile(rel2abs('.'), ('t\copy\t\src\js\bootstrap.widget.ext'));
push @write, catfile(rel2abs('.'), ('t\copy\t\src\js\jquery\jquery-1.11.1.ext'));

xcopy([ sort(find('*.js', 'base' => 't/src/js' )) ], 't/copy', %options, %rename);

################################################################################
use File::Path qw(make_path remove_tree);
################################################################################

my @result;

xcopy([ sort(find('*.js', 'base' => 't/src/js' )) ], 't/copy');
@result = find 'src/js/bootstrap.*', 'rel' => 1;
is scalar(@result), 4, "correct number of results (relative)";
is canonpath($result[0]), canonpath('t/copy/t/src/js/bootstrap.page.js'), "correct result[0] (copy|relative)";
is canonpath($result[1]), canonpath('t/copy/t/src/js/bootstrap.widget.js'), "correct result[1] (copy|relative)";
is canonpath($result[2]), canonpath('t/src/js/bootstrap.page.js'), "correct result[2] (relative)";
is canonpath($result[3]), canonpath('t/src/js/bootstrap.widget.js'), "correct result[3] (relative)";
is ((-d 't/copy' ? remove_tree('t/copy') && 1 : 1), 1, "remove copy tree");

xcopy([ sort(find('src', 'base' => 't', 'rel' => 1, 'maxdepth' => 0 )) ], 't/copy', 'recursive' => 0);
@result = find 'src/js/*.js', 'rel' => 1;
is scalar(@result), 3, "correct number of results (relative)";
is canonpath($result[0]), canonpath('t/src/js/bootstrap.page.js'), "correct result[0] (relative|depth=>0|recursive=>1)";
is canonpath($result[1]), canonpath('t/src/js/bootstrap.widget.js'), "correct result[1] (relative|depth=>0|recursive=>1)";
is canonpath($result[2]), canonpath('t/src/js\jquery\jquery-1.11.1.js'), "correct result[2] (relative|depth=>0|recursive=>1)";
is ((-d 't/copy' ? remove_tree('t/copy') && 1 : 1), 1, "remove copy tree");

xcopy([ sort(find('src', 'base' => 't', 'rel' => 1, 'maxdepth' => 0 )) ], 't/copy', 'recursive' => 1);
@result = find 'src/js/*.js', 'rel' => 1;
is scalar(@result), 5, "correct number of results (relative)";
is canonpath($result[0]), canonpath('t/copy/t/src/js/bootstrap.page.js'), "correct result[0] (copy|relative|depth=>0|recursive=>1)";
is canonpath($result[1]), canonpath('t/copy/t/src/js/bootstrap.widget.js'), "correct result[1] (copy|relative|depth=>0|recursive=>1)";
is canonpath($result[2]), canonpath('t/src/js/bootstrap.page.js'), "correct result[2] (relative|depth=>0|recursive=>1)";
is canonpath($result[3]), canonpath('t/src/js/bootstrap.widget.js'), "correct result[3] (relative|depth=>0|recursive=>1)";
is canonpath($result[4]), canonpath('t\src\js\jquery\jquery-1.11.1.js'), "correct result[4] (relative|depth=>0|recursive=>1)";
is ((-d 't/copy' ? remove_tree('t/copy') && 1 : 1), 1, "remove copy tree");

xcopy([ sort(find('*', 'base' => 't/src/js', 'rel' => 1, 'maxdepth' => 0 )) ], 't/copy', 'recursive' => -1);
@result = find 'src/js/bootstrap.*', 'rel' => 1;
is scalar(@result), 4, "correct number of results (relative)";
is canonpath($result[0]), canonpath('t/copy/t/src/js/bootstrap.page.js'), "correct result[0] (copy|relative)";
is canonpath($result[1]), canonpath('t/copy/t/src/js/bootstrap.widget.js'), "correct result[1] (copy|relative)";
is canonpath($result[2]), canonpath('t/src/js/bootstrap.page.js'), "correct result[2] (relative)";
is canonpath($result[3]), canonpath('t/src/js/bootstrap.widget.js'), "correct result[3] (relative)";
is ((-d 't/copy' ? remove_tree('t/copy') && 1 : 1), 1, "remove copy tree");

################################################################################
# test some error behaviour
################################################################################

{
	local $SIG{__WARN__} = sub {};
	eval { xcopy([ sort(find('*', 'base' => 't/src/js' )) ], '../..', 'chroot' => '.'); };
	like $@, qr/error/, "access out of chroot results in error";
}

################################################################################
done_testing;
################################################################################
