#============================================================= -*-Perl-*-
#
# Template::Plugin
#
# DESCRIPTION
#
#   Module defining a base class for a Plugin object which can be loaded
#   and instantiated via the USE directive.
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
# $Id: Plugin.pm,v 1.8 1999/11/04 10:30:12 abw Exp $
#
#============================================================================

package Template::Plugin;

require 5.004;

use strict;
use vars qw( $VERSION $DEBUG $PLUGIN_NAMES $ERROR );


$VERSION = sprintf("%d.%02d", q$Revision: 1.8 $ =~ /(\d+)\.(\d+)/);
$DEBUG   = 0;

# this maps standard library plugins to lower case names for convenience
$PLUGIN_NAMES = {
    'format'   => 'Format',
    'filter'   => 'Filter',
    'cgi'      => 'CGI',
    'dbi'      => 'DBI',
    'datafile' => 'Datafile',
    'redirect' => 'Redirect',
};



#========================================================================
#                      -----  CLASS METHODS -----
#========================================================================

#------------------------------------------------------------------------
# load()
#
# Class method called when the plugin module is first loaded.  It 
# returns the name of a class (by default, its own class) or a prototype
# object which will be used to instantiate new objects.  The new() 
# method is then called against the class name (class method) or 
# prototype object (object method) to create a new instances of the 
# object.
#------------------------------------------------------------------------

sub load {
    return $_[0];
}


#------------------------------------------------------------------------
# new($context)
#
# Object constructor which is called by the Template::Context to 
# instantiate a new Plugin object.  This may be called as a class or
# object method.  The context is passed as the first parameter and 
# any additional parameters passed to the USE directive that requested
# a new object are passed by reference to a list as the second
# parameter.
#------------------------------------------------------------------------

sub new {
    my ($self, $context, @params) = @_;
    my $class = ref($self) || $self;

    warn("Invalid context passed to $class constructor\n"), return undef
	unless defined $context;

    bless {
	CONTEXT => $context,
	PARAMS  => \@params,
    }, $class;
}


#------------------------------------------------------------------------
# fail()
# error()
# 
# Report/return errors via the $ERROR package variable.
#------------------------------------------------------------------------

sub fail {
    my $class = shift;
    $ERROR = shift;
    return undef;
}

sub error {
    $ERROR;
}


#========================================================================
#                   -----  PUBLIC OBJECT METHODS -----
#========================================================================

#------------------------------------------------------------------------
# params()
# 
# Simple accessor method to return a reference to the list of paramters
# passed to the constructor.  This is really just an example.
#------------------------------------------------------------------------

sub params {
    $_[0]->{ PARAMS };
}



1;

__END__

=head1 NAME

Template::Plugin - Base class for plugin objects.

=head1 SYNOPSIS

    package MyOrg::Template::MyPlugin;
    use base qw( Template::Plugin );

    sub new {
        my ($class, $context, @params) = @_;
	bless {
            ...whatever...
        }, $class;
    }

    sub method1 { }
    sub method1 { }

=head1 DESCRIPTION

The Template::Plugin module defines a base class from which other 
plugin modules can be derived.

=head1 AUTHOR

Andy Wardley E<lt>cre.canon.co.ukE<gt>

=head1 REVISION

$Revision: 1.8 $

=head1 COPYRIGHT

Copyright (C) 1996-1999 Andy Wardley.  All Rights Reserved.
Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template|Template>

=cut





