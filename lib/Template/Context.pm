#============================================================= -*-Perl-*-
#
# Template::Context
#
# DESCRIPTION
#   Module defining a context in which a template document is processed.
#   This is the runtime processing environment in which a template "runs"
#   and through which it can be controlled.
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
# $Id: Context.pm,v 1.19 1999/08/10 11:09:06 abw Exp $
#
#============================================================================

package Template::Context;

require 5.004;

use strict;
use vars qw( $VERSION $DEBUG $CATCH_VAR );
use Template::Constants qw( :status :error :ops );
use Template::Utils qw( :subs );
use Template::Cache;
use Template::Stash;
use Template::OS;


$VERSION   = sprintf("%d.%02d", q$Revision: 1.19 $ =~ /(\d+)\.(\d+)/);
$DEBUG     = 0;
$CATCH_VAR = 'error';


#========================================================================
#                  ----- RUNTIME BINARY OPS -----
#========================================================================

my $binop  = {
    '=='  => sub { local $^W = 0; $_[0] eq $_[1] ? 1 : 0 },
    '!='  => sub { local $^W = 0; $_[0] ne $_[1] ? 1 : 0 },
    '<'   => sub { local $^W = 0; $_[0] <  $_[1] ? 1 : 0 },
    '<='  => sub { local $^W = 0; $_[0] <= $_[1] ? 1 : 0 },
    '>'   => sub { local $^W = 0; $_[0] >  $_[1] ? 1 : 0 },
    '>='  => sub { local $^W = 0; $_[0] >= $_[1] ? 1 : 0 },
    '&&'  => sub { $_[0] && $_[1] ? 1 : 0 },
    '||'  => sub { $_[0] || $_[1] ? 1 : 0 },
};


#========================================================================
#                     -----  PUBLIC METHODS -----
#========================================================================

#------------------------------------------------------------------------
# new(\%config)
#
# Constructor method which creates and initialised a new Template::Context
# object, using the optional configuration hash passed by reference.
# The method creates Template::Cache and Template::Stash objects to 
# manage templates and variables respectively.  Output and error handlers
# are constructed via calls to output_handler().
#------------------------------------------------------------------------

sub new {
    my $class  = shift;
    my $params = shift || { };
    my ($cache, $stash, $os, $pbase) = 
	@$params{ qw( CACHE STASH OS PLUGIN_BASE ) };

    # create an OS object, using provided parameter, autodetecting 
    # if $os is undefined, and defaulting to 'unix' on error.
    $os = Template::OS->new($os) || do {
	warn "Invalid operating system, defaulting to unix: ", 
	    $os || '', "\n";
	Template::OS->new('unix');
    };
    $params->{ OS } = $os;

    # stash is constructed with any PRE_DEFINE variables
    $stash ||= Template::Stash->new($params->{ PRE_DEFINE });

    # CACHE can be either an option to the Template::Cache->new() 
    # constructor or a cache object reference
    $cache = Template::Cache->new($params)
	unless ref $cache;
    
    # PLUGIN_BASE is a single directory or array ref (may also be undef)
    $pbase = ref $pbase eq 'ARRAY' 
	     ?   $pbase 
	     : [ $pbase || 'Template::Plugin'];

    my $self = bless {
	OS          => $os,
	STASH       => $stash,
	CACHE       => $cache,
	PLUGIN_BASE => $pbase,
	PLUGINS     => $params->{ PLUGINS } || { },
	FILTERS     => $params->{ FILTERS } || { },
	CATCH       => $params->{ CATCH } || { },
	OUTPUT      => output_handler($params->{ OUTPUT }),
	ERROR       => output_handler($params->{ ERROR } || \*STDERR),
    }, $class;

    $self;
}



#------------------------------------------------------------------------
# old()
# 
# Destructor method called to undefine all hash members to break any 
# circular references that may exist. 
#------------------------------------------------------------------------

sub old {
    my $self = shift;
    undef %$self;
}



