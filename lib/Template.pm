#============================================================= -*-perl-*-
#
# Template
#
# DESCRIPTION
#   Module implementing a simple, user-oriented front-end to the Template 
#   Toolkit.
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
#------------------------------------------------------------------------
#
#   $Id: Template.pm,v 1.27 1999/08/12 20:15:26 abw Exp $
#
#========================================================================
 
package Template;

require 5.004;

use strict;
use vars qw( $VERSION @ISA @EXPORT_OK %EXPORT_TAGS $AUTOLOAD );
use Exporter;
use Template::Constants qw( :all );
use Template::Context;

## This is the main version number for the Template Toolkit.
## It is extracted by ExtUtils::MakeMaker and inserted in various places.
$VERSION     = '0.24';

@ISA         = qw( Exporter );
*EXPORT_OK   = \@Template::Constants::EXPORT_OK;
*EXPORT_TAGS = \%Template::Constants::EXPORT_TAGS;



#------------------------------------------------------------------------
# new(\%config)
#
# Constructor method.  Returns a reference to a newly created Template 
# object which can be configured by passing a hash reference parameter.
# A Template::Context object is created and stored internally for future
# delegtion.
#------------------------------------------------------------------------

sub new {
    my ($class, $params) = @_;

    $params->{ CONTEXT } ||= Template::Context->new($params);
 
    bless {
	%$params,
	ERROR => '',
    }, $class;
}



#------------------------------------------------------------------------
# process($template, \%params, ...)
#
# Main processing method which delegates to the CONTEXT process() method.  
# The method returns 1 if the template was successfully processed. 
# On error, 0 is returned and error() can be called to return the 
# error message.
#------------------------------------------------------------------------

sub process {
    my $self = shift;

    my $error = $self->{ CONTEXT }->process(@_);

    # store returned error value or exception as string in ERROR
    $self->{ ERROR } = ref($error) ? $error->as_string : $error;

    # return 1 on numerical or 0 status return, 0 on exception (ref)
    return ref($error) ? 0 : 1;
}


#------------------------------------------------------------------------
# context()
# 
# Returns a reference to the internal CONTEXT object
#------------------------------------------------------------------------

sub context {
    $_[0]->{ CONTEXT };
}


#------------------------------------------------------------------------
# error()
# 
# Returns the current contents of $self->{ ERROR } which represents 
# the return code from the most recent call to $context->process(),
# made in process() above.  The error will be numerical to indicate
# that the template was processed sucessfully or a string constructed
# from the exception returned which indicates the error.
#------------------------------------------------------------------------

sub error {
    $_[0]->{ ERROR };
}


#------------------------------------------------------------------------
# AUTOLOAD
#
# Delegates to CONTEXT.
#------------------------------------------------------------------------

sub AUTOLOAD {
    my $self   = shift;
    my $method = $AUTOLOAD;

    $method =~ s/.*:://;
    return if $method eq 'DESTROY';

    $self->{ CONTEXT }->$method(@_);
}


#------------------------------------------------------------------------
# DESTROY
#
# Called automatically on object destruction to call the context old()
# method to break circular references.
#------------------------------------------------------------------------

sub DESTROY {
    my $self = shift;
    $self->{ CONTEXT }->old();
    undef %$self;
}


1;

