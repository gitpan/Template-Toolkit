#============================================================= -*-Perl-*-
#
# Template::Iterator
#
# DESCRIPTION
#
#   Module defining an iterator class which is used by the FOREACH
#   directive for iterating through data sets.  This may be
#   sub-classed to define more specific iterator types.
#
#   An iterator is an object which provides a consistent way to
#   navigate through data which may have a complex underlying form.
#   This implementation uses the first() and next() methods to iterate
#   through a dataset.  The first() method is called once to perform
#   any data initialisation and return the first value, then next() is
#   called repeatedly to return successive values.  Both these methods
#   return a pair of values which are the data item itself and a
#   status code.  The default implementation handles iteration through
#   an array (list) of elements which is passed by reference to the
#   constructor.  An empty list is used if none is passed.  The module
#   may be sub-classed to provide custom implementations which iterate
#   through any kind of data in any manner as long as it can conforms
#   to the first()/next() interface.
#
#   For further information on iterators see "Design Patterns", by the 
#   "Gang of Four" (Erich Gamma, Richard Helm, Ralph Johnson, John 
#   Vlissides), Addision-Wesley, ISBN 0-201-63361-2.
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
# $Id: Iterator.pm,v 1.5 1999/08/12 21:53:47 abw Exp $
#
#============================================================================

package Template::Iterator;

require 5.004;

use strict;
use vars qw( $VERSION $DEBUG );
use Template::Constants qw( :status :error );
use Template::Exception;


$VERSION = sprintf("%d.%02d", q$Revision: 1.5 $ =~ /(\d+)\.(\d+)/);
$DEBUG   = 0;



#========================================================================
#                      -----  CLASS METHODS -----
#========================================================================

#------------------------------------------------------------------------
# new(\@target, \%options)
#
# Constructor method which creates and returns a reference to a new 
# Template::Iterator object.  A reference to the target data (currently 
# an array, but future implementations may support hashes or other set 
# types) may be passed for the object to iterate through.
#------------------------------------------------------------------------

sub new {
    my ($class, $data, $params) = @_;
    my $self = { };

    $data   ||= [ ];
    $params ||= { };

    @$self{ map { uc } keys %$params } = values %$params;

    # coerce any non-list data into an array reference
    $data  = [ $data ] 
	unless UNIVERSAL::isa($data, 'ARRAY');

    $self->{ _DATA } = $data;
    bless $self, $class;
}



#========================================================================
#                   -----  PUBLIC OBJECT METHODS -----
#========================================================================

#------------------------------------------------------------------------
# first()
#
# Initialises the object for iterating through the target data set.  The 
# first record is returned, if defined, along with the STATUS_OK value.
# If there is no target data, or the data is an empty set, then undef 
# is returned with the STATUS_DONE value.  
#
# This method may be redefined through sub-classing to perform any 
# required data initialisation.
#------------------------------------------------------------------------

sub first {
    my $self  = shift;
    my $data  = $self->{ _DATA };
    my ($order, $error);


    # an ORDER parameter may be defined as a code ref for calling or
    # one of the strings 'sorted' or 'reverse'
    if (defined($order = $self->{ ORDER })) {
	if (ref($order) eq 'CODE') {
	    ($data, $error) = &$order($data);
	} 
	elsif ($order eq 'sorted') {
	    $data = $self->sort($data);
	}
	elsif ($order eq 'reverse') {
	    $data = $self->sort($data, 1);
	}
	else {
	    $error = Template::Exception->new(ERROR_UNDEF, 
					   "invalid iterator order: $order");
	}
	return (undef, $error) if $error;
    }

    $self->{ _DATASET } = $data;
    my $size = scalar @$data;
    my $index = 0;
    
    return (undef, STATUS_DONE) unless $size;		    ## RETURN ##

    # slice initial values into $self
    @$self{ qw( _MAX _INDEX size max index number is_first is_last ) } 
    = ( $size - 1, $index, $size, $size - 1, $index, 1, 1, $size > 1 ? 0 : 1 );

    # first data item and OK status
    return $self->iteration($self->{ _DATASET }->[ $index ]);
}



#------------------------------------------------------------------------
# next()
#
# May be called repeatedly to access successive elements in the data.
# Should only be called after a successful call to first or an error
# code will be returned.
#------------------------------------------------------------------------

