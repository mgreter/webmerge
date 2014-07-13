# -*- perl -*-
################################################################################
# test basic tree/node model
################################################################################

use strict;
use warnings;
use lib 'lib';

################################################################################
# define number of tests to be run
################################################################################

use Test::More tests => 31;

################################################################################
# load necessary modules
################################################################################

BEGIN { use_ok('OCBNET::Webmerge::Tree::Node') };
BEGIN { use_ok('OCBNET::Webmerge::Tree::Root') };
BEGIN { use_ok('OCBNET::Webmerge::Tree::Scope') };

################################################################################
# create some fake dom object "html style" programatically
################################################################################

my $html = OCBNET::Webmerge::Tree::Root->new; $html->{'tag'} = 'html';
my $head = OCBNET::Webmerge::Tree::Node->new; $head->{'tag'} = 'head';
my $body = OCBNET::Webmerge::Tree::Node->new; $body->{'tag'} = 'body';
my $table = OCBNET::Webmerge::Tree::Node->new; $table->{'tag'} = 'table';
my $tr1 = OCBNET::Webmerge::Tree::Node->new; $tr1->{'tag'} = 'tr';
my $td1a = OCBNET::Webmerge::Tree::Node->new; $td1a->{'tag'} = 'td';
my $td1b = OCBNET::Webmerge::Tree::Node->new; $td1b->{'tag'} = 'td';
my $tr2 = OCBNET::Webmerge::Tree::Node->new; $tr2->{'tag'} = 'tr';
my $td2a = OCBNET::Webmerge::Tree::Node->new; $td2a->{'tag'} = 'td';
my $td2b = OCBNET::Webmerge::Tree::Node->new; $td2b->{'tag'} = 'td';

################################################################################
# test basic node setup
################################################################################

is $html->tag, 'html', 'html tag set correctly';
is $head->tag, 'head', 'head tag set correctly';
is $body->tag, 'body', 'body tag set correctly';
is $table->tag, 'table', 'table tag set correctly';
is $tr1->tag, 'tr', 'tr1 tag set correctly';
is $td1a->tag, 'td', 'td1a tag set correctly';
is $td1b->tag, 'td', 'td1b tag set correctly';
is $tr2->tag, 'tr', 'tr2 tag set correctly';
is $td2a->tag, 'td', 'td2a tag set correctly';
is $td2b->tag, 'td', 'td2b tag set correctly';

################################################################################
# test node append functionality
################################################################################

# setup base tree
$html->append(
	$head,
	$body->append(
		$table->append(
			$tr1->append($td1a, $td1b),
			$tr2->append($td2a, $td2b)
		)
	)
);

# attach tree to documents
# should recieve add/remove events to
# handle dom collections (by tag name)
$html->document->{'children'} = [ $html ];

################################################################################
# test xpath query functionality
################################################################################

is $html->xpath("/")->tag, '[DOC]', 'xpath root from html is document';
is $table->xpath("/")->tag, '[DOC]', 'xpath root from table is document';
is $html->xpath("/../")->tag, '[DOC]', 'xpath /../ is document';
is $html->xpath("../..")->tag, '[DOC]', 'xpath ../.. is document';
is $html->xpath("/../html")->tag, 'html', 'xpath /../html is html';
is $body->xpath(".")->tag, 'body', 'xpath . from body is body';
is $html->xpath("/html")->tag, 'html', 'xpath html from html is html';
is $table->xpath("/html")->tag, 'html', 'xpath html from table is html';
is $html->xpath("/html")->tag, 'html', 'xpath html from html is html';
is $html->xpath("/html/body")->tag, 'body', 'xpath /html/body from html is body';
is $html->xpath("body")->tag, 'body', 'xpath body from html is body';
is $html->xpath("body/..")->tag, 'html', 'xpath body/.. from html is html';
is $html->xpath("body/../")->tag, 'html', 'xpath body/../ from html is html';
is $table->xpath("../.")->tag, 'body', 'xpath ../. from table is body';
is $table->xpath(".././")->tag, 'body', 'xpath .././ from table is body';
is $table->xpath("tr[0]/td[1]")->tag, 'td', 'xpath tr[0]/td[1] from table is td';
is scalar @{[$table->xpath("tr[0]/td")]}, 2, 'xpath tr[0]/td has two results';

################################################################################
# test node delete functionality
################################################################################

$head->delete; $body->delete;

is scalar @{$html->{'children'}}, 0, 'delete works correctly';

################################################################################
done_testing;
################################################################################
