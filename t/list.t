#============================================================= -*-perl-*-
#
# t/list.t
#
# Test creation of lists.
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: list.t,v 1.4 1999/09/14 23:07:16 abw Exp $
# 
#========================================================================

use strict;
use lib qw( . ./t ../lib );
use vars qw( $DEBUG );
use Template;
require 'texpect.pl';
$^W = 1;

#use Template::Context;
#$Template::Context::DEBUG = 1;
$DEBUG = 0;

test_expect(\*DATA, { INTERPOLATE => 1, POST_CHOMP => 1}, callsign());

__DATA__
Defining block...
[% BLOCK html_list %]
[% RETURN unless list %]
<ul>
[% FOREACH item = list %]
<li>$item
[% END %]
</ul>
[% END %]
[% BLOCK short_list %]
[% RETURN UNLESS list %]
list: 
[%- FOREACH item = list %]
$item, 
[%- END +%]
[% END %]
done
-- expect --
Defining block...
done

-- test --
[% INCLUDE html_list list=[ a b w ] %]
-- expect --
<ul>
<li>alpha
<li>bravo
<li>whisky
</ul>

-- test --
[% callsigns = [ c t r s ] %]
[% INCLUDE html_list list=callsigns %]
-- expect --
<ul>
<li>charlie
<li>tango
<li>romeo
<li>sierra
</ul>

-- test --
[% call1 = [ a  b  c  ] %]
[% call2 = [ d, e, f  ] %]
[% call3 = [ g, h, i, ] %]
[% INCLUDE short_list list=${"call$n"} FOREACH n = [ 1 2 3 ] %]
-- expect --
list: alpha, bravo, charlie, 
list: delta, echo, foxtrot, 
list: golf, hotel, india, 

-- test --
[% list1 = [ a b c d ]
   list2 = [ e f g h i j ]
%]
size of list1: [% list1.size +%]
 max of list2: [% list2.max +%]
-- expect --
size of list1: 4
 max of list2: 5

-- test -- 
[% FOREACH a = [1..5] %]
[% a %]
[% END %]
-- expect --
12345

-- test --
[% start = 1
   finish = 4 
%]
[% FOREACH a = [start..finish] %]
[% a +%]
[% END %]
-- expect --
1
2
3
4



