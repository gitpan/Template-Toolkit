#============================================================= -*-perl-*-
#
# t/macro.t
#
# Template script testing MACRO directive
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: macro.t,v 1.4 1999/11/25 17:51:26 abw Exp $
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
Defining macro
[% MACRO foo INCLUDE header %]
Defined macro

Calling macro
[% foo %]
Done

[% BLOCK header %]
This is the header
[% END %]

-- expect --
Defining macro
Defined macro

Calling macro
This is the header
Done

-- test --
[% MACRO header IF graphics %]
   Graphics are enabled!
[% ELSE %]
   Graphics are not enabled!
[% END %]
macro 'header' defined
calling header
[% header %]
[% graphics = 1 %]
calling header having set graphics on
[% header %]
done

-- expect --
macro 'header' defined
calling header
   Graphics are not enabled!
calling header having set graphics on
   Graphics are enabled!
done


-- test --
[% CATCH %]ERROR: [% e.type %]: [% e.info %][% END %]
[% MACRO zoom INCLUDE lord_lucan %]
starting
[% zoom +%]
done

-- expect --
starting
ERROR: file: lord_lucan: not found
done


-- test --
[% MACRO p "value of a is [$a]  value of b is [$b]" %]
[% p +%]
[% p(10) +%]
[% p(a = 'abw') +%]
[% alpha %]

-- expect --
value of a is [alpha]  value of b is [bravo]
value of a is [alpha]  value of b is [bravo]
value of a is [abw]  value of b is [bravo]

-- test --
[% MACRO header(t) INCLUDE header title="Happy Header: $t" %]
[% header %]
[% header() %]
[% header('Hello') %]
[% header('New Title', a = 'abw') %]

[% BLOCK header %]
Header ([% title %]) a: [% a +%]
[% END %]

-- expect --
Header (Happy Header: ) a: alpha
Header (Happy Header: ) a: alpha
Header (Happy Header: Hello) a: alpha
Header (Happy Header: New Title) a: abw

-- test --
[% MACRO url(host,page,port) 
     IF port; "http://$host:$port/$page";
     ELSE;    "http://$host/$page";
     END 
%]
[% url('www.foo.com', 'index.html')      +%]
[% url('www.bar.com', 'help.html', 8080) +%]

-- expect --
http://www.foo.com/index.html
http://www.bar.com:8080/help.html

-- test --
[% MACRO letter BLOCK %]
Dear $name,

I hope you are ${whatever}.
[% END %]
[% letter(name='Aunt Maud'  whatever='feeling well') %]

[% letter(name='Bill Gates' whatever='sick as a parrot') %]

-- expect --

Dear Aunt Maud,

I hope you are feeling well.

Dear Bill Gates,

I hope you are sick as a parrot.


-- test --
[% MACRO z a %]
z: [% z %]
[% a = b +%]
z: [% z %]

-- expect --
z: alpha
z: bravo
