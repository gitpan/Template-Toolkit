#============================================================= -*-perl-*-
#
# t/if.t
#
# Template script testing the IF/ELSIF/ELSE directives.
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
# $Id: if.t,v 1.9 1999/08/10 11:09:14 abw Exp $
#
#========================================================================

use strict;
use lib qw( . ./t ../lib );
use vars qw( $DEBUG );
require 'texpect.pl';
$^W = 1;

$DEBUG = 0;

my ($a, $b, $c, $r) = qw( alpha bravo charlie romeo );
my $params = {
    'a'      => $a,
    'b'      => $b,
    'c'      => $c,
    'r'      => $r,
    'ten'    => 10,
    'twenty' => 20,
    'zero'   => 0,
    'true'   => 1,
    'false'  => '',
};

test_expect(\*DATA, { POST_CHOMP => 1 }, $params);

__DATA__
r = [% r %].
[% IF r %]
[% r %], [% r %], wherefore art thou, [% r %]?
[% ELSE %]
no romeo
[% END %]
-- expect --
r = romeo.
romeo, romeo, wherefore art thou, romeo?
-- test --
[% IF r == 'romeo' %]
romeo again,
[% END %]
-- expect --
romeo again,

-- test --
[% loverboy = r %]
[% IF $r == loverboy %]still romeo... [% END %]
[% IF $r == $a %]you're not romeo![% ELSE %]get lost [% r %]![% END %]
-- expect --
still romeo... get lost romeo!

-- test --
[% IF ten < twenty %]
The force is strong in this one
[% ELSE %]
I feel a disturbance in the force.
[% END %]
-- expect --
The force is strong in this one

-- test --
[% IF twenty < ten %]
I feel a disturbance in the force.
[% ELSE %]
The force is strong in this one
[% END %]
-- expect --
The force is strong in this one

-- test --
[% IF twenty <= twenty %]
The force is strong in this one
[% ELSE %]
I feel a disturbance in the force.
[% END %]
-- expect --
The force is strong in this one

-- test --
[% IF false %]
do nothing
[% ELSIF true %]
do something
[% END %]
-- expect --
do something

-- test --
[% IF 0 %]
do nothing
[% ELSIF false %]
still doing nothing 
[% ELSIF zero || false and true %]
still not moving
[% END %]
got away lightly
-- expect --
got away lightly

-- test --
[% IF 0 %]
do nothing
[% ELSIF false %]
still doing nothing 
[% ELSIF zero || false and true %]
still not moving
[% ELSE %]
time for action
[% END %]
-- expect --
time for action

-- test --
[% if a and (true or false) %]
yes
[% else %]
no
[% end %]
-- expect --
yes

-- test --
[% if ((a and b) or (zero && false)) && true and (ten < twenty) %]
yes
[% else %]
no
[% end %]
-- expect --
yes

-- test --
[% IF nothing %]
nothing will come of nothing
[% ELSE %]
something in the way she moves
[% END %]
-- expect --
something in the way she moves

-- test --
[% UNLESS nothing %]
nothing will come of nothing
[% ELSE %]
something in the way she moves
[% END %]
-- expect --
nothing will come of nothing
