#============================================================= -*-perl-*-
#
# t/block.t
#
# Template script testing the BLOCK directive and implicit scoping blocks.
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: block.t,v 1.7 1999/11/25 17:51:22 abw Exp $
# 
#========================================================================

use strict;
use lib qw( ../lib );
use Template qw( :status );
use Template::Test;
$^W = 1;

$Template::Test::DEBUG = 0;

test_expect(\*DATA, { POST_CHOMP => 1 });

__DATA__
[% BLOCK dud %][% END %]
[% INCLUDE dud %]
-- expect --

-- test --
[% BLOCK foo %]
this is foo
[% BLOCK bar %]
this is bar
[% END %]
that was foo
[% END %]

-- test --
[% INCLUDE foo %]
[% INCLUDE bar %]
-- expect --
this is foo
that was foo
this is bar

-- test --
loop: [% FOREACH n = [ 'a' 'b' 'c' ] %]
[% n %]
[% END %] endloop
-- expect --
loop: abc endloop

-- test --
loop: [% FOREACH [ 'a' 'b' 'c' ] %][% END %]endloop
-- expect --
loop: endloop

-- test --
[% BLOCK foo.bar %]
This is foo.bar
[% END %]
[% BLOCK foo/bar.txt %]
This is foo/bar.txt
[% END %]
[% INCLUDE foo.bar %]
[% INCLUDE foo/bar.txt %]
-- expect --
This is foo.bar
This is foo/bar.txt

-- test --
[% BLOCK %]
foo
bar
[% END %]

-- expect --
foo
bar

