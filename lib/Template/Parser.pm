#============================================================= -*-Perl-*-
#
# Template::Parser
#
# DESCRIPTION
#   Perl 5 module implementing a LALR(1) parser and assocated support 
#   methods to parse a template document into an internal "compiled"
#   format.  Much of the parser DFA code (see _parse() method) is based
#   on Francois Desarmenien's Parse::Yapp module.  Kudos to him.
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
#   The following copyright notice appears in the Parse::Yapp 
#   documentation.  
#
#      The Parse::Yapp module and its related modules and shell
#      scripts are copyright (c) 1998 Francois Desarmenien,
#      France. All rights reserved.
#
#      You may use and distribute them under the terms of either
#      the GNU General Public License or the Artistic License, as
#      specified in the Perl README file.
#
#----------------------------------------------------------------------------
#
# $Id: Parser.pm,v 1.26 2000/05/19 10:56:31 abw Exp $
#
#============================================================================

package Template::Parser;

require 5.004;

use strict;
use vars qw( $VERSION $DEBUG $DEFAULTS );

use Template::Constants qw( :debug :error :status );
use Template::Utils;
use Template::Directive;

# parser state constants
use constant CONTINUE => 0;
use constant ACCEPT   => 1;
use constant ERROR    => 2;
use constant ABORT    => 3;

$VERSION = sprintf("%d.%02d", q$Revision: 1.26 $ =~ /(\d+)\.(\d+)/);
$DEBUG = 0;


#========================================================================
#                       -----  CONFIGURATION -----
#========================================================================

my $TAG_STYLE   = {
    'default'   => [ '[\[%]%', '%[\]%]' ],
    'template'  => [ '\[%',    '%\]'    ],
    'percent'   => [ '%%',     '%%'     ],
    'html'      => [ '<!--',   '-->'    ],
    'asp'       => [ '<%',     '%>'     ],
    'php'       => [ '<\?',    '\?>'    ],
};

# default config for parser base class
$DEFAULTS = {
    START_TAG   => undef,
    END_TAG     => undef,
    TAG_STYLE   => 'default',
    CASE        => 0,
    INTERPOLATE => 0,
    PRE_CHOMP   => 0,
    POST_CHOMP  => 0,
    GRAMMAR     => undef,
    USER_DIR    => { },
    USER_BLOCK  => { },
    'ERROR'     => '',
};



#========================================================================
#                      -----  PUBLIC METHODS -----
#========================================================================

#------------------------------------------------------------------------
# new(\%config)
#
# Constructor method. 
#------------------------------------------------------------------------

sub new {
    my $class  = shift;
    my $config = shift || { };
    my ($tagstyle, $start, $end, $defaults, $grammar, $hash, $key, $udef);

    # look for hash of defaults in class package or used base defaults
    {  
	no strict 'refs';
	$defaults = ${"$class\::DEFAULTS"}
		  || $DEFAULTS;
    }

    my $self = Template::Utils::update_hash({ }, $config, $defaults);

    $grammar = $self->{ GRAMMAR } ||= do {
	require Template::Grammar;
	Template::Grammar->new();
    };
    $self->{ FACTORY } ||= 'Template::Directive';

    # determine START_TAG and END_TAG for specified (or default) TAG_STYLE
    $tagstyle = $self->{ TAG_STYLE } || 'default';
    unless (defined ($start = $TAG_STYLE->{ $tagstyle })) {
	warn "Invalid tag style: $tagstyle\n";
	$start = $TAG_STYLE->{'default'};
    }
    ($start, $end) = @$start;
    $self->{ START_TAG } ||= $start;
    $self->{   END_TAG } ||= $end;

    # load grammar rules, states and lex table
    @$self{ qw( LEXTABLE STATES RULES ) } 
	= @$grammar{ qw( LEXTABLE STATES RULES ) };
    
    # build lookup table for user defined directives
    $hash = $self->{ USER_DIR };
    foreach $key (%$hash) {
	$udef->{ $key } = [ 'UDIR', $hash->{ $key } ],
    }
    $hash = $self->{ USER_BLOCK };
    foreach $key (%$hash) {
	$udef->{ $key } = [ 'UBLOCK', $hash->{ $key } ],
    }
    $self->{ UDEF } = $udef;

    bless $self, $class;
}