#------------------------------------------------------------------------
# process($template, $params) 
#
# This is the main template processing method.
#
# The first parameter should indicate the template source and should
# be a scalar (filename), scalar ref (text) or a GLOB or IO::Handle
# from which the template should be read.  Reading the template source
# is handled by calling the CACHE fetch() method.  Alternatively,
# $input may reference a Template::Directive object or sublass thereof
# which will be processed directly, bypassing the cache.
#
# The optional second parameter should contain a reference to a hash 
# array defining variables for inclusion into the template.  The 
# STASH clone() method is called to localise any variable changes,
# passing this reference to set variables in the cloned stash.
#
# The method returns a status code represented by one of the 
# STATUS_XXXX constants or a Template::Exception object to indicate 
# an uncaught run-time error condition.
#
# Note that the Template::Directive::Include object, being a good
# friend, is allowed to bypasses this public method and talk directly 
# to the private method _parse().  This is to allow it fast update
# access to the localised stash via an opcode list.
#------------------------------------------------------------------------


sub process {
    my ($self, $template, $params) = @_;
    my ($ops, $error);

    # params may be an ARRAY reference to an opcode list which will
    # update local parameters for us.  In this case, we copy it to $ops
    # and nullify $params
    $params = undef 
	if ($ops = ref($params) eq 'ARRAY' ? $params : undef);
	
    # clone internal stash to localise new variables
    $self->{ STASH } = $self->{ STASH }->clone($params);

    # run any opcode list passed as $params
    $self->_runop($ops)
	if $ops;

    $error = $self->_process($template);

    # restore original stash
    $self->{ STASH } = $self->{ STASH }->declone();
			       
    return $error;
}



#------------------------------------------------------------------------
# throw($type, $info)
# throw($exception)
#
# This method is called to raise an error condition (throw an exception)
# within the context.  An exception object is a simple structure which 
# contains a type to indicate the error (e.g. 'file', 'undef') and an
# information string to represent the error condition (e.g. 'foobar:
# file not found').  This method may be called by passing in a reference
# to a Template::Exception object or the type and information parameters 
# separately.
# 
# The exception type is used to key into the $self->{ CATCH } hash
# to determine how to handle this kind of error.  The default key 
# 'default' is also tried.  Any defined value will be returned to the 
# caller.  If no CATCH entry is found, $exception will be returned
# as is, or an exception will be constructed from $type and $info and 
# returned.
#
#------------------------------------------------------------------------

sub throw {
    my ($self, $type, $info) = @_;
    my $handlers = $self->{ CATCH };
    my ($exception, $catch, $catchref);


    # grok params which may be ($exception) or ($type, $info)
    if (ref $type eq 'Template::Exception') {
	# the first parameter may be an exception from which we extract 
	# the type and info.  If the exception has already been thrown 
	# then we simple return it.
	$exception = $type;
	$type = $exception->type();
	$info = $exception->info();
	$exception->thrown(1);
    }

    # look for specific, then default throw definition
    $catch = $handlers->{ $type };
    $catch = $handlers->{'default'}
	unless defined $catch;

    # THROWING is used to avoid recursive throws (i.e. disable interupts)
    return STATUS_OK
	if $self->{ THROWING }->{ $type };
	
    $self->{ THROWING }->{ $type } = 1;

    # call sub-routine if $catch is a CODE ref
    if (($catchref = ref($catch)) eq 'CODE') {
	$catch = &$catch($self, $type, $info);
    }
    # call process() to render a Template::Directive reference
    elsif ($catchref && UNIVERSAL::isa($catch, 'Template::Directive')) {
	my $errvar = { 'e' => { 'type' => $type, 'info' => $info } };
	$catch = $self->process($catch, $errvar);
    }
    
    undef $self->{ THROWING }->{ $type };
	    
    # create an exception if $catch is still undefined
    $catch = $catch || Template::Exception->new($type, $info, 1)
	unless defined $catch;
	
    return $catch;
}


#------------------------------------------------------------------------
# catch($type, $handler) 
#
# Installs the exception handler, $handler, in the internal CATCH lookup
# table for exceptions of $type.
#
# Returns STATUS_OK or a Template::Exception on error.
#------------------------------------------------------------------------

sub catch {
    my ($self, $type, $handler) = @_;
    $type ||= 'default';
    $self->{ CATCH }->{ $type } = $handler;
    return STATUS_OK;
}



#------------------------------------------------------------------------
# use_plugin($name, \@params) 
#
# Called by the USE directive to instantiate a new plugin object, 
# indicated by $name.  The optional second parameter may contain a 
# reference to a list of parameters passed to the USE directive.
# Attempts to load the required module by prefixing the value(s) 
# of PLUGIN_BASE and converting any periods to '::', or by using a 
# predefined lookup for $name from $Template::Plugin::PLUGIN_NAMES.
# 
# Returns a new plugin object instance.
#------------------------------------------------------------------------

