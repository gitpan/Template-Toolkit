#============================================================= -*-perl-*-
#
# t/unless.t
#
# Template script testing the UNLESS directive.
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: unless.t,v 1.6 1999/11/25 17:51:31 abw Exp $
#
#========================================================================

use strict;
use lib qw( ../lib );
use Template::Test;
$^W = 1;

$Template::Test::DEBUG = 0;

my $params = {
    'true'      => 1,
    'false'     => 0,
    'damn_true' => 'yes, I said it was true',
    'lies'      => '',
    'damn_lies' => undef,
    'four'      => 4,
    'twenty'    => 20,
};

test_expect(\*DATA, undef, $params);

__DATA__
Fact: [% UNLESS true %]This is simply not true[% END %]
-- expect --
Fact: 

-- test --
[% UNLESS false -%]
Now this really is true
[% ELSE -%]
You're having a giraffe
[% END -%]
-- expect --
Now this really is true

-- test --
[% IF damn_true -%]
It is damn true
[% ELSE -%]
It is not damn true
[% END -%]
-- expect --
It is damn true

-- test --
[% IF ! damn_true -%]
It is not damn true
[% ELSE -%]
It is damn true
[% END -%]

[% UNLESS damn_true -%]
I say again, it is not damn true
[% ELSE -%]
I say again, it is damn true
[% END -%]

-- expect --
It is damn true

I say again, it is damn true

-- test --
[% IF four && twenty -%]
Relax
[% ELSE -%]
Don't Relax
[% END -%]

[% IF ! four and twenty -%]
Panic!
[% ELSE -%]
It's always [% four %]:[% twenty %] somewhere in the World
[% END -%]
-- expect --
Relax

It's always 4:20 somewhere in the World

-- test --
[% UNLESS true -%]
It is not false
[% ELSIF lies -%]
It is lies
[% ELSE -%]
It is true
[% END -%]
-- expect --
It is true