#------------------------------------------------------------------------
# parse($text, $cache)
#
# Parses the text string, $text and returns a Template::Directive::Block
# object which represents the root node of the "compiled" template.
# The process() method may then be called on the block, passing in a 
# valid Template::Context reference, to process the template.
#
# The second parameter may contain a reference to a Template::Cache 
# object.  BLOCK definitions within the file will be parsed and compiled
# to the same internal form.  If the template parses successfully, the
# $cache->store($block, $name) method will be called for each defined 
# block.  This step is skipped if $cache is undefined.  
#
# NOTE: callers that pass a global or shared cache object into this 
# method should be aware that BLOCK definitions within the template 
# will overwrite any existing block definitions in the cache.  For example,
# The "%% BLOCK header %% ...blah...blah... %% END %%" definition will 
# cause any subsequent "%% INCLUDE header %%" to get this block.  This 
# may not be what you expected.  I'm looking at improving the overall 
# caching and template retrieval strategy so this may get better in time.
# Ideas welcome.
#
# Returns a reference to a Template::Directive::Block which represents
# the compiled template.  On error, undef is returned and the internal 
# ERROR string is set and may be retrieved via the error() method.
#------------------------------------------------------------------------

sub parse {
    my ($self, $text, $cache) = @_;
    my ($tokens, $block);

    # store for blocks defined in the template (see define_block())
    my $defblock = $self->{ DEFBLOCK } = { };

    $self->{'ERROR'} = '';

    # split file into TEXT/DIRECTIVE chunks
    $tokens = $self->split_text($text)
	|| return undef;				    ## RETURN ##

#    local $" = '] [';
#    print "token: [ @$tokens ]\n";

    # parse chunks
    $block = $self->_parse($tokens)
	|| return undef;				    ## RETURN ##

    # store any defined blocks in the cache
    if (defined $cache) {
	while (my ($name, $blkdef) = (each %$defblock)) {
	    $cache->store($blkdef, $name);
	}
    }

    return $block;					    ## RETURN ##
}



#------------------------------------------------------------------------
# split_text($text)
#
# Called by the parse() method to split the input text into chunks
# of raw text which should be parsed through the template processor 
# intact (TEXT), and template processor directives, embedded within 
# specific tags which indicate some action (DIRECTIVE).  
#
# The method constructs a list in which a pair of consecutive  elements
# is used to represent each chunk.  The first element contains the 
# text string 'TEXT' or 'DIRECTIVE' to indicate the chunk type.  The 
# second contains the text of the chunk itself.
#
# Each time a directive is encountered, its line number is added to 
# the end of the $self->{ LINE_NOS } list (an empty one is created if
# necessary). 
#
# Returns a reference to the list of chunks (each one being 2 elements) 
# identified in the input text.  On error, the internal ERROR string 
# is set and undef is returned.
#------------------------------------------------------------------------

