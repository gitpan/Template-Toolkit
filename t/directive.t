#============================================================= -*-perl-*-
#
# t/directive.t
#
# Template script testing general directives.
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: directive.t,v 1.7 1999/11/25 17:51:23 abw Exp $
# 
#========================================================================

use strict;
use lib qw( ../lib );
use Template qw( :status );
use Template::Test;
$^W = 1;

$Template::Test::DEBUG = 0;

my ($a, $b, $c, $d ) = 
	qw( alpha bravo charlie delta );
my $params = {
    'a'    => $a,
    'b'    => $b,
    'c'    => $c,
    'd'    => $d,
};


test_expect(\*DATA, { INTERPOLATE => 1 }, $params);

__DATA__
[%a%] [% a %] [%			a		%]
-- expect --
alpha alpha alpha

-- test --
[% a %]
[% b %]
[% c -%]
[% d %]
-- expect --
alpha
bravo
charliedelta

-- test --
Defining blocks and handler
[% BLOCK foo -%]
This is foo
[% END -%]
[% block Bar -%]
This is Bar
[% END -%]
[% CATCH file -%]
This is what happens when it all goes rightly wrong
[% END -%]
Done
-- expect --
Defining blocks and handler
Done

-- test --
[% INCLUDE foo %]
[% include foo %]
[% InClUde foo %]
[% INCLUde FOO %]
-- expect --
This is foo

This is foo

This is foo

This is what happens when it all goes rightly wrong
