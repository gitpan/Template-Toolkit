#============================================================= -*-Perl-*-
#
# t/cache.t
#
# Test script for Template::Cache.pm.
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: cache.t,v 1.4 1999/08/01 13:43:16 abw Exp $
#
#========================================================================

use strict;
use lib qw( . ./t ../lib );
use vars qw( $DEBUG );
use Template::Cache;
require 'texpect.pl';
$^W = 1;

$DEBUG = 0;

my $cache = Template::Cache->new()
    || die "Failed to create cache\n";

my $def =<<EOF;
[% d = 'delta' -%]
[% BLOCK foo -%]
[% DEFAULT title="DefTitle" -%]
This is foo: [% title -%]
[% END -%]
End of definition block
EOF

my $compiled = $cache->fetch(\$def, 'defblock')
    || die $cache->error->as_string, "\n";

my $tproc = Template->new({
    CACHE => $cache,
})
    || die "Failed to create Template\n";

test_expect(\*DATA, $tproc);


__DATA__
[% INCLUDE 'foo' %]
[% INCLUDE 'foo' title = 'This is a test of foo' %]
[% INCLUDE 'defblock' %]
[% INCLUDE 'foo' %]
-- expect --
This is foo: DefTitle
This is foo: This is a test of foo
End of definition block

This is foo: DefTitle
-- test --
Defining header block
[% BLOCK header -%]
This is the header
[%- END -%]
End of header block definition
header: [% INCLUDE 'header' %]
-- expect --
Defining header block
End of header block definition
header: This is the header
-- test --
start of test
1: [% INCLUDE 'header' %]
2: [% INCLUDE 'header' %]
end of test
-- expect --
start of test
1: This is the header
2: This is the header
end of test






