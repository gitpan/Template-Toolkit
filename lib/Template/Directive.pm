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
# $Id: Directive.pm,v 1.30 2000/03/20 08:02:20 abw Exp $
#
#============================================================================

package Template::Directive;

require 5.004;

use strict;
use vars qw( $VERSION $DEBUG );
use Template::Constants;
use Template::Exception;


$VERSION = sprintf("%d.%02d", q$Revision: 1.30 $ =~ /(\d+)\.(\d+)/);
$DEBUG = 0;


#========================================================================
#                      -----  CONFIGURATION -----
#========================================================================

# table defining parameters for each directive type
my %param_tbl = (
    'Text'      => [ qw( TEXT                   ) ],
    'Get'       => [ qw( TERM                   ) ],
    'Call'      => [ qw( TERM                   ) ],
    'Set'       => [ qw( ARGS                   ) ],
    'Include'   => [ qw( FILE ARGS              ) ],
    'Process'   => [ qw( FILE ARGS              ) ],
    'Use'       => [ qw( NAME ARGS ALIAS        ) ],
    'If'        => [ qw( EXPR BLOCK ELSE        ) ],
    'For'       => [ qw( ITEM LIST PARAMS BLOCK ) ],
    'While'     => [ qw( EXPR BLOCK             ) ],
    'Filter'    => [ qw( NAME ARGS ALIAS BLOCK  ) ],
    'Block'     => [ qw( CONTENT                ) ],
    'Catch'     => [ qw( ETYPE BLOCK            ) ],
    'Throw'     => [ qw( ETYPE INFO             ) ],
    'Error'     => [ qw( INFO                   ) ],
    'Return'    => [ qw( RETVAL                 ) ],
    'Perl'      => [ qw( PERLCODE               ) ],    
    'Macro'     => [ qw( NAME DIRECTIVE ARGS    ) ],    
    'Userdef'   => [ qw( HANDLER BLOCK          ) ],
);

my $PKGVAR = 'PARAMS';



#------------------------------------------------------------------------
# create($type, \@params) 
#
# This is the base class factory method which is called to instantiate
# Template::Directive objects.  A string representing the directive type
# is passed in as the first parameter (e.g. 'text', 'include') along 
# with any additional parameters specific to the directive.  The method 
# indexes into %param_tbl to find the information required to construct
# an object of the specific type and then does so.  There is no need for 
# any directive-specific construction.  This approach is significantly
# faster than deriving all directives from a common base class whose
# shared new() constructor performs this task. .  
#------------------------------------------------------------------------

sub create {
    my $class = shift;
    my $type  = shift;
    my ($self, $accept);

    # look for parameter acceptance list in %param_tbl
    $accept = $param_tbl{ $type };
    die "not accepted ($type)\n" unless $accept;
    $self = bless { TYPE => $type }, "$class\::$type";

    foreach my $key (@$accept) {
	$self->{ $key } = shift;
    }

    $self;
}


#========================================================================
#                       ----- DEBUG METHODS -----
#========================================================================
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
#                    --- DIRECTIVE SUB-CLASSES ---
#========================================================================

#------------------------------------------------------------------------
# TEXT
#------------------------------------------------------------------------

package Template::Directive::Text;
use vars qw( @ISA );
@ISA = qw( Template::Directive );

sub process {
    my ($self, $context) = @_;
    $context->output($self->{ TEXT });
    return Template::Constants::STATUS_OK;
}


#------------------------------------------------------------------------
# SET				                           [% SET args %]
#------------------------------------------------------------------------

package Template::Directive::Set;
use vars qw( @ISA );
@ISA = qw( Template::Directive );

sub process {
    my ($self, $context) = @_;
    my ($arg, $ident, $term, $value, $error);

    local $" = ', ';

    ($value, $error) = $context->_evaluate($self->{ ARGS });
    return $error || Template::Constants::STATUS_OK;
}


#------------------------------------------------------------------------
# GET				                           [% GET term %]
#------------------------------------------------------------------------

package Template::Directive::Get;
use vars qw( @ISA );
@ISA = qw( Template::Directive );

