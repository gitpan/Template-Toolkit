#============================================================= -*-perl-*-
#
# t/while.t
#
# Template script testing the WHILE directive.
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: while.t,v 1.2 1999/11/25 17:51:32 abw Exp $
# 
#========================================================================

use strict;
use lib qw( ../lib );
use Template qw( :status );
use Template::Directive;
use Template::Test;
$^W = 1;

$Template::Test::DEBUG = 0;

# set low limit on WHILE's maximum iteration count
$Template::Directive::While::MAXITER = 100;

my @list = ( 'x-ray', 'yankee', 'zulu', );
my @pending;

my $params  = {
    'a'     => 'alpha',
    'b'     => 'bravo',
    'c'     => 'charlie',
    'd'     => 'delta',
    'dec'   => sub { --$_[0] },
    'inc'   => sub { ++$_[0] },
    'reset' => sub { @pending = @list; "Reset list\n" },
    'next'  => sub { shift @pending },
    'true'  => 1,
};

test_expect(\*DATA, { INTERPOLATE => 1, POST_CHOMP => 1 }, $params);



__DATA__
before
[% WHILE bollocks %]
do nothing
[% END %]
after
-- expect --
before
after

-- test --
Commence countdown...
[% a = 10 %]
[% WHILE a %]
[% a %]..[% a = dec(a) %]
[% END +%]
The end
-- expect --
Commence countdown...
10..9..8..7..6..5..4..3..2..1..
The end

-- test --
[% reset %]
[% WHILE (item = next) %]
item: [% item +%]
[% END %]
-- expect --
Reset list
item: x-ray
item: yankee
item: zulu

-- test --
[% reset %]
[% WHILE (item = next) %]
item: [% item +%]
[% BREAK IF item == 'yankee' %]
[% END %]
Finis
-- expect --
Reset list
item: x-ray
item: yankee
Finis

-- test --
[% reset %]
[% "* $item\n" WHILE (item = next) %]
-- expect --
Reset list
* x-ray
* yankee
* zulu

-- test --
[% WHILE true %].[% END %]
-- expect --
....................................................................................................
-- error --
Runaway WHILE loop terminated (> 100 iterations)






