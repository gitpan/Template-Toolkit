#============================================================= -*-perl-*-
#
# t/vmeth.t
#
# Template script testing virtual variable methods implemented by
# Template::Stash.
#
# Written by Andy Wardley <abw@kfs.org>
#
# Copyright (C) 1996-2000 Andy Wardley.  All Rights Reserved.
# Copyright (C) 1998-2000 Canon Research Centre Europe Ltd.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: vmeth.t,v 2.12 2002/03/12 14:06:23 abw Exp $
#
#========================================================================

use strict;
use lib qw( ./lib ../lib );
use Template::Test;
use Template::Constants qw( :status );
$^W = 1;

#$Template::Stash::DEBUG = 1;
#$Template::Parser::DEBUG = 1;
#$Template::Directive::PRETTY = 1;

# add some new list ops
$Template::Stash::LIST_OPS->{ sum } = \&sum;
$Template::Stash::LIST_OPS->{ odd } = \&odd;
$Template::Stash::LIST_OPS->{ jumble } = \&jumble;

#------------------------------------------------------------------------
# define a simple object to test sort vmethod calling object method
#------------------------------------------------------------------------
package My::Object;
sub new { 
    my ($class, $name) = @_;
    bless {
	_NAME => $name,
    }, $class;
}
sub name { 
    my $self = shift;
    return $self->{ _NAME };
}
#------------------------------------------------------------------------

package main;

sub sum {
    my $list = shift;
    my $n = 0;
    foreach (@$list) {
	$n += $_;
    }
    return $n;
}

sub odd {
    my $list = shift;
    return [ grep { $_ % 2 } @$list ];
}

sub jumble {
    my ($list, $chop) = @_;
    $chop = 1 unless defined $chop;
    return $list unless @$list > 3;
    push(@$list, splice(@$list, 0, $chop));
    return $list;
}

my $params = {
    undef    => undef,
    zero     => 0,
    one      => 1,
    string   => 'The cat sat on the mat',
    spaced   => '  The dog sat on the log',
    hash     => { a => 'b', c => 'd' },
    uhash    => { tobe => '2b', nottobe => undef },
    metavars => [ qw( foo bar baz qux wiz waz woz ) ],
    people   => [ { id => 'tom',   name => 'Tom' },
		  { id => 'dick',  name => 'Richard' },
		  { id => 'larry', name => 'Larry' },
		],
    primes   => [ 13, 11, 17, 19, 2, 3, 5, 7 ],
    phones   => { 3141 => 'Leon', 5131 => 'Andy', 4131 => 'Simon' },
    groceries => { 'Flour' => 3, 'Milk' => 1, 'Peanut Butter' => 21 },
    names     => [ map { My::Object->new($_) }
		   qw( Tom Dick Larry ) ],
    numbers   => [ map { My::Object->new($_) }
		   qw( 1 02 10 12 021 ) ],

};

test_expect(\*DATA, undef, $params);

__DATA__

# SCALAR_OPS

-- test --
[% notdef.defined ? 'def' : 'undef' %]
-- expect --
undef

-- test --
[% undef.defined ? 'def' : 'undef' %]
-- expect --
undef

-- test --
[% zero.defined ? 'def' : 'undef' %]
-- expect --
def

-- test --
[% one.defined ? 'def' : 'undef' %]
-- expect --
def

-- test --
[% string.length %]
-- expect --
22

-- test --
[% string.split.join('_') %]
-- expect --
The_cat_sat_on_the_mat
-- test --

[% spaced.split.join('_') %]
-- expect --
The_dog_sat_on_the_log

-- test --
[% spaced.split(' ').join('_') %]
-- expect --
__The_dog_sat_on_the_log


# HASH_OPS

-- test --
[% hash.keys.sort.join(', ') %]
-- expect --
a, c

-- test --
[% hash.values.sort.join(', ') %]
-- expect --
b, d

-- test --
[% hash.each.sort.join(', ') %]
-- expect --
a, b, c, d

-- test --
[% hash.size %]
-- expect --
2

-- test --
[% hash.defined('a') ? 'good' : 'bad' %]
[% hash.a.defined ? 'good' : 'bad' %]
[% hash.defined('x') ? 'bad' : 'good' %]
[% hash.x.defined ? 'bad' : 'good' %]
-- expect --
good
good
good
good

-- test --
[% uhash.defined('tobe') ? 'good' : 'bad' %]
[% uhash.tobe.defined ? 'good' : 'bad' %]
[% uhash.exists('tobe') ? 'good' : 'bad' %]
[% uhash.defined('nottobe') ? 'bad' : 'good' %]
[% hash.nottobe.defined ? 'bad' : 'good' %]
[% uhash.exists('nottobe') ? 'good' : 'bad' %]
-- expect --
good
good
good
good
good
good


# LIST_OPS

-- test --
[% metavars.first %]
-- expect --
foo

-- test --
[% metavars.last %]
-- expect --
woz

-- test --
[% metavars.size %]
-- expect --
7

