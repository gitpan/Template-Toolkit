#============================================================= -*-perl-*-
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
# $Id: iterator.t,v 1.6 2000/03/20 08:01:36 abw Exp $
#
#========================================================================

use strict;
use lib qw( ./lib ../lib );
use Template::Iterator;
use Template::Constants qw( :status );
use Template::Test;
$^W = 1;

$Template::Test::DEBUG = 0;


# sample data
my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j, $k, $l, $m, 
    $n, $o, $p, $q, $r, $s, $t, $u, $v, $w, $x, $y, $z) = 
	qw( alpha bravo charlie delta echo foxtrot golf hotel india 
	    juliet kilo lima mike november oscar papa quebec romeo 
	    sierra tango umbrella victor whisky x-ray yankee zulu );

my @set1 = ( $a, $b, $c );
my @set2 = ( $d, $e, $f );
 
pre_ok(1);


#------------------------------------------------------------------------

my ($value, $error, @vals);

#2 - create iterator
my $iter1 = Template::Iterator->new(\@set1);
pre_ok($iter1);

#3-4 - call first and test expected result
($value, $error) = $iter1->get_first();
pre_ok( ! $error);
pre_ok( $value eq $a );

#5-8 - call next() and test expected result
foreach ($b, $c) {
    ($value, $error) = $iter1->get_next();
    pre_ok( ! $error);
    pre_ok( $value eq $_ );
}

#9 - call next() and expect STATUS_DONE
($value, $error) = $iter1->get_next();
pre_ok( $error == STATUS_DONE );

#10-11 - once more with feeling
($value, $error) = $iter1->get_next();
pre_ok( $error == STATUS_DONE );
pre_ok( 1 );           # filler - there used to be a real test here


#12-15 - now try re-iterating through the same set 
@vals = ();
($value, $error) = $iter1->get_first();
pre_ok( ! $error );
push(@vals, $value);

foreach (1..2) {
    ($value, $error) = $iter1->get_next();
    pre_ok( ! $error );
    push(@vals, $value);
}

pre_ok( "@vals" eq join($", $a, $b, $c) );


#------------------------------------------------------------------------

#16 - create an iterator with an empty set
my $iter2 = Template::Iterator->new();
pre_ok($iter1);

#17-18 - call first and test expected result (nothing)
($value, $error) = $iter2->get_first();
pre_ok( $error == STATUS_DONE );
pre_ok( !defined $value );



#------------------------------------------------------------------------

#19 - check iterator will tolerate a non-list reference
my $iter3 = Template::Iterator->new($t);
pre_ok($iter3);

#20-21 - call first and test expected result
($value, $error) = $iter3->get_first();
pre_ok( ! $error );
pre_ok( $value eq $t );

#22-23 - call next and test DONE
($value, $error) = $iter3->get_next();
pre_ok( $error == STATUS_DONE );
pre_ok( ! defined $value );


#------------------------------------------------------------------------

#24 - test get_all() method
my $iter4 = Template::Iterator->new(\@set1);
pre_ok($iter4);

#25-26 - call get_all and test expected result
my $set1 = $iter4->get_all();
pre_ok( ref $set1 eq 'ARRAY' );
pre_ok( $set1->[0] eq 'alpha' && $set1->[1] eq 'bravo' && $set1->[2] eq 'charlie');

#27 - test get_all() method after a get_first()
my $iter5 = Template::Iterator->new(\@set1);
pre_ok($iter5);

#28-30 - call get_first and test expected result
pre_ok( ($iter5->get_first())[0] eq 'alpha' );
my $set2 = $iter5->get_all();
pre_ok( ref $set2 eq 'ARRAY' );
pre_ok( $set2->[0] eq 'bravo' && $set2->[1] eq 'charlie');

#31 - test get_all() method after a get_first() and get_next()
my $iter6 = Template::Iterator->new(\@set1);
pre_ok($iter6);

#32-35 - call get_first and test expected result
pre_ok( ($iter6->get_first())[0] eq 'alpha' );
pre_ok( ($iter6->get_next())[0] eq 'bravo' );
my $set3 = $iter6->get_all();
pre_ok( ref $set3 eq 'ARRAY' );
pre_ok( $set3->[0] eq 'charlie');


#========================================================================
# template based tests
#========================================================================

my $params = {
    set1 => \@set1,
    set2 => \@set2,
};
@$params{ 'a'..'z' } = ('a'..'z');

test_expect(\*DATA, { POST_CHOMP => 1 }, $params);
 
__DATA__
-- test --
[% FOREACH item = set1 %]
item: [% item +%]
[% FOREACH more = loop.get_all %]
more items: [% more +%]
[% END %]
[% END %]

-- expect --
item: alpha
more items: bravo
more items: charlie

-- test --
[% letters = [ c d e a b i f j g h ] ( order = 'sorted' ) %]
[% USE alpha = table(letters, rows=2) %]
[% FOREACH item = alpha.row(0) %]
[% item %]..
[%- END %]

-- expect --
a..c..e..g..i..


-- test --
[% letters = [ c d e a b i f j g h ] ( order = 'sorted' ) %]
[% USE alpha = table(letters, rows=2) %]
[% FOREACH col = alpha.col %]
[% FOREACH item = col %][% item %]..[% END +%]
[% END %]

[% FOREACH row = alpha.rows %]
[% FOREACH item = row %][% item %]..[% END +%]
[% END %]

-- expect --
a..b..
c..d..
e..f..
g..h..
i..j..

a..c..e..g..i..
b..d..f..h..j..












