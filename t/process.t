#============================================================= -*-perl-*-
#
# t/process.t
#
# Template script testing the PROCESS directive.
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: process.t,v 1.1 1999/08/10 11:09:17 abw Exp $
#
#========================================================================

use strict;
use lib qw( . ./t ../lib );
use vars qw( $DEBUG );
use Template;
require 'texpect.pl';
$^W = 1;

$DEBUG = 1;

my $params = { 
    'a' => 'alpha',
    'b' => 'bravo',
    'c' => 'charlie',
    'd' => 'delta',
};

test_expect(\*DATA, { POST_CHOMP => 1 }, $params);

__DATA__
[% a +%]
[% PROCESS config %]
[% a +%]
[% c +%]
[% z +%]
[% BLOCK config %]
Updating configuration...
[% a = b %]
[% c = 'marching powder'
   z = 'zulu'
%]
[% END %]
-- expect --
alpha
Updating configuration...
bravo
marching powder
zulu

