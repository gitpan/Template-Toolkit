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
# $Id: foreach.t,v 1.7 1999/09/14 11:33:42 abw Exp $
# 
#========================================================================

use strict;
use lib qw( . ./t ../lib );
use vars qw( $DEBUG );
use Template qw( :status );
require 'texpect.pl';
$^W = 1;

$DEBUG = 0;

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

