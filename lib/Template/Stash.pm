#============================================================= -*-Perl-*-
#
# Template::Stash
#
# DESCRIPTION
#   Definition of an object class which stores and manages access to 
#   variables for the Template Toolkit. 
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
# $Id: Stash.pm,v 1.9 2000/02/29 18:12:25 abw Exp $
#
#============================================================================

package Template::Stash;

require 5.004;

use strict;
use vars qw( $VERSION );
use Template::Constants qw( :status :error );
use Template::Exception;

$VERSION = sprintf("%d.%02d", q$Revision: 1.9 $ =~ /(\d+)\.(\d+)/);

# IMPORT/EXPORT parameters
my $EXPORT = 'EXPORT';
my $IMPORT = 'IMPORT';



#========================================================================
#                      -----  CLASS METHODS -----
#========================================================================

#------------------------------------------------------------------------
# new(\%params)
#
# Constructor method which creates a new Template::Stash object from
# a blessed hash array.  An optional hash reference may be passed,
# the contents of which will be used to initialise the hash.  These
# represent the variables and their values that the stash will initially
# manage.  Further variables may be added by set() and values can be 
# retrieved by get().
#
# Returns a reference to a newly created Template::Stash.
#------------------------------------------------------------------------

sub new {
    my $class  = shift;
    my $params = shift || { };
    my $self   = {
	%$params,
	'.ERROR'  => '',
	'.PARENT' => undef,
    };

    bless $self, $class;
}



#========================================================================
#                   -----  PUBLIC OBJECT METHODS -----
#========================================================================

#------------------------------------------------------------------------
# clone(\%params)
#
# Creates a copy of the current stash object to effect localisation 
# of variables.  The new stash is blessed into the same class as the 
# parent (which may be a derived class) and has a '.PARENT' member added
# which contains a reference to the parent stash that created it
# ($self).  This member is used in a successive declone() method call to
# return the reference to the parent.
# 
# A parameter may be provided which should reference a hash of 
# variable/values which should be defined in the new stash.
#
# The clone()/declone() process also performs one further function in 
# allowing cloned stashes to export a variable or set of variables into
# the caller's namespace.  The cloned stash may define the 'EXPORT' 
# variable to be a simple value, list or hash of values that is then
# imported into a namespace in the parent stash.  This is done by 
# passing a namespace parameter to declone().  The clone() method always
# clears the 'EXPORT' variable for the clone to avoid any extraneous 
# reference to external data.
#
# Returns a reference to a newly created Template::Stash.
#------------------------------------------------------------------------

sub clone {
    my $self   = shift;
    my $params = shift || { };
    my $class  = ref($self);

    bless { 
	%$self,			# copy all parent members
	%$params,		# update any new params
	 $EXPORT  => 0,		# clear EXPORT parameter
        '.PARENT' => $self,     # link to parent
	'.ERROR'  => '',        # error string
    }, $class;
}


	
#------------------------------------------------------------------------
# declone($export) 
#
# Returns a reference to the PARENT stash.  When called in the following
# manner:
#    $stash = $stash->declone();
# the reference count on the current stash will drop to 0 and be "freed"
# and the caller will be left with a reference to the parent.  This 
# contains the state of the stash before it was cloned.  
#
# A parameter may be provided which can specify a namespace into which 
# the clones export parameter should be copied (linked by reference).  
# This allows a clone to define a variable, list or hash of variables 
# which can then be imported into the caller's namespace at their request.
#------------------------------------------------------------------------

sub declone {
    my ($self, $namespace) = @_;
    my ($parent, $export);

    $parent = $self->{'.PARENT'} || $self;

    # export clone's 'export' into specified namespace of parent
    if (defined($namespace) && ($export = $self->{ $EXPORT })) {
	$parent->set($namespace, $export);
    }
    
    $parent;
}



#------------------------------------------------------------------------
# get($var, \@params, $create)
#
# Returns the stash value associated with the variable named in the 
# first parameter.  If the value contains a CODE reference then it 
# will be run, passing the contents of the list referenced by the 
# second parameter as arguments.  The third, optional parameter is
# a create flag which, when set true, will cause an empty hash to be
# created when a requested item is undefined.
#------------------------------------------------------------------------ 

sub get {
    my ($self, $var, $params, $create) = @_;
    my $value;
    $params ||= [];

    if (defined ($value = $self->{ $var })) {
	return &$value(@$params)
	    if ref($value) eq 'CODE';
    }
    else {
	# create empty hash if value not defined and $create flag set
	$value = $self->{ $var } = { } if $create;
    }

    return $value;
}



#------------------------------------------------------------------------
# set($var, $value)
#
# Updates the stash value associated with the variable named in the 
# first parameter with the value passed in the second. 
#------------------------------------------------------------------------ 
 
sub set {
    my ($self, $var, $val) = @_;

    if ($var eq $IMPORT) {
	return Template::Exception->new(ERROR_UNDEF, 
					"only a hash can be IMPORTed ($val)")
	    unless ref($val) eq 'HASH';
    
	@$self{ keys %$val } = values %$val;
    }
    else {
	$self->{ $var } = $val;
    }

    return STATUS_OK;
}



