#============================================================= -*-Perl-*-
#
# Template::Directive
#
# DESCRIPTION
#   Object classes defining directives that represent the high-level
#   opcodes of the template processor.  All are derived from a common
#   Template::Directive base class.
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
# $Id: Directive.pm,v 1.12 1999/08/01 13:43:12 abw Exp $
#
#============================================================================
 
package Template::Directive;

require 5.004;

use strict;
use vars qw( $VERSION $DEBUG );
use Template::Constants;
use Template::Exception;


$VERSION = sprintf("%d.%02d", q$Revision: 1.12 $ =~ /(\d+)\.(\d+)/);
$DEBUG = 1;


#========================================================================
#                      -----  CONFIGURATION -----
#========================================================================

# define a list of directives and which parameters they accept
my @param_list = (
    [ qw( INCLUDE USE           ) ] => [ qw( IDENT PARAMS NAMESPACE   ) ],
    [ qw( IF                    ) ] => [ qw( EXPR BLOCK ELSE          ) ],
    [ qw( FOR                   ) ] => [ qw( LIST BLOCK VARNAME       ) ],
    [ qw( BLOCK                 ) ] => [ qw( CONTENT                  ) ],
    [ qw( TEXT DEBUG            ) ] => [ qw( TEXT                     ) ],
    [ qw( CATCH                 ) ] => [ qw( ERRTYPE BLOCK            ) ],
    [ qw( THROW                 ) ] => [ qw( ERRTYPE EXPR             ) ],
    [ qw( ERROR                 ) ] => [ qw( EXPR                     ) ],
    [ qw( RETURN                ) ] => [ qw( RETVAL                   ) ],
);

# construct a lookup table of directive parameters
my %param_tbl;
while (my ($d, $p) = splice(@param_list, 0, 2)) {
   @param_tbl{ @$d } = ($p) x @$d;
}

my $PKGVAR = 'PARAMS';



#========================================================================
#                 -----  BASE CLASS PUBLIC METHODS -----
#========================================================================

#------------------------------------------------------------------------
# new($opcode, $tokens)
#
# Constructor method which creates and returns a reference to a 
# Template::Directive object.  The constructor is almost certainly 
# going to be called for a derived class (such as those defined later
# in this file).
#
# We look at the class name and see if it is defined in our parameter
# table above.  If not, we have a look for a "@PARAMS" variable in the 
# class package.  This parameter list defines the named paramters 
# which are expected to follow in @_.  These are shifted off (they may
# be undefined, but we don't worry about that now) and the internal 
# parameters are set to the respective values.  
#
# Return a reference to a new Template::Directive (or derived) object.
# 
#------------------------------------------------------------------------

sub new {
    my $class   = shift;
    my $package = __PACKAGE__;
    my $self;
    my ($type, $accept);
    local $" = ', ';

    # see if we can determine the directive type from the class name...
    $type = $class;

    # examine the class name to see if we have a param table entry for it
    if ($type =~ s/^$package\::(.+)/$1/) {
	$type = uc $type;

	# look for parameter acceptance list in %param_tbl
	$accept = $param_tbl{ $type };
    }
    elsif ($type eq $package) {
	$accept = [ 'OPCODES' ]; 
    }
    
    # if it doesn't exist, we look for @PARAMS in the derived class package
    unless (defined $accept) {
	my $sym = \%main::;

        PARAMS: {
	    foreach my $pkg (split(/::/, $class)) {
		unless (defined($sym = $sym->{$pkg})) {
		    warn("\@$class\::$PKGVAR not defined\n");
		    $accept = [];
		    last PARAMS;
		}
	    }
	    if (defined($sym = $sym->{ $PKGVAR }) && defined(@$sym)) {
		$accept = \@$sym;
	    }
	    else {
		warn("\@$class\::$PKGVAR not defined\n");
		$accept = [];
	    }
	}
    }


    $self = bless { TYPE => $type }, $class;

    foreach my $key (@$accept) {
	$self->{ $key } = shift;
    }

    $self;
}



#------------------------------------------------------------------------
# process($context)
#
# The process() method is called by the template processor context 
# ($context) when the directive is due for processing.  This base class 
# method executes the opcode sequence in $self->{ OPCODE } by calling
# the context->_runop() method.  Thus, it performs as a general directive
# for executing opcode sequences (e.g. GET, SET).
#------------------------------------------------------------------------

