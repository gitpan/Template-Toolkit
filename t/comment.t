#============================================================= -*-perl-*-
#
# t/comment.t
#
# Template script testing comment facility
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 2000 Andy Wardley. All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: comment.t,v 1.1 2000/03/27 12:35:27 abw Exp $
# 
#========================================================================

use strict;
use lib qw( ../lib );
use Template qw( :status );
use Template::Test;
$^W = 1;

$Template::Test::DEBUG = 0;


test_expect(\*DATA, { POST_CHOMP => 1 }, callsign);

__DATA__
-- test --
[% # ignore
   x = a
   # so is this
   y = b
   # this line is ignored
   z = c
%]
result: [% x %] [% y %] [% z %]

-- expect --
result: alpha bravo charlie

-- test --
[% msg = '+#12' 
   foo = "[ # # ]"
   # ignored %]
[% msg +%]
[% foo %]

-- expect --
+#12
[ # # ]


-- test --
pre[%# ignored 
     " FAILED " %]post

-- expect --
prepost
