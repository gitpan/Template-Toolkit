#============================================================= -*-perl-*-
# t/accessor.t
#
# Template test script demonstrating an 'accessor' object that acts
# as an interface to a data source such as a database.
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: accessor.t,v 1.2 1999/11/25 17:51:21 abw Exp $
#
#========================================================================

use strict;
use lib qw( ../lib );
use Template qw( :status );
use Template::Test;
use Template::Exception;
$^W = 1;

$Template::Test::DEBUG = 0;


#------------------------------------------------------------------------
# definition of test object class
#------------------------------------------------------------------------

package Accessor;

use vars qw( $AUTOLOAD );

sub new {
    my ($class, $context, $data) = @_;
    $data ||= {};

    bless {
	DATA    => $data,
	CONTEXT => $context,
    }, $class;
}

sub AUTOLOAD {
    my ($self, @params) = @_;
    my $name = $AUTOLOAD;
    $name =~ s/.*:://;
    return if $name eq 'DESTROY';
    $self->get_record($name);
}

sub get_record {
    my ($self, $key) = @_;
    my $value;
    return (undef, Template::Exception->new('nouser', $key))
	unless defined ($value = $self->{ DATA }->{ $key });
    return $value;
}

sub thingy {
    my ($self, $key) = @_;
    return defined $key ? $self->get_record($key) : $self;
}


#------------------------------------------------------------------------
# main 
#------------------------------------------------------------------------

package main;

# sample data
my ($a, $b, $c, $d, $e) = qw( alpha bravo charlie delta echo );
my $database = { };
foreach my $name ($a, $b, $c, $d, $e) {
    print "+ $name\n";
    $database->{ $name } = { 'name'  => "Mr. $name", 
			     'email' => "$name\@here.com" };
}

my $tproc   = Template->new({ INTERPOLATE => 1, POST_CHOMP => 1 });
my $access  = Accessor->new($tproc->context(), $database);
my $params  = { 'db' => $access };

test_expect(\*DATA, $tproc, $params);


#------------------------------------------------------------------------
# test input
#------------------------------------------------------------------------

__DATA__
[% BLOCK item %]
Name: $item.name    Email: $item.email
[% END %]
[% item = db.thingy('alpha') %]
[% INCLUDE item %]
-- expect --
Name: Mr. alpha    Email: alpha@here.com

-- test --
[% item = db.thingy.bravo %]
[% INCLUDE item %]
-- expect --
Name: Mr. bravo    Email: bravo@here.com

-- test --
[% item = db.charlie %]
[% INCLUDE item %]
-- expect --
Name: Mr. charlie    Email: charlie@here.com



