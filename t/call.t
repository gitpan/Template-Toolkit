#============================================================= -*-perl-*-
#
# t/call.t
#
# Template script testing code bindings to variables, called via the 
# CALL directive, rather than GET, which doesn't insert any return 
# value in the template.
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 1998-2000 Andy Wardley.  All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: call.t,v 1.1 2000/03/20 08:01:35 abw Exp $
#
#========================================================================

use strict;
use lib qw( ../lib );
use Template qw( :status );
use Template::Exception;
use Template::Test;
$^W = 1;

$Template::Test::DEBUG = 0;

my $tproc = Template->new({ INTERPOLATE => 1 });

# sample data
my ($a, $b, $c, $d) = qw( alpha bravo charlie delta );
my $n = 0;
my $params = { 
    'a'      => $a,
    'b'      => $b,
    'c'      => $c,
    'd'      => $d,
    'undef'  => sub { undef },
    'zero'   => sub { 0 },
    'one'    => sub { 'one' },
    'up'     => sub { ++$n },
    'down'   => sub { --$n },
    'n'      => sub { $n },
};

test_expect(\*DATA, $tproc, $params);


#------------------------------------------------------------------------
# test input
#------------------------------------------------------------------------

__DATA__

-- test --
..[% CALL undef %]..

-- expect --
....

-- test --
..[% CALL zero %]..

-- expect --
....

-- test --
..[% n %]..[% CALL n %]..

-- expect --
..0....

-- test --
..[% up %]..[% CALL up %]..[% n %]

-- expect --
..1....2


