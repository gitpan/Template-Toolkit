#============================================================= -*-Perl-*-
#
# t/text.t
#
# Template script testing the TEXT directive.
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: text.t,v 1.3 1999/08/01 13:43:21 abw Exp $
# 
#========================================================================

use strict;
use lib qw( . ./t ../lib );
use vars qw( $DEBUG );
use Template qw( :status );
require 'texpect.pl';
$^W = 1;

$DEBUG = 0;

test_expect(\*DATA);

__DATA__
This will become a Text directive
This line will also be part of the same text directive
[% a = "more text" -%]
This will be a new text directive
-- expect --
This will become a Text directive
This line will also be part of the same text directive
This will be a new text directive
