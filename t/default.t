#============================================================= -*-perl-*-
#
# t/default.t
#
# Test the DEFAULT directive.
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: default.t,v 1.1 1999/09/09 17:02:00 abw Exp $
# 
#========================================================================

use strict;
use lib qw( . ./t ../lib );
use vars qw( $DEBUG );
use Template;
require 'texpect.pl';
$^W = 1;

$DEBUG = 0;

# configuration for Template processor (optional)
my $config  = {
    INTERPOLATE => 1, 
};

# sample data (optional)
my $params  = {
    'a'     => 'alpha',
    'b'     => 'bravo',
    'c'     => 'charlie',
};


test_expect(\*DATA, $config, $params);

__DATA__
-- test --
[% a %]
[% DEFAULT a = b %]
[% a %]
-- expect --
alpha

alpha

