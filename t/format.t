#============================================================= -*-perl-*-
#
# t/format.t
#
# Template script testing format plugin.
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: format.t,v 1.5 1999/09/29 10:35:32 abw Exp $
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
};

test_expect(\*DATA, { INTERPOLATE => 1, POST_CHOMP => 1 }, $params);
 

sub months {
    return \@months;
}

#------------------------------------------------------------------------
# test input
#------------------------------------------------------------------------

__DATA__
[% USE format %]
[% bold = format('<b>%s</b>') %]
[% ital = format('<i>%s</i>') %]
[% bold('heading')  +%]
[% $ital('author')  +%]
${ ital('affil.') }
[% bold('footing')  +%]
$bold

-- expect --
<b>heading</b>
<i>author</i>
<i>affil.</i>
<b>footing</b>
<b></b>

-- test --
[% USE format('<li> %s') %]
[% FOREACH item = [ a b c d ] %]
[% format(item) +%]
[% END %]
-- expect --
<li> alpha
<li> bravo
<li> charlie
<li> delta

-- test -- 
[% USE fmt = format %]
[% FOREACH user = [ c d a b ]( order = 'reverse' action = fmt('++ %s ++') )%]
$user
[% END %]
-- expect --
++ delta ++
++ charlie ++
++ bravo ++
++ alpha ++

-- test --
[% USE bold = format("<b>%s</b>") %]
[% USE ital = format("<i>%s</i>") %]
[% bold('This is bold')   +%]
[% ital('This is italic') +%]
-- expect --
<b>This is bold</b>
<i>This is italic</i>



