#============================================================= -*-Perl-*-
#
# t/exception.t
#
# Test script for Template::Exception.pm
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: exception.t,v 1.4 1999/07/28 11:32:29 abw Exp $
#
#========================================================================

use strict;
use vars qw($loaded $ntests);
$^W = 1;

my $DEBUG = 0;

BEGIN { 
    $ntests = 15;
    $| = 1; 
    print "1..$ntests\n"; 
}

END {
    ok(0) unless $loaded;
}

my $ok_count = 1;
sub ok {
    shift or print "not ";
    print "ok $ok_count\n";
    ++$ok_count;
}

use Template::Exception;
use Template::Context;
use Template::Constants qw( :status );
$loaded = 1;
$^W = 1;
ok(1);


# create some sample data
my @efields = ( 'file', 'some kind of file error' );
my @cfields = ( 'barf', 'catch this barf' );
my $e = Template::Exception->new(@efields);

#2 - check exceptions got created
ok( $e );

#3-4 - check internal data
ok( $e->{ TYPE } eq $efields[0] );
ok( $e->{ INFO } eq $efields[1] );

#5-6 - check via explicit public interface
ok( $e->type() eq $efields[0] );
ok( $e->info() eq $efields[1] );

#7 - create a dummy context for testing exception process() method
my $context = Template::Context->new({ 
    CATCH => { 
	$cfields[0] => \&catch_exception,
    },
});
ok( $context );

#8-10 - call context throw to raise an exception
my $x = $context->throw( $e ); 
ok( $x );
ok( $x->type eq $e->type );
ok( $x->info eq $x->info );

#11-13 - call context throw to raise an exception from type and info
my $y = $context->throw( @efields ); 
ok( $y );
ok( $y->type eq $efields[0] );
ok( $y->info eq $efields[1] );

#14-15 - call context throw to raise an exception
my $z = $context->throw( @cfields );    # calls ok()  # 11
ok( $z == STATUS_OK );

sub catch_exception {
    my ($context, $type, $info) = @_;
    print "catching exception [ $type ] $info\n"
	if $DEBUG;
    ok( 1 );
    return STATUS_OK;
}


