#============================================================= -*-perl-*-
#
# t/throw.t
#
# Template script testing the raising of exceptions via the THROW 
# directive.
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: throw.t,v 1.3 1999/09/09 17:02:02 abw Exp $
#
#========================================================================

use strict;
use lib qw( . ./t ../lib );
use vars qw( $DEBUG );
use Template::Constants qw( :status );
require 'texpect.pl';
$^W = 1;

$DEBUG = 0;

my $tproc = Template->new({	
    CATCH => {
	'foobar'  => sub {
	    my ($context, $type, $info) = @_;
	    $context->output("foobar handler ($info)\n");
	    return STATUS_OK;
	},
	'default' => sub {
	    my ($context, $type, $info) = @_;
	    $context->output("default handler [$type] ($info)");
	    return STATUS_STOP;
	},
    },
    INTERPOLATE => 1,
    POST_CHOMP  => 1,
    DEBUG       => 1,
});

test_expect(\*DATA, $tproc, callsign());


__DATA__
Defining undef handler...
[% CATCH undef %]
CATCH undef: [% e.info +%]
[% END %]
done
-- expect --
Defining undef handler...
done

-- test --
[% none %]
more...
-- expect --
CATCH undef: none is undefined
more...

-- test --
Foo
[% THROW boozle 'Wig Wam Bam Boozle' %]
Bar
-- expect --
Foo
default handler [boozle] (Wig Wam Bam Boozle)


-- test --
pre
[% THROW foobar 'Bar Bar Baby, Baby Bar Bar' %]
post
-- expect --
pre
foobar handler (Bar Bar Baby, Baby Bar Bar)
post

-- test --
[% CATCH football %]
Caught "$e.info"
[% THROW boggle 'The mind boggles' %]
Dropped football
[% END %]
Here's the throw...
[% THROW football "$a $z" +%]
End of play
-- expect --
Here's the throw...
Caught "alpha zulu"
default handler [boggle] (The mind boggles)

-- test --
[% CATCH treatment %]
Treating with $e.info
[% END %]
medical centre established
[% CATCH disease %]
Caught $e.info
[% THROW treatment 'antibiotics' %]
Cured!
[% END %]
treatment strategy established
[% THROW disease "an infection" %]
Repeat until deceased.
-- expect --
medical centre established
treatment strategy established
Caught an infection
Treating with antibiotics
Cured!
Repeat until deceased.









