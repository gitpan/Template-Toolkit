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
# $Id: private.t,v 1.5 1999/11/25 17:51:28 abw Exp $
#
#========================================================================

use strict;
use lib qw( ../lib );
use Template qw( :status );
use Template::Exception;
use Template::Test;
$^W = 1;

$Template::Test::DEBUG = 0;

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
! invalid member name '_b'
! invalid member name '.c'

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
! invalid member name '_d'





