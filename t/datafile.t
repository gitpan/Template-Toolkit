#============================================================= -*-perl-*-
#
# t/datafile.t
#
# Template script testing datafile plugin.
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 1996-2000 Andy Wardley.  All Rights Reserved.
# Copyright (C) 1998-2000 Canon Research Centre Europe Ltd.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: datafile.t,v 2.0 2000/08/10 14:56:20 abw Exp $
#
#========================================================================

use strict;
use lib qw( ../lib );
use Template qw( :status );
use Template::Test;
$^W = 1;

$Template::Test::DEBUG = 0;

my $base   = -d 't' ? 't/test/lib' : 'test/lib';
my $params = { 
    datafile => [ "$base/udata1", "$base/udata2" ],
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