sub process {
    my ($self, $context) = @_;
    my ($ident, $value, $error);

    ($value, $error) = $context->_evaluate($self->{ TERM });
    return $error if $error;

    # throw an exception if value is undefined
    $context->output($value)
	if defined($value);

    return Template::Constants::STATUS_OK;
}


#------------------------------------------------------------------------
# CALL				                          [% CALL term %]
#------------------------------------------------------------------------

package Template::Directive::Call;
use vars qw( @ISA );
@ISA = qw( Template::Directive );

sub process {
    my ($self, $context) = @_;
    my ($ident, $value, $error);

    ($value, $error) = $context->_evaluate($self->{ TERM });

    return $error || Template::Constants::STATUS_OK;
}


#------------------------------------------------------------------------
# INCLUDE			                  [% INCLUDE file args %]
#
# The INCLUDE directive calls on the context process() method to 
# process another template file or block.  Parameters may be defined
# which get passed and used to update a local copy of the stash.
# Variables passed to a INCLUDE'd template, or set within such a 
# template are local to that template and do not affect variables
# in the caller's namespace.
#------------------------------------------------------------------------
 
package Template::Directive::Include;
use vars qw( @ISA );
@ISA = qw( Template::Directive );

sub process {
    my ($self, $context) = @_;
    my ($file, $value, $error);

    # the file/block identifier might be a variable reference so must
    # first be evaluated in context
    if (ref($file = $self->{ FILE })) {
	($file, $error) = $context->_evaluate($file);
	return $error					    ## RETURN ##
	    if $error;
    }
    return $context->throw(Template::Constants::ERROR_FILE, 
			   'Undefined INCLUDE file/block name')
	unless $file;

    # localise variables and set parameters
    $context->localise();
    ($value, $error) = $context->_evaluate($self->{ ARGS });
    return $error if $error;				    ## RETURN ##

    # process file then restore previous variable context
    $error = $context->process($file);
    $context->delocalise();

    $error;
}



#------------------------------------------------------------------------
# PROCESS                                      [% PROCESS ident params %]
#
# The PROCESS directive is similar to INCLUDE except that variables are
# not localised.  This allows variables defined in a sub-template to
# persist in the caller's namespace.  This is ideal for putting config
# values in a separate file which can then be PROCESS'd.  The context's
# 'private' _process() method is called, bypassing the 'public' process()
# method which localises variables.  This is OK.  The Context object 
# treats us as a friend and grants this behaviour.
#------------------------------------------------------------------------
 
package Template::Directive::Process;
use vars qw( @ISA );
@ISA = qw( Template::Directive );

sub process {
    my ($self, $context) = @_;
    my ($file, $value, $error);

    # the file/block identifier might be a variable reference so must
    # first be evaluated in context
    if (ref($file = $self->{ FILE })) {
	($file, $error) = $context->_evaluate($file);
	return $error					    ## RETURN ##
	    if $error;
    }
    return $context->throw(Template::Constants::ERROR_FILE, 
			   'Undefined PROCESS file/block name')
	unless $file;

    # update variables
    ($value, $error) = $context->_evaluate($self->{ ARGS });
    return $error if $error;				    ## RETURN ##

    $context->process($file);
}



#------------------------------------------------------------------------
# IF				            [% IF expr %] block [% END %]
#
# Iterates through the expression stored in $self->{ EXPR } and calls the 
# process() method of the $self->{ BLOCK } if it evaluates true.  If it 
# evaluates false, any block referenced in $self->{ ELSE } is processed.
#------------------------------------------------------------------------
 
package Template::Directive::If;
use vars qw( @ISA );
@ISA = qw( Template::Directive );

