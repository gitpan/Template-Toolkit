#============================================================= -*-Perl-*-
#
# Template::Exception
#
# DESCRIPTION
#   Module implementing a generic exception class used for error handling
#   in the Template Toolkit.
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
# $Id: Exception.pm,v 1.3 1999/07/28 11:33:01 abw Exp $
#
#============================================================================

package Template::Exception;

require 5.004;

use strict;
use vars qw( $VERSION );

$VERSION = sprintf("%d.%02d", q$Revision: 1.3 $ =~ /(\d+)\.(\d+)/);



#========================================================================
#                      -----  CLASS METHODS -----
#========================================================================

#------------------------------------------------------------------------
# new($type, $info, $thrown)
#
# Constructor method used to instantiate a new Template::Exception
# object.  The first parameter should contain the exception type.  This
# can be any arbitrary string of the user's choosing to represent a 
# specific exception.  The second parameter should contain any 
# information (i.e. error message or data reference) relevant to the 
# specific exception event.  The object mantains a state flag, THROWN, 
# to indicate if it has been thrown by, or through the $context->throw()
# method.  Exceptions may be returned by template methods, user code, 
# plugin objects, etc.  Those that have not been thrown are passed to 
# $context->throw() which may have a relevant handler installed to catch
# and possibly convert or ignore the error.  The exception is then marked
# as thrown.  Exceptions that have been thrown will no longer be passed
# to $context->throw().  The optional third parameter is used to set the
# THROWN flag as construction time.  This generally happens when an 
# exception is created by the $context->throw() method and naturally 
# does not need to see it again.
#------------------------------------------------------------------------

sub new {
    my ($class, $type, $info, $thrown) = @_;
    bless {
	TYPE   => $type,
	INFO   => $info,
	THROWN => $thrown,
    }, $class;
}



#========================================================================
#                   -----  PUBLIC OBJECT METHODS -----
#========================================================================

#------------------------------------------------------------------------
# type()
#
# Accessor method to return the internal TYPE value.
#------------------------------------------------------------------------

sub type {
    $_[0]->{ TYPE };
}


#------------------------------------------------------------------------
# info()
#
# Accessor method to return the internal INFO value.
#------------------------------------------------------------------------

sub info {
    $_[0]->{ INFO };
}


#------------------------------------------------------------------------
# type_info()
#
# Accessor method to return the internal TYPE and INFO values.
#------------------------------------------------------------------------

sub type_info {
    my $self = shift;
    @$self{ qw( TYPE INFO ) };
}


#------------------------------------------------------------------------
# thrown()
#
# Accessor method to return the internal THROWN flag.  A parameter may 
# also be provided to update the thrown flag.
#------------------------------------------------------------------------

sub thrown {
    my ($self, $flag) = @_;
    $self->{ THROWN } = $flag
	if defined $flag;
    $self->{ THROWN };
}


#------------------------------------------------------------------------
# as_string()
#
# Accessor method to return a string indicating the exception type and
# information.
#------------------------------------------------------------------------

sub as_string {
    my $self = shift;
    return "$self->{ TYPE } error - $self->{ INFO }";
}



#------------------------------------------------------------------------
# process($context)
#
# This method is part of the Template::Directive interface, allowing 
# Template::Exception objects to be treated as Template::Directive
# objects.  The method throws itself to the calling context.
#------------------------------------------------------------------------

sub process {
    my ($self, $context) = @_;
    $context->throw($self);
}




1;

__END__



=head1 NAME

Template::Exception - exception handling class for the Template Toolkit

=head1 SYNOPSIS

    use Template::Exception;

    my $exception = Template::Exception->new($type, $data);

=head1 DESCRIPTION

The Template::Exception module defines an object class for representing
exceptional conditions (i.e. errors) within the template processing 
life cycle.  Exceptions can be raised by modules within the Template 
Toolkit, or can be generated and returned by user code bound to template
variables.

User code bound to template stash variables is expected to return a 
single C<$value> or a pair of C<($value, $error)>.  The $error code
may be a numerical value represented by one of the Template::Constant
STATUS_XXXX constants.  User code may "throw" an exception to the 
calling context, or throw the exception type and information fields
so that an exception can be constructed.  The context will then handle 
the exception in some way and return a value which can be propogated
back to the caller.  Depending on the presence of a CATCH for the 
exception type, that value may be the exception itself or some 
other status value.

    sub my_code {
        my ($context = shift);
	
	# blah, blah, blah...

	if ($database_has_exploded) {
	    return (undef, $context->throw("database", $database_error));
	}
	else {
	    return $value;
	}
    }

    $template->process($my_file, { 'magic' => \&my_code })
	|| die $template->error(); 

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