sub use_plugin {
    my ($self, $name, $params) = @_;
    my ($factory, $module, $base, $package, $filename, $plugin, $ok);

    require Template::Plugin;

    # we may have already loaded the module and obtained a factory name/obj
    unless (defined ($factory = $self->{ PLUGINS }->{ $name })) {

	# module name is built from $name unless defined in PLUGIN_NAME hash
	($module = $name) =~ s/\./::/g
	    unless defined($module = 
			   $Template::Plugin::PLUGIN_NAMES->{ $name });

	foreach $base (@{ $self->{ PLUGIN_BASE } }) {
	    $package =  $base . '::' . $module;
	    ($filename = $package) =~ s|::|/|g;
	    $filename .= '.pm';

	    $ok = eval { require $filename };
	    last unless $@;
	}
	return (undef, Template::Exception->new(ERROR_UNDEF,
			"failed to load plugin module $name"))
	    unless $ok;

	$factory = eval { $package->load($self) };
	return (undef, Template::Exception->new(ERROR_UNDEF, 
			"failed to initialise plugin module $name"))
	    if $@ || ! $factory;

	$self->{ PLUGINS }->{ $name } = $factory;
    }

    # call the new() method on the factory object or class name
    eval {
	$plugin = $factory->new($self, @{ $params || [] })
	    || die "$name plugin: ", $factory->error(), "\n";
    };
    return (undef, Template::Exception->new(ERROR_UNDEF, $@))
	if $@;

    return $plugin;
}



#------------------------------------------------------------------------
# use_filter($name, \@params, $alias) 
#
# Called by the FILTER directive to request a filter sub-routine.
# Calls use_plugin() to request a filter plugin type, passing the 
# filter name and params.  Filters specified without any parameters
# will be cached by their name or a provided alias.  Filters that
# have parameters will only be cached if an alias is provided.
#
# Returns a CODE reference representing the filter.
#------------------------------------------------------------------------

sub use_filter {
    my ($self, $name, $params, $alias) = @_;
    my ($filter, $args, $error);
    
    # use any cached version of the filter if no params provided
    $filter = $self->{ FILTERS }->{ $name }
	unless ($params);

    unless ($filter) {
	# prepare arguments for passing to the 'filter' plugin
	$args = $params || [];
	unshift(@$args, $name);

	# request filter plugin to build filter
	($filter, $error) = $self->use_plugin('filter', $args);
	return (undef, $error)
	    if $error;
    }

    # alias defaults to name iff no parameters were supplied
    $alias = $name
	unless $params || defined $alias;

    # cache FILTER if alias is valid
    $self->{ FILTERS }->{ $alias } = $filter
	if $alias;

    return ($filter, Template::Constants::STATUS_OK);
} 



#------------------------------------------------------------------------
# redirect($what, $where)
#
# Called to set OUTPUT, ERROR or DEBUG output ($what) to a new location
# ($where).  See Template::Utils::output_handler() for details of what 
# $where can can be.  Returns a reference to the previous handler or
# undef.
#------------------------------------------------------------------------

sub redirect {
    my ($self, $what, $where) = @_;
    my ($previous, $output, $reftype);
    
    # default output stream to 'OUTPUT'
    $what = Template::Constants::TEMPLATE_OUTPUT
	unless defined $what;

    $what = uc $what;
    return undef
	unless $what =~ /^OUTPUT|ERROR$/;
    
    # default OUTPUT to STDOUT, anything else to STDERR
    $where = $what eq Template::Constants::TEMPLATE_OUTPUT
	     ? \*STDOUT
	     : \*STDERR
	unless defined $where;

    # save previous handler
    $previous = $self->{ $what };

    # set handler internally
    $self->{ $what } = Template::Utils::output_handler($where);

    # return previous handler
    $previous;
}



#------------------------------------------------------------------------
# output(...) 
#
# Calls the internal OUTPUT code sub, , as established by redirect(), 
# passing all parameters.
#------------------------------------------------------------------------

sub output {
    my $self = shift;
    &{ $self->{ OUTPUT } }(@_);
}



