#============================================================= -*-perl-*-
#
# t/stash.t
#
# Test script for Template::Stash.pm.
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use strict;
use lib qw( ../lib );
use Template::Constants qw( :status );
use Template;
use Template::Test;
$^W = 1;

$Template::Test::DEBUG = 0;

# sample data
my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j, $k, $l, $m, 
    $n, $o, $p, $q, $r, $s, $t, $u, $v, $w, $x, $y, $z) = 
	qw( alpha bravo charlie delta echo foxtrot golf hotel india 
	    juliet kilo lima mike november oscar papa quebec romeo 
	    sierra tango umbrella victor whisky x-ray yankee zulu );

my $data = { 
    a => $a,
    b => $b,
    c => {
	d => $d,
	e => $e,
	f => {
	    g => $g,
	    h => $h,
	},
    },
    i => $i,
};

test_expect(\*DATA, undef, $data);

__DATA__
[% a %]
[% b %]
[% c.d %]
[% c.e %]
[% c.f.g %]
[% c.f.h %]
[% i %]
-- expect --
alpha
bravo
delta
echo
golf
hotel
india

-- test --
[% j = 'juliet' -%]
%% k.l = 'lima'
   k.b = 'bean' 
   k.food = "$k.l $k.b" 
-%%
[% j %]
[% k.food %]
-- expect --
juliet
lima bean





