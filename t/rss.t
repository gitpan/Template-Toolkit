#============================================================= -*-perl-*-
#
# t/rss.t
#
# Test the XML::RSS plugin.
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 2000 Andy Wardley.  All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: rss.t,v 1.1 2000/03/01 13:39:09 abw Exp $
# 
#========================================================================

use strict;
use lib qw( lib ../lib );
use Template;
use Template::Test;
use Cwd qw( abs_path );
$^W = 1;

eval "use XML::RSS";
if ($@) {
    print "1..0\n";
    exit(0);
}

# account for script being run in distribution root or 't' directory
my $file = abs_path( -d 't' ? 't/test' : 'test' );
$file .= '/example.rdf';   

test_expect(\*DATA, undef, { 'newsfile' => $file });

__END__
-- test --
[% USE news = XML.RSS(newsfile) -%]
[% FOREACH item = news.items -%]
* [% item.title %]
  [% item.link  %]

[% END %]

-- expect --
* I Read the News Today
  http://oh.boy.com/

* I am the Walrus
  http://goo.goo.ga.joob.org/

-- test --
[% USE news = XML.RSS(newsfile) -%]
[% news.channel.title %]
[% news.channel.link %]

-- expect --
Template Toolkit XML::RSS Plugin
http://template-toolkit.org/plugins/XML/RSS

-- test --
[% USE news = XML.RSS(newsfile) -%]
[% news.image.title %]
[% news.image.url %]

-- expect --
Test Image
http://www.myorg.org/images/test.png