#------------------------------------------------------------------------
# error(...) 
#
# Calls the internal ERROR code sub, as established by redirect(), 
# passing all parameters.
#------------------------------------------------------------------------

sub error {
    my $self = shift;
    &{ $self->{ ERROR } }(@_);
}


sub DESTROY {
    my $self = shift;
    undef $self->{ STASH };
#    print "destroying $self\n";
}


#========================================================================
#                      -----  PRIVATE METHODS -----
#========================================================================

#------------------------------------------------------------------------
# sub _process($template)
#
# This is the private template processing method, called by the public
# process() method and directly by the INCLUDE directive process()
# method.  
#
# The parameter, $template, should indicate the template source and
# should be a scalar (filename), scalar ref (text) or a GLOB or
# IO::Handle from which the template should be read.  Reading the
# template source is handled by calling the CACHE fetch() method.
# Alternatively, $input may reference a Template::Directive object or
# sublass thereof which will be processed directly, bypassing the
# cache.  
#
# The template is processed in the current context.  The method marks
# templates as "hot" while they are being processed to help identify
# recursion.  The return value is a status code or exception which 
# will be undefined or 0 (STATUS_OK) if the template processed without
# any (uncaught) errors.
#------------------------------------------------------------------------

sub _process {
    my ($self, $template) = @_;
    my $error;

    # request compiled template from cache
    $template = $self->{ CACHE }->fetch($template)
	|| return $self->throw($self->{ CACHE }->error())   ## RETURN ##
	    unless UNIVERSAL::isa($template, 'Template::Directive');

    # check we're not already visiting this template
    return $self->throw(ERROR_FILE, "recursion into '$template' identified")
	if $self->{ VISITING }->{ $template };		    ## RETURN ##

    # mark template as being visited
    $self->{ VISITING }->{ $template } = 1;

    # process template
    $error = $template->process($self);

    # a STATUS_RETURN is caught and cleared as this represents the 
    # correct point for a %% RETURN %% to return to
    $error = STATUS_OK 
	if $error == STATUS_RETURN;

    # clear visitation flag
    undef $self->{ VISITING }->{ $template };

    return $error;
}



#------------------------------------------------------------------------
# _runop(\@oplist) 
#
# This is the main runtime loop for processing opcode lists.  A reference
# to a list is passed in by parameter and the result of processing
# the sequence of operations contained therein is returned.  A second
# parameter may also be returned to indicate the status of the 
# operation.  This may be undefined or 0 (STATUS_OK) to indicate no
# error.
#
# Each entry in the list may be a numerical constant to indicate a
# fundamental operation or an array ref containing one member - an
# item to be be pushed straight onto the stack.  Different operations
# may push, pop or manipulate the stack in other ways.
#
# The top item on the stack after completing the opcode list is 
# popped and returned.  A second value may also be returned to 
# indicate an exception or error.
#------------------------------------------------------------------------ 

my $root_ops = {
    'inc'  => sub { local $^W = 0; my $item = shift; ++$item }, 
    'dec'  => sub { local $^W = 0; my $item = shift; --$item }, 
};

