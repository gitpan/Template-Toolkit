#============================================================= -*-Perl-*-
# t/object.t
#
# Template script testing code bindings to objects.
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: object.t,v 1.3 1999/08/01 13:43:19 abw Exp $
#
#========================================================================

use strict;
use lib qw( . ./t ../lib );
use vars qw( $DEBUG );
use Template qw( :status );
use Template::Exception;
require 'texpect.pl';
$^W = 1;

$DEBUG = 0;


#------------------------------------------------------------------------
# definition of test object class
#------------------------------------------------------------------------

package TestObject;

use vars qw( $AUTOLOAD );

sub new {
    my ($class, $context, $params) = @_;
    $params ||= {};

    bless {
	PARAMS  => $params,
	CONTEXT => $context,
	DAYS    => [ qw( Monday Tuesday Wednesday Thursday 
			 Friday Saturday Sunday ) ],
	DAY     => 0,
    }, $class;
}

sub yesterday {
    my $self = shift;
    return "Love was such an easy game to play...";
}

sub today {
    my $self = shift;
    my $when = shift || 'Now';
    return "Live for today and die for tomorrow.";
}

sub tomorrow {
    my ($self, $dayno) = @_;
    $dayno = $self->{ DAY }++
        unless defined $dayno;
    $dayno %= 7;
    return $self->{ DAYS }->[$dayno];
}

sub belief {
    my $self = shift;
    my $b = join(' and ', @_);
    $b = '<nothing>' unless length $b;
    return "Oh I believe in $b.";
}

sub homer {
    return "D'Oh";
}

sub fail {
    return undef;
}

sub puke {
    return (undef, Template::Exception->new('barf', 'Veni, Vidi, Barfi'));
}

# throw an exception via the context
sub context_throw {
    my $self = shift;
    my $context = $self->{ CONTEXT };
    return (undef, $context->throw('barf', 'We came, we saw, we hurled'));
}

sub _private {
    my $self = shift;
    die "illegal call to private method _private()\n";
}


sub AUTOLOAD {
    my ($self, @params) = @_;
    my $name = $AUTOLOAD;
    $name =~ s/.*:://;
    return if $name eq 'DESTROY';

    my $value = $self->{ PARAMS }->{ $name };
    if (ref($value) eq 'CODE') {
	return &$value(@params);
    }
    elsif (@params) {
	return $self->{ PARAMS }->{ $name } = shift @params;
    }
    else {
	return $value;
    }
}


#------------------------------------------------------------------------
# main 
#------------------------------------------------------------------------

package main;

# sample data
my ($a, $b, $c, $d, $e, $f) = qw( alpha bravo charlie delta echo foxtrot);
my $day = -1;

# these are *additional* parameters for the object to store that provide 
# access to other data and subs
my $obj_params = { 
    'a'      => $a,
    'b'      => $b,
    'w'      => 'whisky',
    'creed'  => \&belief,
    'day'    => {
	'prev' => \&yesterday,
	'this' => \&today,
	'next' => \&tomorrow,
    },
};

my $tproc   = Template->new({ INTERPOLATE => 1 });
my $tobj    = TestObject->new($tproc->context(), $obj_params);
my $params  = {
    'e'     => $e,
    'f'     => $f,
    'thing' => $tobj,
};

test_expect(\*DATA, $tproc, $params);


#------------------------------------------------------------------------
# subs
#------------------------------------------------------------------------

sub yesterday {
    return "All my troubles seemed so far away...";
}

sub today {
    my $when = shift || 'Now';
    return "$when it looks as though they're here to stay.";
}

sub tomorrow {
    my $dayno = shift;
    my @days = qw( Monday Tuesday Wednesday Thursday Friday Saturday Sunday );
    unless (defined $dayno) {
	$day++;
	$day %= 7;
	$dayno = $day;
    }
    return $days[$dayno];
}


sub belief {
    local $" = ', ';
    my $b = join(' and ', @_);
    $b = '<nothing>' unless length $b;
    return "Oh I believe in $b.";
}

#------------------------------------------------------------------------
# test input
#------------------------------------------------------------------------

__DATA__
# test method calling via autoload to get parameters
[% thing.a %]
[% thing.b %]
$thing.w
-- expect --
alpha
bravo
whisky

# ditto to set parameters
-- test --
[% thing.c = thing.b -%]
[% thing.c %]
-- expect --
bravo

