#============================================================= -*-Perl-*-
#
# Template::Filters
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
# $Id: Filters.pm,v 1.1 1999/11/03 01:20:32 abw Exp $
#
#============================================================================

package Template::Filters;

require 5.004;

use strict;
use vars qw( $VERSION );

use Template qw( :template :status );


$VERSION = sprintf("%d.%02d", q$Revision: 1.1 $ =~ /(\d+)\.(\d+)/);

sub register {
    my ($class, $context) = @_;
    my ($filter, $factory);

    my $FILTERS = {
	# static filters
	'html'     => sub { return \&html_filter },

	# dynamic filters
	'format'   => \&format_filter_factory,

	# dynamic filters that require a context reference
	'redirect' => sub { redirect_filter_factory($context, @_) },
	'into'     => sub { into_filter_factory($context, @_) },
    };

    # register all those filters
    while (($filter, $factory) = each %$FILTERS) {
	$context->register_filter($filter, $factory);
    }

    return 1;
}


#========================================================================
# dynamic filter factories
#========================================================================

sub format_filter_factory {
    my $format = shift;
    $format = '%s' unless defined $format;

    return sub {
	my $text = shift;
	$text = '' unless defined $text;
	return join("\n", map{ sprintf($format, $_) } split(/\n/, $text));
    }
}

sub into_filter_factory {
    my ($context, $var) = @_;
    sub {
	my $text = shift;
	$context->{ STASH }->set($var, $text, $context);
	return '';
    }
}

sub redirect_filter_factory {
    my ($context, $file) = @_;
    sub {
	my $text = shift;
	my $handler;
	$handler = $context->redirect(TEMPLATE_OUTPUT, $file);
	$context->output($text);
	$context->redirect(TEMPLATE_OUTPUT, $handler);
	return '';
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

Template::Filters - filters

=head1 SYNOPSIS

    [% FILTER html %]
       x < 10 && y != 0
    [% END %]

    [% FILTER format('<!-- %-40s -->') %]
    This will end up formatted, line-by-line,
    as HTML comments...
    [% END %]

=head1 DESCRIPTION

The 'html' filter converts the characters '<', '>' and '&' to '&lt;', 
'&gt;' and '&amp', respectively, protecting them from being interpreted 
as representing HTML tags or entities.  

The 'format' filter takes a format string as a parameter (as per printf()) 
and formats each line of text accordingly.

=head1 AUTHOR

Andy Wardley E<lt>cre.canon.co.ukE<gt>

=head1 REVISION

$Revision: 1.1 $

=head1 COPYRIGHT

Copyright (C) 1996-1999 Andy Wardley.  All Rights Reserved.
Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template>

=cut