sub process {
    my ($self, $context) = @_;
    my ($value, $error) = $context->_runop($self->{ OPCODES });
    $error ||= 0;
    $context->output($value)
	if !$error && defined $value;
    return $error || Template::Constants::STATUS_OK;
}



#========================================================================
#                       ----- DEBUG METHODS -----
#========================================================================

#------------------------------------------------------------------------
# _inspect()
#
# Inspector method which may be called for debugging purposes.  This
# definition does nothing but is redefined in Template::Debug.
#------------------------------------------------------------------------

sub _inspect {
}



#------------------------------------------------------------------------
# _report(@msg)
#
# Formats and outputs the debug messages passed by parameter if $DEBUG
# is set.
#------------------------------------------------------------------------

sub _report {
    my $self = shift;

    return unless $DEBUG;

    my $type = $self->{ TYPE };
    my $out = join("", @_);

    $out =~ s/^/[%$type%] /gm;
    $out .= "\n" unless $out =~ /\n$/;
    print STDERR $out if $DEBUG;
}



#========================================================================
#               -----  Template::Directive::Include  -----
#========================================================================
 
package Template::Directive::Include;
use vars qw( @ISA );
@ISA = qw( Template::Directive );


#------------------------------------------------------------------------
# process($context)  ->  %% INCLUDE ident params %%
#------------------------------------------------------------------------

sub process {
    my ($self, $context) = @_;
    my ($ident, $error);

    # the file/block identifier might be a variable reference so must
    # first be evaluated in context
    ($ident, $error) = $context->_runop($self->{ IDENT });
    return $error					    ## RETURN ##
	if $error;

    return $context->throw(Template::Constants::ERROR_FILE, 
			   'Undefined INCLUDE file/block name')
	unless defined $ident && length $ident;

    # clone stash and run PARAMS oplist to update vars
    $context->{ STASH } = $context->{ STASH }->clone();
    $context->_runop($self->{ PARAMS });
    $error = $context->_process($ident);
    $context->{ STASH } = $context->{ STASH }->declone($self->{ NAMESPACE });

    return $error;
}



#========================================================================
#                 -----  Template::Directive::If  -----
#========================================================================
 
package Template::Directive::If;
use vars qw( @ISA );
@ISA = qw( Template::Directive );

#------------------------------------------------------------------------
# process($context)  ->  %% IF expr %%
#
# Iterates through the expression stored in $self->{ EXPR } and calls the 
# process() method of the $self->{ BLOCK } if it evaluates true.  If it 
# evaluates false, any block referenced in $self->{ ELSE } is processed.
#------------------------------------------------------------------------

sub process {
    my ($self, $context) = @_;
    my $input = $self->{ EXPR };
    my ($true, $else, $error);

    ($true, $error) = $context->_runop($self->{ EXPR });
    return $error if $error;

#    $self->_report('IF evaluated ', $true ? 'TRUE' : 'FALSE', "\n");

    if ($true) {
	return $self->{ BLOCK }->process($context);	    ## RETURN ##
    }
    elsif (defined ($else = $self->{ ELSE })) {
	return $else->process($context);		    ## RETURN ##
    }
    else {
	return Template::Constants::STATUS_OK;		    ## RETURN ##
    }

    # not reached 
}



#========================================================================
#                 -----  Template::Directive::For  -----
#========================================================================
 
package Template::Directive::For;
use vars qw( @ISA );
@ISA = qw( Template::Directive );


#------------------------------------------------------------------------
# process($context)  ->  %% FOR [ident in] target %%
#------------------------------------------------------------------------

