#============================================================= -*-Perl-*-
#
# t/texpect.pl
#
# Test script function for processing some template input and then 
# comparing the output against a pre-define expected output.
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#------------------------------------------------------------------------
# USAGE:
#    use lib qw( . ./t ../lib );
#    use vars qw( $DEBUG );
#    use Template;
#    require 'texpect.pl';
#
#    $DEBUG = 0;       # set this true to see each test running
#
#    extra_tests($n);  # some extra tests follow test_expect()...
#    pre_ok($truth);   # a pre-check test
#    test_expect($input, \%tproc_config, \%vars)
#    ok( $truth )      # for 1..$n extra tests
#
#
# The test_expect() sub splits the input source into a number of tests:
#
# Each test is defined like this:
#   -- test --
#   input
#   -- expect --
#   expected output
#   -- error --
#   expected error message(s) (optional)
#
# The first test in the file does not require a '-- test --' line.
#
# test_expect() counts the number of tests, and then calls ntests() 
# to generate the familiar "1..$ntests\n" test harness line.  Each 
# test defined generates three test numbers.  The first indicates 
# that the input was processed without error.  The second that the 
# output matches that expected.  The third does the same for any 
# error text expected.  In addition to this, any test results cached
# by calling pre_ok() will be added to the total along with any 
# additional tests known to follow the test_expect() method, set 
# by calling extra_tests($n).  The known result of the pre_ok() 
# calls is printed first.  Then test_expect() resumes and calls ok()
# to generate its results.  Finally, control is returned to the caller
# who can manually call ok() to run and final tests.
#
# Lines in tests that start with a '#' are ignored.  Lines that 
# look '-- likethis --' may also confuse the test splitter.
#========================================================================

use strict;
use Template qw( :template );
use vars qw( $DEBUG $loaded %callsign);

$DEBUG = 0;
$^W = 1;
$| = 1;

# some random data
@callsign{ 'a'..'z' } = qw( 
	    alpha bravo charlie delta echo foxtrot golf hotel india 
	    juliet kilo lima mike november oscar papa quebec romeo 
	    sierra tango umbrella victor whisky x-ray yankee zulu );

sub callsign {
    return \%callsign;
}


# kludge to allow us to define some extra tests to add to the 
# overall count

my @pre_tests = ();
my $xtests = 0;
sub extra_tests {
    $xtests = shift;
}

my ($ntests, $ok_count);

sub ntests {
    $ntests = shift;
    $ntests += $xtests + scalar @pre_tests;	# add any extra tests 
    $ok_count = 1;
    print "1..$ntests\n";
    foreach my $pre_test (@pre_tests) {
	ok($pre_test);
    }
}

sub pre_ok {
    my $ok = shift || 0;
    push(@pre_tests, $ok);
}

sub ok {
    warn "ok() called before ntests()\n"
	unless $ok_count;
    shift or print "not ";
    print "ok $ok_count\n";
    ++$ok_count;
}


sub test_expect {
    my ($src, $tproc, @params) = @_;
    my ($input, @tests);
    my ($ohandler, $ehandler, $output, $error, $expect, $errexpect, $match);
    my ($copyi, $copye, $copyo);
    local $/ = undef;

    # read input text
    eval {
	$input = ref $src ? <$src> : $src;
    };
    if ($@) {
	ntests(1); ok(0);
	warn "Cannot read input text from $src\n";
	return undef;
    }

    @tests = split(/^\s*--+\s*test\s*--+\s*\n/im, $input);

    ntests(3 + scalar(@tests) * 3);

    # first test is that Template loaded OK, which it did
    ok(1);

    # optional second param may contain a Template reference or a HASH ref
    # of constructor options, or may be undefined
    if (ref($tproc) eq 'HASH') {
	$tproc = Template->new($tproc);
    }
    $tproc ||= Template->new();

    # test: template processor created OK
    ok($tproc);

    # third test is that the input read ok, which it did
    ok(1);

    # the remaining tests are defined in @tests...

    # install new output and error redirection handlers
    $ohandler = $tproc->redirect(TEMPLATE_OUTPUT, \$output);
    $ehandler = $tproc->redirect(TEMPLATE_ERROR,  \$error);

    foreach $input (@tests) {

	# remove any comment lines
	$input =~ s/^#.*?\n//gm;

	# split input by a line like "-- expect --"
	($input, $expect) = 
	    split(/^\s*--+\s*expect\s*--+\s*\n/im, $input);
	$expect = '' 
	    unless defined $expect;

	# there may also be an "-- error --" section
	($expect, $errexpect) = 
	    split(/^\s*--+\s*error\s*--+\s*\n/im, $expect);
	$expect = '' 
	    unless defined $expect;
	$errexpect = '' 
	    unless defined $errexpect;

	$output = '';
	$error  = '';

	# process input text
	$tproc->process(\$input, @params) || do {
	    warn "Template process failed: ", $tproc->error(), "\n";
	    # report failure and automatically fail the expect match
	    ok(0);
	    ok(0);
	    next;
	};

	# processed OK
	ok(1);

	# strip any trailing blank lines from expected and real output
	foreach ($expect, $errexpect, $output) {
	    s/\n*\Z//mg;
	}

	$match = ($expect eq $output) ? 1 : 0;
	if (! $match || $DEBUG) {
	    
	    print "MATCH FAILED\n"
		unless $match;

	    ($copyi, $copye, $copyo) = ($input, $expect, $output);
	    foreach ($copyi, $copye, $copyo) {
		s/\n/\\n/g;
	    };
	    printf(" input: [%s]\nexpect: [%s]\noutput: [%s]\n", 
		   $copyi, $copye, $copyo);
	}

	ok($match);

	if ($errexpect) {
	    $match = ($errexpect eq $error) ? 1 : 0;

	    if (! $match || $DEBUG) {
		print "ERROR MATCH FAILED\n"
		    unless $match;
		($copye, $copyo) = ($errexpect, $error);
		foreach ($copye, $copyo) {
		    s/\n/\\n/g;
		};
		printf("expect: [%s]\n error: [%s]\n", $copye, $copyo);
	    }
	    ok($match);
	}
	else {
	    ok(1);
	}
    };

    # restore original output and error handlers
    $tproc->redirect(TEMPLATE_OUTPUT, $ohandler);
    $tproc->redirect(TEMPLATE_ERROR,  $ehandler);

}






1;
