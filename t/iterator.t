#============================================================= -*-Perl-*-
#
# t/iterator.t
#
# Test script for Template::Iterator.pm
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: iterator.t,v 1.3 1999/07/28 11:32:30 abw Exp $
#
#========================================================================

use strict;
use vars qw($loaded $ntests);
$^W = 1;

BEGIN { 
    $ntests = 23;
    $| = 1; 
    print "1..$ntests\n"; 
}

END {
    ok(0) unless $loaded;
}

my $ok_count = 1;
sub ok {
    shift or print "not ";
    print "ok $ok_count\n";
    ++$ok_count;
}

use Template::Iterator;
use Template::Constants qw( :status );
$loaded = 1;
ok(1);

# sample data
my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j, $k, $l, $m, 
    $n, $o, $p, $q, $r, $s, $t, $u, $v, $w, $x, $y, $z) = 
	qw( alpha bravo charlie delta echo foxtrot golf hotel india 
	    juliet kilo lima mike november oscar papa quebec romeo 
	    sierra tango umbrella victor whisky x-ray yankee zulu );

my @set1 = ( $a, $b, $c );
my @set2 = ( $d, $e, $f );
 


#------------------------------------------------------------------------

my ($value, $error, @vals);

#2 - create iterator
my $iter1 = Template::Iterator->new(\@set1);
ok($iter1);

#3-4 - call first and test expected result
($value, $error) = $iter1->first();
ok( ! $error);
ok( $value eq $a );

#5-8 - call next() and test expected result
foreach ($b, $c) {
    ($value, $error) = $iter1->next();
    ok( ! $error);
    ok( $value eq $_ );
}

#9 - call next() and expect STATUS_DONE
($value, $error) = $iter1->next();
ok( $error == STATUS_DONE );

#10-11 - once more with feeling, expecting a warning
{
    my $warning;
    local $SIG{__WARN__} = sub { $warning = shift };

    ($value, $error) = $iter1->next();
    ok( $error == STATUS_DONE );
    ok( length $warning );
}

#12-15 - now try re-iterating through the same set 
@vals = ();
($value, $error) = $iter1->first();
ok( ! $error );
push(@vals, $value);

foreach (1..2) {
    ($value, $error) = $iter1->next();
    ok( ! $error );
    push(@vals, $value);
}

ok( "@vals" eq join($", $a, $b, $c) );


#------------------------------------------------------------------------

#16 - create an iterator with an empty set
my $iter2 = Template::Iterator->new();
ok($iter1);

#17-18 - call first and test expected result (nothing)
($value, $error) = $iter2->first();
ok( $error == STATUS_DONE );
ok( !defined $value );



#------------------------------------------------------------------------

#19 - check iterator will tolerate a non-list reference
my $iter3 = Template::Iterator->new($t);
ok($iter3);

#20-21 - call first and test expected result
($value, $error) = $iter3->first();
ok( ! $error );
ok( $value eq $t );

#22-23 - call next and test DONE
($value, $error) = $iter3->next();
ok( $error == STATUS_DONE );
ok( ! defined $value );

