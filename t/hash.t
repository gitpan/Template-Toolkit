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
# $Id: hash.t,v 1.9 1999/11/25 17:51:25 abw Exp $
# 
#========================================================================

use strict;
use lib qw( ../lib );
use Template;
use Template::Test;
$^W = 1;

use Template::Context;
#$Template::Context::DEBUG = 1;
$Template::Test::DEBUG = 0;

my $data = {
    a => 'alpha',
    b => 'bravo',
    c => 'charlie',
    is_hash => \&test_hash,
};
test_expect(\*DATA, { POST_CHOMP => 1 }, $data);

sub test_hash {
    my $hash = shift;
    return ref($hash) eq 'HASH' 
	? 'is a hash'
	: 'is not a hash';
}
	    
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

-- test --
[% empty = { } %]
[% is_hash(empty) %]
-- expect --
is a hash

-- test --
[% list = [ { a => b }, { } ] %]
[% is_hash(list.0) +%]
[% is_hash(list.1) %]
-- expect --
is a hash
is a hash

-- test --
[% is_hash({ }, 123) %]
-- expect --
is a hash

