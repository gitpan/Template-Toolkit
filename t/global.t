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
# $Id: global.t,v 1.1 1999/09/14 11:33:43 abw Exp $
#
#========================================================================

use strict;
use lib qw( . ./t ../lib );
use vars qw( $DEBUG );
use Template;
require 'texpect.pl';
$^W = 1;

$DEBUG = 0;

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
