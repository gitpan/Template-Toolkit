#============================================================= -*-perl-*-
#
# t/hash.t
#
# Test creation of hashes.
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: hash.t,v 1.7 1999/09/14 23:07:15 abw Exp $
# 
#========================================================================

use strict;
use lib qw( . ./t ../lib );
use vars qw( $DEBUG );
use Template;
require 'texpect.pl';
$^W = 1;

$DEBUG = 0;

test_expect(\*DATA, { POST_CHOMP => 1});

__DATA__
Defining hash...
%% user1 = {
     name = 'Andy Wardley'
     id   = 'abw'
   }
%%
done
[% user1.name %] ([%user1.id%])
-- expect --
Defining hash...
done
Andy Wardley (abw)

-- test --
%% user2 = {
     'name' = 'Andy Wardley'
     'id'   = 'abw'
   }
%%
[% user2.name %] ([%user2.id%])
-- expect --
Andy Wardley (abw)


-- test --
%% user3 = {
    "for"     = 'items'
    'include' = 'all_files'
   }
%%
[% f = 'for'  i = 'include'  foo.bar.baz = 'for'%]
[% user3.${f} +%]
[% user3.${"for"} +%]
[% user3.${i} +%]
[% user3.${'include'} +%]
[% user3.${"$f"} +%]
[% user3.${foo.bar.baz} %]
-- expect --
items
items
all_files
all_files
items
items


# test for hashes with extra commas
-- test --
%% user4 = {
    id   => 'lukes',
    name => 'Luke Skywalker',
   }
%%
[%user4.name%] ([%user4.id%])
-- expect --
Luke Skywalker (lukes)

-- test --
%% users = {
    abw  => 'Andy Wardley',
    mrp  => 'Martin Portman',
    sam  => 'Simon Matthews',
   }
%%
[% FOREACH id = users.keys.sort; "Users:\n" IF loop.first %]
  ID: [% id %]   Name: [% users.${id} +%]
[% END %]
[% FOREACH name = users.values.sort %]
[ [% name %] ] [% END %]
-- expect --
Users:
  ID: abw   Name: Andy Wardley
  ID: mrp   Name: Martin Portman
  ID: sam   Name: Simon Matthews
[ Andy Wardley ] [ Martin Portman ] [ Simon Matthews ] 



