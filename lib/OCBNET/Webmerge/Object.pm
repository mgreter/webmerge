################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
# Every module that includes us will automatically get
# a constructor. So do not overwrite new yourself. The
# trick is to define a "initialize" method to do your
# initialization work. This method will automatically
# be called on all classes that an object is part of.
################################################################################
package OCBNET::Webmerge::Object;
################################################################################

use strict;
use warnings;

# sub setting { warn "called setting" }

################################################################################
# export our mixin methods
################################################################################

# load exporter and inherit from it
BEGIN { use Exporter qw(); our @ISA = qw(Exporter); }

# define our functions that will be exported
BEGIN { our @EXPORT = qw(new initialization); }

################################################################################
# return all decedent classes
################################################################################

my $decedents; $decedents = sub
{

	# enable symbolic refs
	no strict 'refs';
	# get decedents from given namespace
	my @ISA = @{sprintf "%s::ISA", $_[0]};
	# disable symbolic refs
	use strict 'refs';

	# return recursively resolved and ordered list
	(map { &{$decedents}($_) } reverse @ISA), $_[0];

};

################################################################################
# constructor for all classes
# used to implement anamorphism
# initialize is called on everybody
################################################################################
use List::MoreUtils qw();
################################################################################

sub new
{

	# get argument
	my $pkg = shift;

	# are we called from existing
	$pkg = ref $pkg if ref $pkg;

	# bless into package
	my $node = bless {}, $pkg;

	&{$_}($node, @_) foreach
		List::MoreUtils::uniq grep { ref $_ eq 'CODE' }
			map { $_->can('initialize') } &{$decedents}($pkg, @_);

	# return object
	return $node;

}

################################################################################
################################################################################
1;


