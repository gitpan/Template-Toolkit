#============================================================= -*-perl-*-
#
# t/tags.t
#
# Template script testing TAGS parse-time directive to switch the
# tokens that mark start and end of directive tags.
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: tags.t,v 1.3 2000/05/19 10:56:31 abw Exp $
# 
#========================================================================

use strict;
use lib qw( ../lib );
use Template qw( :status );
use Template::Test;
$^W = 1;

$Template::Test::DEBUG = 0;

my $params = {
    'a'  => 'alpha',
    'b'  => 'bravo',
    'c'  => 'charlie',
    'd'  => 'delta',
    'e'  => 'echo',
};


test_expect(\*DATA, { INTERPOLATE => 1 }, $params);

__DATA__
[%a%] [% a %] [% a %]
-- expect --
alpha alpha alpha

-- test --
Redefining tags
[% TAGS (+ +) %]
[% a %]
[% b %]
(+ c +)
-- expect --
Redefining tags

[% a %]
[% b %]
charlie

-- test --
[% a %]
[% TAGS (+ +) %]
[% a %]
%% b %%
(+ c +)
(+ TAGS <* *> +)
(+ d +)
<* e *>
-- expect --
alpha

[% a %]
%% b %%
charlie

(+ d +)
echo

-- test --
[% TAGS (+ +) -%]
[% a %]
[% b %]
(+ c +)
-- expect --
[% a %]
[% b %]
charlie

-- test --
[% tags (+ +) -%]
[% a %]
[% b %]
(+ c +)
-- expect --
[% a %]
[% b %]
charlie

-- test --
[% TAGS html -%]
<!-- a -->
<!-- TAGS asp -->
<% b %>
<% TAGS php %>
<? c ?>
<? TAGS template ?>
[% d %]
-- expect --
alpha

bravo

charlie

delta


