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
# $Id: Filter.pm,v 1.4 1999/08/12 21:53:55 abw Exp $
#
#============================================================================

package Template::Plugin::Filter;

require 5.004;

use strict;
use vars qw( @ISA $VERSION );
use Template::Plugin;

@ISA     = qw( Template::Plugin );
$VERSION = sprintf("%d.%02d", q$Revision: 1.4 $ =~ /(\d+)\.(\d+)/);

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


=head1 NAME

Template::Plugin::Filter - plugin implementing filtering functions

=head1 SYNOPSIS

    [% FILTER html %]
       x < 10 && y != 0
    [% END %]

    [% FILTER format('<!-- %-40s -->') %]
    This will end up formatted, line-by-line,
    as HTML comments...
    [% END %]

=head1 DESCRIPTION

The Filter plugin module defines filters for the FILTER directive.

The 'html' filter converts the characters '<', '>' and '&' to '&lt;', 
'&gt;' and '&amp', respectively, protecting them from being interpreted 
as representing HTML tags or entities.  

The 'format' filter takes a format string as a parameter (as per printf()) 
and formats each line of text accordingly.

=head1 AUTHOR

Andy Wardley E<lt>cre.canon.co.ukE<gt>

=head1 REVISION

$Revision: 1.4 $

=head1 COPYRIGHT

Copyright (C) 1996-1999 Andy Wardley.  All Rights Reserved.
Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template::Plugin|Template::Plugin>, 

=cut




