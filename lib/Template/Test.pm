#============================================================= -*-Perl-*-
#
# Template::Test
#
# DESCRIPTION
#   Module defining a test harness which processes template input and
#   then compares the output against pre-define expected output.
#   Generates test output compatible with Test::Harness.  This was 
#   originally the t/texpect.pl script.
#
# AUTHOR
#   Andy Wardley   <abw@cre.canon.co.uk>
#
# COPYRIGHT
#   Copyright (C) 1996-1999 Andy Wardley.  All Rights Reserved.
#   Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.
#
#   This module is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
#
#----------------------------------------------------------------------------
#
# $Id: Test.pm,v 1.4 2000/02/17 11:41:48 abw Exp $
#
#============================================================================

package Template::Test;

require 5.004;

use strict;
use vars qw( @ISA @EXPORT $VERSION $DEBUG $loaded %callsign);
use Template qw( :template );
use Exporter;

$VERSION = sprintf("%d.%02d", q$Revision: 1.4 $ =~ /(\d+)\.(\d+)/);
$DEBUG   = 0;
@ISA     = qw( Exporter );
@EXPORT  = qw( callsign extra_tests pre_ok ntests test_expect ok );
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

    # remove anything before '-- start --' and/or after '-- stop --'
    $input = $' if $input =~ /\s*--+\s*start\s*--+\s*/;
    $input = $` if $input =~ /\s*--+\s*stop\s*--+\s*/;

    @tests = split(/^\s*--+\s*test\s*--+\s*\n/im, $input);

    # if the first line of the file was '--test--' (optional) then the 
    # first test will be empty and can be discarded
    shift(@tests) if $tests[0] =~ /^\s*$/;

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

#========================================================================
#
#
#========================================================================

=head1 NAME

Template::Test - module for automating test scripts

=head1 SYNOPSIS

    use Template::Test;
   
    $Template::Test::DEBUG = 0;   # set this true to see each test running
   
    pre_ok($truth);               # a pre-check test

    extra_tests($n);              # some extra tests follow test_expect()...

    test_expect($input, \%tproc_config, \%vars)

    ok($truth)                    # for 1..$n extra tests

=head1 DESCRIPTION

The Template::Test module defines the test_expect() sub-routine which
automates the testing of template input against expected output.  It
splits an input document into a number of separate tests, processes
each one using the Template Toolkit and then compares the generated
output against an expected output, also specified in the input
document.  It generates the familiar "ok/not ok" output compatible 
with Test::Harness.

An input filename or handle, or reference to a text string
(i.e. anything that the Template module accepts as a valid input)
should be provided which contains a number of tests defined in the
following format:

    -- test --
    input
    -- expect --
    expected output

    -- test --
    input for next test
    -- expect --
    expected output for next test
    -- error --
    expected errors (optional)

The first test in the file does not require a '-- test --' line.  Blank
lines between test sections are generally ignored.  The '-- error --'
section may be used to specify any error messages that the template
fragment is expected to produce.

The second and third parameters to test_expect() are optional.  The second
may be either a reference to a Template object which should be used to 
process the template fragments, or a reference to a hash array containing
configuration values which should be used to instantiate a new Template
object.  The third parameter may be used to reference a hash array of 
template parameters which should be defined when processing the tests.

    test_expect(\*DATA, { POST_CHOMP => 1 }, { a = 'alpha' });
   
The test_expect() sub counts the number of tests, and then calls ntests() 
to generate the familiar "1..$ntests\n" test harness line.  Each 
test defined generates three test numbers.  The first indicates 
that the input was processed without error.  The second that the 
output matches that expected.  The third does the same for any 
error text expected.

Additional test may also be run before test_expect() by calling the 
pre_ok() sub-routine, passing in a true/false value.  These test
results are cached until test_expect() is called.  They are added 
to the total number of tests and their output generated before 
the main template tests.

    pre_ok(1);
    test_expect('myfile');

Any additional tests that you wish to run after calling test_expect()
may be declared to the Template::Test module using the extra_tests($n)
sub-routine.  Call this B<before> calling test_expect() so that the 
total number of tests reported when test_expect() is called can be 
adjusted accordingly.  When it comes to performing these tests, simply
call ok() passing a true or false value to generate the "ok/not ok"
output.

    extra_tests(1);
    test_expect('myfile');
    ok(1);

If you don't want to call test_expect() at all then you can call
ntests($n) to declare the number of tests and generate the test 
header line.  After that, simply call ok() for each test passing 
a true or false values to indicate that the test passed or failed.

    ntests(2);
    ok(1);
    ok(0);

Lines in tests that start with a '#' are ignored.  Lines that look 
'-- likethis --' may also confuse the test splitter.

You can identify only a specific part of the input file for testing
using the '-- start --' and '-- stop --' markers.  Anything before the 
first '-- start --' is ignored, along with anything after the next 
'-- stop --' marker.

    -- test --
    this is test 1 (not performed)
    -- expect --
    this is test 1 (not performed)

    -- start --

    -- test --
    this is test 2
    -- expect --
    this is test 2
 
    -- stop --

    ...

For historical reasons and general utility, the module also defines a
'callsign' sub-routine which returns a hash containing the a..z of 
radio callsigns (e.g. a => 'alpha', b => 'bravo').  This is used by many
of the test scripts as a "known source" of variable values.

=head1 BUGS

This module is butt-ugly but it works.

It imports all methods by default.  This is generally a Bad Thing, but 
this module is really only used in test scripts (i.e. at build time) 
and it made it more compatible with the previous t/texpect.pl script.

=head1 AUTHOR

Andy Wardley E<lt>abw@cre.canon.co.ukE<gt>

=head1 REVISION

$Revision: 1.4 $

=head1 HISTORY

This module started life as the t/texpect.pl script.

=head1 COPYRIGHT

Copyright (C) 1996-1999 Andy Wardley.  All Rights Reserved.
Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

The test scripts in the 't' sub-directory, L<Template|Template>.

=cut



