#============================================================= -*-perl-*-
#
# t/perl.t
#
# Template script testing PERL directive
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: perl.t,v 1.3 1999/12/21 14:22:15 abw Exp $
#
#========================================================================

use strict;
use lib qw( ../lib );
use Template::Test;
$^W = 1;

$Template::Test::DEBUG = 0;

test_expect(\*DATA, { EVAL_PERL => 1, POST_CHOMP => 1 }, callsign);

__DATA__
-- test --
[% PERL %]
my @data = qw( tom dick harry );
$stash->{'newdata'} = \@data;
$context->output('set data');
[% END %]

[% FOREACH name = newdata %]
* [% name +%]
[% END %]

-- expect --
set data
* tom
* dick
* harry

-- test --
[% PERL %]
    $stash->{'joint'} = join(', ', qw( [% a %] [% b %] [% w %] ));
[% END %]
joined: [% joint %]

-- expect --
joined: alpha, bravo, whisky
