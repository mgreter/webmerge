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
my $smap9 = OCBNET::SourceMap->new;

my $smap1 = OCBNET::SourceMap->new;
$smap1->init(my $data1 = 'var abc = Math.random();'."\n", 'input1.js');
my $smap2 = OCBNET::SourceMap->new;
$smap2->init(my $data2 = '    var foo = Math.random();', 'input2.js');

open (my $fhinp1, ">", 'input1.js'); print $fhinp1 $data1;
open (my $fhinp2, ">", 'input2.js'); print $fhinp2 $data2;


$smap2->mixin([0,0],[0,0],$smap1);

substr($data2, 0, 0, $data1);

my $file = bless {}, 'TEST';

my ($data, $srcmap) = OCBNET::Webmerge::Plugin::JS::Compile::process($file, \ $data2);

$smap->read($srcmap);

$smap->remap($smap2);


my ($data9, $srcmap9) = OCBNET::Webmerge::Plugin::JS::Compile::process($file, $data);

$smap9->read($srcmap9);

$smap9->remap($smap);


print Data::Dumper::Dumper($smap9);

open (my $fhdebug, ">", 'debug.html');
print $fhdebug debugger($data9, $smap9);

open (my $fhoutput, ">", 'output.js');
open (my $fhsrcmap, ">", 'output.js.map');

print $fhoutput ${$data9};
print $fhsrcmap $smap9->render;

print $fhoutput "\n\n//\# sourceMappingURL=output.js.map\n";


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