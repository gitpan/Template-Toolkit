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
# $Id: abspaths.t,v 1.2 1999/11/25 17:51:21 abw Exp $
#
#========================================================================

use strict;
use lib qw( ../lib );
use Template::Constants qw( :status );
use Template::Test;
use Cwd 'abs_path';

$^W = 1;

$Template::Test::DEBUG = 0;

#------------------------------------------------------------------------
# test that a file exception gets thrown unless ABSOLUTE_PATHS is enabled

# account for script being run in distribution root or 't' directory
my $file = abs_path( -d 't' ? 't/test/src' : 'test/src' );
$file .= '/foo';

my $tproc = Template->new({ 
    ABSOLUTE_PATHS => 0,
    CATCH => { 
	file => sub {
	    my ($context, $type, $info) = @_;
#	    $context->output("Caught $type exception: $info");
	    return STATUS_ERROR;
	},
    },
});

my $params = {
    filename => $file,
};

# process() should fail with an error value of STATUS_ERROR
pre_ok($tproc->process($file));
pre_ok($tproc->error() == STATUS_ERROR);

test_expect(\*DATA, { ABSOLUTE_PATHS => 1 }, $params);

__DATA__
[% INCLUDE $filename %]

-- expect --
This is foo  a is $a



