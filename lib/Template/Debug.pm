#============================================================= -*-Perl-*-
#
# Template::Debug
#
# DESCRIPTION
#   Module defining various debug functions and methods to extend other 
#   Template::* modules.
#
# AUTHOR
#   Andy Wardley   <abw@cre.canon.co.uk>
#
# COPYRIGHT
#   Copyright (C) 1996-1999 Andy Wardley.  All Rights Reserved.
#   Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.
#
#   This module is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
#
#----------------------------------------------------------------------------
#
# $Id: Debug.pm,v 1.3 1999/08/12 21:53:47 abw Exp $
#
#============================================================================
 
package Template::Debug;

require 5.004;

use strict;
use vars qw( $VERSION $DEBUG );
use Template::Constants qw( :debug );

$VERSION = sprintf("%d.%02d", q$Revision: 1.3 $ =~ /(\d+)\.(\d+)/);
$DEBUG = 0;


1;






