#============================================================= -*-Perl-*-
#
# t/predefs.t
#
# Template script testing the PREDEF configuration option.
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: predefs.t,v 1.4 1999/08/01 13:43:19 abw Exp $
# 
#========================================================================

use strict;
use lib qw( . ./t ../lib );
use vars qw( $DEBUG );
use Template;
require 'texpect.pl';
$^W = 1;

$DEBUG = 0;

# sample data
my ($a, $b, $c, $d, $e, $f) = qw( alpha bravo charlie delta echo foxtrot );
my $data = {
    'a' => $a,
    'b' => $b,	
    'c' => { 
	'd' => $d, 
	'e' => { 
	    'f' => $f,
	},
    },
};

test_expect(\*DATA, { PRE_DEFINE => $data, INTERPOLATE => 1 }, $data);

__DATA__
-- test --
[% a %]
[% b %]
[% c.d %]
[% c.e.f %]
-- expect --
alpha
bravo
delta
foxtrot

-- test --
$a $b $c.d $c.e.f
-- expect --
alpha bravo delta foxtrot
