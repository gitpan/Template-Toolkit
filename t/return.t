#============================================================= -*-perl-*-
#
# t/return.t
#
# Template script testing the RETURN directive.
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: return.t,v 1.6 1999/11/25 17:51:28 abw Exp $
#
#========================================================================

use strict;
use lib qw( ../lib );
use Template qw( :status );
use Template::Test;
$^W = 1;

$Template::Test::DEBUG = 0;

test_expect(\*DATA);

__DATA__
line 1
[% INCLUDE 'first_block' %]
line 2
[% RETURN %]

[% BLOCK first_block -%]
first block line 1
[%- RETURN %]
first block line 2
[% END %]
-- expect --
line 1
first block line 1
line 2












