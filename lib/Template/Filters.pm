#============================================================= -*-Perl-*-
#
# Template::Filters
#
# DESCRIPTION
#   Defines filter plugins as used by the FILTER directive.
#
# AUTHORS
#   Andy Wardley <abw@cre.canon.co.uk>, with a number of filters 
#   contributed by Leslie Michael Orchard <deus_x@nijacode.com>
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
# $Id: Filters.pm,v 1.3 2000/03/06 20:10:31 abw Exp $
#
#============================================================================

package Template::Filters;

require 5.004;

use strict;
use vars qw( $VERSION );

use Template qw( :template :status );


$VERSION = sprintf("%d.%02d", q$Revision: 1.3 $ =~ /(\d+)\.(\d+)/);

sub register {
    my ($class, $context) = @_;
    my ($filter, $factory);

    my $FILTERS = {
	# static filters
	'html'       => sub { return \&html_filter },
	'html_para'  => sub { return \&html_paragraph; },
	'html_break' => sub { return \&html_break; },

	# dynamic filters
	'format'     => \&format_filter_factory,
	'truncate'   => \&truncate_filter_factory,
	'repeat'     => \&repeat_filter_factory,
	'replace'    => \&replace_filter_factory,
	'remove'     => sub { replace_filter_factory(shift, '') },

	# dynamic filters that require a context reference
	'redirect'   => sub { redirect_filter_factory($context, @_) },
	'into'       => sub { into_filter_factory($context, @_) },
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

#------------------------------------------------------------------------
# [% FILTER format(format) %] -> format_filter_factory()
#
# Create a filter to format text according to a printf()-like format
# string.
#------------------------------------------------------------------------

sub format_filter_factory {
    my $format = shift;
    $format = '%s' unless defined $format;

    return sub {
	my $text = shift;
	$text = '' unless defined $text;
	return join("\n", map{ sprintf($format, $_) } split(/\n/, $text));
    }
}


#------------------------------------------------------------------------
# [% FILTER repeat(n) %] -> repeat_filter_factory($n)
#
# Create a filter to repeat text n times.
#------------------------------------------------------------------------

sub repeat_filter_factory {
    my $iter = shift;
    $iter = 1 unless defined $iter;

    return sub {
	my $text = shift;
	$text = '' unless defined $text;
	return join('\n', $text) x $iter;
    }
}


#------------------------------------------------------------------------
# [% FILTER replace(search, replace) %] -> replace_filter_factory($n)
#
# Create a filter to replace 'search' text with 'replace'
#------------------------------------------------------------------------

sub replace_filter_factory {
    my $search  = shift;
    my $replace = shift || '';

    return sub {
	my $text = shift;
	$text = '' unless defined $text;
	$text =~ s/$search/$replace/g;
	return $text;
    }
}


#------------------------------------------------------------------------
# [% FILTER truncate(n) %] -> truncate_filter_factory($n)
#
# Create a filter to truncate text after n characters.
#------------------------------------------------------------------------

sub truncate_filter_factory {
    my $len = shift || 32;
    return '' unless $len > 3;
    
    return sub {
	my $text = shift;
	return $text if length $text < $len;
	return substr($text, 0, $len - 3) . "...";
    }
}


#------------------------------------------------------------------------
# [% FILTER into(varname) %] -> into_filter_factory($context, $varname)
#
# Create a filter to assign the block text to a named variable.
#------------------------------------------------------------------------

sub into_filter_factory {
    my ($context, $var) = @_;
    sub {
	my $text = shift;
	$context->{ STASH }->set($var, $text, $context);
	return '';
    }
}


#------------------------------------------------------------------------
# [% FILTER redirect(file) %] -> redirect_filter_factory($context, $file)
#
# Create a filter to redirect the block text to a file.
#------------------------------------------------------------------------

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

#------------------------------------------------------------------------
# [% FILTER html %] -> html_filter()
#
# Convert any '<', '>' or '&' characters to the HTML equivalents, '&lt;',
# '&gt;' and '&amp;', respectively.
#------------------------------------------------------------------------

sub html_filter {
    my $text = shift;
    foreach ($text) {
	s/&/&amp;/g;
	s/</&lt;/g;
	s/>/&gt;/g;
    }
    $text;
}


#------------------------------------------------------------------------
# [% FILTER html_para %] -> html_paragraph()
#
# Wrap each paragraph of text (delimited by two or more newlines) in the
# <p>...</p> HTML tags.
#------------------------------------------------------------------------

sub html_paragraph  {
    my $text = shift;
    return "<p>\n" 
           . join("\n</p>\n\n<p>\n", split(/(?:\r?\n){2,}/, $text))
	   . "</p>\n";
}


#------------------------------------------------------------------------
# [% FILTER html_break %] -> html_break()
#
# Wrap each paragraph of text (delimited by two or more newlines) in the
# <p>...</p> HTML tags.
#------------------------------------------------------------------------

sub html_break  {
    my $text = shift;
    $text =~ s/(\r?\n){2,}/$1<br>$1<br>$1/g;
    return $text;
}


1;


=head1 NAME

Template::Filters - defines post-processing filters for template blocks

=head1 SYNOPSIS

    [% FILTER html %]
       x < 10 && y != 0
    [% END %]

    [% FILTER format('<!-- %-40s -->') %]
    This will end up formatted, line-by-line,
    as HTML comments...
    [% END %]

    etc...

=head1 DESCRIPTION

The 'html' filter converts the characters '<', '>' and '&' to '&lt;',
'&gt;' and '&amp', respectively, protecting them from being
interpreted as representing HTML tags or entities.  The 'html_para'
filter converts text into HTML paragraphs E<lt>pE<gt>....E<lt>/pE<gt>.
The 'html_break' filter is similar, but uses E<lt>brE<gt>E<lt>brE<gt> as
a paragraph delimiter.

The 'format' filter takes a format string as a parameter (as per
printf()) and formats each line of text accordingly. The 'truncate'
filter truncates text at a given length and the 'repeat' filter
duplicates text any number of times.  The 'remove' filter removes a 
specified character sequence or Perl regular expression, and the 
'replace' filter does the same, allowing a replacement string to be
specified.

The 'redirect' and 'into' filters can be used to redirect a text block 
to another file, or to store it in a named variable, respectively.

See L<Template> for full (and possibly more up-to-date) information on 
using these filters.

See the module source code for insights on writing additional filter.

=head1 AUTHOR

Andy Wardley E<lt>cre.canon.co.ukE<gt>

=head1 REVISION

$Revision: 1.3 $

=head1 COPYRIGHT

Copyright (C) 1996-1999 Andy Wardley.  All Rights Reserved.
Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template>

=cut





