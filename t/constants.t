#============================================================= -*-Perl-*-
#
# t/constants.t
#
# Test script for Template::Constants.pm.
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: constants.t,v 1.3 1999/07/28 11:32:28 abw Exp $
#
#========================================================================

use strict;
use vars qw($loaded $ntests);
$^W = 1;
select(STDERR); $| = 1;
select(STDOUT); $| = 1;

BEGIN { 
    $ntests = 9;
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

use Template::Constants;
$loaded = 1;
ok(1);

#2-3: test direct access of the constants
ok( defined(Template::Constants::DEBUG_ALL)  );
ok( Template::Constants::ERROR_FILE );


#4: test import of single constant
package test1;
use Template::Constants qw( STATUS_STOP );
main::ok( defined STATUS_STOP );


#5-6: test import of tagset
package test2;
use Template::Constants qw( :ops );
main::ok( OP_ROOT );
main::ok( OP_DOT  );


#7-9: test import via Template
package test3;
use Template qw( :debug OP_ASSIGN );
main::ok( defined DEBUG_ALL  );
main::ok( defined DEBUG_INFO );
main::ok( defined OP_ASSIGN  );













