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
# $Id: perl.t,v 1.2 1999/11/25 17:51:28 abw Exp $
#
#========================================================================

use strict;
use lib qw( ../lib );
use Template::Test;
$^W = 1;

$Template::Test::DEBUG = 0;

my ($a, $b, $c, $d, $w) = qw( alpha bravo charlie delta whisky );
my $params = {
    'a'    => $a,
    'b'    => $b,
    'c'    => $c,
    'd'    => $d,
    'w'    => $w,
};

my $template = Template->new({
	INTERPOLATE => 1,
	POST_CHOMP  => 1,
});

test_expect(\*DATA, $template, $params);

__DATA__
before perl
[% PERL %]
my $name = get_username($uid);
[% END %]
after perl

-- expect --
before perl
PERL directive not yet implemented
after perl
