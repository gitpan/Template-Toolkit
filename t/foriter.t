#============================================================= -*-perl-*-
#
# t/foriter.t
#
# Template script testing iterators created implicitly via the FOREACH
# directive an explictly using trailing parenthesised parameters.
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: foriter.t,v 1.4 1999/08/10 11:09:14 abw Exp $
#
#========================================================================

use strict;
use lib qw( . ./t ../lib );
use vars qw( $DEBUG );
use Template qw( :status );
require 'texpect.pl';
$^W = 1;

$DEBUG = 0;

my ($a, $b, $c, $d) = qw( alpha bravo charlie delta );
my @days = qw( Monday Tuesday Wednesday Thursday Friday Saturday Sunday );
my @months = qw( jan feb mar apr may jun jul aug sep oct nov dec );
my $day = -1;
my $params = { 
    'a'      => $a,
    'b'      => $b,
    'c'      => $c,
    'C'      => uc $c,
    'd'      => $d,
    'days'   => \@days,
    'months' => \&months,
    'format' => \&format,
};

test_expect(\*DATA, { INTERPOLATE => 1, POST_CHOMP => 1 }, $params);
 

sub months {
    return \@months;
}

sub format {
    my $format = shift;
    $format = '%s' unless defined $format;
    return sub {
	sprintf($format, shift);
    }
}

#------------------------------------------------------------------------
# test input
#------------------------------------------------------------------------

__DATA__
[% FOREACH item = [ a b c d ] %]
$item
[% END %]
-- expect --
alpha
bravo
charlie
delta

-- test --
[% FOREACH item = [ d C a c b ](order => 'sorted') %]
$item
[% END %]
-- expect --
alpha
bravo
CHARLIE
charlie
delta

-- test --
[% FOREACH item = [ d a c b ](order => 'reverse') %]
$item
[% END %]
-- expect --
delta
charlie
bravo
alpha

-- test --
[% CATCH undef %]
ERROR: [% e.info %]
[% END %]
[% FOREACH item = [ a b c ] (order => 'sideways') %]
$item
[% END +%]
[% FOREACH item = [ a b c ] (order => inverted) %]
$item
[% END %]
-- expect --
ERROR: invalid iterator order: sideways
ERROR: inverted is undefined

-- test --
[% userlist = [ b c d a C 'Andy' 'tom' 'dick' 'harry' ] (order => 'sorted') %]
[% FOREACH u = userlist %]
$u
[% END %]
-- expect --
alpha
Andy
bravo
charlie
CHARLIE
delta
dick
harry
tom

-- test --
%% ulist = [ b c d a 'Andy' ]( order  => 'sorted', 
			       action => format('[- %-7s -]') ) %%
[% FOREACH item = ulist %]
$item
[% END %]
-- expect --
[- alpha   -]
[- Andy    -]
[- bravo   -]
[- charlie -]
[- delta   -]

