#============================================================= -*-perl-*-
#
# t/foreach.t
#
# Template script testing the FOREACH directive.
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: foreach.t,v 1.11 2000/02/17 12:15:31 abw Exp $
# 
#========================================================================

use strict;
use lib qw( ../lib );
use Template qw( :status );
use Template::Test;
$^W = 1;

$Template::Test::DEBUG = 0;

my ($a, $b, $c, $d, $l, $o, $r, $u, $w ) = 
	qw( alpha bravo charlie delta lima oscar romeo uncle whisky );
my @people  = ( { 'id' => 'abw', 'name' => 'Andy Wardley' },
                { 'id' => 'sam', 'name' => 'Simon Matthews' } );
my @seta    = ( $a, $b, $w );
my @setb    = ( $c, $l, $o, $u, $d );
my $params  = {
    'a'     => $a,
    'b'     => $b,
    'c'     => $c,
    'd'     => $d,
    'l'     => $l,
    'o'     => $o,
    'r'     => $r,
    'u'     => $u,
    'w'     => $w,
    'seta'  => \@seta,
    'setb'  => \@setb,
    'users' => \@people,
    'item'  => 'foo',
    'items' => [ 'foo', 'bar' ],
};


my $template = Template->new({ INTERPOLATE => 1, POST_CHOMP => 1 });

test_expect(\*DATA, $template, $params);

__DATA__
Commence countdown...
[% FOREACH count = [ 'five' 'four' 'three' 'two' 'one' ] %]
  [% count %]

[% END %]
Fire!
-- expect --
Commence countdown...
  five
  four
  three
  two
  one
Fire!

-- test --
[% FOR count = [ 1 2 3 ] %]${count}..[% END %]
-- expect --
1..2..3..

-- test --
[% for count = [ 1 2 3 ] %]${count}..[% END %]
-- expect --
1..2..3..

-- test --
[% foreach count = [ 1 2 3 ] %]${count}..[% END %]
-- expect --
1..2..3..

-- test --
[% for [ 1 2 3 ] %]<blip>..[% END %]
-- expect --
<blip>..<blip>..<blip>..

-- test --
[% foreach [ 1 2 3 ] %]<blip>..[% END %]
-- expect --
<blip>..<blip>..<blip>..

-- test --
people:
[% bloke = r %]
[% people = [ c, bloke, o, 'frank' ] %]
[% FOREACH person = people %]
  [ [% person %] ]
[% END %]
-- expect --
people:
  [ charlie ]
  [ romeo ]
  [ oscar ]
  [ frank ]

-- test --
[% FOREACH name = setb %]
[% name %],
[% END %]
-- expect --
charlie,
lima,
oscar,
uncle,
delta,

-- test --
[% FOREACH name = r %]
[% name %], [% $name %], wherefore art thou, $name?
[% END %]
-- expect --
romeo, romeo, wherefore art thou, romeo?

-- test --
[% user = 'fred' %]
[% FOREACH user = users %]
   $user.name ([% user.id %])
[% END %]
   [% user.name %]
-- expect --
   Andy Wardley (abw)
   Simon Matthews (sam)
   Simon Matthews

-- test --
[% name = 'Joe Random Hacker' id = 'jrh' %]
[% FOREACH users %]
   $name ([% id %])
[% END %]
   $name ($id)
-- expect --
   Andy Wardley (abw)
   Simon Matthews (sam)
   Joe Random Hacker (jrh)

-- test --
[% FOREACH i = [1..4] %]
[% i +%]
[% END %]
-- expect --
1
2
3
4

-- test --
[% first = 4 
   last  = 8
%]
[% FOREACH i = [first..last] %]
[% i +%]
[% END %]
-- expect --
4
5
6
7
8

-- test --
[% list = [ 'one' 'two' 'three' 'four' ] %]
[% list.0 %] [% list.3 %]

[% FOREACH n = [0..3] %]
[% list.${n} %], 
[%- END %]

-- expect --
one four
one, two, three, four, 

-- test --
[% "$i, " FOREACH i = [-2..2] %]

-- expect --
-2, -1, 0, 1, 2, 

-- test --
[% FOREACH i = item -%]
    - [% i %]
[% END %]
-- expect --
    - foo

-- test --
[% FOREACH i = items -%]
    - [% i +%]
[% END %]
-- expect --
    - foo
    - bar

