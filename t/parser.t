#============================================================= -*-Perl-*-
#
# t/parser.t
#
# Test script for Template::Parser.pm.
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# TODO: this does nothing usefull
#
# $Id: parser.t,v 1.4 1999/08/01 13:43:19 abw Exp $
#
#========================================================================

use strict;
use vars qw($loaded $ntests);
$^W = 1;

BEGIN { 
    $ntests = 3;
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

use Template qw( :status );
use Template::Stash;
$loaded = 1;
ok(1);


#------------------------------------------------------------------------
# begin tests

package main;

my ($output, $error);

# sample stash data
my ($foo, $bar, $baz) = map { "This is '$_'" } qw( foo bar baz );
my $stash = Template::Stash->new({
	'foo' => $foo,
	'bar' => $bar,
    });	

my $tproc = Template->new({
    OUTPUT => \$output,
    ERROR  => \$error,
    STASH  => $stash,
});


my $text1 = 'Blah blah [% a = 10 %] foo: [% foo %]  a: [% a %]';

ok( $tproc->process(\$text1) );
ok( $output eq "Blah blah  foo: This is 'foo'  a: 10" );





