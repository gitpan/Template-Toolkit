#============================================================= -*-perl-*-
#
# t/datafile.t
#
# Template script testing datafile plugin.
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: datafile.t,v 1.1 1999/10/07 13:09:04 abw Exp $
#
#========================================================================

use strict;
use lib qw( . ./t ../lib );
use vars qw( $DEBUG );
use Template qw( :status );
require 'texpect.pl';
$^W = 1;

$DEBUG = 0;

my $base   = -d 't' ? 't/test/lib' : 'test/lib';
my $params = { 
    datafile => [ "$base/userdata1", "$base/userdata2" ],
};

test_expect(\*DATA, { INTERPOLATE => 1, POST_CHOMP => 1 }, $params);
 


#------------------------------------------------------------------------
# test input
#------------------------------------------------------------------------

__DATA__
[% USE userlist = datafile(datafile.0) %]
Users:
[% FOREACH user = userlist %]
  * $user.id: $user.name
[% END %]

-- expect --
Users:
  * way: Wendy Yardley
  * mop: Marty Proton
  * nellb: Nell Browser

-- test --
[% USE userlist = datafile(datafile.1, delim = '|') %]
Users:
[% FOREACH user = userlist %]
  * $user.id: $user.name
[% END %]

-- expect --
Users:
  * way: Wendy Yardley
  * mop: Marty Proton
  * nellb: Nell Browser




