#============================================================= -*-perl-*-
#
# t/userdef.t
#
# Template script testing creation and use of user-defined directives and
# block directives.
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 1996-2000 Andy Wardley.  All Rights Reserved.
# Copyright (C) 1998-2000 Canon Research Centre Europe Ltd.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: userdef.t,v 1.2 2000/02/07 18:28:18 abw Exp $
# 
#========================================================================

use strict;
use lib qw( ../lib );
use Template qw( :status );
use Template::Test;
$^W = 1;

$Template::Test::DEBUG = 0;


sub make_foo {
    my $text = shift;
#    print STDERR "constructing foo from [$text]\n";
    return \&run_anything;
}

sub make_bar {
    my $text = shift;
#    print STDERR "constructing bar from [$text]\n";
    return \&run_anything;
}

sub make_baz {
    my $params = shift;
    my $name;
    ($name, $params) = split(/\s+/, $params, 2);
    
    return sub {
	my ($context, $text) = @_;
	$text =~ s/^/  /mg;
	chomp $text;
	$context->output("<$name($params)>\n$text\n</$name>\n");
	STATUS_OK;
    }
}
	

sub run_anything {
    my ($context, $text) = @_;
    $text ||= '<non-block>';
    $context->output("run_anything($text)");
    return STATUS_OK;
}

my $config = { 
    USER_DIR   => { foo => \&make_foo },
    USER_BLOCK => { bar => \&make_bar, baz => \&make_baz },
};

test_expect(\*DATA, $config);

__DATA__
-- test --
[% foo %]
-- expect --
run_anything(<non-block>)

-- test --
[% foo bar baz %]
-- expect --
run_anything(<non-block>)

-- test --
[% foo "^## bang blah... %]
-- expect --
run_anything(<non-block>)

-- test --
[% bar baz -%]
This is the content
[%- end %]
-- expect --
run_anything(This is the content)

-- test --
[% baz plang bang schmang -%]
More content
Even more content
[%- END %]
-- expect --
<baz(plang bang schmang)>
  More content
  Even more content
</baz>
