#============================================================= -*-perl-*-
#
# t/dom.t
#
# Test the XML::DOM plugin.
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: dom.t,v 1.1 2000/03/01 13:39:09 abw Exp $
# 
#========================================================================

use strict;
use lib qw( lib ../lib );
use Template;
use Template::Test;
use Cwd qw( abs_path );
$^W = 1;

eval "use XML::DOM";
if ($@) {
    print "1..0\n";
    exit(0);
}

# account for script being run in distribution root or 't' directory
my $file = abs_path( -d 't' ? 't/test' : 'test' );
$file .= '/testfile.xml';   

test_expect(\*DATA, undef, { 'xmlfile' => $file });

__END__
-- test --
[% USE doc = XML.DOM(xmlfile) -%]
[% FOREACH tag = doc.getElementsByTagName('page') -%]
   * [% tag.href %] [% tag.title %]
[% END %]
-- expect --
   * /foo/bar The Foo Page
   * /bar/baz The Bar Page
   * /baz/qux The Baz Page




