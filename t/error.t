#============================================================= -*-Perl-*-
#
# t/error.t
#
# Template script testing error reporting via the ERROR directive
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: error.t,v 1.1 1999/08/01 13:43:17 abw Exp $
#
#========================================================================

use strict;
use lib qw( . ./t ../lib );
use vars qw( $DEBUG );
use Template::Constants qw( :status );
require 'texpect.pl';
$^W = 1;

$DEBUG = 0;

test_expect(\*DATA, { POST_CHOMP => 1 }, callsign());


__DATA__
Foo
[% ERROR "! The cat sat on the mat\n! " %]
[% ERROR a %]
Bar
-- expect --
Foo
Bar
-- error --
! The cat sat on the mat
! alpha


