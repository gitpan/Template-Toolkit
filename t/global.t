#============================================================= -*-perl-*-
#
# t/global.t
#
# Template script testing 'global' namespace.
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: global.t,v 1.2 1999/11/25 17:51:24 abw Exp $
#
#========================================================================

use strict;
use lib qw( ../lib );
use Template;
use Template::Test;
$^W = 1;

$Template::Test::DEBUG = 0;

my $params = { };
test_expect(\*DATA, { POST_CHOMP => 1 }, $params);


__DATA__
[% INCLUDE set_global %]
thing: [% global.thing %]

[% BLOCK set_global %]
[% global.thing = 'something' %]
[% END %]
-- expect --
thing: something
