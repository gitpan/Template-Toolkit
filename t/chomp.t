#============================================================= -*-Perl-*-
#
# t/chomp.t
#
# Test script to test the chomp options.
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: chomp.t,v 1.3 1999/08/01 13:43:16 abw Exp $
# 
#========================================================================

use strict;
use lib qw( . ./t ../lib );
use vars qw( $DEBUG );
use Template;
require 'texpect.pl';
$^W = 1;

$DEBUG = 0;

# sample data (optional)
my $params  = {
    'a'     => 'alpha',
    'b'     => 'bravo',
    'c'     => 'charlie',
};


test_expect(\*DATA, undef, $params);

__DATA__
start
[% IF a %]
a is [% a %].
[% ELSIF zero %]
This should never happen
[% END %]
[% IF a && b %]
[% a %] and [% b +%]
end
[% END %]
-- expect --
start

a is alpha.


alpha and bravo
end

-- test --
[% a %]
[% a %]
-- expect --
alpha
alpha

-- test --
[% a -%]
[% a %]
-- expect --
alphaalpha

-- test --
[% a -%]                  		      
[% a %]
-- expect --
alphaalpha

-- test --
[% a %]
[%- a %]
-- expect --
alphaalpha

-- test --
[% a -%]
          [%- a %]
-- expect --
alphaalpha

-- test --
[% a -%]  
     [%- a %]
-- expect --
alphaalpha

-- test --
a     [%- a %]
-- expect --
a     alpha

-- test --
     [%- a %]
-- expect --
alpha

