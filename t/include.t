#============================================================= -*-Perl-*-
#
# t/include.t
#
# Template script testing the INCLUDE directive.
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# TODO: This is old code which is incomplete and possibly innaccurate.
#   Note, in particular, that INCLUDE params must be quoted, e.g.
#   [% INCLUDE 'header' %].  This is a bit tricky, but it *must* be 
#   fixed ASAP.  Apart from this inconvenience, INCLUDE seems to work OK.
#
# $Id: include.t,v 1.6 1999/08/01 13:43:18 abw Exp $
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
    'c' => {
	'd' => $d,
	'e' => $e,
	'f' => {
	    'g' => $g,
	    'h' => $h,
	},
    },
    'r'    => $r,
    's'	   => $s,
    't'    => $t,
};

my $tproc = Template->new({ 
    INTERPOLATE => 1,
    INCLUDE_PATH => 't/misc:misc'
});
test_expect(\*DATA, $tproc, $params);

__DATA__
[% a %]
[% BLOCK first_block -%]
this is my first block, a is set to '[% a %]'
[%- END -%]
[% BLOCK second_block; DEFAULT b = 99, m = 98 -%]
this is my second block, a is initially set to '[% a %]' and 
then set to [% a = $s %]'[% $a %]'  b is $b  m is $m
[%- END -%]
[% b %]
-- expect --
alpha
bravo

-- test --
[% INCLUDE 'first_block' %]
-- expect --
this is my first block, a is set to 'alpha'

-- test --
[% INCLUDE first_block a = 'abstract' %]
[% a %]
-- expect --
this is my first block, a is set to 'abstract'
alpha

-- test --
[% INCLUDE 'first_block' a = $t %]
[% a %]
-- expect --
this is my first block, a is set to 'tango'
alpha

-- test --
[% INCLUDE 'second_block' %]
-- expect --
this is my second block, a is initially set to 'alpha' and 
then set to 'sierra'  b is bravo  m is 98

-- test --
[% INCLUDE 'second_block' a = $r, b = c.f.g, m = 97 %]
[% a %]
-- expect --
this is my second block, a is initially set to 'romeo' and 
then set to 'sierra'  b is golf  m is 97
alpha

-- test --
FOO: [% INCLUDE foo.txt -%]
FOO: [% INCLUDE foo.txt a = b -%]
-- expect --
FOO: This is foo.txt  a is alpha
FOO: This is foo.txt  a is bravo

-- test --
GOLF: [% INCLUDE $c.f.g %]
GOLF: [% INCLUDE $c.f.g  g = c.f.h %]
[% DEFAULT g = "a new $c.f.g" -%]
[% g %]
-- expect --
GOLF: This is the golf file, g is golf
GOLF: This is the golf file, g is hotel
a new golf

-- test --
BAR: [% INCLUDE other/bar %]
BAR: [% INCLUDE other/bar word='wizzle' %]
BAR: [% INCLUDE "other/bar" %]
-- expect --
BAR: This is file bar
The word is 'qux'
BAR: This is file bar
The word is 'wizzle'
BAR: This is file bar
The word is 'qux'

-- test --
BAZ: [% INCLUDE other/baz.txt %]
BAZ: [% INCLUDE other/baz.txt time = 'nigh' %]
-- expect --
BAZ: This is file baz
The time is now
BAZ: This is file baz
The time is nigh
