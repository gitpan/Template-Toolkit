#============================================================= -*-perl-*-
#
# t/listndx.t
#
# Template script testing numerical indexing of lists.
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: listndx.t,v 1.1 1999/09/29 10:18:01 abw Exp $
# 
#========================================================================

use strict;
use lib qw( . ./t ../lib );
use vars qw( $DEBUG );
use Template qw( :status );
require 'texpect.pl';
$^W = 1;

$DEBUG = 0;

my $data = {
    'days' => [ qw( Mon Tue Wed Thu Fri Sat Sun ) ],
};

test_expect(\*DATA, { POST_CHOMP => 1, DEBUG => 0 }, $data);

__DATA__
[% days.0 +%]
[% days.1 %]
-- expect --
Mon
Tue

-- test --
[% FOREACH n = [0..6] %]
[% days.${n} +%]
[% END %]
-- expect --
Mon
Tue
Wed
Thu
Fri
Sat
Sun
-- test --
Without DEBUG, this should silently fail: [% days.8 %]
-- expect --
Without DEBUG, this should silently fail: 
