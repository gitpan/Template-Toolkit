#============================================================= -*-perl-*-
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
# $Id: predefs.t,v 1.6 1999/11/25 17:51:28 abw Exp $
# 
#========================================================================

use strict;
use lib qw( ../lib );
use Template;
use Template::Test;
$^W = 1;

$Template::Test::DEBUG = 0;

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