-- test --
[% metavars.max %]
-- expect --
6

-- test --
[% metavars.join %]
-- expect --
foo bar baz qux wiz waz woz

-- test --
[% metavars.join(', ') %]
-- expect --
foo, bar, baz, qux, wiz, waz, woz

-- test --
[% metavars.sort.join(', ') %]
-- expect --
bar, baz, foo, qux, waz, wiz, woz

-- test --
[% FOREACH person = people.sort('id') -%]
[% person.name +%]
[% END %]
-- expect --
Richard
Larry
Tom

-- test --
[% FOREACH obj = names.sort('name') -%]
[% obj.name +%]
[% END %]
-- expect --
Dick
Larry
Tom

-- test --
[% FOREACH obj = numbers.sort('name') -%]
[% obj.name +%]
[% END %]
-- expect --
02
021
1
10
12

-- test --
[% FOREACH obj = numbers.nsort('name') -%]
[% obj.name +%]
[% END %]
-- expect --
1
02
10
12
021

-- test --
[% FOREACH person = people.sort('name') -%]
[% person.name +%]
[% END %]
-- expect --
Larry
Richard
Tom

-- test --
[% folk = [] -%]
[% folk.push("<a href=\"${person.id}.html\">$person.name</a>")
    FOREACH person = people.sort('id') -%]
[% folk.join(",\n") %]
-- expect --
<a href="dick.html">Richard</a>,
<a href="larry.html">Larry</a>,
<a href="tom.html">Tom</a>

-- test --
[% primes.sort.join(', ') %]
-- expect --
11, 13, 17, 19, 2, 3, 5, 7

-- test --
[% primes.nsort.join(', ') %]
-- expect --
2, 3, 5, 7, 11, 13, 17, 19


# USER DEFINED LIST OPS

-- test --
[% items = [0..6] -%]
[% items.jumble.join(', ') %]
[% items.jumble(3).join(', ') %]
-- expect --
1, 2, 3, 4, 5, 6, 0
4, 5, 6, 0, 1, 2, 3

-- test -- 
[% primes.sum %]
-- expect --
77

-- test --
[% primes.odd.nsort.join(', ') %]
-- expect --
3, 5, 7, 11, 13, 17, 19

-- test --
[% FOREACH n = phones.sort -%]
[% phones.$n %] is [% n %],
[% END %]
-- expect --
Andy is 5131,
Leon is 3141,
Simon is 4131,

-- test --
[% FOREACH n = groceries.nsort.reverse -%]
I want [% groceries.$n %] kilos of [% n %],
[% END %]
-- expect --
I want 21 kilos of Peanut Butter,
I want 3 kilos of Flour,
I want 1 kilos of Milk,


-- test --
[% string = 'foo' -%]
[% string.repeat(3) %]
-- expect --
foofoofoo

-- test --
[% string1 = 'foobarfoobarfoo'
   string2 = 'foobazfoobazfoo'
-%]
[% string1.search('bar') ? 'ok' : 'not ok' %]
[% string2.search('bar') ? 'not ok' : 'ok' %]
[% string1.replace('bar', 'baz') %]
[% string2.replace('baz', 'qux') %]
-- expect --
ok
ok
foobazfoobazfoo
fooquxfooquxfoo

-- test --
[% string1 = 'foobarfoobarfoo'
   string2 = 'foobazfoobazfoo'
-%]
[% string1.match('bar') ? 'ok' : 'not ok' %]
[% string2.match('bar') ? 'not ok' : 'ok' %]
-- expect --
ok
ok

-- test --
[% string = 'foo     bar   ^%$ baz' -%]
[% string.replace('\W+', '_') %]
-- expect --
foo_bar_baz

-- test --
[% var = 'value99' ;
   var.replace('value', '')
%]
-- expect --
99

-- test --
[% bob = "0" -%]
bob: [% bob.replace('0','') %].
-- expect --
bob: .

-- test --
[% string = 'The cat sat on the mat';
   match  = string.match('The (\w+) (\w+) on the (\w+)');
-%]
[% match.0 %].[% match.1 %]([% match.2 %])
-- expect --
cat.sat(mat)

-- test --
[% string = 'The cat sat on the mat' -%]
[% IF (match  = string.match('The (\w+) sat on the (\w+)')) -%]
matched animal: [% match.0 %]  place: [% match.1 %]
[% ELSE -%]
no match
[% END -%]
[% IF (match  = string.match('The (\w+) shat on the (\w+)')) -%]
matched animal: [% match.0 %]  place: [% match.1 %]
[% ELSE -%]
no match
[% END -%]
-- expect --
matched animal: cat  place: mat
no match

-- stop --

-- test --
[% var = 'foo'; var.replace('f(o+)$', 'b$1') %]
-- expect --
boo

-- test --
[% var = 'foo|bar/baz'; var.replace('(fo+)|(bar)(.*)$', '[ $1 | $2 | $3 ]') %]
-- expect --
[ foo | bar | ]

