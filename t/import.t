#============================================================= -*-Perl-*-
#
# t/import.t
#
# Template script testing IMPORT option to stash.
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: import.t,v 1.3 1999/08/01 13:43:18 abw Exp $
# 
#========================================================================

use strict;
use lib qw( . ./t ../lib );
use vars qw( $DEBUG );
use Template qw( :status );
require 'texpect.pl';
$^W = 1;

$DEBUG = 0;

my ($a, $b, $c, $d, $e, $f ) = 
	qw( alpha bravo charlie delta echo foxtrot);
my $params = {
    'a'    => $a,
    'b'    => $b,
    'c'    => $c,
    'd'    => {
	'e' => $e,
	'f' => $f,
    },
};


my $template = Template->new({ INTERPOLATE => 1 });

test_expect(\*DATA, $template, $params);

__DATA__
Defining catch block
[% CATCH undef -%]
NOT DEFINED
[%- END -%]
done

-- expect --
Defining catch block
done

-- test --
[% a %]
[% e %]

-- expect --
alpha
NOT DEFINED

-- test --
[% IMPORT=d -%]
[% e %]
[% f %]
-- expect --
echo
foxtrot


-- test --
[% b %]
[% IMPORT = b %]
[% c %]
-- expect --
bravo
NOT DEFINED
charlie
