#============================================================= -*-Perl-*-
#
# t/set.t
#
# Template script testing the GET directive.
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: set.t,v 1.3 1999/08/01 13:43:20 abw Exp $
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
    'r' => $r,
    's' => $s,
    't' => $t,
    "letter$a" => "'$a'",
    'join'  => sub { join(shift, @_) },
    'split' => sub { my $s = shift; $s = quotemeta($s); 
		     my @r = split(/$s/, shift); \@r },
    'magic' => {
	'chant' => 'Hocus Pocus',
	'spell' => sub { join(" and a bit of ", @_) },
    }, 
};



my $tproc = Template->new({ INTERPOLATE => 1 });
test_expect(\*DATA, $tproc, $params);


__DATA__
[% a = a %] $a
[% a = b %] $a
[% a = $c %] $a
[% $a = d %] $a
[% $a = $e %] $a
-- expect --
 alpha
 bravo
 charlie
 delta
 echo

-- test --
[% a = f.g %] $a
[% a = $f.h %] $a
[% a = f.i.j %] $a
[% a = $f.i.k %] $a
-- expect --
 golf
 hotel
 juliet
 kilo

-- test --
[% f.g = r %] $f.g
[% $f.h = $r %] $f.h
[% f.i.j = $s %] $f.i.j
[% $f.i.k = f.i.j %] ${f.i.k}
-- expect --
 romeo
 romeo
 sierra
 sierra

