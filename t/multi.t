#============================================================= -*-perl-*-
#
# t/multi.t
#
# Template script testing multiple directives per tag.
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# TODO: this should test the binary comparison and boolean operators
#    more thoroughly, including parenthesised sub-expressions, etc.
#
# $Id: multi.t,v 1.2 1999/08/10 11:09:16 abw Exp $
#
#========================================================================

use strict;
use lib qw( . ./t ../lib );
use vars qw( $DEBUG );
require 'texpect.pl';
$^W = 1;

$DEBUG = 0;

my ($a, $b, $c, $d, $r, $s) = qw( alpha bravo charlie delta romeo sierra );
my $params = {
    'a'      => $a,
    'b'      => $b,
    'c'      => $c,
    'd'      => $d,
    'r'      => $r,
    's'      => $s,
    'ten'    => 10,
    'twenty' => 20,
    'zero'   => 0,
    'true'   => 1,
    'false'  => '',
};

test_expect(\*DATA, { POST_CHOMP => 1 }, $params);

__DATA__
[% r; r = s; "-"; r %].
-- expect --
romeo-sierra.

-- test --
[% IF a; b; ELSIF c; d; ELSE; s; END %]
-- expect --
bravo

-- test --
[% "* $item\n" FOREACH item = [ c b a ] %]
-- expect --
* charlie
* bravo
* alpha

