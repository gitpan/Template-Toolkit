#============================================================= -*-perl-*-
#
# t/context.t
#
# Test script for Template::Context.pm.
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# TODO: this only tests output(), error() and redirect().  Should really
#   test process(), throw() and possibly _runop() for completeness but 
#   these get so thoroughly tested by so many things that any problems 
#   there would show up immediately and blow smoke.
#
# $Id: context.t,v 1.6 1999/08/10 11:09:12 abw Exp $
#
#========================================================================

use strict;
use lib qw( . ./t ../lib );
use vars qw( $DEBUG );
use Template::Constants qw( :template :status );
use Template::Context;
require 'texpect.pl';
$^W = 1;

$DEBUG = 0;

# number of tests
ntests(11);

my ($output, $error);
my $context = Template::Context->new({
    OUTPUT     => \$output,
    ERROR      => \$error,
    PRE_DEFINE => { 'a' => 'alpha', 'b' => 'bravo' },
});

#1 - loaded OK
ok($context);

#2-3 - test output and error methods
$context->output("Hello");
ok( $output eq "Hello" );
$context->error("World");
ok( $error eq "World" );
$output = $error = "";

#4-6 - test redirection of output 
my $old_handler = $context->redirect(TEMPLATE_OUTPUT, \$error);
ok( $old_handler );
$context->output("Hello");
ok( $error eq "Hello" );
$context->error(" World");
ok( $error eq "Hello World" );

$output = $error = '';

#7-9 - re-install previous handler and test
my $new_handler = $context->redirect(TEMPLATE_OUTPUT, $old_handler);
ok( $new_handler );
$context->output("Hello");
ok( $output eq "Hello" );
$context->error("World");
ok( $error eq "World" );

$output = $error = '';

#10-12 - once last switch-around
$context->redirect(TEMPLATE_OUTPUT, $new_handler);
$context->output("Hello");
ok( $error eq "Hello" );
$context->redirect(TEMPLATE_OUTPUT, $old_handler);
$context->output("World");
ok( $output eq "World" );



print "OS: ", $context->{ OS }->name(), "\n";





