#============================================================= -*-Perl-*-
#
# t/case.t
#
# Template script testing CASE sensitivity option.
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: case.t,v 1.1 1999/08/01 13:43:16 abw Exp $
#
#========================================================================

use strict;
use lib qw( . ./t ../lib );
use vars qw( $DEBUG );
use Template::Constants qw( :status );
require 'texpect.pl';
$^W = 1;

$DEBUG = 0;

test_expect(\*DATA, { CASE => 1, POST_CHOMP => 1 }, callsign());


__DATA__
-- test --
[% include = a %]
[% for = b %]
i([% include %])
f([% for %])
-- expect --
i(alpha)
f(bravo)

-- test --
[% IF a AND b %]
good
[% ELSE %]
bad
[% END %]
-- expect --
good

-- test --
# 'and', 'or' and 'not' can ALWAYS be expressed in lower case, regardless
# of CASE sensitivity option.
[% IF a and b %]
good
[% ELSE %]
bad
[% END %]
-- expect --
good

