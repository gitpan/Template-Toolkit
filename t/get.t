#============================================================= -*-perl-*-
#
# t/get.t
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
# $Id: get.t,v 1.5 1999/11/25 17:51:24 abw Exp $
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
[% a %]
[% $a %]
[% GET b %]
[% GET $b %]
[% get c %]
[% get $c %]
-- expect --
alpha
alpha
bravo
bravo
charlie
charlie

-- test --
[% b %] [% $b %] [% GET b %] [% GET $b %]
-- expect --
bravo bravo bravo bravo

-- test --
$a $b ${c} ${d} [% $e %]
-- expect --
alpha bravo charlie delta echo

-- test --
[% letteralpha %]
[% ${"letter$a"} %]
[% GET ${"letter$a"} %]
-- expect --
'alpha'
'alpha'
'alpha'

-- test --
[% f.g %] [% $f.g %] [% GET f.h %] [% get $f.h %] [% get $f.${'h'} %]
-- expect --
golf golf hotel hotel hotel

-- test --
[% f.i.j %] [% GET $f.i.j %]
-- expect --
juliet juliet

-- test --
[% get $f.i.k %]
-- expect --
kilo

-- test --
[% $f.${'i'}.${"j"} %]
${f.i.k}.gif
-- expect --
juliet
kilo.gif

-- test --
[% 'this is literal text' %]
[% GET 'so is this' %]
[% "this is interpolated text containing $r and $f.i.j" %]
[% GET "$t?" %]
[% "<a href=\"${f.i.k}.html\">$f.i.k</a>" %]

-- expect --
this is literal text
so is this
this is interpolated text containing romeo and juliet
tango?
<a href="kilo.html">kilo</a>

-- test --
[% join('--', a b, c, f.i.j) %]
-- expect --
alpha--bravo--charlie--juliet

-- test --
[% text = 'The cat sat on the mat' -%]
[% FOREACH word = split(' ', text) -%]<$word> [% END %]
-- expect --
<The> <cat> <sat> <on> <the> <mat> 

-- test -- 
[% magic.chant %] [% GET magic.chant %]
[% magic.chant('foo') %] [% GET $magic.chant('foo') %]
-- expect --
Hocus Pocus Hocus Pocus
Hocus Pocus Hocus Pocus

-- test -- 
<<[% magic.spell %]>>
[% magic.spell(a b c) %]
-- expect --
<<>>
alpha and a bit of bravo and a bit of charlie

