#============================================================= -*-perl-*-
#
# t/import.t
#
# Template script testing IMPORT directive and "IMPORT = namespace"
# assignment option.
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: import.t,v 1.6 1999/11/25 17:51:25 abw Exp $
# 
#========================================================================

use strict;
use lib qw( ../lib );
use Template qw( :status );
use Template::Test;
$^W = 1;

#$Template::Context::DEBUG = 1;
$Template::Test::DEBUG = 0;

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


test_expect(\*DATA, { INTERPOLATE => 1, POST_CHOMP => 1 }, $params);

__DATA__
[% domain = 'cre.canon.co.uk'
   name   = 'John Doe'  
   user   = {
    id    = 'abw'
    name  = 'Andy Wardley'
    email = "abw@$domain"
   }
%]
$user.id:  $user.name <$user.email>
Name: $name
[% IMPORT = user %]
Name: $name

-- expect --
abw:  Andy Wardley <abw@cre.canon.co.uk>
Name: John Doe
Name: Andy Wardley

-- test --
[% user.id    = 'xyz'
   user.name  = 'Xyzzyx'
   user.email = 'xyz@zyx.com'
%]
[% name = 'nobody' %]
Name: $name
[% INCLUDE user_block1 %]
Name: $name
[% INCLUDE user_block2 IMPORT=user %]
Name: $name
[% PROCESS user_block2 IMPORT=user %]
Name: $name
[% BLOCK   user_block1 %]*1 $user.id: $user.name <$user.email>
[% END %]
[% BLOCK   user_block2 %]*2 $id: $name <$email>
[% END %]
-- expect --
Name: nobody
*1 xyz: Xyzzyx <xyz@zyx.com>
Name: nobody
*2 xyz: Xyzzyx <xyz@zyx.com>
Name: nobody
*2 xyz: Xyzzyx <xyz@zyx.com>
Name: Xyzzyx
