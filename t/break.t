#============================================================= -*-perl-*-
#
# t/break.t
#
# Template script testing the BREAK directive.
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: break.t,v 1.1 1999/08/10 11:09:11 abw Exp $
#
#========================================================================

use strict;
use lib qw( . ./t ../lib );
use vars qw( $DEBUG );
use Template qw( :status );
require 'texpect.pl';
$^W = 1;

$DEBUG = 0;

test_expect(\*DATA, { POST_CHOMP => 1 });

__DATA__
-- test --
[% FOREACH number = [ 1 2 3 4 5 ] %]
[% BREAK IF number > 3 %]
[% number %] [% END +%]
The end
-- expect --
1 2 3 
The end













