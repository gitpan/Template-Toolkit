#============================================================= -*-perl-*-
#
# t/output.t
#
# Template script testing the OUTPUT option.
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: output.t,v 1.3 1999/11/25 17:51:27 abw Exp $
#
#========================================================================

use strict;
use lib qw( ../lib );
use Template qw( :template );
use Template::Test;
$^W = 1;

$Template::Test::DEBUG = 0;

# sample data
my ($a, $b, $c, $d, $e ) = 
	qw( alpha bravo charlie delta echo );

my $params = { 
    'a' => $a,
    'b' => $b,
    'c' => $c,	
    'd' => $d,
    'e' => $e,
};

# determine output path so that this script can be run from the 't' 
# sub-directory as well as from the distribution root via 'make test'
my $output;
my $dir = 'test/dest';
if (-d $dir) {
    $output = $dir;
}
elsif (-d "t/$dir") {
    $output = "t/$dir";
}
else {
    warn "Cannot determine output path\n";
}
pre_ok( $output );

#---- create template processor -----
my $config = {
    INCLUDE_PATH => [ qw( t/test/lib t/test/dest test/lib test/dest . ) ],
    OUTPUT_PATH  => $output,
};
my $tproc = Template->new($config);


#----- first test -----
$tproc->redirect(TEMPLATE_OUTPUT, "testfile1.atml");

my $input =<<EOF;
This is a test file created by t/output.t
[% a %]
[% b %]
[% TAGS [** **] -%]
[% c %]
[% d %]
The end
EOF

my $ok = $tproc->process(\$input, $params);
pre_ok( $ok );
warn $tproc->error() . "\n"
    unless $ok;

$tproc->redirect(TEMPLATE_OUTPUT);


#----- second test -----
$input = "This is another test file created by t/output.t";
$ok = $tproc->process(\$input, $params, "testfile2.atml");
pre_ok( $ok );
warn $tproc->error() . "\n"
    unless $ok;


#----- expect test -----
test_expect(\*DATA, $tproc, $params);

__DATA__
Next test
[% INCLUDE testfile1.atml -%]
End of next test.
-- expect --
Next test
This is a test file created by t/output.t
alpha
bravo
charlie
delta
The end
End of next test.

-- test --
Second test
[% INCLUDE testfile2.atml %]
End of second test.
Rain stopped play.
-- expect --
Second test
This is another test file created by t/output.t
End of second test.
Rain stopped play.
