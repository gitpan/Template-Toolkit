#============================================================= -*-perl-*-
#
# t/skel.t
#
# Skeleton test file.  You can copy this and modify appropriately to 
# create new test scripts.
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: skel.t,v 1.5 1999/08/10 11:09:18 abw Exp $
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


# The first parameter to test_expect() is the input source.  The second
# optional parameter may be a reference to a Template object or a HASH
# ref containing configuration options which should be used to instantiate
# a new Template object.  The third parameter, also optional may contain
# a reference to a HASH of variables to be defined when processing.

test_expect(\*DATA, $config, $params);

# could also be called as:
#   test_expect(\*DATA);
#   test_expect(\*DATA, $template);
#   test_expect(\*DATA, $config);
#   test_expect(\*DATA, undef, $params);
#   test_expect(\$mytext);    # ...or any other supported input source
#   etc., etc.

__DATA__
# Any line with a '#' in the first character is a comment and will be
# ignored by the test_expect() sub.  Each test is split into a 
# '-- test --' and '-- expect --' section.  Each test section is fed
# into the template processor and the output compared against that 
# which was expected.  Trailing blank lines are generally stripped from 
# the input, output and expected texts.

-- test --
[% a %]
-- expect --
alpha

-- test --
[% b %]
$c
-- expect --
bravo
charlie

