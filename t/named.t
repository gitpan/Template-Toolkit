#============================================================= -*-perl-*-
#
# t/named.t
#
# Template script testing passing of named parameters to code
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: named.t,v 1.2 1999/09/14 23:07:16 abw Exp $
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

#my $tproc = Template->new({ INTERPOLATE => 1, DEBUG => 1 });
my $tproc = Template->new({ INTERPOLATE => 1 });

# sample data
my ($a, $b, $c, $d) = qw( alpha bravo charlie delta );
my @days = qw( Monday Tuesday Wednesday Thursday Friday Saturday Sunday );
my $day = -1;
my $params = { 
    'a'       => $a,
    'b'       => $b,
    'c'       => $c,
    'd'       => $d,
    'collect' => \&collector,
};

test_expect(\*DATA, $tproc, $params);

sub collector {
    my @args = @_;
    my $hash = pop(@args) if ref($args[-1]) eq 'HASH';
    local $" = ', ';
    $tproc->context->output("Collected args: [ @args ]\n");
    $tproc->context->output("Also collected hash:\n",
			    map { sprintf("  %-8s => %s\n", 
					  $_, $hash->{ $_ }) } keys %$hash)
	if $hash;

    return '';
}

#------------------------------------------------------------------------
# test input
#------------------------------------------------------------------------

__DATA__
[% collect(a, b, c) %]
-- expect --
Collected args: [ alpha, bravo, charlie ]

-- test --
[% collect(a, b, name=c, email=d) %]
-- expect --
Collected args: [ alpha, bravo ]
Also collected hash:
  email    => delta
  name     => charlie

-- test --
[% collect(a, name=c, b, email=d) %]
-- expect --
Collected args: [ alpha, bravo ]
Also collected hash:
  email    => delta
  name     => charlie