sub _runop {
    my ($self, $oplist) = @_;
    my $root = $self->{ STASH };
    my @stack = ();
    my ($op, $err, $val, $lflag, $p, $x, $y, $z);
    my $default_mode = 0;
    my $tolerant = 0;

    # DEBUG
    local $" = ', ';
    if ($DEBUG) {
	print STDERR "\n----- OPCODE RUNTIME -----\n";
	$self->oplist_dump($oplist);
	print STDERR "--------------------------\n";
    }

    foreach $op (@$oplist) {
	print STDERR "stack   ", join("\n        ", reverse @stack), "\n"
	    if $DEBUG;

	# if $op is an ARRAY ref then it contains some value which 
	# should be pushed straight onto the stack
	if (ref($op)) {
	    # DEBUG
	    print STDERR "runop + $op->[0]\n" if $DEBUG;

	    push(@stack, $op->[0]);
	    next;					    ## NEXT ##
	}

	# if $op isn't an ARRAY ref then it should be a numeric 
	# indicating the opcode type 

	# DEBUG
	print STDERR "runop * $op ($OP_NAME[$op]) " if $DEBUG;

	## OP_ROOT ##
	if ($op == OP_ROOT) {
	    # DEBUG
	    print STDERR "- $root\n" if $DEBUG;

	    # push a reference to the root stash onto the stack
	    push(@stack, $root);
	}

	## OP_BINOP ##
	elsif ($op == OP_BINOP) {
	    # top item on stack is a binary operator which keys into
	    # the $execute hash to get a coderef.  This is called with 
	    # the top two items popped off the stack and the result is
	    # pushed back onto the top.
	    $x = pop(@stack);
	    $y = $binop->{ $x }
		|| die "Invalid binary operation: $x\n";

	    # DEBUG
	    print STDERR "- $x ($stack[-2]) ($stack[-1])\n" if $DEBUG;

	    ($z, $err) = &$y(splice(@stack, -2));
	    return (undef, $err) if $err;		    ## RETURN ##
	    push(@stack, $z);
	}

	## OP_NOT ##
	elsif ($op == OP_NOT) {
	    # DEBUG
	    print STDERR "- $stack[-1]\n" if $DEBUG;

	    # logical negation of top item on stack
	    $stack[-1] = ! $stack[-1];
	}

	## OP_AND ##
	elsif ($op == OP_AND) {
	    # DEBUG
	    print STDERR "- $stack[-2] AND $stack[-1]\n" if $DEBUG;

	    # logical AND of top two items
	    $x = pop @stack;
	    $stack[-1] &&= $x;
	}

	## OP_OR ##
	elsif ($op == OP_OR) {
	    # DEBUG
	    print STDERR "- $stack[-2] OR $stack[-1]\n" if $DEBUG;

	    # logical OR of top two items
	    $x = pop @stack;
	    $stack[-1] ||= $x;

	}

	## OP_DUP ##
	elsif ($op == OP_DUP) {
	    # DEBUG
	    print STDERR "- $stack[-1]\n" if $DEBUG;

	    # duplicate top item on stack
	    push(@stack, $stack[-1]);
	}

	## OP_POP ##
	elsif ($op == OP_POP) {
	    # DEBUG
	    print STDERR "- $stack[-1]\n" if $DEBUG;

	    # pop top item off stack and discard
	    pop(@stack);
	}

	## OP_LIST ##
	elsif ($op == OP_LIST) {
	    # pushes a new anonymous list onto the stack
	    push(@stack, []);

	    # DEBUG
	    print STDERR "- $stack[-1]\n" if $DEBUG;
	}

	## OP_ITER ##
	elsif ($op == OP_ITER) {
	    require Template::Iterator;
	    ($x, $y) = splice(@stack, -2);
	    push(@stack, Template::Iterator->new($x, $y));
	}

	## OP_PUSH ##
	elsif ($op == OP_PUSH) {
	    # pushes the item popped off the top of the stack onto the end 
	    # of the list ref (we hope!) underneath it
	    # NOTE: this is *not* the logical opposite of OP_POP.  Think
	    # of it more as OP_LIST_PUSH without the extra typing.
	    
	    # DEBUG
	    print STDERR "- $stack[-1]\n" if $DEBUG;
	    $z = pop @stack;
	    push(@{$stack[-1]}, $z);
	}

	## OP_CAT ##
	elsif ($op == OP_CAT) {
	    # DEBUG
	    print STDERR "- $stack[-1]\n" if $DEBUG;

	    # concatenates the item popped off the top of the stack onto the 
	    # end of the string underneath it underneath it
	    $z = pop @stack;
	    $stack[-1] .= $z;
	}

	## OP_DEFAULT ##
	elsif ($op == OP_DEFAULT) {
	    # this is  kludge to turn the modify the OP_ASSIGN operator to
	    # only make the assignment if not already set (DEFAULT mode)
	    $default_mode = 1;
	}

	## OP_TOLERANT ##
	elsif ($op == OP_TOLERANT) {
	    # this is another hack to tell the DOT_OP to *NOT* raise an 
	    # exception when it encounters an undefined result.  Used by IF
	    $tolerant = 1;
	}

	## OP_DOT ##
	elsif ($op == OP_DOT || $op == OP_LDOT) {
	    # evaluates the item on top of the stack, representing the 
	    # right hand side of a 'dot' (aka period, '.') with respect to 
	    # the item below it, representing the left hand side.  Both 
	    # items are popped off and the result, based on a fairly 
	    # simple heuristic, is pushed back onto the stack. In the case
	    # of OP_LDOT, the operation is assumed to be on an lvalue and
	    # thus we allow auto-vivification of intermediate namespaces

	    # three items represent part of a variable of the form: x.y(p)
	    ($x, $y, $p) = splice(@stack, -3);
	    $p ||= [];
	    $lflag = ($op == OP_LDOT);

	    # DEBUG
	    print STDERR "- ", "[ $x ].[ $y ]( @$p )\n"
		if $DEBUG;

	    if (! defined $x || ! defined $y) {
		$x = 'undefined' unless defined $x;
		$y = 'undefined' unless defined $y;
		return (undef, $self->throw(ERROR_UNDEF,    ## RETURN ##
					    "cannot access [ $x ].[ $y ]"));
	    }
	    elsif ($y =~ /^[\._]/) {
		$z = undef;
	    }
	    elsif (UNIVERSAL::isa($x, 'Template::Stash')) {
		# DEBUG
		print STDERR "        . (Stash)\n" if $DEBUG;

		# if the LHS is a Stash then we call its get() method
		($z, $err) = $x->get($y, $p, $self);

		unless (defined $z || $err) {
		    # create an intermediate namespace hash if the item 
		    # doesn't exist and this is an OP_LDOT (lvalue)
		    if ($lflag) {
			$err = $x->set($y, $z = { });
		    }
		    # try to resolve undefined root variables
		    elsif ($x eq $root) {
			$z = $root_ops->{ $y };
			($z, $err) = &$z(@$p)
			    if $z;
		    }
		}
	    }
	    elsif (ref($x) eq 'HASH') {
		# DEBUG
		print STDERR "        . (HASH)\n" if $DEBUG;

		# if the LHS is a HASH then we look for the entry keyed by RHS;
		# value may be a CODE ref, which is called; if this is an 
		# OP_LDOT (lvalue) then we create a hash (intermediate 
		# namespace) if it doesn't already exist
		$z = $x->{ $y };
		if (defined $z) {
		    # TODO: may want to look for and reference returned lists
		    ($z, $err) = &$z(@$p)
			if ref($z) eq 'CODE';
		}
		elsif ($lflag) {
		    $z = $x->{ $y } = { };
		}
	    }
	    elsif (ref($x)) {
		# LHS may be an object ref so we call $lhs->$rhs($params)
		eval {
		    ($z, $err) = $x->$y(@$p);
		    # DEBUG
		    print STDERR "        . (Object)\n" if $DEBUG;
		};

		return (undef, $self->throw(ERROR_UNDEF,    ## RETURN ##
					    "cannot access [ $x ].$y ($@)")) 
		    if $@;
	    }
	    else {
		# give up
		return (undef, $self->throw(ERROR_UNDEF,    ## RETURN ##
		     "cannot access [ $x ].$y"));
	    }

	    # can't carry on in the face of an error
	    return (undef, $err) if $err;		    ## RETURN ##
	    
	    # an undefined value is OK (but converted to '') if error is 
	    # defined but 0 (STATUS_OK)
	    $z = ''
		if ! defined $z && defined $err;
		
	    # throw an exception if value is undefined - note that the 
	    # handler may return STATUS_OK to effectively clear the error.
	    return (undef, $self->throw(ERROR_UNDEF,	    ## RETURN ##
			"$y is undefined"))
		unless defined($z) || $tolerant;

	    # DEBUG
	    print STDERR "runop < ", $lflag ? "LDOT" : "DOT", " pushing $z\n"
		if $DEBUG;

	    push(@stack, $z);
	}

	## OP_ASSIGN ##
	elsif ($op == OP_ASSIGN) {
	    ($x, $y, $p, $z) = splice(@stack, -4);

	    # DEBUG
	    print STDERR "- $x.$y(@$p) = $z\n" if $DEBUG;

	    if (! defined $x || ! defined $y) {
		$x = 'undefined' unless defined $x;
		$y = 'undefined' unless defined $y;
		return (undef, $self->throw(ERROR_UNDEF,    ## RETURN ##
					    "cannot assign to [ $x ].[ $y ]"));
	    }
	    elsif  ($y =~ /^[\._]/) {
		return (undef, $self->throw(ERROR_UNDEF,    ## RETURN ##
					    "invalid name [ $y ]"));
	    }
	    elsif (UNIVERSAL::isa($x, 'Template::Stash')) {
		# DEBUG
		print STDERR "        = (Stash)\n" if $DEBUG;
		$err = $x->set($y, $z, $self)
		    unless ($default_mode 
			    && (($val, $err) = $x->get($y, $p, $self))
			    && $val);
	    }
	    elsif (ref($x) eq 'HASH') {
		# DEBUG
		print STDERR "        = (HASH)\n" if $DEBUG;
		$x->{ $y } = $z
		    unless $default_mode && $x->{ $y };
	    }
	    elsif (ref($x)) {
		# LHS may be an object ref so we call $lhs->$rhs($value)
		eval {
		    ($z, $err) = $x->$y($z)
			unless ($default_mode 
			    && (($val, $err) = $x->$y())
			    && $val);

		    # DEBUG
		    print STDERR "        . (Object)\n" if $DEBUG;
		};

		return (undef, $self->throw(ERROR_UNDEF,    ## RETURN ##
					    "cannot assign to [ $x ].$y")) 
		    if $@;
	    }
	    else {
		# give up
		return (undef, $self->throw(ERROR_UNDEF,    ## RETURN ##
		     "Cannot assign to [$x].$y"));
	    }

	    # can't carry on in the face of an error
	    return (undef, $err) if $err;		    ## RETURN ##
	    
	    # NOTE: we may want to throw an exception if value is undefined...
	    
	    # DEBUG
	    print STDERR "runop < $z\n" if $DEBUG;

	    push(@stack, $z);
	}

	## BAD OP ##
	else {
	    return (undef, $self->throw('opcode', "Bad opcode: $op\n"));
	}
    }

    pop(@stack);
}



