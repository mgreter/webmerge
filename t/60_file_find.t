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

use Test::More tests => 44;

################################################################################
# load necessary modules
################################################################################

BEGIN { use_ok('OCBNET::File::Find') };
BEGIN { use_ok('File::Spec::Functions') };

################################################################################
use File::Spec::Functions qw(rel2abs abs2rel);
################################################################################
use File::Path qw(make_path remove_tree);
################################################################################

my @result;

is ((-d 't/copy' ? remove_tree('t/copy') && 1 : 1), 1, "remove copy tree");

@result = find 'src/js/bootstrap.*';
is scalar(@result), 2, "correct number of results";
is canonpath($result[0]), rel2abs('t/src/js/bootstrap.page.js'), "correct result[0]";
is canonpath($result[1]), rel2abs('t/src/js/bootstrap.widget.js'), "correct result[1]";

@result = find 'src/js/bootstrap.page.js', 'cb' => sub {
	is canonpath($_), canonpath('t/src/js/bootstrap.page.js'), "correct callback arguments";
	is abs2rel($_[0]),  canonpath('t/src/js/bootstrap.page.js'), "correct callback arguments";
};
is scalar(@result), 1, "correct number of results (callback)";
is canonpath($result[0]), rel2abs('t/src/js/bootstrap.page.js'), "correct result[0] (callback)";

@result = find 'src/js/bootstrap.*', 'rel' => 1;
is scalar(@result), 2, "correct number of results (relative)";
is canonpath($result[0]), canonpath('t/src/js/bootstrap.page.js'), "correct result[0] (relative)";
is canonpath($result[1]), canonpath('t/src/js/bootstrap.widget.js'), "correct result[1] (relative)";

chdir 't';

	@result = find 'src/js/bootstrap.*', 'rel' => 1;
	is scalar(@result), 2, "correct number of results (chdir)";
	is canonpath($result[0]), canonpath('src/js/bootstrap.page.js'), "correct result[0] (chdir)";
	is canonpath($result[1]), canonpath('src/js/bootstrap.widget.js'), "correct result[1] (chdir)";

	@result = find 't/src/js/bootstrap.*', 'rel' => 1;
	is scalar(@result), 0, "no results found for outside match";

chdir '..';

@result = find '*.css', 'base' => 't/src/css/50-widgets';
is scalar(@result), 3, "correct number of results (base)";
is abs2rel($result[0]), canonpath('t/src/css/50-widgets/10-slider.css'), "correct result[0] (base)";
is abs2rel($result[1]), canonpath('t/src/css/50-widgets/10-slider/10-layout.css'), "correct result[1] (base)";
is abs2rel($result[2]), canonpath('t/src/css/50-widgets/10-slider/30-buttons.css'), "correct result[2] (base)";

@result = find '*.css', 'rel' => 1, 'base' => 't/src/css/50-widgets';
is scalar(@result), 3, "correct number of results (relative|base)";
is canonpath($result[0]), canonpath('t/src/css/50-widgets/10-slider.css'), "correct result[0] (relative|base)";
is canonpath($result[1]), canonpath('t/src/css/50-widgets/10-slider/10-layout.css'), "correct result[1] (relative|base)";
is canonpath($result[2]), canonpath('t/src/css/50-widgets/10-slider/30-buttons.css'), "correct result[2] (relative|base)";

@result = find '*.css', 'base' => 't/src/css/50-widgets', 'maxdepth' => undef;
is scalar(@result), 3, "correct number of results (maxdepth=>undef)";
is abs2rel($result[0]), canonpath('t/src/css/50-widgets/10-slider.css'), "correct result[0] (maxdepth=>undef)";
is abs2rel($result[1]), canonpath('t/src/css/50-widgets/10-slider/10-layout.css'), "correct result[1] (maxdepth=>undef)";
is abs2rel($result[2]), canonpath('t/src/css/50-widgets/10-slider/30-buttons.css'), "correct result[2] (maxdepth=>undef)";

@result = find '*.css', 'base' => 't/src/css/50-widgets', 'maxdepth' => 0;
is scalar(@result), 1, "correct number of results (maxdepth=>undef)";
is abs2rel($result[0]), canonpath('t/src/css/50-widgets/10-slider.css'), "correct result[0] (maxdepth=>undef)";

@result = find '*.css', 'base' => 't/src/css/50-widgets', 'maxdepth' => 1;
is scalar(@result), 3, "correct number of results (maxdepth=>1)";
is abs2rel($result[0]), canonpath('t/src/css/50-widgets/10-slider.css'), "correct result[0] (maxdepth=>1)";
is abs2rel($result[1]), canonpath('t/src/css/50-widgets/10-slider/10-layout.css'), "correct result[1] (maxdepth=>1)";
is abs2rel($result[2]), canonpath('t/src/css/50-widgets/10-slider/30-buttons.css'), "correct result[2] (maxdepth=>1)";

@result = find '*.css', 'rel' => 1, 'base' => 't/src/css/50-widgets', 'maxdepth' => 2;
is scalar(@result), 3, "correct number of results (rel|maxdepth=>2)";
is canonpath($result[0]), canonpath('t/src/css/50-widgets/10-slider.css'), "correct result[0] (rel|maxdepth=>2)";
is canonpath($result[1]), canonpath('t/src/css/50-widgets/10-slider/10-layout.css'), "correct result[1] (rel|maxdepth=>2)";
is canonpath($result[2]), canonpath('t/src/css/50-widgets/10-slider/30-buttons.css'), "correct result[2] (rel|maxdepth=>2)";

@result = find 'src/js/bootstrap.*.js', filter => sub { ! /^(?:[A-Z]\:|\/)/ };
is scalar(@result), 0, "correct number of results (filter)";
@result = find 'src/js/bootstrap.*.js', 'rel' => 1, filter => sub { ! /^t/ };
is scalar(@result), 0, "correct number of results (rel|filter)";
@result = find '*.css', 'base' => 't/src/css/50-widgets', filter => sub { ! /^(?:[A-Z]\:[\\\/]|\/)/ };
is scalar(@result), 0, "correct number of results (base|filter)";
@result = find '*.css', 'rel' => 1, 'base' => 't/src/css/50-widgets', filter => sub { ! /^t/ };
is scalar(@result), 0, "correct number of results (base|rel|filter)";

################################################################################

is ((-d 't/copy' ? remove_tree('t/copy') && 1 : 1), 1, "remove copy tree");

################################################################################
done_testing;
################################################################################
