#============================================================= -*-perl-*-
#
# t/os.t
#
# Template script testing Template::OS module.
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: os.t,v 1.1 1999/08/10 11:09:16 abw Exp $
#
#========================================================================

use strict;
use lib qw( . ./t ../lib );
use vars qw( $DEBUG );
use Template::OS;
require 'texpect.pl';
$^W = 1;

$DEBUG = 0;

extra_tests(1);

test_expect(\*DATA);

my $os = Template::OS->new();
ok( $os );

print "pathsep: ", $os->pathsep(), "\npathsplit: ", $os->pathsplit, "\n";



__DATA__
hello world
-- expect --
hello world














