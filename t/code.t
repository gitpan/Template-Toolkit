#============================================================= -*-Perl-*-
#
# t/code.t
#
# Template script testing code bindings to variables.
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: code.t,v 1.3 1999/08/01 13:43:16 abw Exp $
#
#========================================================================

use strict;
use lib qw( . ./t ../lib );
use vars qw( $DEBUG );
use Template qw( :status );
use Template::Exception;
require 'texpect.pl';
$^W = 1;

$DEBUG = 0;

my $tproc = Template->new({ INTERPOLATE => 1 });

# sample data
my ($a, $b, $c, $d) = qw( alpha bravo charlie delta );
my @days = qw( Monday Tuesday Wednesday Thursday Friday Saturday Sunday );
my $day = -1;
my $params = { 
    'a'      => $a,
    'b'      => $b,
    'c'      => $c,
    'd'      => $d,
    'fail'   => \&nyet,
    'barf'   => \&barf,
    'homer'  => \&doh,
    'belief' => \&belief,
    'cthrow' => \&context_throw,
    'day'    => {
	'prev' => \&yesterday,
	'this' => \&today,
	'next' => \&tomorrow,
    },
};

test_expect(\*DATA, $tproc, $params);


#------------------------------------------------------------------------
# subs
#------------------------------------------------------------------------

sub yesterday {
    return "All my troubles seemed so far away...";
}

sub today {
    my $when = shift || 'Now';
    return "$when it looks as though they're here to stay.";
}

sub tomorrow {
    my $dayno = shift;
    unless (defined $dayno) {
	$day++;
	$day %= 7;
	$dayno = $day;
    }
    return $days[$dayno];
}


sub belief {
    my @beliefs = @_;
    my $b = join(' and ', @beliefs);
    $b = '<nothing>' unless length $b;
    return "Oh I believe in $b.";
}

sub doh {
    return "D'Oh";
}

sub nyet {
    return undef;
}

sub barf {
    return (undef, Template::Exception->new('barf', 'Veni, Vidi, Barfi'));
}

# throw an exception via the context
sub context_throw {
    return (undef,
	    $tproc->{ CONTEXT }->throw('barf', 'We came, we saw, we hurled'));
}


#------------------------------------------------------------------------
# test input
#------------------------------------------------------------------------

__DATA__
[% homer           %]
[% homer(900)      %]
[% homer(900, 800) %]
[% homer(a b c)    %]
-- expect --
D'Oh
D'Oh
D'Oh
D'Oh

-- test --
$homer
${homer}
-- expect --
D'Oh
D'Oh

-- test --
[% day.prev %]
[% day.this %]
[% belief('yesterday') %]
-- expect --
All my troubles seemed so far away...
Now it looks as though they're here to stay.
Oh I believe in yesterday.

-- test --
Yesterday, $day.prev
$day.this
${belief('yesterday')}
-- expect --
Yesterday, All my troubles seemed so far away...
Now it looks as though they're here to stay.
Oh I believe in yesterday.

-- test --
[% belief('fish' 'chips') %]
[% belief %]
-- expect --
Oh I believe in fish and chips.
Oh I believe in <nothing>.

-- test --
${belief('fish' 'chips')}
$belief
-- expect --
Oh I believe in fish and chips.
Oh I believe in <nothing>.

-- test --
[% day.next %]
$day.next
-- expect --
Monday
Tuesday

-- test --
[% FOREACH [ 1 2 3 4 5 ] %]$day.next [% END %]
-- expect --
Wednesday Thursday Friday Saturday Sunday 

-- test --
[% CATCH undef -%]ERROR: $e.info[% END -%]
[% fail %]
$fail
-- expect --
ERROR: fail is undefined
ERROR: fail is undefined

-- test -- 
[% CATCH barf %]Yeeeuuuukkkk! [$e.info][% END -%] 
[% barf%]
-- expect -- 
Yeeeuuuukkkk! [Veni, Vidi, Barfi]

-- test --
[% CATCH barf %]THROWN! [$e.info][% END -%] 
[% cthrow %]
-- expect --
THROWN! [We came, we saw, we hurled]

-- test --
[% foo = cthrow %]
Hello
-- expect --
THROWN! [We came, we saw, we hurled]
Hello

-- test --
[% cthrow = 'aaa' -%]
[% cthrow %]
-- expect --
aaa