sub next {
    my $self = shift;
    my ($max, $index) = @$self{ qw( _MAX _INDEX ) };


    # warn about incorrect usage
    unless (defined $index) {
	my ($pack, $file, $line) = caller();
	warn("Iterator next() called before first() at $file line $line\n");
	return (undef, STATUS_DONE);			    ## RETURN ##
    }

    # if there's still some data to go...
    if ($index < $max) {
	# slice new values into $self
	@$self{ qw( _INDEX index number is_first is_last ) }
	    = ( ++$index, $index, $index + 1, 0, $index == $max ? 1 : 0 );

	# return data and OK status			    ## RETURN ##
	return $self->iteration($self->{ _DATASET }->[ $index ]);  
    }
    else {
	# clear index and indicate data finished
	undef $self->{ _INDEX };
	return (undef, STATUS_DONE);			    ## RETURN ##
    }
}



#------------------------------------------------------------------------
# iteration($item)
#
# Called each time the iterator is ready to return an iterative value.
# This method calls any $self->{ ACTION } defined.
#------------------------------------------------------------------------

sub iteration {
    my ($self, $data) = @_;
    my $action;

    # there may be an ACTION defined to run on each iteration
    if (defined($action = $self->{ ACTION })) {
	return &$action($data) 
	    if ref($action) eq 'CODE';
    }
    return ($data, STATUS_OK);
}



#------------------------------------------------------------------------
# sort(\@data, $reverse)
# 
# Default sorting method for base class iterator which sorts the values
# passed by list reference into alphanumerical order.  Sorting is 
# handle case-insensitivity using a Schwartzian Transform to create 
# a lower-case folded comparitor for the sort sub.  The $reverse flag
# may be set true to indicate that the set order should be reversed.
#------------------------------------------------------------------------ 

sub sort {
    my ($self, $data, $reverse) = @_;
    return $reverse 
	?  [ map  { $_->[0] }
	     sort { $b->[1] cmp $a->[1] }
	     map  { [ $_, lc $_ ] } 
	     @$data 
	   ]
        :  [ map  { $_->[0] }
	     sort { $a->[1] cmp $b->[1] }
	     map  { [ $_, lc $_ ] } 
	     @$data 
	   ]
}



#========================================================================
#                   -----  PRIVATE DEBUG METHODS -----
#========================================================================

#------------------------------------------------------------------------
# _state()
#
# Prints the internal state of the iterator object.
#------------------------------------------------------------------------

sub _state {
    my $self = shift;
    print "  Data: ", $self->{ _DATA }, "\n";
    print " Index: ", $self->{ _INDEX }, "\n";
    print "Number: ", $self->{'number'}, "\n";
    print "   Max: ", $self->{ _MAX }, "\n";
    print "  Size: ", $self->{'size'}, "\n";
    print " First: ", $self->{'is_first'}, "\n";
    print "  Last: ", $self->{'is_last'}, "\n";
    print "\n";
}



1;

__END__

=head1 NAME

Template::Iterator - Base iterator class used by the FOREACH directive.

=head1 SYNOPSIS

    my $iter = Template::Iterator->new(\@data, \%options);

=head1 DESCRIPTION

THe Template::Iterator module defines a generic data iterator for use 
by the FOREACH directive.  

It may be used as the base class for custom iterators.

=head1 PUBLIC METHODS
    
=head2 new(\@data, \%options) 

Constructor method.  A reference to a list of values is passed as the
first parameter and subsequent first() and next() calls will return
each element.

The second optional parameter may be a hash reference containing the
following items:

=over 4

=item ORDER

A code reference which will be called to pre-sort the data items.  A
list reference is passed in and should be returned, along with any
status code.  The ORDER option may also be either of the strings
'sorted' or 'reverse'.

=item ACTION   

A code ref to be called on each iteration.  The data item is passed.
The modified data should be returned.

=back

=head2 first()

Returns a ($value, $error) pair for the first item in the iterator set.
Returns an error of STATUS_DONE if the list is empty.

=head2 next()

Returns a ($value, $error) pair for the next item in the iterator set.
Returns an error of STATUS_DONE if all items in the list have been 
visited.

=head1 AUTHOR

Andy Wardley E<lt>cre.canon.co.ukE<gt>

=head1 REVISION

$Revision: 1.5 $

=head1 COPYRIGHT

Copyright (C) 1996-1999 Andy Wardley.  All Rights Reserved.
Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template|Template>

=cut





