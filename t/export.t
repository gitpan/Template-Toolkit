#============================================================= -*-Perl-*-
#
# t/export.t
#
# Template script testing EXPORT of data from an INCLUDE block.
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: export.t,v 1.3 1999/08/01 13:43:17 abw Exp $
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


my $template = Template->new({ INTERPOLATE => 1, POST_CHOMP => 1 });

test_expect(\*DATA, $template, $params);

__DATA__
Defining exception handler...
[% CATCH undef %]
<UNDEFINED>
[% END %]
done
Defining blocks...
[% BLOCK number %]  
number
[% EXPORT = 123 %]
[% END %]
[% BLOCK list   %]
list
[% EXPORT = [ 123, 456, 'seven eight nine' ]  %]
[% END %] 
done

-- expect --
Defining exception handler...
done
Defining blocks...
done

-- test --
[% stuff %]
[% INCLUDE stuff = number %]
[% stuff %]

-- expect --
<UNDEFINED>
number
123

-- test --
[% FOREACH item = things %]
item: [% item %]

[% END %]
[% INCLUDE things = list %]
[% FOREACH item = things %]
item: [% item %]

[% END %]

-- expect --
<UNDEFINED>
list
item: 123
item: 456
item: seven eight nine