#------------------------------------------------------------------------
# error()
#
# Return and clear the contents of the .ERROR member.
#------------------------------------------------------------------------

sub error {
    my $self  = shift;
    my $error = $self->{'.ERROR'};
    $self->{'.ERROR'} = '';
    return $error;
}



#========================================================================
#                  -----  PRIVATE OBJECT METHODS -----
#========================================================================

#------------------------------------------------------------------------
# _dump()
#
# Debug method which returns a string representing the internal state
# of the object.  The method calls itself recursively to dump sub-hashes.
#------------------------------------------------------------------------

sub _dump {
    my $self   = shift;
    my $indent = shift || 1;
    my $buffer = '    ';
    my $pad    = $buffer x $indent;
    my $text   = '';
    local $" = ', ';

    my ($key, $value);


    return $text . "...excessive recursion, terminating\n"
	if $indent > 32;

    foreach $key (keys %$self) {

	$value = $self->{ $key };

	if (ref($value) eq 'ARRAY') {
	    $value = "$value [@$value]";
	}
	$text .= sprintf("$pad%-8s => $value\n", $key);
	next if $key =~ /^\./;
	if (UNIVERSAL::isa($value, 'HASH')) {
	    $text .= _dump($value, $indent + 1);
	}
    }
    $text;
}


sub _debug {
    my $self = shift;
#    print STDERR @_;
}




1;

__END__

=head1 NAME

Template::Stash - variable storage for Template Toolkit

=head1 SYNOPSIS

    use Template::Stash;

    my $stash = Template::Stash->new(\%params);

    # set variable value
    $stash->set($variable, $value, $context);

    # get variable values
    ($value, $error) = $stash->get($variable, \@params, $context);

    # methods for localising variables
    $stash = $stash->clone(\%new_params);
    $stash = $stash->declone($namespace);

=head1 DESCRIPTION

The Template::Stash module defines an object class which is used to store
variable values for the runtime use of the template processor.  Variable
values are stored internally in a hash reference (which itself is blessed 
to create the object) and are accessible via the get() and set() methods.

The stash allows user code to be bound to variables which is then called
automatically when the variable value is accesed via get().  By simply
storing a code reference in the stash, the get() method will recognise 
it and call when the variable is requested.  The user code should then 
return the intended variable value and optionally also a status code
to report any error conditions.  The Template Toolkit implements a basic
exception handling mechanism to permit flexible handling and recovery 
from such errors.

The object has clone() and declone() methods which are used by the 
template processor to make temporary copies of the stash for localising
changes made to variables.  The use of the 'magical' variable, 'IMPORT' 
allows users to manipulate the contents of namespaces.

=head1 PUBLIC METHODS

=head2 new(\%params)

The new() constructor method creates and returns a reference to a new
Template::Stash object.  A hash reference may be passed to provide
variables and values which should be used to initialise the stash.

    $stash->new({ 'bgcolor' => '#ffffff', 'img' => '/images' });

=head2 set($variable, $value, $context)

The set() method sets the variable name in the first parameter to the 
value specified in the second.  The calling context passes a reference 
to itself as the third parameter.

The magical variable 'IMPORT' can be specified whose corresponding
value should be a hash reference.  The contents of the hash array are
copied (i.e. imported) into the current namespace.

    # foo.bar = baz, foo.wiz = waz
    $stash->set('foo', { 'bar' => 'baz', 'wiz' => 'waz' });

    # import 'foo' into main namespace: foo = baz, wiz = waz
    $stash->set('IMPORT', $stash->get('foo'));

=head2 get($variable, \@params, $context)

The get() method returns the value of the variable named by the first 
parameter or undef if the variable is not defined.  If the variable 
is bound to code then any additional parameters referenced by the 
second parameter are passed as arguments as the code is called.

=head2 clone(\%params)

The clone() method creates and returns a new Stash object which represents
a local context of the parent stash.  Variables can be freely updated in the 
cloned stash and when declone() is called, the original stash is returned 
with all it's members intact and in the same state as they were before 
clone() was called.  

For convenience, a hash of parameters may be passed into clone() which 
is used to update any simple variable (i.e. those that don't contain any 
namespace elements like 'foo' and 'bar' but not 'foo.bar') variables while 
cloning the stash.  For adding and updating complex variables, the set() 
method should be used after calling clone().  This will correctly resolve
and/or create any necessary namespace hashes.

A cloned stash maintains a reference to the stash that it was copied 
from in its '.PARENT' member.

=head2 declone($namespace)

The declone() method returns the '.PARENT' reference and can be used to
restore the state of a stash as described above.  A namespace parameter
may be provided to specify a namespace into which the clone's EXPORT 
variable should be imported.  The namespace may be 'IMPORT' to indicate
that the contents of the clone's EXPORT hash should be imported into
the parent's (caller's) namespace.

=head1 AUTHOR

Andy Wardley E<lt>cre.canon.co.ukE<gt>

=head1 REVISION

$Revision: 1.9 $

=head1 COPYRIGHT

Copyright (C) 1996-1999 Andy Wardley.  All Rights Reserved.
Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template|Template>, 
L<Template::Context|Template::Context>, 

=cut

