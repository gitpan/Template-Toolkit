#============================================================= -*-perl-*-
#
# t/define.t
#
# Test script testing the define() method of the Template.pm module.
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 2000 Andy Wardley. All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: define.t,v 1.1 2000/03/27 12:35:28 abw Exp $
#
#========================================================================

use strict;
use lib qw( ../lib );
use Template::Constants qw( :status :template );
use Template;
use Template::Test;
$^W = 1;

$Template::Test::DEBUG = 0;

package MyDirective;
use vars qw( @ISA );
@ISA = qw( Template::Directive );

sub new {
    my $class = shift;
    bless { }, $class;
}

sub process {
    my ($self, $context) = @_;
    $context->output('MyDirective output');
    return 0;
}

package main;

my $tproc   = Template->new({ INTERPOLATE => 1 });
my $context = $tproc->context();

my $compiled = $tproc->define("Header: [% title %]", 'header');
pre_ok($compiled);


my $output;
$context->redirect(TEMPLATE_OUTPUT, \$output);
$context->{ STASH }->set('title' => 'Hello World');
pre_ok( $compiled->process($context) == STATUS_OK );
pre_ok( $output eq 'Header: Hello World' );

my $precomp = MyDirective->new();
$tproc->define($precomp, 'other');

test_expect(\*DATA, $tproc);



__DATA__
-- test --
[% INCLUDE header %]

-- expect --
Header: Hello World

-- test --
[% INCLUDE header title="Hello There" %]

-- expect --
Header: Hello There

-- test --
[% INCLUDE other %]

-- expect --
MyDirective output