#------------------------------------------------------------------------
# oplist_dump(\@oplist)
#
# Debug method to print opcode list.
#------------------------------------------------------------------------

sub oplist_dump {
    my ($self, $oplist) = @_;

    foreach my $op (@$oplist) {
	if (ref($op)) {
	    print STDERR "oplist + $op->[0]\n";
	}
	else {
	    print STDERR "oplist * $op ($OP_NAME[$op])\n";
	}
    }
}



1;

__END__

=head1 NAME

Template::Context - object class representing a runtime context in which templates are rendered.

=head1 SYNOPSIS

    use Template::Context;

    $context = Template::Context->new(\%cfg);

    $error   = $context->process($template, \%values);

    $context->output($text);
    $context->error($text);
    $context->throw($exception);   

    ($value, $error) = $context->runop(\@opcodes);

=head1 DOCUMENTATION NOTES

This documentation describes the Template::Context module and is aimed at 
people who wish to understand, extend or build template processing 
applications with the Template Toolkit.

For a general overview and information of how to use the modules, write
and render templates, see L<Template-Toolkit>.

=head1 DESCRIPTION

The Template::Context module defines an object which represents a runtime
context in which a template is rendered.  The context reference is passed 
down through the processing engine, allowing template directives and user 
code to generate output, retrieve and update variable values, render
other template documents, and so on.

