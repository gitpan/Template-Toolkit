#============================================================= -*-perl-*-
#
# t/private.t
#
# Template script testing that hash members prefixed by '_' or '.'
# are treated as private and not exposed.  
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: private.t,v 1.3 1999/08/10 11:09:17 abw Exp $
#
#========================================================================

use strict;
use lib qw( . ./t ../lib );
use vars qw( $DEBUG );
use Template qw( :status );
use Template::Exception;
require 'texpect.pl';
$^W = 1;

$DEBUG = 0;

my ($a, $b, $c, $d) = qw( alpha bravo charlie delta );
my $params = { 
    'a'      => $a,
    'b'      => $b,
    '_b'     => $b,
    'c'      => $c,
    '.c'     => $c,
    'more'   => {
	'c'  => $c,
	'_c' => $c,
	'd'  => $d,
	'.d' => $d,
    },
};

test_expect(\*DATA, { INTERPOLATE => 1 }, $params);



#------------------------------------------------------------------------
# test input
#------------------------------------------------------------------------

__DATA__
[% a %] $b [% c %]
-- expect --
alpha bravo charlie

-- test --
[% CATCH undef -%]
! [% e.info -%]
[% END -%]
[% _b %]
[% see = '.c' -%]
[% ${"$see"} %]
-- expect --
! _b is undefined
! .c is undefined

-- test --
[% more.c %]
-- expect --
charlie

-- test --
[% more.d %]
-- expect --
delta

-- test --
[% more._d %]
-- expect --
! _d is undefined


