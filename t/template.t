#============================================================= -*-perl-*-
#
# t/template.t
#
# Test the Template.pm module.  Does nothing of any great importance
# at the moment, but all of its options are tested in the various other
# test scripts.
#
# Written by Andy Wardley <abw@kfs.org>
#
# Copyright (C) 1996-2000 Andy Wardley.  All Rights Reserved.
# Copyright (C) 1998-2000 Canon Research Centre Europe Ltd.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: template.t,v 2.1 2000/11/01 12:01:45 abw Exp $
#
#========================================================================

use strict;
use lib  qw( ./lib ../lib );
use Template;
use Template::Test;

my $out;
my $dir = -d 't' ? 't/test' : 'test';
my $tt  = Template->new({
    INCLUDE_PATH => "$dir/src:$dir/lib",	
    OUTPUT       => \$out,
});

ok( $tt );
ok( $tt->process('header') );
ok( $out );

$out = '';
ok( ! $tt->process('this_file_does_not_exist') );
my $error = $tt->error();
ok( $error->type() eq 'file' );
ok( $error->info() eq 'this_file_does_not_exist: not found' );


