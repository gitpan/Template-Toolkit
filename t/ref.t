#============================================================= -*-perl-*-
#
# t/ref.t
#
# Template script testing the reference operator, '\'.
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id$
# 
#========================================================================

use strict;
use lib qw( ../lib );
use Template qw( :ops );
use Template::Test;
use Template::Context;
#$Template::Context::DEBUG = 1;

$^W = 1;

$Template::Test::DEBUG = 0;

my $vars = {
    'a'   => 'alpha',
    'b'   => 'bravo',
    'c'   => 'charlie',
    'foo' => sub { my $x = shift || '<undef>'; 
		   return "foo($x)" },
    'bar' => sub { my $x = shift || '<undef>'; $x = &$x if ref($x) eq 'CODE'; 
		   return "bar($x)" },
    'baz' => 'baz',
    'comment' => \&html_comment,
    'magic'   => \&do_magic,
    'format'  => \&sprintf_format,
    'joint'   => \&connect,
};

sub html_comment {
    my $text = shift || '';
    $text =~ s/^(.*)$/<!-- $1 -->/mg;
    return $text;
}

sub sprintf_format {
    my $format = shift || '%s';
    my $text   = shift || '';
    $text = sprintf($format, $text);
    return $text;
}

sub do_magic {
    my ($data, $callback) = @_;
#    print "data: [@$data]\n";
    @$data = sort @$data;
#    print "sorted data: [@$data]\n";
#    print "callback: $callback\n";
    @$data = map { &$callback($_) } @$data if ref($callback) eq 'CODE';
#    print "mapped data: [@$data]\n";

    return $data;
}

sub connect {
    return join('+', @_);
}

test_expect(\*DATA, undef, $vars);

__DATA__
-- test --
[% z = \comment -%]
a: [% z %]
b: [% z() %]
c: [% z(10) %]

-- expect --
a: <!--  -->
b: <!--  -->
c: <!-- 10 -->

-- test --
[% z = \comment() -%]
a: [% z %]
b: [% z() %]
c: [% z(10) %]

-- expect --
a: <!--  -->
b: <!--  -->
c: <!-- 10 -->

-- test --
[% z = \comment(a) -%]
a: [% z %]
b: [% z(b) %]

-- expect --
a: <!-- alpha -->
b: <!-- alpha -->

-- test --
[% "$item\n" FOREACH item = magic([c b a], \comment) %]

-- expect --
<!-- alpha -->
<!-- bravo -->
<!-- charlie -->

-- test --
[% p FOREACH p = magic([c b a], \format("** %-10s **\n")) %]

-- expect --
** alpha      **
** bravo      **
** charlie    **

-- test --
[% MACRO table_row(data) BLOCK -%]
<td>[% data %]</td>
[% END -%]
[% ok = magic([c b a], \table_row) %]

-- expect --
<td>alpha</td>
<td>bravo</td>
<td>charlie</td>


-- test --
[% joint(a, b) %]
-- expect  --
alpha+bravo

-- test --
[% "$p\n" FOREACH p = magic([b, a], \joint(c)) %]
-- expect --
charlie+alpha
charlie+bravo