The context defines the variables that exist for the template to access 
and what values they have (a task delegated to a 
L<Template::Stash|Template::Stash> object).

The context also maintains a reference to a cache of previously
compiled templates and has the facility to load, parse and compile new
template documents as they are requested.  These templates can then be 
accessed from within other templates via the "INCLUDE template_name" 
directive or may be rendered by a direct call from a template processing
engine.  The L<Template::Cache|Template::Cache> manages the template 
documents for the context  and delegates the parsing of new templates to 
a L<Template::Parser|Template::Parser> object.  A cache may be shared
among multiple context objects allowing common templates documents to
be compile only once and rendered many times in different contexts.

The context object provides template output and error handling methods 
which can output/delegate to a user-supplied file handle, text string or
sub-routine.  These handlers are defined using the redirect() method.

=head1 PUBLIC METHODS
    
=head2 new(\%config) 

Constructor method which instantiates a new Template::Context object,
initialised with the contents of an optional configuration hash array
passed by reference as a parameter.

Valid configuration values are:

=over 4

=item CATCH

The CATCH option may be used to specify a hash array of error handlers
which are used when a run time error condition occurs.  Each key in 
the hash represents an error type.  The Template Toolkit generates the 
following error types which have corresponding ERROR_XXX constants.

   undef    - GET on an undefined variable 
   file     - INCLUDE a file that can't be read
   parse    - INCLUDE a file that can't be parsed (bad syntwx)

