#============================================================= -*-perl-*-
#
# t/catch.t
#
# Template script testing error handling via the Template::Context CATCH 
# option.
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: catch.t,v 1.9 1999/11/25 17:51:22 abw Exp $
#
#========================================================================

use strict;
use lib qw( ../lib );
use Template::Constants qw( :status );
use Template::Test;
$^W = 1;

$Template::Test::DEBUG = 0;

my $tproc = Template->new({	
    CATCH => {
	'file'  => sub {
		      my ($context, $type, $info) = @_;
		      # the part after the ':' is platform specific so 
		      # we chop it off and ignore it
		      $info = (split(/\:/, $info))[0];
		      $context->output("FILE ERROR ($info)");
		      return STATUS_OK;
		  },
	'default' => sub { STATUS_STOP },
#	'default' => STATUS_STOP,
    },
    DEBUG => 1,
});

test_expect(\*DATA, $tproc, callsign());


__DATA__
Defining undef handler...
[% CATCH undef -%]
CATCH: [% e.info -%]
[% END -%]
done
-- expect --
Defining undef handler...
done

-- test --
[% a %]
[% b %]
[% none %]
[% no.such %]
[% no.such = nothing %]
[% nothing = 0 %]
[% no.such = nothing %]
[% no.such %]
more...
-- expect --
alpha
bravo
CATCH: none is undefined
CATCH: no is undefined
CATCH: nothing is undefined


0
more...
-- test --
[% INCLUDE 'no_such_file_exists' %]
[% INCLUDE 'this file does not exist either' %]
-- expect --
FILE ERROR (no_such_file_exists)
FILE ERROR (this file does not exist either)

-- test --
# this test should raise a parse exception which will cause the 
# processor to STOP cleanly without any output

about to fail parse...
[% INCLUDE %]
never reached
-- expect --
FILE ERROR (parse error)

-- test --
%% CATCH -%%
Default catcher [[% e.type %]]: [% e.info %]
%% END -%%
%% THROW bamboozle 'Blinded by science' %%
-- expect --
Default catcher [bamboozle]: Blinded by science









