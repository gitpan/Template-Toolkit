#============================================================= -*-perl-*-
#
# t/abspaths.t
#
# Template script testing the ABSPATHS option.
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: abspaths.t,v 1.1 1999/11/03 01:20:38 abw Exp $
#
#========================================================================

use strict;
use lib qw( . ./t ../lib );
use vars qw( $DEBUG );
use Template::Constants qw( :status );
use Template;
require 'texpect.pl';
$^W = 1;

$DEBUG = 0;

my $tproc = Template->new({ 
    ABSOLUTE_PATHS => 0,
});
test_expect(\*DATA, $tproc);

__DATA__
[% CATCH file %]NOT ALLOWED: [% e.info %][% END -%]
before
[% INCLUDE '/slash/bang/wallop' %]
after

-- expect --
before
NOT ALLOWED: /slash/bang/wallop: ABSOLUTE_PATHS not enabled
after

-- test --
[% INCLUDE /foo/bar.html %]

-- expect --
NOT ALLOWED: /foo/bar.html: ABSOLUTE_PATHS not enabled
