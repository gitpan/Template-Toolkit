#============================================================= -*-perl-*-
#
# t/filter.t
#
# Template script testing FILTER directive.
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: filter.t,v 1.3 1999/10/01 10:56:29 abw Exp $
#
#========================================================================

use strict;
use lib qw( . ./t ../lib );
use vars qw( $DEBUG );
use Template qw( :status );
require 'texpect.pl';
$^W = 1;

$DEBUG = 0;

my ($a, $b, $c, $d) = qw( alpha bravo charlie delta );
my $params = { 
    'a'      => $a,
    'b'      => $b,
    'c'      => $c,
    'd'      => $d,
    'list'   => [ $a, $b, $c, $d ],
};
my $config = {
    INTERPOLATE => 1, 
    POST_CHOMP  => 1,
    FILTERS     => {
        'badfact'   => 'nonsense',
	'badfilt'   => sub { 'rubbish' },
	'microjive' => sub { \&microjive },
	'censor'    => \&censor_factory,
    },
};

sub microjive {
    my $text = shift;
    $text =~ s/microsoft/The 'Soft/sig;
    $text;
}

sub censor_factory {
    my @forbidden = @_;
    return sub {
	my $text = shift;
	foreach my $word (@forbidden) {
	    $text =~ s/$word/[** CENSORED **]/sig;
	}
	return $text;
    }
}

test_expect(\*DATA, $config, $params);
 

__DATA__
[% FILTER html %]
This is some html text
All the <tags> should be escaped & protected
[% END %]
-- expect --
This is some html text
All the &lt;tags&gt; should be escaped &amp; protected

-- test --
[% text = "The <cat> sat on the <mat>" %]
[% FILTER html %]
   text: $text
[% END %]
-- expect --
   text: The &lt;cat&gt; sat on the &lt;mat&gt;

-- test --
[% text = "The <cat> sat on the <mat>" %]
[% text FILTER html %]
-- expect --
The &lt;cat&gt; sat on the &lt;mat&gt;

-- test --
[% FILTER format %]
Hello World!
[% END %]
-- expect --
Hello World!

-- test --
# test aliasing of a filter
[% FILTER comment = format('<!-- %s -->') %]
Hello World!
[% END +%]
[% "Goodbye, cruel World" FILTER comment %]
-- expect --
<!-- Hello World! -->
<!-- Goodbye, cruel World -->

-- test --
[% FILTER format %]
Hello World!
[% END %]
-- expect --
Hello World!

-- test --
[% "Foo" FILTER test1 = format('+++ %-4s +++') +%]
[% FOREACH item = [ 'Bar' 'Baz' 'Duz' 'Doze' ] %]
  [% item FILTER test1 +%]
[% END %]
[% "Wiz" FILTER test1 = format("*** %-4s ***") +%]
[% "Waz" FILTER test1 +%]
-- expect --
+++ Foo  +++
  +++ Bar  +++
  +++ Baz  +++
  +++ Duz  +++
  +++ Doze +++
*** Wiz  ***
*** Waz  ***

-- test --
[% FILTER microjive %]
The "Halloween Document", leaked to Eric Raymond from an insider
at Microsoft, illustrated Microsoft's strategy of "Embrace,
Extend, Extinguish"
[% END %]
-- expect --
The "Halloween Document", leaked to Eric Raymond from an insider
at The 'Soft, illustrated The 'Soft's strategy of "Embrace,
Extend, Extinguish"

-- test --
[% FILTER censor('bottom' 'nipple') %]
At the bottom of the hill, he had to pinch the
nipple to reduce the oil flow.
[% END %]
-- expect --
At the [** CENSORED **] of the hill, he had to pinch the
[** CENSORED **] to reduce the oil flow.

-- test --
[% CATCH; msg = "$e.type: $e.info"; ERROR msg; "[-- BZZZZT --]"; END %]
[% FILTER badfact %]
[% END %]
-- expect --
[-- BZZZZT --]
-- error --
undef: invalid FILTER factory for 'badfact' (not a CODE ref)

-- test --
[% FILTER badfilt %]
[% END %]
-- expect --
[-- BZZZZT --]
-- error --
undef: invalid FILTER 'badfilt' (not a CODE ref)

-- test --
[% FILTER bold = format('<b>%s</b>') %]
This is bold
[% END +%]
[% FILTER italic = format('<i>%s</i>') %]
This is italic
[% END +%]
[% 'This is both' FILTER bold FILTER italic %]
-- expect --
<b>This is bold</b>
<i>This is italic</i>
<i><b>This is both</b></i>

-- test --
[% "foo" FILTER format("<< %s >>") FILTER format("=%s=") %]
-- expect --
=<< foo >>=

