#============================================================= -*-Perl-*-
#
# t/vars.t
#
# Template script testing variable use.
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: vars.t,v 1.3 1999/08/01 13:43:22 abw Exp $
#
#========================================================================

use strict;
use lib qw( . ./t ../lib );
use vars qw( $DEBUG );
use Template::Constants qw( :status );
use Template;
require 'texpect.pl';
$^W = 1;

$DEBUG = 0;

# sample data
my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j, $k, $l, $m, 
    $n, $o, $p, $q, $r, $s, $t, $u, $v, $w, $x, $y, $z) = 
	qw( alpha bravo charlie delta echo foxtrot golf hotel india 
	    juliet kilo lima mike november oscar papa quebec romeo 
	    sierra tango umbrella victor whisky x-ray yankee zulu );

my $params = { 
    'a' => $a,
    'b' => $b,
    'c' => $c,
    'd' => $d,
    'e' => $e,
    'f' => {
	'g' => $g,
	'h' => $h,
	'i' => {
	    'j' => $j,
	    'k' => $k,
	},
    },
    'l' => $l,
    "letter$a" => "'$a'",
};

my $tproc = Template->new({ INTERPOLATE => 1 });
test_expect(\*DATA, $tproc, $params);


__DATA__
[% a %]
[% $a %]
-- expect --
alpha
alpha
-- test --
[% b %] [% $b %]
-- expect --
bravo bravo
-- test --
$a $b ${c} ${d} [% $e %]
-- expect --
alpha bravo charlie delta echo
-- test --
[% letteralpha %]
[% ${"letter$a"} %]
-- expect --
'alpha'
'alpha'
-- test --
[% f.g %] [% $f.g %] $f.h ${f.g} ${f.h}.gif
-- expect --
golf golf hotel golf hotel.gif
-- test --
[% f.i.j %] [% $f.i.j %] $f.i.k [% $f.${'i'}.${"j"} %] ${f.i.k}.gif
-- expect --
juliet juliet kilo juliet kilo.gif