sub process {
    my ($self, $context) = @_;
    my $input = $self->{ EXPR };
    my ($true, $else, $error);

    ($true, $error) = $context->_evaluate($self->{ EXPR });
    return $error if $error;

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



#------------------------------------------------------------------------
# WHILE				         [% WHILE expr %] block [% END %]
#
# Iterates through the following block while the expression evaluates
# true.
#------------------------------------------------------------------------
 
package Template::Directive::While;
use vars qw( @ISA $MAXITER );
@ISA = qw( Template::Directive );
$MAXITER = 1_000;

sub process {
    my ($self, $context) = @_;
    my $expr = $self->{ EXPR };
    my ($true, $error);

    $error = Template::Constants::STATUS_OK;

    # this is a hack to prevent runaways
    my $failsafe = $MAXITER + 1;
    for (;--$failsafe;) {
	# test expression
	($true, $error) = $context->_evaluate($self->{ EXPR });
	return $error if $error;
	last unless $true;

	# run block
	$error = $self->{ BLOCK }->process($context);
	last if $error;
    }
    $context->error("Runaway WHILE loop terminated (> $MAXITER iterations)")
	unless $failsafe;
    
    # STATUS_DONE indicates the iterator completed succesfully
    return ! $error || $error == Template::Constants::STATUS_DONE
	? Template::Constants::STATUS_OK
	: $error;
}


#------------------------------------------------------------------------
# FOR				  [% FOREACH item list %] block [% END %]
#------------------------------------------------------------------------
 
package Template::Directive::For;
use vars qw( @ISA );
@ISA = qw( Template::Directive );

sub process {
    my ($self, $context) = @_;
    my ($item, $params, $list) = @$self{ qw( ITEM PARAMS LIST ) };
    my ($iterator, $value, $error, $loopsave);
    my $LOOPVAR = 'loop';


    require Template::Iterator;

    ($list, $error) = $context->_evaluate($list);
    return $error if $error;

    if ($params && @$params) {
	($params, $error) = $context->_evaluate($params);
	return $error if $error;
	$params = pop @$params;
    }

    # do nothing if there's nothing to do
    return Template::Constants::STATUS_OK		    ## RETURN ##
	unless defined $list;

    # the target may already be an iterator, otherwise we create one
    $iterator = UNIVERSAL::isa($list, 'Template::Iterator')
	? $list
	: Template::Iterator->new($list, $params);

    return (undef, $context->throw($Template::Iterator::ERROR))
	unless $iterator;

    # initialise iterator
    ($value, $error) = $iterator->get_first();

    if ($item) {
	# loop has a target variable to which values will be assigned, so
	# there's no need to localise the stash to prevent existing variables
	# being overwritten.  However, we do need to take a copy of any 
	# existing 'loop' variable which we will overwrite
	$loopsave = $context->{ STASH }->get($LOOPVAR);
    }
    else {
	# with a target variable, any hash values will be imported.  Thus we
	# need to clone the stash to avoid variable trample
	$context->localise();
    }
    
    $context->{ STASH }->set($LOOPVAR => $iterator);

    # loop
    while (! $error) {
	# if a loop variable hasn't been specified (e.g. %% FOREACH
	# userlist %%) then we will automatically import the members
	# of HASH references that get returned by each iteration.  We
	# can only safely import hashes so that's all we try and do -
	# anything else is gracefully ignored.  If a loop variable has
	# been specified then we set that variable to each iterative
	# item.  
	if ($item) {
	    # set target variable to iteration value
	    $context->{ STASH }->set($item, $value);
	}
	elsif (ref($value) eq 'HASH') {
	    # otherwise IMPORT a hash value
	    $context->{ STASH }->set('IMPORT', $value);
	}

	# process block
	last if ($error = $self->{ BLOCK }->process($context));

	# get next iteration
	($value, $error) = $iterator->get_next();
    }

    $context->{ STASH }->set($LOOPVAR => $loopsave);

    # declone the stash (revert to parent context)
    $context->delocalise()
	unless $item;

    # STATUS_DONE indicates the iterator completed succesfully
    return $error == Template::Constants::STATUS_DONE
	? Template::Constants::STATUS_OK
	: $error;
}


#------------------------------------------------------------------------
# FILTER		  [% FILTER alias = name(args) %] block [% END %]
#------------------------------------------------------------------------

package Template::Directive::Filter;
use vars qw( @ISA );
@ISA = qw( Template::Directive );

sub process {
    my ($self, $context) = @_;
    my ($name, $args, $alias, $block) 
	= @$self{ qw( NAME ARGS ALIAS BLOCK ) };
    my ($filter, $handler, $input, $output, $error);
    
    # evaluate ARGS
    ($args, $error) = $context->_evaluate($args);
    return $error if $error;

    # ask the context for the requested filter
    ($filter, $error) = $context->use_filter($name, $args, $alias)
	unless $error;

    return $error					    ## RETURN ##
	if $error;

    # install output handler to capture output, saving existing handler
    $input = '';
    $handler = 
	$context->redirect(Template::Constants::TEMPLATE_OUTPUT, \$input);

    # process contents of FILTER block
    $error = $block->process($context);

    # restore previous output handler
    $context->redirect(Template::Constants::TEMPLATE_OUTPUT, $handler);

    # filter output generated from processing block
    ($output, $error) = &$filter($input)
	unless $error;

    # output the filtered text, or the original text if the filter failed
    $context->output($error ? $input : $output);

    return $error || Template::Constants::STATUS_OK;
}


#------------------------------------------------------------------------
# USE			                     [% USE alias = name(args) %]
#------------------------------------------------------------------------
 
package Template::Directive::Use;
use vars qw( @ISA );
@ISA = qw( Template::Directive );

sub process {
    my ($self, $context) = @_;
    my ($name, $args, $alias) =
	@$self{ qw( NAME ARGS ALIAS ) };
    my ($plugin, $error);

    # evaluate ARGS
    ($args, $error) = $context->_evaluate($args);
    return $error if $error;
    $args ||= [];

    ($plugin, $error) = $context->use_plugin($name, $args);
    return $error
	if $error;

    # default target ident to plugin name and convert illegal characters
    $alias ||= $name;
    $alias =~ s/\W+/_/g;

    # bind plugin object into stash under identifier
    $context->{ STASH }->set($alias, $plugin);

    return Template::Constants::STATUS_OK;
}


#------------------------------------------------------------------------
# BLOCK			                    [% BLOCK %] content [% END %]
#------------------------------------------------------------------------

package Template::Directive::Block;
use vars qw( @ISA );
@ISA = qw( Template::Directive );

sub process {
    my ($self, $context) = @_;
    my $error = Template::Constants::STATUS_OK;

    foreach my $child (@{ $self->{ CONTENT } }) {
	next unless defined $error;
	$error = $child->process($context);

	# the child process may return an exception that hasn't yet been 
	# thrown through $context->throw() which may have a handler for it
	$error = $context->throw($error)
	    if ref($error) && ! $error->thrown();
	last if $error;
    }

    return $error;
}


#------------------------------------------------------------------------
# THROW			                          [% THROW etype einfo %]
#------------------------------------------------------------------------
 
package Template::Directive::Throw;
use vars qw( @ISA );
@ISA = qw( Template::Directive );

sub process {
    my ($self, $context) = @_;
    my ($info, $error);

    # evaluate info 
    ($info, $error) = $context->_evaluate($self->{ INFO });
    return $error					    ## RETURN ##
	if $error;

    return $context->throw($self->{ ETYPE } || 'default', $info);
}


#------------------------------------------------------------------------
# CATCH			                [% CATCH etype %] block [% END %]
#------------------------------------------------------------------------
 
package Template::Directive::Catch;
use vars qw( @ISA );
@ISA = qw( Template::Directive );

sub process {
    my ($self, $context) = @_;
    return $context->catch($self->{ ETYPE } || 'default', $self->{ BLOCK });
}


#------------------------------------------------------------------------
# ERROR			                                 [% ERROR info %]
#------------------------------------------------------------------------
 
package Template::Directive::Error;
use vars qw( @ISA );
@ISA = qw( Template::Directive );

sub process {
    my ($self, $context) = @_;
    my ($value, $error) = $context->_evaluate($self->{ INFO });
    $error ||= 0;
    $context->error($value)
	if !$error && defined $value;
    return $error || Template::Constants::STATUS_OK;
}


#------------------------------------------------------------------------
# RETURN		                              [% RETURN retval %]
#------------------------------------------------------------------------
 
package Template::Directive::Return;
use vars qw( @ISA );
@ISA = qw( Template::Directive );

sub process {
    my ($self, $context) = @_;
    my $retval;

    $retval = Template::Constants::STATUS_RETURN
	unless defined ($retval = $self->{ RETVAL });

    return $retval;
}


#------------------------------------------------------------------------
# PERL			                    [% PERL %] perlcode [% END %]
#------------------------------------------------------------------------
 
package Template::Directive::Perl;
use vars qw( @ISA );
@ISA = qw( Template::Directive );

sub process {
    my ($self, $context) = @_;
    my $block = $self->{ PERLCODE };
    my $stash = $context->{ STASH };
    my ($perlcode, $handler, $error);
    
    return $context->throw(Template::Constants::ERROR_PERL, 
			   "EVAL_PERL is disabled, ignoring PERL section")
	unless $context->{ EVAL_PERL };

    # first we process the block contained within PERL...END to expand
    # and directives contained within the block; we install an output 
    # handler to capture all output from the block and then restore the 
    # original handler

    $perlcode = '';
    $handler  = 
	$context->redirect(Template::Constants::TEMPLATE_OUTPUT, \$perlcode);
    $error = $block->process($context);
    $context->redirect(Template::Constants::TEMPLATE_OUTPUT, $handler);
    return $error if $error;

    # we update the $context and $stash variables to ensure they contain
    # the relevent references and then evaluate the Perl code

    $Template::Perl::context = $context;
    $Template::Perl::stash   = $stash;
    eval {
	eval "package Template::Perl; $perlcode";
    };
    return $context->throw(Template::Constants::ERROR_PERL, $@)
	if $@;

    return Template::Constants::STATUS_OK;
}


#------------------------------------------------------------------------
# MACRO			                 [% MACRO name(args) directive %]
#------------------------------------------------------------------------
 
package Template::Directive::Macro;
use vars qw( @ISA );
@ISA = qw( Template::Directive );

sub process {
    my ($self, $context) = @_;
    my ($name, $directive, $args) =
	@$self{ qw( NAME DIRECTIVE ARGS ) };


    my $callback = sub {
	my ($params, $error, $output);

	# see if any mandatory arguments are expected
	if ($args) {
	    my %args;
	    @args{@$args} = splice(@_, 0, scalar @$args);

	    # hash may follow mandatory args
	    $params = shift;
	    $params = { } unless ref($params) eq 'HASH';
	    $params = { %args, %$params };
	}
	# otherwise just look for a hash
	else {
	    $params = $_[0] if ref($_[0]) eq 'HASH';
	}

	# set passed variable values in a local context
	$context->localise($params)
	    if $params;

	$error = $directive->process($context);

	# restore original context
	$context->delocalise()
	    if $params;

	return $error 
	    ? (undef, $error)
	    : '';
    };
    $context->{ STASH }->set($name, $callback);

    return Template::Constants::STATUS_OK;
}


#------------------------------------------------------------------------
# USERDEF/USERBLOCK	  [% USERDEF * %]/[% USERDEF * %] block [% END %]
#------------------------------------------------------------------------
 
package Template::Directive::Userdef;
use vars qw( @ISA );
@ISA = qw( Template::Directive );

sub process {
    my ($self, $context) = @_;
    my ($handler, $block) = @$self{ qw( HANDLER BLOCK ) };
    my ($text, $hsave, $error);

    # if a BLOCK is defined we process it and capture the output for 
    # feeding into the handler as input text
    if ($block) {
	# install output handler to capture output, saving existing handler
	$text = '';
	$hsave = 
	    $context->redirect(Template::Constants::TEMPLATE_OUTPUT, \$text);

	# process contents of FILTER block
	$error = $block->process($context);

	# restore previous output handler
	$context->redirect(Template::Constants::TEMPLATE_OUTPUT, $hsave);
    }

    $error ||= &$handler($context, $text);

    return $error || Template::Constants::STATUS_OK;
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
  my $inc = Template::Directive::Include->new(\@ident, \@params);
  my $if  = Template::Directive::If->new(\@expr, $true_block, $else_block);
  my $for = Template::Directive::For->new(\@list, $block, $varname);
  my $blk = Template::Directive::Block->new($content);
  my $txt = Template::Directive::Text->new($text);
  my $thr = Template::Directive::Throw->new($errtype, \@expr);
  my $cth = Template::Directive::Catch->new($errtype, $block);
  my $ret = Template::Directive::Return->new($retval);
  my $dbg = Template::Directive::Debug->new($text);

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

$Revision: 1.30 $

=head1 COPYRIGHT

Copyright (C) 1996-1999 Andy Wardley.  All Rights Reserved.
Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template>, L<Template::Stash>, L<Template::Parser>, L<Template::Grammar>

=cut