sub process {
    my ($self, $context) = @_;
    my $stash = $context->{ STASH };
    my ($varname, $varlist, $iterator, $value, $error);

    require Template::Iterator;

    # retrieve target variable name and list values
    $varname = $self->{ VARNAME };
    ($varlist, $error) = $context->_runop($self->{ LIST });
    return $error if $error;

    # do nothing if there's nothing to do
    return Template::Constants::STATUS_OK		    ## RETURN ##
	unless defined $varlist;

    # the target may already be an iterator, otherwise we create one
    $iterator = UNIVERSAL::isa($varlist, 'Template::Iterator')
	? $varlist
	: Template::Iterator->new($varlist);

    # initialise iterator
    ($value, $error) = $iterator->first();

    # clone the stash so that we don't have to worry about trampling
    # on any variables. We should probably localise the stash for each
    # iteration but that's too costly, IMHO, for a level of
    # "correctness" that most people won't ever need to worry about.
    $context->{ STASH } = $stash = $stash->clone();

    # loop
    while (! $error) {
	# if a loop variable hasn't been specified (e.g. %% FOREACH
	# userlist %%) then we will automatically import the members
	# of HASH references that get returned by each iteration.  We
	# can only safely import hashes so that's all we try and do -
	# anything else is gracefully ignored.  If a loop variable has
	# been specified then we set that variable to each iterative
	# item.  
	if ($varname) {
	    # set target variable to iteration value
	    $context->{ STASH }->set($varname , $value);
	}
	elsif (ref($value) eq 'HASH') {
	    # otherwise IMPORT a hash value
	    $context->{ STASH }->set('IMPORT', $value);
	}

	# process block
	last if ($error = $self->{ BLOCK }->process($context));

	# get next iteration
	($value, $error) = $iterator->next();
    }

    # declone the stash (revert to parent context)
    $context->{ STASH } = $stash->declone();

    # STATUS_DONE indicates the iterator completed succesfully
    return $error == Template::Constants::STATUS_DONE
	? Template::Constants::STATUS_OK
	: $error;
}



#========================================================================
#                 -----  Template::Directive::Use  -----
#========================================================================
 
package Template::Directive::Use;
use vars qw( @ISA );
@ISA = qw( Template::Directive );


#------------------------------------------------------------------------
# process($context)  ->  %% USE ident = plugin(params) %%
#------------------------------------------------------------------------

sub process {
    my ($self, $context) = @_;
    my ($name, $params, $plugin, $ident, $error);

    $name = $self->{ IDENT };

    # evaluate PARAMS
    ($params, $error) = $context->_runop($self->{ PARAMS });
    return $error					    ## RETURN ##
	if $error;

    $params = [] 
	unless defined $params;

    ($plugin, $error) = $context->use_plugin($name, $params);
    return $error
	if $error;

    # default target ident to plugin name and convert illegal characters
    $ident = $self->{ NAMESPACE } || $name;
    $ident =~ s/\W+/_/g;

    # bind plugin object into stash under identifier
    $context->{ STASH }->set($ident, $plugin);

    return Template::Constants::STATUS_OK;
}



#========================================================================
#                -----  Template::Directive::Block  -----
#========================================================================

package Template::Directive::Block;
use vars qw( @ISA );
@ISA = qw( Template::Directive );


#------------------------------------------------------------------------
# process($context)
#
# Iterates through the array of directive references stores in the 
# $self->{ CONTENT } list, calling the process() method on each one.
#------------------------------------------------------------------------

sub process {
    my ($self, $context) = @_;
    my $error = Template::Constants::STATUS_OK;

    foreach my $child (@{ $self->{ CONTENT } }) {
	$error = $child->process($context);

	# the child process may return an exception that hasn't yet been 
	# thrown through $context->throw() which may have a handler for it
	$error = $context->throw($error)
	    if ref($error) && ! $error->thrown();
	last if $error;
    }

    return $error;
}



#========================================================================
#                 -----  Template::Directive::Text  -----
#========================================================================
 
package Template::Directive::Text;
use vars qw( @ISA );
@ISA = qw( Template::Directive );


#------------------------------------------------------------------------
# process($context)
#
# Outputs the text stored in $self->{ TEXT } by calling the output() 
# method on the template instance referenced by the first parameter.
#------------------------------------------------------------------------

sub process {
    my ($self, $context) = @_;

    $context->output($self->{ TEXT });

    return Template::Constants::STATUS_OK;
}



#========================================================================
#                 -----  Template::Directive::Throw  -----
#========================================================================
 
package Template::Directive::Throw;
use vars qw( @ISA );
@ISA = qw( Template::Directive );


#------------------------------------------------------------------------
# process($context)
#
# Calls $context->throw() to raise an exception. 
#------------------------------------------------------------------------

