#============================================================= -*-perl-*-
#
# t/listndx.t
#
# Template script testing numerical indexing of lists.
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: listndx.t,v 1.3 2000/03/20 08:01:36 abw Exp $
# 
#========================================================================

use strict;
use lib qw( ../lib );
use Template qw( :status );
use Template::Test;
$^W = 1;

$Template::Test::DEBUG = 0;

my $data = {
    'days'    => [ qw( Mon Tue Wed Thu Fri Sat Sun ) ],
    'letters' => [ 'a'..'z' ],
};

test_expect(\*DATA, { POST_CHOMP => 1, DEBUG => 0 }, $data);

__DATA__
[% days.0 +%]
[% days.1 %]
-- expect --
Mon
Tue

-- test --
[% FOREACH n = [0..6] %]
[% days.${n} +%]
[% END %]
-- expect --
Mon
Tue
Wed
Thu
Fri
Sat
Sun
-- test --
Without DEBUG, this should silently fail: [% days.8 %]
-- expect --
Without DEBUG, this should silently fail: 

-- test --
[% letters.first %] - [% letters.last %]

-- expect --
a - z

-- test --
[% letters.size %] entries ([% letters.first %] - [% letters.last %]):
   -> [% letters.join(', ') %]

-- expect --
26 entries (a - z):
   -> a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y, z


-- test --
[% items  = [ 'zulu', 'charlie', 'alpha', 'bravo', 'whisky' ] %]
[% sorted = items.sort %]
[% sorted.size %] entries ([% sorted.first %] - [% sorted.last %]):
   -> [% sorted.join(', ') %]

-- expect --
5 entries (alpha - zulu):
   -> alpha, bravo, charlie, whisky, zulu

-- test --
[% list = [ 'Tom', 'Dick', 'Harry' ] %]
[% list.sort.join(', ') %]

-- expect --
Dick, Harry, Tom