-- test --
[% thing.homer           %]
[% thing.homer(900)      %]
[% thing.homer(900, 800) %]
[% thing.homer(thing.a thing.b thing.w)    %]
-- expect --
D'Oh
D'Oh
D'Oh
D'Oh

-- test --
$thing.homer
${thing.homer}
-- expect --
D'Oh
D'Oh

-- test --
[% thing.yesterday %]
[% thing.today %]
[% thing.belief(thing.a thing.b thing.w) %]
-- expect --
Love was such an easy game to play...
Live for today and die for tomorrow.
Oh I believe in alpha and bravo and whisky.

-- test --
Yesterday, $thing.yesterday
$thing.today
${thing.belief('yesterday')}
-- expect --
Yesterday, Love was such an easy game to play...
Live for today and die for tomorrow.
Oh I believe in yesterday.

-- test --
[% thing.belief('fish' 'chips') %]
[% thing.belief %]
-- expect --
Oh I believe in fish and chips.
Oh I believe in <nothing>.

-- test --
${thing.belief('fish' 'chips')}
$thing.belief
-- expect --
Oh I believe in fish and chips.
Oh I believe in <nothing>.

-- test --
[% thing.tomorrow %]
$thing.tomorrow
-- expect --
Monday
Tuesday

-- test --
[% FOREACH [ 1 2 3 4 5 ] %]$thing.tomorrow [% END %]
-- expect --
Wednesday Thursday Friday Saturday Sunday 


#------------------------------------------------------------------------
# test that object returns hash references that contains code or code 
# references themselves which should then get called by the context.
#------------------------------------------------------------------------
-- test --
[% thing.day.prev %]
[% thing.day.this %]
[% thing.creed(thing.a thing.b thing.w) %]
-- expect --
All my troubles seemed so far away...
Now it looks as though they're here to stay.
Oh I believe in alpha and bravo and whisky.

-- test --
Yesterday, $thing.day.prev
$thing.day.this
${thing.creed('yesterday')}
-- expect --
Yesterday, All my troubles seemed so far away...
Now it looks as though they're here to stay.
Oh I believe in yesterday.

-- test --
[% thing.creed('fish' 'chips') %]
[% thing.creed %]
-- expect --
Oh I believe in fish and chips.
Oh I believe in <nothing>.

-- test --
${thing.creed('fish' 'chips')}
$thing.creed
-- expect --
Oh I believe in fish and chips.
Oh I believe in <nothing>.

-- test --
[% thing.day.next %]
$thing.day.next
-- expect --
Monday
Tuesday

-- test --
[% FOREACH [ 1 2 3 4 5 ] %]$thing.day.next [% END %]
-- expect --
Wednesday Thursday Friday Saturday Sunday 


#------------------------------------------------------------------------
# test error handling
#------------------------------------------------------------------------
-- test --
[% CATCH undef -%]ERROR: $e.info[% END -%]
[% thing.fail %]
$thing.fail
-- expect --
ERROR: fail is undefined
ERROR: fail is undefined

-- test -- 
[% CATCH barf %]Yeeeuuuukkkk! [$e.info][% END -%] 
[% thing.puke %]
-- expect -- 
Yeeeuuuukkkk! [Veni, Vidi, Barfi]

-- test --
[% CATCH barf %]THROWN! [$e.info][% END -%] 
[% thing.context_throw %]
-- expect --
THROWN! [We came, we saw, we hurled]

-- test --
[% foo = thing.context_throw %]
Hello
-- expect --
THROWN! [We came, we saw, we hurled]
Hello

-- test --
[% thing.context_throw = 'aaa' %]
[% thing.context_throw %]
-- expect --
THROWN! [We came, we saw, we hurled]
THROWN! [We came, we saw, we hurled]


#------------------------------------------------------------------------
# test private methods do not get exposed
#------------------------------------------------------------------------
-- test --
[% thing._private %]
-- expect --
ERROR: _private is undefined

-- test --
[% thing._private = 10 %]
-- expect --
ERROR: invalid name [ _private ]


-- test --
[% key = '_private' -%]
[% thing.${key} %]
-- expect --
ERROR: _private is undefined

-- test --
[% key = '.private' -%]
[% thing.${key} = 'foo' %]
-- expect --
ERROR: invalid name [ .private ]




