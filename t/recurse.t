#============================================================= -*-perl-*-
#
# t/recurse.t
#
# Template script testing recursion into template files/blocks.
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: recurse.t,v 1.1 1999/08/28 04:55:19 abw Exp $
#
#========================================================================

use strict;
use lib qw( . ./t ../lib );
use vars qw( $DEBUG );
use Template::Constants qw( :status );
use Template;
require 'texpect.pl';
$^W = 1;

$DEBUG = 1;

my $tree = { 
    name  => 'foo',
    items => [ 
	{ 
	    name  => 'bar',
	    items => [ { name => 'qux', items => [] } ],
	},
	{
	    name  => 'baz',
#	    items => [],
	},
    ],
};
my $params = {
    tree => $tree,
};
my $config = {
    INTERPOLATE => 1,
    POST_CHOMP  => 1,
    RECURSION   => 1,
};
test_expect(\*DATA, $config, $params);

__DATA__
[% CATCH undef %]<!-- undef: $e.info -->[% END %]
[% INCLUDE tree %]

[% BLOCK tree %]
Name: $tree.name
[% INCLUDE tree FOREACH tree = tree.items %]
[% END %]
-- expect --
Name: foo
Name: bar
Name: qux
Name: baz