sub process {
    my ($self, $context) = @_;
    my ($info, $error, $errtype);

    $errtype = $self->{ ERRTYPE } || 'default';

    # evaluate EXPR
    ($info, $error) = $context->_runop($self->{ EXPR });
    return $error					    ## RETURN ##
	if $error;

    return $context->throw($errtype, $info);
}



#========================================================================
#                 -----  Template::Directive::Catch  -----
#========================================================================
 
package Template::Directive::Catch;
use vars qw( @ISA );
@ISA = qw( Template::Directive );


#------------------------------------------------------------------------
# process($context)
#
# Calls $context->catch() to install an exception handling template
# block.
#------------------------------------------------------------------------

sub process {
    my ($self, $context) = @_;
    my $retval;

    my $errtype = $self->{ ERRTYPE } || 'default';

    return $context->catch($errtype, $self->{ BLOCK });
}


#========================================================================
#                 -----  Template::Directive::Error  -----
#========================================================================
 
package Template::Directive::Error;
use vars qw( @ISA );
@ISA = qw( Template::Directive );


#------------------------------------------------------------------------
# process($context)
#
# Evaluate the term specified in the ERROR directive and send the result
# to the $context->error() method.
#------------------------------------------------------------------------

sub process {
    my ($self, $context) = @_;
    my ($value, $error) = $context->_runop($self->{ EXPR });
    $error ||= 0;
    $context->error($value)
	if !$error && defined $value;
    return $error || Template::Constants::STATUS_OK;
}



#========================================================================
#                 -----  Template::Directive::Return  -----
#========================================================================
 
package Template::Directive::Return;
use vars qw( @ISA );
@ISA = qw( Template::Directive );


#------------------------------------------------------------------------
# process($context)
#
# Returns the value in $self->{ RETVAL } or STATUS_RETURN if not defined.
#------------------------------------------------------------------------

sub process {
    my ($self, $context) = @_;
    my $retval;

    $retval = Template::Constants::STATUS_RETURN
	unless defined ($retval = $self->{ RETVAL });

    return $retval;
}



#========================================================================
#               -----  Template::Directive::Debug  -----
#========================================================================
 
package Template::Directive::Debug;
use vars qw( @ISA );
@ISA = qw( Template::Directive );


#------------------------------------------------------------------------
# process($context)
#------------------------------------------------------------------------

sub process {
    my ($self, $context) = @_;
    my $stash = $context->{ STASH };
    my $debug;
    
    # debug stuff
    $debug = $self->{ TEXT };

    if ($debug =~ /stashdump/i) {
	$context->output("Stash Dump:\n", $stash->_dump(), "\n");
    }

    return Template::Constants::STATUS_OK;
}


1;

__END__

=head1 NAME

Template::Directive - Object class for defining directives that represent the opcodes of the Template processor.

=head1 SYNOPSIS

  use Template::Directive;

  my $dir = Template::Directive->new(\@opcodes);
  my $inc = Template::Directive::Include->new(\@ident, \@param, $namespace);
  my $if  = Template::Directive::If->new(\@expr, $true_block, $else_block);
  my $for = Template::Directive::For->new(\@list, $block, $varname);
  my $blk = Template::Directive::Block->new($content);
  my $txt = Template::Directive::Text->new($text);
  my $thr = Template::Directive::Throw->new($errtype, \@expr);
  my $cth = Template::Directive::Catch->new($errtype, $block);
  my $ret = Template::Directive::Return->new($retval);
  my $dbg = Template::Directive::Debug->new($text);
  
  $get->process($context);
  $set->process($context);
  ...etc..

=head1 DESCRIPTION

The Template::Directive module defines a class which represents the 
basic operations of the Template Processor.  These are created and returned
(in tree form) by the Template::Parser object as a product of parsing a 
template file.  The process() method is called on the directives at the 
time at which the "compiled" template is rendered for output.

The derived classes of Template::Directive, as listed above, define
specific operations of the template processor.  You don't really need to
worry about them unless you plan to hack on the internals of the processor.

=head1 AUTHOR

Andy Wardley E<lt>abw@cre.canon.co.ukE<gt>

=head1 REVISION

$Revision: 1.12 $

=head1 COPYRIGHT

Copyright (C) 1996-1999 Andy Wardley.  All Rights Reserved.
Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template>, L<Template::Stash>, L<Template::Parser>, L<Template::Grammar>

=cut