sub split_text {
    my ($self, $text) = @_;
    my ($pre, $dir, $prelines, $dirlines, $postlines, $linenos, $chomp);
    my ($start, $end, $prechomp, $postchomp, $interp ) = 
	@$self{ qw( START_TAG END_TAG PRE_CHOMP POST_CHOMP INTERPOLATE ) };

    my @tokens = ();
    my $line   = 1;

    return \@tokens					    ## RETURN ##
	unless defined $text && length $text;
    
    $self->{ LINE_NOS } = $linenos  = [];

#    $start = quotemeta($start);
#    $end   = quotemeta($end);

    # extract all directives from the text
    while ($text =~ s/
	   ^(.*?)               # $1 - start of line up to directive
	    (?:
		$start          # start of tag
		(.*?)           # $2 - tag contents
		$end            # end of tag
	    )
	    //sx) {

	($pre, $dir) = ($1, $2);
	$pre = '' unless defined $pre;
	$dir = '' unless defined $dir;
	
# DEBUG
#	my ($cp, $cd) = ($pre, $dir);
#	foreach ($cp, $cd) { s/\n/\\n/g };
#	print "[$cp] [$cd]\n";

	$postlines = 0;                      # denotes lines chomped

	$prelines  = ($pre =~ tr/\n//);      # NULL - count only
	$dirlines  = ($dir =~ tr/\n//);      # ditto 

	# the directive CHOMP options may modify the preceeding text
	for ($dir) {
	    # remove leading whitespace and check for a '-' chomp flag
	    s/^([-+#])?\s*//s;
	    if ($1 && $1 eq '#') {
		# comment out entire directive
		$dir = '';
	    }
	    else {
		$chomp = ($1 && $1 eq '+') ? 0 : ($1 || $prechomp);

		# chomp off whitespace and newline preceeding directive
		$chomp and $pre =~ s/(\n|^)[ \t]*\Z//m
		       and $1 eq "\n"
		       and $prelines++;
	    }

	    # remove trailing whitespace and check for a '-' chomp flag
	    s/\s*([-+])?\s*$//s;
	    $chomp = ($1 && $1 eq '+') ? 0 : ($1 || $postchomp);

	    # only chomp newline if it's not the last character
	    $chomp and $text =~ s/^[ \t]*\n(.|\n)/$1/
		   and $postlines++;
	}

	# any text preceeding the directive can now be added
	if (length $pre) {
	    push(@tokens, $interp 
		      ? (@{ $self->interpolate_text($pre, $line) })
		      : ('TEXT', $pre) );
	    $line += $prelines;
	}
	
	# and now the directive, along with line number information
	if (length $dir) {
	    # the TAGS directive is a compile-time switch
	    if ($dir =~ /TAGS\s+(.*)/i) {
		my $tags;
		my @tags = split(/\s+/, $1);
		if (scalar @tags > 1) {
		    ($start, $end) = map { quotemeta($_) } @tags;
		}
		elsif ($tags = $TAG_STYLE->{ $tags[0] }) {
		    ($start, $end) = @$tags;
		}
		else {
		    warn "invalid TAGS style: $tags[0]\n";
		}
	    }
	    else {
		push(@tokens, 'DIRECTIVE', $dir);
		push(@$linenos, $line);
	    }

	    # this is the fancy way but is temporarily removed because "n-n"
	    # line numbers are not numeric and confuse interpolate_text()
	    # push(@$linenos, 
	    #	 $dirlines ? sprintf("%d-%d", $line, $line + $dirlines)
	    #	           : $line
	    #	 );

	}

	# update line counter to include directive lines and any extra
	# newline chomped off the start of the following text
	$line += $dirlines + $postlines;
    }

    # anything remaining in the string is plain text 
    push(@tokens, $interp 
	    ? (@{ $self->interpolate_text($text, $line) })
	    : ('TEXT', $text))
	if length $text;

    return \@tokens;					    ## RETURN ##
}



#------------------------------------------------------------------------
# interpolate_text($text, $line)
#
# Examines $text looking for any variable references embedded like
# $this or like ${ this }.  The text string is split into a list 
# of TEXT elements or DIRECTIVE elements, as per split_text().
# This method also updates LINE_NOS, using the starting offset of
# $line if specified.
#
# A reference to the list is returned.
#------------------------------------------------------------------------

sub interpolate_text {
    my ($self, $text, $line) = @_;
    my $linenos = $self->{ LINE_NOS } ||= [ ];
    my @tokens  = ();
    my ($pre, $var, $dir);

    $line ||= 1;

    while ($text =~ 
	   /
	   ( (?: \\. | [^\$] )+ )   # escaped or non-'$' character [$1]
	   | 
	   ( \$ (?:		    # embedded variable	           [$2]
	     (?: \{ ([^\}]*) \} )   # ${ ... }                     [$3]
	     |
	     ([\w\.]+)		    # $word                        [$4]
	     )
	   )
	/gx) {
    
	($pre, $var, $dir) = ($1, $3 || $4, $2);

	# preceeding text
	if ($pre) {
# DEBUG
#	    my $copypre = $pre;
#	    $copypre =~ s/\n/\\n/g;
#	    print "INTERP: pre: [ $copypre ]\n";

	    $line += $pre =~ tr/\n//;
	    $pre =~ s/\\\$/\$/g;
	    push(@tokens, 'TEXT', $pre);
	}
	# $variable reference
        if ($var) {
# DEBUG 
#	    my $copyvar = $var;
#	    $copyvar =~ s/\n/\\n/g;
#	    print "INTERP: var: [ $copyvar ]\n";

	    push(@$linenos, $line);
	    $line += $dir =~ tr/\n/ /;

	    push(@tokens, 'DIRECTIVE', $var);
	}
	# other '$' reference - treated as text
	elsif ($dir) {
# DEBUG
#	    my $copydir = $dir;
#	    $copydir =~ s/\n/\\n/g;
#	    print "INTERP: ign: [ $copydir ]\n";

	    $line += $dir =~ tr/\n//;
	    push(@tokens, 'TEXT', $dir);
	}
    }

    return \@tokens;
}



#------------------------------------------------------------------------
# tokenise_directive($text)
#
# Called by the private _parse() method when it encounters a DIRECTIVE
# token in the list provided by the split_text() or interpolate_text()
# methods.  The directive text is passed by parameter.
#
# The method splits the directive into individual tokens as recognised
# by the parser grammar (see Template::Grammar for details).  It
# constructs a list of tokens each represented by 2 elements, as per
# split_text() et al.  The first element contains the token type, the
# second the token itself.
#
# The method tokenises the string using a complex (but fast) regex.
# For a deeper understanding of the regex magic at work here, see
# Jeffrey Friedl's excellent book "Mastering Regular Expressions",
# from O'Reilly, ISBN 1-56592-257-3
#
# Returns a reference to the list of chunks (each one being 2 elements) 
# identified in the directive text.  On error, the internal ERROR string 
# is set and undef is returned.
#------------------------------------------------------------------------

sub tokenise_directive {
    my ($self, $text) = @_;
    my ($token, $uctoken, $type, $lookup);
    my ($lextable, $case) = @$self{ qw( LEXTABLE CASE ) };
    my @tokens = ( );


    if ($text =~ /^(\S+)\s*(.*)/) {
	$token = $1;
	if (uc $token eq 'DEBUG') {
	    # return 2 lexer token pairs; the 'DEBUG' identitifer and the text
	    return [ 'DEBUG', 'DEBUG', 'TEXT', $2 ];	    ## RETURN ##
	}
	elsif ($lookup = $self->{ UDEF }->{ $token }) {
	    return [ $lookup->[0], &{$lookup->[1]}($text) ];
	}
    }

#    $self->_debug("TOKENISE: $text\n");

    while ($text =~ 
	    / 
		# a quoted phrase matches in $2
		(["'])                   # $1 - opening quote, " or '
		(                        # $2 - quoted text buffer
		    (?:                  # repeat group (no backreference)
			\\\\             # an escaped backslash \\
		    |                    # ...or...
			\\\1             # an escaped quote \" or \' (match $1)
		    |                    # ...or...
			.                # any other character
		    )*?                  # non-greedy repeat
		)                        # end of $2
		\1                       # match opening quote
	    |
		# strip out any comments in $3
	        (\#[^\n]*)
	   |
		# an unquoted number matches in $4
		(-?\d+)                  # numbers
	    |
		# an identifier matches in $5
		(\w+)                    # variable identifier
	    |   
		# an unquoted word or symbol matches in $6
		(   [(){}\[\];,\/\\]     # misc parenthesis and symbols
		|   \+\-\*               # math operations
		|   \$\{?                # dollar with option left brace
		|   =>			 # like '='
		|   [=!<>]?= | [!<>]     # eqality tests
		|   &&? | \|\|?          # boolean ops
		|   \.\.?                # n..n sequence
 		|   \S+                  # something unquoted
		)                        # end of $5
	    /gmxo) {

	# ignore comments to EOL
	next if $3;

	# quoted string
	if (defined ($token = $2)) {
            # double-quoted string may include $variable references
	    if ($1 eq '"' && $token =~ /[\$\\]/) {
		$type = 'QUOTED';
		$token =~ s/\\([\\"])/$1/g;
		$token =~ s/\\n/\n/g;
	    } 
	    else {
		$type = 'LITERAL';
		# unescape escaped characters
		$token =~ s/\\([\\'])/$1/g;
	    }
	}
	# number
	elsif (defined ($token = $4)) {
	    $type = 'LITERAL';
	}
	elsif (defined($token = $5)) {
	    # reserved words may be in lower case unless case sensitive
	    $uctoken = $case ? $token : uc $token;
	    if (defined ($type = $lextable->{ $uctoken })) {
		$token = $uctoken;
	    }
	    else {
		$type = 'IDENT';
	    }
	}
	elsif (defined ($token = $6)) {
	    # reserved words may be in lower case unless case sensitive
	    $uctoken = $case ? $token : uc $token;
	    unless (defined ($type = $lextable->{ $uctoken })) {
		$type = 'UNQUOTED';
	    }
	}

	push(@tokens, $type, $token);

#	print("  [ $type, $token ]\n");
    }

    return \@tokens;					    ## RETURN ##
}



#------------------------------------------------------------------------
# define_block($name, $block)
#
# Called by the parser 'defblock' rule when a BLOCK definition is 
# encountered in the template.  The name of the block is passed in the 
# first parameter and a reference to the compiled block is passed in
# the second.  This method stores the block in the $self->{ DEFBLOCK }
# hash which has been initialised by parse() and will later be used 
# by the same method to call the store() method on the calling cache
# to define the block "externally".
#------------------------------------------------------------------------

sub define_block {
    my ($self, $name, $block) = @_;
    my $defblock = $self->{ DEFBLOCK } 
        || return undef;

    $defblock->{ $name } = $block;
}



#------------------------------------------------------------------------
# error()
#
# Simple accessor method to return the internal ERROR string.
#------------------------------------------------------------------------

sub error {
    $_[0]->{'ERROR'};
}



#========================================================================
#                     -----  PRIVATE METHODS -----
#========================================================================

#------------------------------------------------------------------------
# _parse(\@tokens)
#
# Parses the list of input tokens passed by reference and returns a 
# Template::Directive::Block object which contains the compiled 
# representation of the template. 
#
# This is the main parser DFA loop.  See embedded comments for 
# further details.
#
# On error, undef is returned and the internal ERROR field is set to 
# indicate the error.  This can be retrieved by calling the error() 
# method.
#------------------------------------------------------------------------

sub _parse {
    my ($self, $tokens) = @_;
    my ($token, $value, $dirtext, $dirtoks, $dirno, $line, $linenos);
    my ($state, $stateno, $status, $action, $lookup, $coderet, @codevars);
    my ($lhs, $len, $code);	    # rule contents
    my $stack = [ [ 0, undef ] ];   # DFA stack

# DEBUG
   local $" = ', ';

    # retrieve internal rule and state tables
    my ($states, $rules) = @$self{ qw( STATES RULES ) };

    # call the grammar set_factory method to install emitter factory
    $self->{ GRAMMAR }->install_factory($self->{ FACTORY });

    # when we report errors, we want to be able to report the line offset
    # in the file or text where the error occured.  split_text() obliges us
    # by creating a LINE_NOS member referencing a list of the line
    # offset for each directive in the text.
    $linenos = $self->{ LINE_NOS };
    $line    = 0;
    $self->{ LINE } = \$line;

    $status = CONTINUE;

    while(1) {
	# get state number and state
	$stateno =  $stack->[-1]->[0];
	$state   = $states->[$stateno];

	# see if any lookaheads exist for the current state
	if (exists $state->{'ACTIONS'}) {

	    # get next token/value pair from the lexer
	    defined($token) or	do {
		($token, $value) = splice(@$tokens, 0, 2);
	    };
	    $token = '' unless defined $token;

# DEBUG
#	     my $v = $value;
#	     $v = '' unless defined $v;
#	     $v =~ s/\n/\\n/g;
#	     print "token: [$token] value: [$v]\n";
#	     print "stack: [@$tokens]\n";
# /DEBUG
	    # if the token is a directive, we call call the lexer to
	    # tokenise it
	    if ($token eq 'DIRECTIVE') {

		# get the line number of the directive
		$line = shift @$linenos
		    || 0;

		# save directive text for error reporting on failure
		$dirtext = $value;

		$dirtoks = $self->tokenise_directive($value)
		    || return undef;			    ## RETURN ##

# DEBUG
#		print STDERR "directive @ $line\ndirtoks: @$dirtoks\n"
#		    if $DEBUG;
# /DEBUG
		# push tokens into front of existing token list,
		# adding a 'SEPARATOR' token - this is a hack to 
		# simulate the 'THEN' after an 'IF', for example
		unshift(@$tokens, @$dirtoks, ';', ';');

		($token, $value) = ();
		redo;					    ## REDO ##
	    }
	    elsif ($token eq 'QUOTED') {
		# $line may be slightly wrong, but it's our best guess
		# and we should never need to access these line nos
		unshift(@$tokens, 
			'"', '"',
			@{ $self->interpolate_text($value, $line) },
			'"', '"');
		($token, $value) = ();
		redo;					    ## REDO ##
	    }

	    # get the next state for the current lookahead token
	    $action = defined ($lookup = $state->{'ACTIONS'}->{ $token })
	              ? $lookup
		      : defined ($lookup = $state->{'DEFAULT'})
		        ? $lookup
		        : undef;
	}
	else {
	    # no lookahead actions
	    $action = $state->{'DEFAULT'};
	}

# DEBUG
#	$self->_debug(DEBUG_PARSE, 
#	 print(
#		 "  State #$stateno",
#		 "  Token: ", 
#		     defined $token ? "[$token]" : "<undef>",
#		 "  Value: ",
#		     defined $value ? "[$value]" : "<undef>",
#		 "  Action: ",
#		     $action > 0 
#			 ? "shift -> $action"
#			 : "reduce -> $action",
#		 "\n");
# /DEBUG

	# ERROR: no ACTION
	last unless defined $action;

	# - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	# shift (+ive ACTION)
	# - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	if ($action > 0) {
	    push(@$stack, [ $action, $value ]);
# DEBUG
#	 $self->_debug(DEBUG_PARSE, 
#		 "  Shift $action, $value\n");
# /DEBUG

	    $token = $value = undef;
	    redo;
	};


	# - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	# reduce (-ive ACTION)
	# - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	($lhs, $len, $code) = @{ $rules->[ -$action ] };

# DEBUG
#	 $self->_debug(DEBUG_PARSE, 
#		 "  Reduce stack by $len from rule '$lhs'\n");
# /DEBUG
	# no action imples ACCEPTance
	$action
	    or $status = ACCEPT;

	# use dummy sub if code ref doesn't exist
	$code = sub { $_[1] }
	    unless $code;

	@codevars = $len
		?   map { $_->[1] } @$stack[ -$len .. -1 ]
		:   ();

	$coderet = &$code( $self, @codevars );

	# reduce stack by $len
	splice(@$stack, -$len, $len);

	# ACCEPT
	return $coderet					    ## RETURN ##
	    if $status == ACCEPT;

	# ABORT
	return undef					    ## RETURN ##
	    if $status == ABORT;

	# ERROR
	last 
	    if $status == ERROR;
    }
    continue {
	push(@$stack, [ $states->[ $stack->[-1][0] ]->{'GOTOS'}->{ $lhs }, 
	      $coderet ]), 
    }

    # ERROR						    ## RETURN ##
    return $self->_parse_error('unexpected end of input')
	unless defined $value;

    # munge text of last directive to make it readable
    $dirtext =~ s/\n/\\n/g;

    return $self->_parse_error("unexpected end of directive\n -- $dirtext")
	if $value eq ';';   # end of directive SEPARATOR

    return $self->_parse_error("unexpected token ($value)\n -- $dirtext");
}



#------------------------------------------------------------------------
# _parse_error($msg)
#
# Method used to handle errors encountered during the parse process
# in the _parse() method.  
#------------------------------------------------------------------------

sub _parse_error {
    my ($self, $msg) = @_;
    my $line = $self->{ LINE };

    $line = ref($line) ? $$line : $line;
    $line = 'unknown' unless $line;

    $self->{'ERROR'} = "line $line: $msg";

    return undef;
}


sub _debug {
    my $self = shift;
    my $level = shift;
    local $" = '';
    print STDERR "DEBUG: @_"
	if $DEBUG;
}

sub dump_args {
    my $self = shift;
    my $args = shift || [];

    foreach my $arg (@$args) {
	print $arg;
	print "  [@$arg]" if ref($arg) eq 'ARRAY';
	print "\n";
    }
    $args;
}

1;


__END__


=head1 NAME

Template::Parser - module implementing LALR(1) parser for compiling template documents

=head1 SYNOPSIS

    use Template::Parser;

    my $parser   = Template::Parser->new();
    my $template = $parser->parse($text);

    die $parser->error()
	unless defined $template;

=head1 DESCRIPTION

The Template::Parser module implements a LALR(1) parser and associated methods
for parsing template documents into an internal compiled format.

=head1 PUBLIC METHODS

=head2 new(\%params)

The new() constructor creates and returns a reference to a new 
Template::Parser object.  A reference to a hash may be supplied as a 
parameter to provide configuration values.  These may include:

=over

=item START_TAG, END_TAG, TAG_STYLE

The START_TAG and END_TAG options are used to specify the character 
sequences that mark the start and end of a template directive.

=item INTERPOLATE

The INTERPOLATE flag, when set to any true value will cause variable 
references in plain text (i.e. not surrounded by START_TAG and END_TAG)
to be recognised and interpolated accordingly.  Variables should be
prefixed by a '$' to identify them and may contain only alphanumeric
characters, underscores or periods.  Curly braces can be used to 
explicitly specify the variable name where it may be ambiguous.

=item PRE_CHOMP, POST_CHOMP

These values set the chomping options for the parser.  With POST_CHOMP
set true, any whitespace after a directive up to and including the newline
will be deleted.  This has the effect of joining a line that ends with 
a directive onto the start of the next line.

With PRE_CHOMP set true, the newline and whitespace preceeding a directive
at the start of a line will be deleted.  This has the effect of 
concatenating a line that starts with a directive onto the end of the 
previous line.

=item GRAMMAR

The GRAMMAR configuration item can be used to specify an alternate 
grammar for the parser.  If not specified, an instance of the default
Template::Grammar will be created and used automatically.  

    use Template::Parser;
    use MyTemplate::MyGrammar;

    my $parser = Template::Parser->new({ 
       	GRAMMAR = MyTemplate::MyGrammar->new();
    });

=back

=head2 parse($text)

The parse() method parses the text passed in the first parameter and returns
a reference to a Template::Directive::Block object which contains the 
compiled representation of the template text.  On error, undef is returned.

Example:

    $parser->parse($text)
	|| die $parser->error();

=head2 error()

Returns a string indicating the most recent parser error.

=head1 AUTHOR

Andy Wardley E<lt>abw@cre.canon.co.ukE<gt>

=head1 REVISION

$Revision: 1.26 $

=head1 COPYRIGHT

Copyright (C) 1996-1999 Andy Wardley.  All Rights Reserved.
Copyright (C) 1998-1999 Canon Research Centre Europe Ltd.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

The Template::Parser module is derived from a standalone parser generated
by version 0.16 of the Parse::Yapp module.  The following copyright notice 
appears in the Parse::Yapp documentation.  

    The Parse::Yapp module and its related modules and shell
    scripts are copyright (c) 1998 Francois Desarmenien,
    France. All rights reserved.

    You may use and distribute them under the terms of either
    the GNU General Public License or the Artistic License, as
    specified in the Perl README file.

=head1 SEE ALSO

L<Template|Template>, 
L<Template::Grammar|Template::Grammar>, 
L<Template::Directive|Template::Directive>

=cut


