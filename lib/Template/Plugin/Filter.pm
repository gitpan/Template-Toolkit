#============================================================= -*-Perl-*-
#
# Template::Plugin::Filter
#
# DESCRIPTION
#   Defines filter plugins as used by the FILTER directive.
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
# $Id: Filter.pm,v 1.3 1999/08/10 11:09:10 abw Exp $
#
#============================================================================

package Template::Plugin::Filter;

require 5.004;

use strict;
use vars qw( @ISA $VERSION );
use Template::Plugin;

@ISA     = qw( Template::Plugin );
$VERSION = sprintf("%d.%02d", q$Revision: 1.3 $ =~ /(\d+)\.(\d+)/);

my $FILTERS = {
    'html'   => sub { return \&html_filter },
    'format' => \&make_format_filter,
};

sub new {
    my ($class, $context, $name, @params) = @_;
    my $filter;
    
    return $class->fail("invalid filter name ($name)")
	unless $filter = $FILTERS->{ $name };

    &$filter(@params);
}

#========================================================================
# Filter constructors
#========================================================================

sub make_format_filter {
    my $format = shift;
    $format = '%s' unless defined $format;
    return sub {
	my $text = shift;
	$text = '' unless defined $text;
	return join("\n", map{ sprintf($format, $_) } split(/\n/, $text));
    }
}

#========================================================================
# Filters
#========================================================================

sub html_filter {
    my $text = shift;
    foreach ($text) {
	s/&/&amp;/g;
	s/</&lt;/g;
	s/>/&gt;/g;
    }
    $text;
}


1;




