#============================================================= -*-Perl-*-
#
# Template::Plugin::Format
#
# DESCRIPTION
#
#   Simple Template Toolkit Plugin which creates formatting functions.
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
# $Id: Format.pm,v 1.3 2000/01/14 20:12:28 abw Exp $
#
#============================================================================

package Template::Plugin::Format;

require 5.004;

use strict;
use vars qw( @ISA $VERSION );
use Template::Plugin;
use CGI;

@ISA     = qw( Template::Plugin );
$VERSION = sprintf("%d.%02d", q$Revision: 1.3 $ =~ /(\d+)\.(\d+)/);


sub new {
    my ($class, $context, $format) = @_;;
    return defined $format
	? make_formatter($format)
	: \&make_formatter;
}


sub make_formatter {
    my $format = shift;
    $format = '%s' unless defined $format;
    return sub { return sprintf($format, @_); }
}


1;

__END__

=head1 NAME

Template::Plugin::Format - simple Template Plugin interface to create formatting function

=head1 SYNOPSIS

    [% USE format %]
    [% commented = format('# %s') %]
    [% commented('The cat sat on the mat') %]
    
    [% USE bold = format('<b>%s</b>') %]
    [% bold('Hello') %]

=head1 DESCRIPTION

The format plugin constructs sub-routines which format text according to
a printf()-like format string.

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

L<Template::Plugin|Template::Plugin>, 

=cut





