###################################################################################################
# Copyright 2013/2014 by Marcel Greter
# This file is part of OCBNET-SourceMap (GPL3)
####################################################################################################

use utf8;
use strict;
use warnings;

################################################################################
use File::Spec::Functions qw(rel2abs);
################################################################################

BEGIN
{
	# load find bin
	use FindBin qw($Bin);
	# add local  library path
	use lib rel2abs("./lib", $Bin);

	use lib 'D:\github\OCBNET-SourceMap\lib';
}

use OCBNET::Webmerge;
use OCBNET::SourceMap;

require OCBNET::Webmerge::Plugin::JS::Compile;

my $smap = OCBNET::SourceMap->new;

my $file = bless {}, 'TEST';

my $code = '(function() { var abc = Math.random(), xyz = Math.random(); if (abc || xyz) debugger; }())';
open (my $fhinput, ">", 'closure-input.js');
print $fhinput $code;

my ($data, $srcmap) = OCBNET::Webmerge::Plugin::JS::Compile::process($file, \ $code);

$smap->read($srcmap);

open (my $fhdebug, ">", 'debug.html');
open (my $fhoutput, ">", 'output.js');
open (my $fhsrcmap, ">", 'output.js.map');

print $fhoutput ${$data};
print $fhsrcmap $smap->render;

print $fhoutput "\n\n//\# sourceMappingURL=output.js.map\n";

use Data::Dumper;


use OCBNET::SourceMap::Utils qw(debugger);
print $fhdebug debugger(${$data}, $smap);

exit;



# die Dumper($smap);



exit;

die ${$data};

package TEST;

# load find bin
use FindBin qw($Bin);

sub respath
{
	join("/", $Bin, substr($_[1], 6))
}