User code may generate further errors of any types and custom handlers
may be provided to trap them.  A handler, defined as the related value
in the CATCH configuration hash may be one of the STATUS_XXXX constants
defined in Template::Constants (e.g. STATUS_OK, STATUS_STOP) or a code
reference which is called when an error occurs.  The handler is passed
a reference to the context ($self) and the error type and info.  The 
return value should be one of the aforementioned constants.

    use Template qw( :error );

    my $template = Template->new({
	CATCH => {
	    ERROR_UNDEF => STATUS_OK,
	    ERROR_FILE  => sub { my ($context, $type, $info) = @_;
				 $context->output("FILE ERROR: $info");
				 return STATUS_OK; 
			   },
	}
    });

=item STASH
    
A reference to a L<Template::Stash|Template::Stash> object or derivative
which should be used for storing and managing variable data.  A default 
stash is created (using PRE_DEFINE variables) if this parameter is not 
defined.

=item PRE_DEFINE

A reference to a hash which is passed to the Stash constructor to
pre-defined variables.  This variable has no effect if STASH is
defined to contain some existing Stash object.

=item CACHE

A reference to a L<Template::Cache|Template::Cache> object or derivative
which should be used for loading, parsing, compiling and caching template
documents.  A default cache is created (passing all configuration parameters)
if this is not provided.

=back

Examples:

    use Template::Context;
    use Template::Stash;
    use Template::Cache;

    my $stash = Template::Stash->new();
    my $cache = Template::Cache->new();

    # create own stash and cache
    my $context1 = Template::Context->new();

    # own cache, shared stash
    my $context2 = Template::Context->new({ 
	STASH => $stash 
    });

    # shared cached and stash
    my $context3 = Template::Context->new({ 
	STASH => $stash,
	CACHE => $cache,
    });

    # shared cached, own stash
    my $context4 = Template::Context->new({ 
	CACHE => $cache,
    });

=head2 process($template, \%params, $alias)

The process() method is called to render a template document within the
current context.  The first parameter should name the template document
or should be a file handle, glob reference or string (scalar) reference
from which the template can be read.  The second, optional parameter should
be a reference to a hash array of variables and values that should be 
defined for use (i.e. substitution) within the template.

    my $params = {
	'name' = 'Fred Oliver Oscarson',
	'id'   = 'foo'
    };

    $context->process('foopage.html', $params);

=head2 redirect($what, $where)

The redirect() method should be called with a first parameter represented
by one of the constants TEMPLATE_OUTPUT or TEMPLATE_ERROR.  These are 
defined in Template::Constants and can be imported by specifying 
C<':template'> as a parameter to C<use Template> or 
C<use Template::Constants>.

The second parameter may contain a file handle (GLOB or IO::handle) 
to which the output or error stream should be written.  Altenatively,
$where may be a reference to a scalar variable to which output is appended
or a code reference which is called to handle output.

    use Template::Context;
    use Template::Constants qw( :template );

    my $context = Template::Context->new();
    my $output  = '';
    $context->redirect(TEMPLATE_OUTPUT, \$output);
    $context->redirect(TEMPLATE_ERROR, \*STDOUT);

=head2 output($text, ...)

Prints all passed parameters to the output stream for the current template
context.  By default, output is sent to STDOUT unless redirected by 
calling the redirect() method.

    $context->output("The cat sat on the ", $place);

=head2 error($text, ...)

Directs the passed parameters to the error stream for the current template
context.  By default, errors are sent to STDERR unless redirected by 
calling the redirect() method.

    $context->error("This parrot is ", $dead);

=head2 throw($type, $info) / throw($exception)

The throw() method is called by other Template modules when an 
error condition occurs.  The caller will pass an error type and 
information string or a reference to a Template::Exception which
encompasses those values.  The error type is used to index into 
the CATCH hash array to see if a handler has been defined for this
kind of error.  If it has, the CATCH value is returned or code 
reference is run and it's value returned.

=head1 AUTHOR

Andy Wardley E<lt>cre.canon.co.ukE<gt>

=head1 REVISION

$Revision: 1.19 $

=head1 COPYRIGHT

Copyright (C) 1996-1999 Andy Wardley.  All Rights Reserved.
Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template-Toolkit|Template-Toolkit>

=cut

