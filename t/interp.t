#============================================================= -*-Perl-*-
#
# t/interp.t
#
# Template script testing string interpolation.
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: interp.t,v 1.4 1999/08/01 13:43:18 abw Exp $
#
#========================================================================

use strict;
use lib qw( . ./t ../lib );
use vars qw( $DEBUG );
require 'texpect.pl';
$^W = 1;

$DEBUG = 0;

my ($a, $b, $c, $d, $w) = qw( alpha bravo charlie delta whisky );
my $params = {
    'a'    => $a,
    'b'    => $b,
    'c'    => $c,
    'd'    => $d,
    'w'    => $w,
};

my $template = Template->new({
	INTERPOLATE => 1,
	POST_CHOMP  => 1,
});

test_expect(\*DATA, $template, $params);

__DATA__
<[% a %]> <[% b %]> <[% c %]> <[% d %]>
[$a] [$b] [${c}] [$d]
-- expect --
<alpha> <bravo> <charlie> <delta>
[alpha] [bravo] [charlie] [delta]
-- test --
[% name = "$a $b $w" %]
Name: $name
-- expect --
Name: alpha bravo whisky
-- test --
%% user = {
      id = 'abw'
      name = 'Andy Wardley'
      callsign = "[-$a-$b-$w-]"
    }
%%
${user.id} ${ user.id } $user.id ${user.id}.gif
[% message = "$b: ${ user.name } (${user.id}) ${ user.callsign }" %]
MSG: $message
-- expect --
abw abw abw abw.gif
MSG: bravo: Andy Wardley (abw) [-alpha-bravo-whisky-]

-- test --
[% product = {
     id   = 'XYZ-2000'
     desc = 'Bogon Generator'
     cost = 678
   }
%]
The $product.id $product.desc costs \$${product.cost}.00
-- expect --
The XYZ-2000 Bogon Generator costs $678.00

