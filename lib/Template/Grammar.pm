#=========================================================================
#
# Template::Grammar
#
# DESCRIPTION
#   Perl 5 module defining the default grammar for Template::Parser.
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
# NOTE: this module is constructed from the parser/Grammar.pm.skel
# file by running the parser/yc script.  You only need to do this if 
# you have modified the grammar in the parser/Parser.yp file and need
# to-recompile it.  See the README in the 'parser' directory for more
# information (sub-directory of the Template distribution).
#
#------------------------------------------------------------------------
#
# $Id: Grammar.pm,v 1.41 2000/05/19 09:38:25 abw Exp $
#
#========================================================================

package Template::Grammar;

require 5.004;

use strict;
use vars qw( $VERSION );

use Template::Constants qw( :ops :status );

$VERSION = sprintf("%d.%02d", q$Revision: 1.41 $ =~ /(\d+)\.(\d+)/);

my (@RESERVED, $LEXTABLE, $RULES, $STATES);
my $factory;

sub new {
    my $class = shift;
    bless {
	LEXTABLE => $LEXTABLE,
	STATES   => $STATES,
	RULES    => $RULES,
    };
}

# update method to set package-scoped $factory lexical 
sub install_factory {
    my ($self, $new_factory) = @_;
    $factory = $new_factory;
}



#========================================================================
# Reserved Words
#========================================================================

@RESERVED = qw( 
	GET CALL SET DEFAULT INCLUDE PROCESS 
	IF UNLESS ELSE ELSIF FOR WHILE USE FILTER 
	THROW CATCH ERROR RETURN STOP BREAK MACRO
	PERL BLOCK END TO STEP AND OR NOT
    );


#========================================================================
# Lexer Token Table
#========================================================================

# lookup table used by lexer is initialised with special-cases
$LEXTABLE = {
    'FOREACH' => 'FOR',
    '&&'      => 'AND',
    '||'      => 'OR',
    '!'       => 'NOT',
    '|'	      => 'FILTER',
    '.'       => 'DOT',
    '..'      => 'TO',
    '='       => 'ASSIGN',
    '=>'      => 'ASSIGN',
    ','       => 'COMMA',
    '\\'      => 'REF',
    'and'     => 'AND',		# explicitly specified so that qw( and or
    'or'      => 'OR',		# not ) can always be used in lower case, 
    'not'     => 'NOT'		# regardless of CASE sensitivity flag
};

# localise the temporary variables needed to complete lexer table
{ 
    my @tokens   = qw< ( ) [ ] { } ${ $ / ; >;
    my @compop   = qw( == != < <= >= > );
    my @binop    = qw( + - * DIV MOD );

    # fill lexer table, slice by slice, with reserved words and operators
    @$LEXTABLE{ @RESERVED, @compop, @binop, @tokens } 
	= ( @RESERVED, ('COMPOP') x @compop, ('BINOP') x @binop, @tokens );
}


#========================================================================
# States
#========================================================================

$STATES = [
	{#State 0
		ACTIONS => {
			'GET' => 2,
			'UBLOCK' => 1,
			'INCLUDE' => 4,
			'TEXT' => 7,
			'DEFAULT' => 6,
			'BREAK' => 5,
			'STOP' => 8,
			'FOR' => 9,
			"[" => 13,
			'BLOCK' => 14,
			'SET' => 15,
			'USE' => 16,
			'MACRO' => 17,
			'UNLESS' => 20,
			'PROCESS' => 23,
			'RETURN' => 25,
			'CATCH' => 26,
			'FILTER' => 28,
			'DEBUG' => 30,
			";" => -16,
			"{" => 31,
			'ERROR' => 32,
			"\${" => 35,
			'LITERAL' => 36,
			'IF' => 39,
			"\"" => 40,
			"\$" => 42,
			'PERL' => 44,
			'IDENT' => 46,
			'UDIR' => 47,
			'THROW' => 48,
			'WHILE' => 50,
			'CALL' => 51,
			'REF' => 52
		},
		DEFAULT => -2,
		GOTOS => {
			'return' => 24,
			'catch' => 3,
			'assign' => 27,
			'filter' => 29,
			'condition' => 11,
			'debug' => 10,
			'setlist' => 12,
			'block' => 33,
			'chunks' => 34,
			'userdef' => 37,
			'item' => 38,
			'atomdir' => 41,
			'macro' => 43,
			'perl' => 45,
			'ident' => 18,
			'term' => 49,
			'chunk' => 19,
			'defblock' => 22,
			'loop' => 21,
			'directive' => 53
		}
	},
	{#State 1
		ACTIONS => {
			";" => 54
		}
	},
	{#State 2
		ACTIONS => {
			"\"" => 40,
			"{" => 31,
			"[" => 13,
			"\$" => 42,
			'IDENT' => 46,
			'REF' => 52,
			'LITERAL' => 56,
			"\${" => 35
		},
		GOTOS => {
			'term' => 57,
			'ident' => 55,
			'item' => 38
		}
	},
	{#State 3
		DEFAULT => -8
	},
	{#State 4
		ACTIONS => {
			"\"" => 62,
			"\$" => 63,
			'IDENT' => 64,
			'LITERAL' => 61,
			"/" => 59
		},
		GOTOS => {
			'file' => 60,
			'textdot' => 58
		}
	},
	{#State 5
		DEFAULT => -32
	},
	{#State 6
		ACTIONS => {
			"\$" => 42,
			'IDENT' => 46,
			"\${" => 35,
			'LITERAL' => 67
		},
		GOTOS => {
			'setlist' => 65,
			'ident' => 66,
			'assign' => 27,
			'item' => 38
		}
	},
	{#State 7
		DEFAULT => -5
	},
	{#State 8
		DEFAULT => -31
	},
	{#State 9
		ACTIONS => {
			"\"" => 40,
			"{" => 31,
			"[" => 13,
			"\$" => 42,
			'IDENT' => 69,
			'REF' => 52,
			'LITERAL' => 56,
			"\${" => 35
		},
		GOTOS => {
			'term' => 70,
			'loopvar' => 68,
			'ident' => 55,
			'item' => 38
		}
	},
	{#State 10
		DEFAULT => -15
	},
	{#State 11
		DEFAULT => -9
	},
	{#State 12
		ACTIONS => {
			"\$" => 42,
			'IDENT' => 46,
			'LITERAL' => 67,
			"\${" => 35,
			'COMMA' => 72
		},
		DEFAULT => -27,
		GOTOS => {
			'ident' => 66,
			'assign' => 71,
			'item' => 38
		}
	},
	{#State 13
		ACTIONS => {
			"\"" => 40,
			"{" => 31,
			"[" => 13,
			"\$" => 42,
			'IDENT' => 46,
			'REF' => 52,
			'LITERAL' => 56,
			"\${" => 35
		},
		GOTOS => {
			'term' => 75,
			'list' => 74,
			'ident' => 55,
			'range' => 73,
			'item' => 38
		}
	},
	{#State 14
		ACTIONS => {
			";" => 77,
			'IDENT' => 64
		},
		GOTOS => {
			'textdot' => 76
		}
	},
	{#State 15
		ACTIONS => {
			"\$" => 42,
			'IDENT' => 46,
			"\${" => 35,
			'LITERAL' => 67
		},
		GOTOS => {
			'setlist' => 78,
			'ident' => 66,
			'assign' => 27,
			'item' => 38
		}
	},
	{#State 16
		ACTIONS => {
			'IDENT' => 81
		},
		GOTOS => {
			'textdot' => 79,
			'useparam' => 80
		}
	},
	{#State 17
		ACTIONS => {
			'IDENT' => 82
		}
	},
	{#State 18
		ACTIONS => {
			'ASSIGN' => 84,
			'DOT' => 83
		},
		DEFAULT => -61
	},
	{#State 19
		DEFAULT => -4
	},
	{#State 20
		ACTIONS => {
			"\"" => 40,
			'NOT' => 85,
			"\$" => 42,
			'IDENT' => 46,
			"(" => 88,
			"[" => 13,
			"{" => 31,
			'REF' => 52,
			"\${" => 35,
			'LITERAL' => 36
		},
		GOTOS => {
			'term' => 89,
			'ident' => 18,
			'assign' => 87,
			'item' => 38,
			'expr' => 86
		}
	},
	{#State 21
		DEFAULT => -10
	},
	{#State 22
		DEFAULT => -11
	},
	{#State 23
		ACTIONS => {
			"\"" => 62,
			"\$" => 63,
			'IDENT' => 64,
			'LITERAL' => 61,
			"/" => 59
		},
		GOTOS => {
			'file' => 90,
			'textdot' => 58
		}
	},
	{#State 24
		DEFAULT => -26
	},
	{#State 25
		DEFAULT => -30
	},
	{#State 26
		ACTIONS => {
			";" => 92,
			'IDENT' => 64
		},
		GOTOS => {
			'textdot' => 91
		}
	},
	{#State 27
		DEFAULT => -84
	},
	{#State 28
		ACTIONS => {
			'IDENT' => 81
		},
		GOTOS => {
			'textdot' => 79,
			'useparam' => 93
		}
	},
	{#State 29
		DEFAULT => -29
	},
	{#State 30
		ACTIONS => {
			'TEXT' => 94
		}
	},
	{#State 31
		ACTIONS => {
			'IDENT' => 99,
			'LITERAL' => 98
		},
		DEFAULT => -94,
		GOTOS => {
			'param' => 95,
			'params' => 96,
			'paramlist' => 97
		}
	},
	{#State 32
		ACTIONS => {
			"\"" => 40,
			"{" => 31,
			"[" => 13,
			"\$" => 42,
			'IDENT' => 46,
			'REF' => 52,
			'LITERAL' => 56,
			"\${" => 35
		},
		GOTOS => {
			'term' => 100,
			'ident' => 55,
			'item' => 38
		}
	},
	{#State 33
		ACTIONS => {
			'' => 101
		}
	},
	{#State 34
		ACTIONS => {
			'GET' => 2,
			'UBLOCK' => 1,
			'INCLUDE' => 4,
			'TEXT' => 7,
			'DEFAULT' => 6,
			'BREAK' => 5,
			'STOP' => 8,
			'FOR' => 9,
			"[" => 13,
			'BLOCK' => 14,
			'SET' => 15,
			'USE' => 16,
			'MACRO' => 17,
			'UNLESS' => 20,
			'PROCESS' => 23,
			'RETURN' => 25,
			'CATCH' => 26,
			'FILTER' => 28,
			'DEBUG' => 30,
			";" => -16,
			"{" => 31,
			'ERROR' => 32,
			"\${" => 35,
			'LITERAL' => 36,
			'IF' => 39,
			"\"" => 40,
			"\$" => 42,
			'PERL' => 44,
			'IDENT' => 46,
			'UDIR' => 47,
			'THROW' => 48,
			'WHILE' => 50,
			'CALL' => 51,
			'REF' => 52
		},
		DEFAULT => -1,
		GOTOS => {
			'atomdir' => 41,
			'return' => 24,
			'macro' => 43,
			'perl' => 45,
			'catch' => 3,
			'ident' => 18,
			'assign' => 27,
			'filter' => 29,
			'condition' => 11,
			'debug' => 10,
			'term' => 49,
			'setlist' => 12,
			'chunk' => 102,
			'defblock' => 22,
			'loop' => 21,
			'userdef' => 37,
			'directive' => 53,
			'item' => 38
		}
	},
	{#State 35
		ACTIONS => {
			"\"" => 40,
			"{" => 31,
			"[" => 13,
			"\$" => 42,
			'IDENT' => 46,
			'REF' => 52,
			'LITERAL' => 56,
			"\${" => 35
		},
		GOTOS => {
			'term' => 103,
			'ident' => 55,
			'item' => 38
		}
	},
	{#State 36
		ACTIONS => {
			'ASSIGN' => 104
		},
		DEFAULT => -60
	},
	{#State 37
		DEFAULT => -14
	},
	{#State 38
		DEFAULT => -71
	},
	{#State 39
		ACTIONS => {
			"\"" => 40,
			'NOT' => 85,
			"\$" => 42,
			'IDENT' => 46,
			"(" => 88,
			"[" => 13,
			"{" => 31,
			'REF' => 52,
			"\${" => 35,
			'LITERAL' => 36
		},
		GOTOS => {
			'term' => 89,
			'ident' => 18,
			'assign' => 87,
			'item' => 38,
			'expr' => 105
		}
	},
	{#State 40
		DEFAULT => -125,
		GOTOS => {
			'quoted' => 106
		}
	},
	{#State 41
		ACTIONS => {
			'WHILE' => 111,
			'UNLESS' => 108,
			'FILTER' => 109,
			'IF' => 110,
			'FOR' => 107
		},
		DEFAULT => -7
	},
	{#State 42
		ACTIONS => {
			'IDENT' => 46,
			"\${" => 35
		},
		GOTOS => {
			'item' => 112
		}
	},
	{#State 43
		DEFAULT => -13
	},
	{#State 44
		ACTIONS => {
			";" => 113
		}
	},
	{#State 45
		DEFAULT => -12
	},
	{#State 46
		ACTIONS => {
			"(" => 114
		},
		DEFAULT => -76
	},
	{#State 47
		DEFAULT => -57
	},
	{#State 48
		ACTIONS => {
			'IDENT' => 64
		},
		GOTOS => {
			'textdot' => 115
		}
	},
	{#State 49
		ACTIONS => {
			'BINOP' => 116
		},
		DEFAULT => -28
	},
	{#State 50
		ACTIONS => {
			"\"" => 40,
			'NOT' => 85,
			"\$" => 42,
			'IDENT' => 46,
			"(" => 88,
			"[" => 13,
			"{" => 31,
			'REF' => 52,
			"\${" => 35,
			'LITERAL' => 36
		},
		GOTOS => {
			'term' => 89,
			'ident' => 18,
			'assign' => 87,
			'item' => 38,
			'expr' => 117
		}
	},
	{#State 51
		ACTIONS => {
			"\"" => 40,
			"{" => 31,
			"[" => 13,
			"\$" => 42,
			'IDENT' => 46,
			'REF' => 52,
			'LITERAL' => 56,
			"\${" => 35
		},
		GOTOS => {
			'term' => 118,
			'ident' => 55,
			'item' => 38
		}
	},
	{#State 52
		ACTIONS => {
			"\$" => 42,
			'IDENT' => 46,
			"\${" => 35
		},
		GOTOS => {
			'ident' => 119,
			'item' => 38
		}
	},
	{#State 53
		ACTIONS => {
			";" => 120
		}
	},
	{#State 54
		ACTIONS => {
			'GET' => 2,
			'UBLOCK' => 1,
			'INCLUDE' => 4,
			'TEXT' => 7,
			'DEFAULT' => 6,
			'BREAK' => 5,
			'STOP' => 8,
			'FOR' => 9,
			"[" => 13,
			'BLOCK' => 14,
			'SET' => 15,
			'USE' => 16,
			'MACRO' => 17,
			'UNLESS' => 20,
			'PROCESS' => 23,
			'RETURN' => 25,
			'CATCH' => 26,
			'FILTER' => 28,
			'DEBUG' => 30,
			";" => -16,
			"{" => 31,
			'ERROR' => 32,
			"\${" => 35,
			'LITERAL' => 36,
			'IF' => 39,
			"\"" => 40,
			"\$" => 42,
			'PERL' => 44,
			'IDENT' => 46,
			'UDIR' => 47,
			'THROW' => 48,
			'WHILE' => 50,
			'CALL' => 51,
			'REF' => 52
		},
		DEFAULT => -2,
		GOTOS => {
			'return' => 24,
			'catch' => 3,
			'assign' => 27,
			'filter' => 29,
			'condition' => 11,
			'debug' => 10,
			'setlist' => 12,
			'block' => 121,
			'chunks' => 34,
			'userdef' => 37,
			'item' => 38,
			'atomdir' => 41,
			'macro' => 43,
			'perl' => 45,
			'ident' => 18,
			'term' => 49,
			'chunk' => 19,
			'loop' => 21,
			'defblock' => 22,
			'directive' => 53
		}
	},
	{#State 55
		ACTIONS => {
			'DOT' => 83
		},
		DEFAULT => -61
	},
	{#State 56
		DEFAULT => -60
	},
	{#State 57
		ACTIONS => {
			'BINOP' => 116
		},
		DEFAULT => -17
	},
	{#State 58
		ACTIONS => {
			'DOT' => 122,
			"/" => 123
		},
		DEFAULT => -115
	},
	{#State 59
		ACTIONS => {
			'IDENT' => 64
		},
		GOTOS => {
			'textdot' => 124
		}
	},
	{#State 60
		ACTIONS => {
			"\$" => 42,
			'IDENT' => 46,
			'LITERAL' => 67,
			"\${" => 35
		},
		DEFAULT => -86,
		GOTOS => {
			'setlist' => 125,
			'ident' => 66,
			'assign' => 27,
			'setopt' => 126,
			'item' => 38
		}
	},
	{#State 61
		DEFAULT => -116
	},
	{#State 62
		DEFAULT => -125,
		GOTOS => {
			'quoted' => 127
		}
	},
	{#State 63
		ACTIONS => {
			"\$" => 42,
			'IDENT' => 46,
			"\${" => 35
		},
		GOTOS => {
			'ident' => 128,
			'item' => 38
		}
	},
	{#State 64
		DEFAULT => -119
	},
	{#State 65
		ACTIONS => {
			"\$" => 42,
			'IDENT' => 46,
			'LITERAL' => 67,
			"\${" => 35,
			'COMMA' => 72
		},
		DEFAULT => -20,
		GOTOS => {
			'ident' => 66,
			'assign' => 71,
			'item' => 38
		}
	},
	{#State 66
		ACTIONS => {
			'ASSIGN' => 84,
			'DOT' => 83
		}
	},
	{#State 67
		ACTIONS => {
			'ASSIGN' => 104
		}
	},
	{#State 68
		ACTIONS => {
			";" => 129
		}
	},
	{#State 69
		ACTIONS => {
			'ASSIGN' => 130,
			"(" => 114
		},
		DEFAULT => -76
	},
	{#State 70
		ACTIONS => {
			"\"" => 40,
			"\$" => 42,
			'IDENT' => 136,
			'BINOP' => 116,
			"[" => 13,
			"{" => 31,
			'REF' => 52,
			"\${" => 35,
			'LITERAL' => 133,
			'COMMA' => 134
		},
		DEFAULT => -101,
		GOTOS => {
			'term' => 137,
			'param' => 131,
			'arg' => 138,
			'ident' => 55,
			'args' => 135,
			'arglist' => 132,
			'item' => 38
		}
	},
	{#State 71
		DEFAULT => -82
	},
	{#State 72
		DEFAULT => -83
	},
	{#State 73
		ACTIONS => {
			"]" => 139
		}
	},
	{#State 74
		ACTIONS => {
			"\"" => 40,
			"\$" => 42,
			'IDENT' => 46,
			"[" => 13,
			"{" => 31,
			"]" => 140,
			'REF' => 52,
			"\${" => 35,
			'LITERAL' => 56,
			'COMMA' => 141
		},
		GOTOS => {
			'term' => 142,
			'ident' => 55,
			'item' => 38
		}
	},
	{#State 75
		ACTIONS => {
			'TO' => 143,
			'BINOP' => 116
		},
		DEFAULT => -81
	},
	{#State 76
		ACTIONS => {
			";" => 144,
			"/" => 123,
			'DOT' => 122
		}
	},
	{#State 77
		ACTIONS => {
			'GET' => 2,
			'UBLOCK' => 1,
			'INCLUDE' => 4,
			'TEXT' => 7,
			'DEFAULT' => 6,
			'BREAK' => 5,
			'STOP' => 8,
			'FOR' => 9,
			"[" => 13,
			'BLOCK' => 14,
			'SET' => 15,
			'USE' => 16,
			'MACRO' => 17,
			'UNLESS' => 20,
			'PROCESS' => 23,
			'RETURN' => 25,
			'CATCH' => 26,
			'FILTER' => 28,
			'DEBUG' => 30,
			";" => -16,
			"{" => 31,
			'ERROR' => 32,
			"\${" => 35,
			'LITERAL' => 36,
			'IF' => 39,
			"\"" => 40,
			"\$" => 42,
			'PERL' => 44,
			'IDENT' => 46,
			'UDIR' => 47,
			'THROW' => 48,
			'WHILE' => 50,
			'CALL' => 51,
			'REF' => 52
		},
		DEFAULT => -2,
		GOTOS => {
			'return' => 24,
			'catch' => 3,
			'assign' => 27,
			'filter' => 29,
			'condition' => 11,
			'debug' => 10,
			'setlist' => 12,
			'block' => 145,
			'chunks' => 34,
			'userdef' => 37,
			'item' => 38,
			'atomdir' => 41,
			'macro' => 43,
			'perl' => 45,
			'ident' => 18,
			'term' => 49,
			'chunk' => 19,
			'loop' => 21,
			'defblock' => 22,
			'directive' => 53
		}
	},
	{#State 78
		ACTIONS => {
			"\$" => 42,
			'IDENT' => 46,
			'LITERAL' => 67,
			"\${" => 35,
			'COMMA' => 72
		},
		DEFAULT => -19,
		GOTOS => {
			'ident' => 66,
			'assign' => 71,
			'item' => 38
		}
	},
	{#State 79
		ACTIONS => {
			"(" => 146,
			'DOT' => 122,
			"/" => 123
		},
		DEFAULT => -123
	},
	{#State 80
		DEFAULT => -21
	},
	{#State 81
		ACTIONS => {
			'ASSIGN' => 147
		},
		DEFAULT => -119
	},
	{#State 82
		ACTIONS => {
			'GET' => 2,
			'UBLOCK' => 1,
			'INCLUDE' => 4,
			'DEFAULT' => 6,
			'BREAK' => 5,
			'STOP' => 8,
			'FOR' => 9,
			"[" => 13,
			'BLOCK' => 14,
			'SET' => 15,
			'USE' => 16,
			'MACRO' => 17,
			'UNLESS' => 20,
			'PROCESS' => 23,
			'RETURN' => 25,
			'CATCH' => 26,
			'FILTER' => 28,
			'DEBUG' => 30,
			"{" => 31,
			'ERROR' => 32,
			"\${" => 35,
			'LITERAL' => 36,
			'IF' => 39,
			"\"" => 40,
			"\$" => 42,
			'PERL' => 44,
			'IDENT' => 46,
			'UDIR' => 47,
			'THROW' => 48,
			"(" => 148,
			'WHILE' => 50,
			'CALL' => 51,
			'REF' => 52
		},
		DEFAULT => -16,
		GOTOS => {
			'atomdir' => 41,
			'return' => 24,
			'macro' => 43,
			'perl' => 45,
			'catch' => 3,
			'ident' => 18,
			'assign' => 27,
			'filter' => 29,
			'condition' => 11,
			'debug' => 10,
			'term' => 49,
			'setlist' => 12,
			'defblock' => 22,
			'loop' => 21,
			'userdef' => 37,
			'directive' => 149,
			'item' => 38
		}
	},
	{#State 83
		ACTIONS => {
			'IDENT' => 46,
			'LITERAL' => 150,
			"\${" => 35
		},
		GOTOS => {
			'item' => 151
		}
	},
	{#State 84
		ACTIONS => {
			"\"" => 40,
			"{" => 31,
			"[" => 13,
			"\$" => 42,
			'IDENT' => 46,
			'REF' => 52,
			'LITERAL' => 56,
			"\${" => 35
		},
		GOTOS => {
			'term' => 152,
			'ident' => 55,
			'item' => 38
		}
	},
	{#State 85
		ACTIONS => {
			"\"" => 40,
			'NOT' => 85,
			"\$" => 42,
			'IDENT' => 46,
			"(" => 88,
			"[" => 13,
			"{" => 31,
			'REF' => 52,
			"\${" => 35,
			'LITERAL' => 36
		},
		GOTOS => {
			'term' => 89,
			'ident' => 18,
			'assign' => 87,
			'item' => 38,
			'expr' => 153
		}
	},
	{#State 86
		ACTIONS => {
			";" => 156,
			'OR' => 154,
			'AND' => 155,
			'COMPOP' => 157
		}
	},
	{#State 87
		DEFAULT => -110
	},
	{#State 88
		ACTIONS => {
			"\"" => 40,
			'NOT' => 85,
			"\$" => 42,
			'IDENT' => 46,
			"(" => 88,
			"[" => 13,
			"{" => 31,
			'REF' => 52,
			"\${" => 35,
			'LITERAL' => 36
		},
		GOTOS => {
			'term' => 89,
			'ident' => 18,
			'assign' => 87,
			'item' => 38,
			'expr' => 158
		}
	},
	{#State 89
		ACTIONS => {
			'BINOP' => 116
		},
		DEFAULT => -111
	},
	{#State 90
		ACTIONS => {
			"\$" => 42,
			'IDENT' => 46,
			'LITERAL' => 67,
			"\${" => 35
		},
		DEFAULT => -86,
		GOTOS => {
			'setlist' => 125,
			'ident' => 66,
			'assign' => 27,
			'setopt' => 159,
			'item' => 38
		}
	},
	{#State 91
		ACTIONS => {
			";" => 160,
			"/" => 123,
			'DOT' => 122
		}
	},
	{#State 92
		ACTIONS => {
			'GET' => 2,
			'UBLOCK' => 1,
			'INCLUDE' => 4,
			'TEXT' => 7,
			'DEFAULT' => 6,
			'BREAK' => 5,
			'STOP' => 8,
			'FOR' => 9,
			"[" => 13,
			'BLOCK' => 14,
			'SET' => 15,
			'USE' => 16,
			'MACRO' => 17,
			'UNLESS' => 20,
			'PROCESS' => 23,
			'RETURN' => 25,
			'CATCH' => 26,
			'FILTER' => 28,
			'DEBUG' => 30,
			";" => -16,
			"{" => 31,
			'ERROR' => 32,
			"\${" => 35,
			'LITERAL' => 36,
			'IF' => 39,
			"\"" => 40,
			"\$" => 42,
			'PERL' => 44,
			'IDENT' => 46,
			'UDIR' => 47,
			'THROW' => 48,
			'WHILE' => 50,
			'CALL' => 51,
			'REF' => 52
		},
		DEFAULT => -2,
		GOTOS => {
			'return' => 24,
			'catch' => 3,
			'assign' => 27,
			'filter' => 29,
			'condition' => 11,
			'debug' => 10,
			'setlist' => 12,
			'block' => 161,
			'chunks' => 34,
			'userdef' => 37,
			'item' => 38,
			'atomdir' => 41,
			'macro' => 43,
			'perl' => 45,
			'ident' => 18,
			'term' => 49,
			'chunk' => 19,
			'loop' => 21,
			'defblock' => 22,
			'directive' => 53
		}
	},
	{#State 93
		ACTIONS => {
			";" => 162
		}
	},
	{#State 94
		DEFAULT => -59
	},
	{#State 95
		DEFAULT => -92
	},
	{#State 96
		ACTIONS => {
			"}" => 163
		}
	},
	{#State 97
		ACTIONS => {
			'IDENT' => 99,
			'COMMA' => 165,
			'LITERAL' => 98
		},
		DEFAULT => -93,
		GOTOS => {
			'param' => 164
		}
	},
	{#State 98
		ACTIONS => {
			'ASSIGN' => 166
		}
	},
	{#State 99
		ACTIONS => {
			'ASSIGN' => 167
		}
	},
	{#State 100
		ACTIONS => {
			'BINOP' => 116
		},
		DEFAULT => -25
	},
	{#State 101
		DEFAULT => -0
	},
	{#State 102
		DEFAULT => -3
	},
	{#State 103
		ACTIONS => {
			'BINOP' => 116,
			"}" => 168
		}
	},
	{#State 104
		ACTIONS => {
			"\"" => 40,
			"{" => 31,
			"[" => 13,
			"\$" => 42,
			'IDENT' => 46,
			'REF' => 52,
			'LITERAL' => 56,
			"\${" => 35
		},
		GOTOS => {
			'term' => 169,
			'ident' => 55,
			'item' => 38
		}
	},
	{#State 105
		ACTIONS => {
			";" => 170,
			'OR' => 154,
			'AND' => 155,
			'COMPOP' => 157
		}
	},
	{#State 106
		ACTIONS => {
			"\"" => 174,
			";" => 173,
			"\$" => 42,
			'IDENT' => 46,
			"\${" => 35,
			'TEXT' => 171
		},
		GOTOS => {
			'ident' => 172,
			'quotable' => 175,
			'item' => 38
		}
	},
	{#State 107
		ACTIONS => {
			"\"" => 40,
			"{" => 31,
			"[" => 13,
			"\$" => 42,
			'IDENT' => 69,
			'REF' => 52,
			'LITERAL' => 56,
			"\${" => 35
		},
		GOTOS => {
			'term' => 70,
			'loopvar' => 176,
			'ident' => 55,
			'item' => 38
		}
	},
	{#State 108
		ACTIONS => {
			"\"" => 40,
			'NOT' => 85,
			"\$" => 42,
			'IDENT' => 46,
			"(" => 88,
			"[" => 13,
			"{" => 31,
			'REF' => 52,
			"\${" => 35,
			'LITERAL' => 36
		},
		GOTOS => {
			'term' => 89,
			'ident' => 18,
			'assign' => 87,
			'item' => 38,
			'expr' => 177
		}
	},
	{#State 109
		ACTIONS => {
			'IDENT' => 81
		},
		GOTOS => {
			'textdot' => 79,
			'useparam' => 178
		}
	},
	{#State 110
		ACTIONS => {
			"\"" => 40,
			'NOT' => 85,
			"\$" => 42,
			'IDENT' => 46,
			"(" => 88,
			"[" => 13,
			"{" => 31,
			'REF' => 52,
			"\${" => 35,
			'LITERAL' => 36
		},
		GOTOS => {
			'term' => 89,
			'ident' => 18,
			'assign' => 87,
			'item' => 38,
			'expr' => 179
		}
	},
	{#State 111
		ACTIONS => {
			"\"" => 40,
			'NOT' => 85,
			"\$" => 42,
			'IDENT' => 46,
			"(" => 88,
			"[" => 13,
			"{" => 31,
			'REF' => 52,
			"\${" => 35,
			'LITERAL' => 36
		},
		GOTOS => {
			'term' => 89,
			'ident' => 18,
			'assign' => 87,
			'item' => 38,
			'expr' => 180
		}
	},
	{#State 112
		DEFAULT => -72
	},
	{#State 113
		ACTIONS => {
			'GET' => 2,
			'UBLOCK' => 1,
			'INCLUDE' => 4,
			'TEXT' => 7,
			'DEFAULT' => 6,
			'BREAK' => 5,
			'STOP' => 8,
			'FOR' => 9,
			"[" => 13,
			'BLOCK' => 14,
			'SET' => 15,
			'USE' => 16,
			'MACRO' => 17,
			'UNLESS' => 20,
			'PROCESS' => 23,
			'RETURN' => 25,
			'CATCH' => 26,
			'FILTER' => 28,
			'DEBUG' => 30,
			";" => -16,
			"{" => 31,
			'ERROR' => 32,
			"\${" => 35,
			'LITERAL' => 36,
			'IF' => 39,
			"\"" => 40,
			"\$" => 42,
			'PERL' => 44,
			'IDENT' => 46,
			'UDIR' => 47,
			'THROW' => 48,
			'WHILE' => 50,
			'CALL' => 51,
			'REF' => 52
		},
		DEFAULT => -2,
		GOTOS => {
			'return' => 24,
			'catch' => 3,
			'assign' => 27,
			'filter' => 29,
			'condition' => 11,
			'debug' => 10,
			'setlist' => 12,
			'block' => 181,
			'chunks' => 34,
			'userdef' => 37,
			'item' => 38,
			'atomdir' => 41,
			'macro' => 43,
			'perl' => 45,
			'ident' => 18,
			'term' => 49,
			'chunk' => 19,
			'loop' => 21,
			'defblock' => 22,
			'directive' => 53
		}
	},
	{#State 114
		ACTIONS => {
			"\"" => 40,
			"\$" => 42,
			'IDENT' => 136,
			"[" => 13,
			"{" => 31,
			'REF' => 52,
			"\${" => 35,
			'LITERAL' => 133
		},
		DEFAULT => -101,
		GOTOS => {
			'term' => 137,
			'param' => 131,
			'arg' => 138,
			'ident' => 55,
			'args' => 182,
			'arglist' => 132,
			'item' => 38
		}
	},
	{#State 115
		ACTIONS => {
			"\"" => 40,
			"\$" => 42,
			'IDENT' => 46,
			'DOT' => 122,
			"[" => 13,
			"{" => 31,
			'REF' => 52,
			"/" => 123,
			"\${" => 35,
			'LITERAL' => 56
		},
		GOTOS => {
			'term' => 183,
			'ident' => 55,
			'item' => 38
		}
	},
	{#State 116
		ACTIONS => {
			"\"" => 40,
			"{" => 31,
			"[" => 13,
			"\$" => 42,
			'IDENT' => 46,
			'REF' => 52,
			'LITERAL' => 56,
			"\${" => 35
		},
		GOTOS => {
			'term' => 184,
			'ident' => 55,
			'item' => 38
		}
	},
	{#State 117
		ACTIONS => {
			";" => 185,
			'OR' => 154,
			'AND' => 155,
			'COMPOP' => 157
		}
	},
	{#State 118
		ACTIONS => {
			'BINOP' => 116
		},
		DEFAULT => -18
	},
	{#State 119
		ACTIONS => {
			'DOT' => 83
		},
		DEFAULT => -62
	},
	{#State 120
		DEFAULT => -6
	},
	{#State 121
		ACTIONS => {
			'END' => 186
		}
	},
	{#State 122
		ACTIONS => {
			'IDENT' => 187
		}
	},
	{#State 123
		ACTIONS => {
			'IDENT' => 188
		}
	},
	{#State 124
		ACTIONS => {
			'DOT' => 122,
			"/" => 123
		},
		DEFAULT => -114
	},
	{#State 125
		ACTIONS => {
			"\$" => 42,
			'IDENT' => 46,
			'LITERAL' => 67,
			"\${" => 35,
			'COMMA' => 72
		},
		DEFAULT => -85,
		GOTOS => {
			'ident' => 66,
			'assign' => 71,
			'item' => 38
		}
	},
	{#State 126
		DEFAULT => -22
	},
	{#State 127
		ACTIONS => {
			"\"" => 189,
			";" => 173,
			"\$" => 42,
			'IDENT' => 46,
			"\${" => 35,
			'TEXT' => 171
		},
		GOTOS => {
			'ident' => 172,
			'quotable' => 175,
			'item' => 38
		}
	},
	{#State 128
		ACTIONS => {
			'DOT' => 83
		},
		DEFAULT => -112
	},
	{#State 129
		ACTIONS => {
			'GET' => 2,
			'UBLOCK' => 1,
			'INCLUDE' => 4,
			'TEXT' => 7,
			'DEFAULT' => 6,
			'BREAK' => 5,
			'STOP' => 8,
			'FOR' => 9,
			"[" => 13,
			'BLOCK' => 14,
			'SET' => 15,
			'USE' => 16,
			'MACRO' => 17,
			'UNLESS' => 20,
			'PROCESS' => 23,
			'RETURN' => 25,
			'CATCH' => 26,
			'FILTER' => 28,
			'DEBUG' => 30,
			";" => -16,
			"{" => 31,
			'ERROR' => 32,
			"\${" => 35,
			'LITERAL' => 36,
			'IF' => 39,
			"\"" => 40,
			"\$" => 42,
			'PERL' => 44,
			'IDENT' => 46,
			'UDIR' => 47,
			'THROW' => 48,
			'WHILE' => 50,
			'CALL' => 51,
			'REF' => 52
		},
		DEFAULT => -2,
		GOTOS => {
			'return' => 24,
			'catch' => 3,
			'assign' => 27,
			'filter' => 29,
			'condition' => 11,
			'debug' => 10,
			'setlist' => 12,
			'block' => 190,
			'chunks' => 34,
			'userdef' => 37,
			'item' => 38,
			'atomdir' => 41,
			'macro' => 43,
			'perl' => 45,
			'ident' => 18,
			'term' => 49,
			'chunk' => 19,
			'loop' => 21,
			'defblock' => 22,
			'directive' => 53
		}
	},
	{#State 130
		ACTIONS => {
			"\"" => 40,
			"{" => 31,
			"[" => 13,
			"\$" => 42,
			'IDENT' => 46,
			'REF' => 52,
			'LITERAL' => 56,
			"\${" => 35
		},
		GOTOS => {
			'term' => 191,
			'ident' => 55,
			'item' => 38
		}
	},
	{#State 131
		DEFAULT => -95
	},
	{#State 132
		ACTIONS => {
			"\"" => 40,
			"\$" => 42,
			'IDENT' => 136,
			"[" => 13,
			"{" => 31,
			'REF' => 52,
			"\${" => 35,
			'LITERAL' => 133,
			'COMMA' => 192
		},
		DEFAULT => -100,
		GOTOS => {
			'term' => 137,
			'param' => 131,
			'arg' => 193,
			'ident' => 55,
			'item' => 38
		}
	},
	{#State 133
		ACTIONS => {
			'ASSIGN' => 166
		},
		DEFAULT => -60
	},
	{#State 134
		ACTIONS => {
			"\"" => 40,
			"\$" => 42,
			'IDENT' => 136,
			"[" => 13,
			"{" => 31,
			'REF' => 52,
			"\${" => 35,
			'LITERAL' => 133
		},
		DEFAULT => -101,
		GOTOS => {
			'term' => 137,
			'param' => 131,
			'arg' => 138,
			'ident' => 55,
			'args' => 194,
			'arglist' => 132,
			'item' => 38
		}
	},
	{#State 135
		DEFAULT => -48
	},
	{#State 136
		ACTIONS => {
			'ASSIGN' => 167,
			"(" => 114
		},
		DEFAULT => -76
	},
	{#State 137
		ACTIONS => {
			'BINOP' => 116
		},
		DEFAULT => -96
	},
	{#State 138
		DEFAULT => -99
	},
	{#State 139
		DEFAULT => -63
	},
	{#State 140
		ACTIONS => {
			"(" => 195
		},
		DEFAULT => -64
	},
	{#State 141
		DEFAULT => -80
	},
	{#State 142
		ACTIONS => {
			'BINOP' => 116
		},
		DEFAULT => -79
	},
	{#State 143
		ACTIONS => {
			"\"" => 40,
			"{" => 31,
			"[" => 13,
			"\$" => 42,
			'IDENT' => 46,
			'REF' => 52,
			'LITERAL' => 56,
			"\${" => 35
		},
		GOTOS => {
			'term' => 196,
			'ident' => 55,
			'item' => 38
		}
	},
	{#State 144
		ACTIONS => {
			'GET' => 2,
			'UBLOCK' => 1,
			'INCLUDE' => 4,
			'TEXT' => 7,
			'DEFAULT' => 6,
			'BREAK' => 5,
			'STOP' => 8,
			'FOR' => 9,
			"[" => 13,
			'BLOCK' => 14,
			'SET' => 15,
			'USE' => 16,
			'MACRO' => 17,
			'UNLESS' => 20,
			'PROCESS' => 23,
			'RETURN' => 25,
			'CATCH' => 26,
			'FILTER' => 28,
			'DEBUG' => 30,
			";" => -16,
			"{" => 31,
			'ERROR' => 32,
			"\${" => 35,
			'LITERAL' => 36,
			'IF' => 39,
			"\"" => 40,
			"\$" => 42,
			'PERL' => 44,
			'IDENT' => 46,
			'UDIR' => 47,
			'THROW' => 48,
			'WHILE' => 50,
			'CALL' => 51,
			'REF' => 52
		},
		DEFAULT => -2,
		GOTOS => {
			'return' => 24,
			'catch' => 3,
			'assign' => 27,
			'filter' => 29,
			'condition' => 11,
			'debug' => 10,
			'setlist' => 12,
			'block' => 197,
			'chunks' => 34,
			'userdef' => 37,
			'item' => 38,
			'atomdir' => 41,
			'macro' => 43,
			'perl' => 45,
			'ident' => 18,
			'term' => 49,
			'chunk' => 19,
			'loop' => 21,
			'defblock' => 22,
			'directive' => 53
		}
	},
	{#State 145
		ACTIONS => {
			'END' => 198
		}
	},
	{#State 146
		ACTIONS => {
			"\"" => 40,
			"\$" => 42,
			'IDENT' => 136,
			"[" => 13,
			"{" => 31,
			'REF' => 52,
			"\${" => 35,
			'LITERAL' => 133
		},
		DEFAULT => -101,
		GOTOS => {
			'term' => 137,
			'param' => 131,
			'arg' => 138,
			'ident' => 55,
			'args' => 199,
			'arglist' => 132,
			'item' => 38
		}
	},
	{#State 147
		ACTIONS => {
			'IDENT' => 64
		},
		GOTOS => {
			'textdot' => 200
		}
	},
	{#State 148
		ACTIONS => {
			'IDENT' => 202
		},
		GOTOS => {
			'mlist' => 201
		}
	},
	{#State 149
		DEFAULT => -55
	},
	{#State 150
		DEFAULT => -70
	},
	{#State 151
		DEFAULT => -69
	},
	{#State 152
		ACTIONS => {
			'BINOP' => 116
		},
		DEFAULT => -77
	},
	{#State 153
		ACTIONS => {
			'COMPOP' => 157
		},
		DEFAULT => -108
	},
	{#State 154
		ACTIONS => {
			"\"" => 40,
			'NOT' => 85,
			"\$" => 42,
			'IDENT' => 46,
			"(" => 88,
			"[" => 13,
			"{" => 31,
			'REF' => 52,
			"\${" => 35,
			'LITERAL' => 36
		},
		GOTOS => {
			'term' => 89,
			'ident' => 18,
			'assign' => 87,
			'item' => 38,
			'expr' => 203
		}
	},
	{#State 155
		ACTIONS => {
			"\"" => 40,
			'NOT' => 85,
			"\$" => 42,
			'IDENT' => 46,
			"(" => 88,
			"[" => 13,
			"{" => 31,
			'REF' => 52,
			"\${" => 35,
			'LITERAL' => 36
		},
		GOTOS => {
			'term' => 89,
			'ident' => 18,
			'assign' => 87,
			'item' => 38,
			'expr' => 204
		}
	},
	{#State 156
		ACTIONS => {
			'GET' => 2,
			'UBLOCK' => 1,
			'INCLUDE' => 4,
			'TEXT' => 7,
			'DEFAULT' => 6,
			'BREAK' => 5,
			'STOP' => 8,
			'FOR' => 9,
			"[" => 13,
			'BLOCK' => 14,
			'SET' => 15,
			'USE' => 16,
			'MACRO' => 17,
			'UNLESS' => 20,
			'PROCESS' => 23,
			'RETURN' => 25,
			'CATCH' => 26,
			'FILTER' => 28,
			'DEBUG' => 30,
			";" => -16,
			"{" => 31,
			'ERROR' => 32,
			"\${" => 35,
			'LITERAL' => 36,
			'IF' => 39,
			"\"" => 40,
			"\$" => 42,
			'PERL' => 44,
			'IDENT' => 46,
			'UDIR' => 47,
			'THROW' => 48,
			'WHILE' => 50,
			'CALL' => 51,
			'REF' => 52
		},
		DEFAULT => -2,
		GOTOS => {
			'return' => 24,
			'catch' => 3,
			'assign' => 27,
			'filter' => 29,
			'condition' => 11,
			'debug' => 10,
			'setlist' => 12,
			'block' => 205,
			'chunks' => 34,
			'userdef' => 37,
			'item' => 38,
			'atomdir' => 41,
			'macro' => 43,
			'perl' => 45,
			'ident' => 18,
			'term' => 49,
			'chunk' => 19,
			'loop' => 21,
			'defblock' => 22,
			'directive' => 53
		}
	},
	{#State 157
		ACTIONS => {
			"\"" => 40,
			'NOT' => 85,
			"\$" => 42,
			'IDENT' => 46,
			"(" => 88,
			"[" => 13,
			"{" => 31,
			'REF' => 52,
			"\${" => 35,
			'LITERAL' => 36
		},
		GOTOS => {
			'term' => 89,
			'ident' => 18,
			'assign' => 87,
			'item' => 38,
			'expr' => 206
		}
	},
	{#State 158
		ACTIONS => {
			'OR' => 154,
			'AND' => 155,
			'COMPOP' => 157,
			")" => 207
		}
	},
	{#State 159
		DEFAULT => -23
	},
	{#State 160
		ACTIONS => {
			'GET' => 2,
			'UBLOCK' => 1,
			'INCLUDE' => 4,
			'TEXT' => 7,
			'DEFAULT' => 6,
			'BREAK' => 5,
			'STOP' => 8,
			'FOR' => 9,
			"[" => 13,
			'BLOCK' => 14,
			'SET' => 15,
			'USE' => 16,
			'MACRO' => 17,
			'UNLESS' => 20,
			'PROCESS' => 23,
			'RETURN' => 25,
			'CATCH' => 26,
			'FILTER' => 28,
			'DEBUG' => 30,
			";" => -16,
			"{" => 31,
			'ERROR' => 32,
			"\${" => 35,
			'LITERAL' => 36,
			'IF' => 39,
			"\"" => 40,
			"\$" => 42,
			'PERL' => 44,
			'IDENT' => 46,
			'UDIR' => 47,
			'THROW' => 48,
			'WHILE' => 50,
			'CALL' => 51,
			'REF' => 52
		},
		DEFAULT => -2,
		GOTOS => {
			'return' => 24,
			'catch' => 3,
			'assign' => 27,
			'filter' => 29,
			'condition' => 11,
			'debug' => 10,
			'setlist' => 12,
			'block' => 208,
			'chunks' => 34,
			'userdef' => 37,
			'item' => 38,
			'atomdir' => 41,
			'macro' => 43,
			'perl' => 45,
			'ident' => 18,
			'term' => 49,
			'chunk' => 19,
			'loop' => 21,
			'defblock' => 22,
			'directive' => 53
		}
	},
	{#State 161
		ACTIONS => {
			'END' => 209
		}
	},
	{#State 162
		ACTIONS => {
			'GET' => 2,
			'UBLOCK' => 1,
			'INCLUDE' => 4,
			'TEXT' => 7,
			'DEFAULT' => 6,
			'BREAK' => 5,
			'STOP' => 8,
			'FOR' => 9,
			"[" => 13,
			'BLOCK' => 14,
			'SET' => 15,
			'USE' => 16,
			'MACRO' => 17,
			'UNLESS' => 20,
			'PROCESS' => 23,
			'RETURN' => 25,
			'CATCH' => 26,
			'FILTER' => 28,
			'DEBUG' => 30,
			";" => -16,
			"{" => 31,
			'ERROR' => 32,
			"\${" => 35,
			'LITERAL' => 36,
			'IF' => 39,
			"\"" => 40,
			"\$" => 42,
			'PERL' => 44,
			'IDENT' => 46,
			'UDIR' => 47,
			'THROW' => 48,
			'WHILE' => 50,
			'CALL' => 51,
			'REF' => 52
		},
		DEFAULT => -2,
		GOTOS => {
			'return' => 24,
			'catch' => 3,
			'assign' => 27,
			'filter' => 29,
			'condition' => 11,
			'debug' => 10,
			'setlist' => 12,
			'block' => 210,
			'chunks' => 34,
			'userdef' => 37,
			'item' => 38,
			'atomdir' => 41,
			'macro' => 43,
			'perl' => 45,
			'ident' => 18,
			'term' => 49,
			'chunk' => 19,
			'loop' => 21,
			'defblock' => 22,
			'directive' => 53
		}
	},
	{#State 163
		DEFAULT => -66
	},
	{#State 164
		DEFAULT => -90
	},
	{#State 165
		DEFAULT => -91
	},
	{#State 166
		ACTIONS => {
			"\"" => 40,
			"{" => 31,
			"[" => 13,
			"\$" => 42,
			'IDENT' => 46,
			'REF' => 52,
			'LITERAL' => 56,
			"\${" => 35
		},
		GOTOS => {
			'term' => 211,
			'ident' => 55,
			'item' => 38
		}
	},
	{#State 167
		ACTIONS => {
			"\"" => 40,
			"{" => 31,
			"[" => 13,
			"\$" => 42,
			'IDENT' => 46,
			'REF' => 52,
			'LITERAL' => 56,
			"\${" => 35
		},
		GOTOS => {
			'term' => 212,
			'ident' => 55,
			'item' => 38
		}
	},
	{#State 168
		ACTIONS => {
			"(" => 213
		},
		DEFAULT => -73
	},
	{#State 169
		ACTIONS => {
			'BINOP' => 116
		},
		DEFAULT => -78
	},
	{#State 170
		ACTIONS => {
			'GET' => 2,
			'UBLOCK' => 1,
			'INCLUDE' => 4,
			'TEXT' => 7,
			'DEFAULT' => 6,
			'BREAK' => 5,
			'STOP' => 8,
			'FOR' => 9,
			"[" => 13,
			'BLOCK' => 14,
			'SET' => 15,
			'USE' => 16,
			'MACRO' => 17,
			'UNLESS' => 20,
			'PROCESS' => 23,
			'RETURN' => 25,
			'CATCH' => 26,
			'FILTER' => 28,
			'DEBUG' => 30,
			";" => -16,
			"{" => 31,
			'ERROR' => 32,
			"\${" => 35,
			'LITERAL' => 36,
			'IF' => 39,
			"\"" => 40,
			"\$" => 42,
			'PERL' => 44,
			'IDENT' => 46,
			'UDIR' => 47,
			'THROW' => 48,
			'WHILE' => 50,
			'CALL' => 51,
			'REF' => 52
		},
		DEFAULT => -2,
		GOTOS => {
			'return' => 24,
			'catch' => 3,
			'assign' => 27,
			'filter' => 29,
			'condition' => 11,
			'debug' => 10,
			'setlist' => 12,
			'block' => 214,
			'chunks' => 34,
			'userdef' => 37,
			'item' => 38,
			'atomdir' => 41,
			'macro' => 43,
			'perl' => 45,
			'ident' => 18,
			'term' => 49,
			'chunk' => 19,
			'loop' => 21,
			'defblock' => 22,
			'directive' => 53
		}
	},
	{#State 171
		DEFAULT => -127
	},
	{#State 172
		ACTIONS => {
			'DOT' => 83
		},
		DEFAULT => -126
	},
	{#State 173
		DEFAULT => -128
	},
	{#State 174
		DEFAULT => -67
	},
	{#State 175
		DEFAULT => -124
	},
	{#State 176
		DEFAULT => -43
	},
	{#State 177
		ACTIONS => {
			'OR' => 154,
			'AND' => 155,
			'COMPOP' => 157
		},
		DEFAULT => -38
	},
	{#State 178
		DEFAULT => -51
	},
	{#State 179
		ACTIONS => {
			'OR' => 154,
			'AND' => 155,
			'COMPOP' => 157
		},
		DEFAULT => -36
	},
	{#State 180
		ACTIONS => {
			'OR' => 154,
			'AND' => 155,
			'COMPOP' => 157
		},
		DEFAULT => -45
	},
	{#State 181
		ACTIONS => {
			'END' => 215
		}
	},
	{#State 182
		ACTIONS => {
			")" => 216
		}
	},
	{#State 183
		ACTIONS => {
			'BINOP' => 116
		},
		DEFAULT => -24
	},
	{#State 184
		DEFAULT => -68
	},
	{#State 185
		ACTIONS => {
			'GET' => 2,
			'UBLOCK' => 1,
			'INCLUDE' => 4,
			'TEXT' => 7,
			'DEFAULT' => 6,
			'BREAK' => 5,
			'STOP' => 8,
			'FOR' => 9,
			"[" => 13,
			'BLOCK' => 14,
			'SET' => 15,
			'USE' => 16,
			'MACRO' => 17,
			'UNLESS' => 20,
			'PROCESS' => 23,
			'RETURN' => 25,
			'CATCH' => 26,
			'FILTER' => 28,
			'DEBUG' => 30,
			";" => -16,
			"{" => 31,
			'ERROR' => 32,
			"\${" => 35,
			'LITERAL' => 36,
			'IF' => 39,
			"\"" => 40,
			"\$" => 42,
			'PERL' => 44,
			'IDENT' => 46,
			'UDIR' => 47,
			'THROW' => 48,
			'WHILE' => 50,
			'CALL' => 51,
			'REF' => 52
		},
		DEFAULT => -2,
		GOTOS => {
			'return' => 24,
			'catch' => 3,
			'assign' => 27,
			'filter' => 29,
			'condition' => 11,
			'debug' => 10,
			'setlist' => 12,
			'block' => 217,
			'chunks' => 34,
			'userdef' => 37,
			'item' => 38,
			'atomdir' => 41,
			'macro' => 43,
			'perl' => 45,
			'ident' => 18,
			'term' => 49,
			'chunk' => 19,
			'loop' => 21,
			'defblock' => 22,
			'directive' => 53
		}
	},
	{#State 186
		DEFAULT => -58
	},
	{#State 187
		DEFAULT => -117
	},
	{#State 188
		DEFAULT => -118
	},
	{#State 189
		DEFAULT => -113
	},
	{#State 190
		ACTIONS => {
			'END' => 218
		}
	},
	{#State 191
		ACTIONS => {
			"\"" => 40,
			"\$" => 42,
			'IDENT' => 136,
			'BINOP' => 116,
			"[" => 13,
			"{" => 31,
			'REF' => 52,
			"\${" => 35,
			'LITERAL' => 133,
			'COMMA' => 219
		},
		DEFAULT => -101,
		GOTOS => {
			'term' => 137,
			'param' => 131,
			'arg' => 138,
			'ident' => 55,
			'args' => 220,
			'arglist' => 132,
			'item' => 38
		}
	},
	{#State 192
		DEFAULT => -98
	},
	{#State 193
		DEFAULT => -97
	},
	{#State 194
		DEFAULT => -49
	},
	{#State 195
		ACTIONS => {
			"\"" => 40,
			"\$" => 42,
			'IDENT' => 136,
			"[" => 13,
			"{" => 31,
			'REF' => 52,
			"\${" => 35,
			'LITERAL' => 133
		},
		DEFAULT => -101,
		GOTOS => {
			'term' => 137,
			'param' => 131,
			'arg' => 138,
			'ident' => 55,
			'args' => 221,
			'arglist' => 132,
			'item' => 38
		}
	},
	{#State 196
		ACTIONS => {
			'BINOP' => 116
		},
		DEFAULT => -87
	},
	{#State 197
		ACTIONS => {
			'END' => 222
		}
	},
	{#State 198
		DEFAULT => -53
	},
	{#State 199
		ACTIONS => {
			")" => 223
		}
	},
	{#State 200
		ACTIONS => {
			"(" => 224,
			'DOT' => 122,
			"/" => 123
		},
		DEFAULT => -121
	},
	{#State 201
		ACTIONS => {
			'IDENT' => 227,
			'COMMA' => 226,
			")" => 225
		}
	},
	{#State 202
		DEFAULT => -104
	},
	{#State 203
		ACTIONS => {
			'COMPOP' => 157
		},
		DEFAULT => -107
	},
	{#State 204
		ACTIONS => {
			'COMPOP' => 157
		},
		DEFAULT => -106
	},
	{#State 205
		ACTIONS => {
			'ELSE' => 229,
			'ELSIF' => 228
		},
		DEFAULT => -41,
		GOTOS => {
			'else' => 230
		}
	},
	{#State 206
		DEFAULT => -105
	},
	{#State 207
		DEFAULT => -109
	},
	{#State 208
		ACTIONS => {
			'END' => 231
		}
	},
	{#State 209
		DEFAULT => -34
	},
	{#State 210
		ACTIONS => {
			'END' => 232
		}
	},
	{#State 211
		ACTIONS => {
			'BINOP' => 116
		},
		DEFAULT => -88
	},
	{#State 212
		ACTIONS => {
			'BINOP' => 116
		},
		DEFAULT => -89
	},
	{#State 213
		ACTIONS => {
			"\"" => 40,
			"\$" => 42,
			'IDENT' => 136,
			"[" => 13,
			"{" => 31,
			'REF' => 52,
			"\${" => 35,
			'LITERAL' => 133
		},
		DEFAULT => -101,
		GOTOS => {
			'term' => 137,
			'param' => 131,
			'arg' => 138,
			'ident' => 55,
			'args' => 233,
			'arglist' => 132,
			'item' => 38
		}
	},
	{#State 214
		ACTIONS => {
			'ELSE' => 229,
			'ELSIF' => 228
		},
		DEFAULT => -41,
		GOTOS => {
			'else' => 234
		}
	},
	{#State 215
		DEFAULT => -54
	},
	{#State 216
		DEFAULT => -75
	},
	{#State 217
		ACTIONS => {
			'END' => 235
		}
	},
	{#State 218
		DEFAULT => -42
	},
	{#State 219
		ACTIONS => {
			"\"" => 40,
			"\$" => 42,
			'IDENT' => 136,
			"[" => 13,
			"{" => 31,
			'REF' => 52,
			"\${" => 35,
			'LITERAL' => 133
		},
		DEFAULT => -101,
		GOTOS => {
			'term' => 137,
			'param' => 131,
			'arg' => 138,
			'ident' => 55,
			'args' => 236,
			'arglist' => 132,
			'item' => 38
		}
	},
	{#State 220
		DEFAULT => -46
	},
	{#State 221
		ACTIONS => {
			")" => 237
		}
	},
	{#State 222
		DEFAULT => -52
	},
	{#State 223
		DEFAULT => -122
	},
	{#State 224
		ACTIONS => {
			"\"" => 40,
			"\$" => 42,
			'IDENT' => 136,
			"[" => 13,
			"{" => 31,
			'REF' => 52,
			"\${" => 35,
			'LITERAL' => 133
		},
		DEFAULT => -101,
		GOTOS => {
			'term' => 137,
			'param' => 131,
			'arg' => 138,
			'ident' => 55,
			'args' => 238,
			'arglist' => 132,
			'item' => 38
		}
	},
	{#State 225
		ACTIONS => {
			'GET' => 2,
			'UBLOCK' => 1,
			'INCLUDE' => 4,
			'DEFAULT' => 6,
			'BREAK' => 5,
			'STOP' => 8,
			'FOR' => 9,
			"[" => 13,
			'BLOCK' => 14,
			'SET' => 15,
			'USE' => 16,
			'MACRO' => 17,
			'UNLESS' => 20,
			'PROCESS' => 23,
			'RETURN' => 25,
			'CATCH' => 26,
			'FILTER' => 28,
			'DEBUG' => 30,
			"{" => 31,
			'ERROR' => 32,
			"\${" => 35,
			'LITERAL' => 36,
			'IF' => 39,
			"\"" => 40,
			"\$" => 42,
			'PERL' => 44,
			'IDENT' => 46,
			'UDIR' => 47,
			'THROW' => 48,
			'WHILE' => 50,
			'CALL' => 51,
			'REF' => 52
		},
		DEFAULT => -16,
		GOTOS => {
			'atomdir' => 41,
			'return' => 24,
			'macro' => 43,
			'perl' => 45,
			'catch' => 3,
			'ident' => 18,
			'assign' => 27,
			'filter' => 29,
			'condition' => 11,
			'debug' => 10,
			'term' => 49,
			'setlist' => 12,
			'defblock' => 22,
			'loop' => 21,
			'userdef' => 37,
			'directive' => 239,
			'item' => 38
		}
	},
	{#State 226
		DEFAULT => -103
	},
	{#State 227
		DEFAULT => -102
	},
	{#State 228
		ACTIONS => {
			"\"" => 40,
			'NOT' => 85,
			"\$" => 42,
			'IDENT' => 46,
			"(" => 88,
			"[" => 13,
			"{" => 31,
			'REF' => 52,
			"\${" => 35,
			'LITERAL' => 36
		},
		GOTOS => {
			'term' => 89,
			'ident' => 18,
			'assign' => 87,
			'item' => 38,
			'expr' => 240
		}
	},
	{#State 229
		ACTIONS => {
			";" => 241
		}
	},
	{#State 230
		ACTIONS => {
			'END' => 242
		}
	},
	{#State 231
		DEFAULT => -33
	},
	{#State 232
		DEFAULT => -50
	},
	{#State 233
		ACTIONS => {
			")" => 243
		}
	},
	{#State 234
		ACTIONS => {
			'END' => 244
		}
	},
	{#State 235
		DEFAULT => -44
	},
	{#State 236
		DEFAULT => -47
	},
	{#State 237
		DEFAULT => -65
	},
	{#State 238
		ACTIONS => {
			")" => 245
		}
	},
	{#State 239
		DEFAULT => -56
	},
	{#State 240
		ACTIONS => {
			";" => 246,
			'OR' => 154,
			'AND' => 155,
			'COMPOP' => 157
		}
	},
	{#State 241
		ACTIONS => {
			'GET' => 2,
			'UBLOCK' => 1,
			'INCLUDE' => 4,
			'TEXT' => 7,
			'DEFAULT' => 6,
			'BREAK' => 5,
			'STOP' => 8,
			'FOR' => 9,
			"[" => 13,
			'BLOCK' => 14,
			'SET' => 15,
			'USE' => 16,
			'MACRO' => 17,
			'UNLESS' => 20,
			'PROCESS' => 23,
			'RETURN' => 25,
			'CATCH' => 26,
			'FILTER' => 28,
			'DEBUG' => 30,
			";" => -16,
			"{" => 31,
			'ERROR' => 32,
			"\${" => 35,
			'LITERAL' => 36,
			'IF' => 39,
			"\"" => 40,
			"\$" => 42,
			'PERL' => 44,
			'IDENT' => 46,
			'UDIR' => 47,
			'THROW' => 48,
			'WHILE' => 50,
			'CALL' => 51,
			'REF' => 52
		},
		DEFAULT => -2,
		GOTOS => {
			'return' => 24,
			'catch' => 3,
			'assign' => 27,
			'filter' => 29,
			'condition' => 11,
			'debug' => 10,
			'setlist' => 12,
			'block' => 247,
			'chunks' => 34,
			'userdef' => 37,
			'item' => 38,
			'atomdir' => 41,
			'macro' => 43,
			'perl' => 45,
			'ident' => 18,
			'term' => 49,
			'chunk' => 19,
			'loop' => 21,
			'defblock' => 22,
			'directive' => 53
		}
	},
	{#State 242
		DEFAULT => -37
	},
	{#State 243
		DEFAULT => -74
	},
	{#State 244
		DEFAULT => -35
	},
	{#State 245
		DEFAULT => -120
	},
	{#State 246
		ACTIONS => {
			'GET' => 2,
			'UBLOCK' => 1,
			'INCLUDE' => 4,
			'TEXT' => 7,
			'DEFAULT' => 6,
			'BREAK' => 5,
			'STOP' => 8,
			'FOR' => 9,
			"[" => 13,
			'BLOCK' => 14,
			'SET' => 15,
			'USE' => 16,
			'MACRO' => 17,
			'UNLESS' => 20,
			'PROCESS' => 23,
			'RETURN' => 25,
			'CATCH' => 26,
			'FILTER' => 28,
			'DEBUG' => 30,
			";" => -16,
			"{" => 31,
			'ERROR' => 32,
			"\${" => 35,
			'LITERAL' => 36,
			'IF' => 39,
			"\"" => 40,
			"\$" => 42,
			'PERL' => 44,
			'IDENT' => 46,
			'UDIR' => 47,
			'THROW' => 48,
			'WHILE' => 50,
			'CALL' => 51,
			'REF' => 52
		},
		DEFAULT => -2,
		GOTOS => {
			'return' => 24,
			'catch' => 3,
			'assign' => 27,
			'filter' => 29,
			'condition' => 11,
			'debug' => 10,
			'setlist' => 12,
			'block' => 248,
			'chunks' => 34,
			'userdef' => 37,
			'item' => 38,
			'atomdir' => 41,
			'macro' => 43,
			'perl' => 45,
			'ident' => 18,
			'term' => 49,
			'chunk' => 19,
			'loop' => 21,
			'defblock' => 22,
			'directive' => 53
		}
	},
	{#State 247
		DEFAULT => -39
	},
	{#State 248
		ACTIONS => {
			'ELSE' => 229,
			'ELSIF' => 228
		},
		DEFAULT => -41,
		GOTOS => {
			'else' => 249
		}
	},
	{#State 249
		DEFAULT => -40
	}
]; 


#========================================================================
# Rules
#========================================================================

$RULES = [
	[#Rule 0
		 '$start', 2, undef
	],
	[#Rule 1
		 'block', 1,
sub
#line 16 "Parser.yp"
{ $factory->create(Block => $_[1])      }
	],
	[#Rule 2
		 'block', 0,
sub
#line 17 "Parser.yp"
{ $factory->create(Block => [])         }
	],
	[#Rule 3
		 'chunks', 2,
sub
#line 20 "Parser.yp"
{ push(@{$_[1]}, $_[2]) if defined $_[2];
				   $_[1]                                }
	],
	[#Rule 4
		 'chunks', 1,
sub
#line 22 "Parser.yp"
{ defined $_[1] ? [ $_[1] ] : [ ]       }
	],
	[#Rule 5
		 'chunk', 1,
sub
#line 25 "Parser.yp"
{ $factory->create(Text => $_[1])       }
	],
	[#Rule 6
		 'chunk', 2, undef
	],
	[#Rule 7
		 'directive', 1, undef
	],
	[#Rule 8
		 'directive', 1, undef
	],
	[#Rule 9
		 'directive', 1, undef
	],
	[#Rule 10
		 'directive', 1, undef
	],
	[#Rule 11
		 'directive', 1, undef
	],
	[#Rule 12
		 'directive', 1, undef
	],
	[#Rule 13
		 'directive', 1, undef
	],
	[#Rule 14
		 'directive', 1, undef
	],
	[#Rule 15
		 'directive', 1, undef
	],
	[#Rule 16
		 'directive', 0, undef
	],
	[#Rule 17
		 'atomdir', 2,
sub
#line 46 "Parser.yp"
{ $factory->create(Get     => $_[2])    }
	],
	[#Rule 18
		 'atomdir', 2,
sub
#line 47 "Parser.yp"
{ $factory->create(Call    => $_[2])    }
	],
	[#Rule 19
		 'atomdir', 2,
sub
#line 48 "Parser.yp"
{ $factory->create(Set     => $_[2])    }
	],
	[#Rule 20
		 'atomdir', 2,
sub
#line 49 "Parser.yp"
{ unshift(@{$_[2]}, OP_DEFAULT);
				  $factory->create(Set     => $_[2])    }
	],
	[#Rule 21
		 'atomdir', 2,
sub
#line 51 "Parser.yp"
{ $factory->create(Use     => @{$_[2]}) }
	],
	[#Rule 22
		 'atomdir', 3,
sub
#line 52 "Parser.yp"
{ $factory->create(Include => @_[2,3])  }
	],
	[#Rule 23
		 'atomdir', 3,
sub
#line 53 "Parser.yp"
{ $factory->create(Process => @_[2,3])  }
	],
	[#Rule 24
		 'atomdir', 3,
sub
#line 54 "Parser.yp"
{ $factory->create(Throw   => @_[2,3])  }
	],
	[#Rule 25
		 'atomdir', 2,
sub
#line 55 "Parser.yp"
{ $factory->create(Error   => $_[2])    }
	],
	[#Rule 26
		 'atomdir', 1,
sub
#line 56 "Parser.yp"
{ $factory->create(Return  => $_[1])    }
	],
	[#Rule 27
		 'atomdir', 1,
sub
#line 57 "Parser.yp"
{ $factory->create(Set     => $_[1])    }
	],
	[#Rule 28
		 'atomdir', 1,
sub
#line 58 "Parser.yp"
{ $factory->create(Get     => $_[1])    }
	],
	[#Rule 29
		 'atomdir', 1, undef
	],
	[#Rule 30
		 'return', 1,
sub
#line 62 "Parser.yp"
{ STATUS_RETURN }
	],
	[#Rule 31
		 'return', 1,
sub
#line 63 "Parser.yp"
{ STATUS_STOP   }
	],
	[#Rule 32
		 'return', 1,
sub
#line 64 "Parser.yp"
{ STATUS_DONE   }
	],
	[#Rule 33
		 'catch', 5,
sub
#line 68 "Parser.yp"
{ $factory->create(Catch =>, @_[2, 4])    }
	],
	[#Rule 34
		 'catch', 4,
sub
#line 70 "Parser.yp"
{ $factory->create(Catch => undef, $_[3]) }
	],
	[#Rule 35
		 'condition', 6,
sub
#line 74 "Parser.yp"
{ $factory->create(If => @_[2, 4, 5])   }
	],
	[#Rule 36
		 'condition', 3,
sub
#line 75 "Parser.yp"
{ $factory->create(If => @_[3, 1])      }
	],
	[#Rule 37
		 'condition', 6,
sub
#line 77 "Parser.yp"
{ push(@{$_[2]}, OP_NOT);
				  $factory->create(If => @_[2, 4, 5])   }
	],
	[#Rule 38
		 'condition', 3,
sub
#line 79 "Parser.yp"
{ push(@{$_[3]}, OP_NOT);
				  $factory->create(If => @_[3, 1])      }
	],
	[#Rule 39
		 'else', 3,
sub
#line 83 "Parser.yp"
{ $_[3]                                 }
	],
	[#Rule 40
		 'else', 5,
sub
#line 85 "Parser.yp"
{ $factory->create(If => @_[2, 4, 5])   }
	],
	[#Rule 41
		 'else', 0, undef
	],
	[#Rule 42
		 'loop', 5,
sub
#line 90 "Parser.yp"
{ $factory->create(For => @{$_[2]}, $_[4]) }
	],
	[#Rule 43
		 'loop', 3,
sub
#line 91 "Parser.yp"
{ $factory->create(For => @{$_[3]}, $_[1]) }
	],
	[#Rule 44
		 'loop', 5,
sub
#line 93 "Parser.yp"
{ $factory->create(While  => @_[2, 4])   }
	],
	[#Rule 45
		 'loop', 3,
sub
#line 94 "Parser.yp"
{ $factory->create(While  => @_[3, 1])   }
	],
	[#Rule 46
		 'loopvar', 4,
sub
#line 98 "Parser.yp"
{ [ @_[1, 3, 4] ]     }
	],
	[#Rule 47
		 'loopvar', 5,
sub
#line 100 "Parser.yp"
{ [ @_[1, 3, 5] ]     }
	],
	[#Rule 48
		 'loopvar', 2,
sub
#line 101 "Parser.yp"
{ [ undef, @_[1, 2] ] }
	],
	[#Rule 49
		 'loopvar', 3,
sub
#line 102 "Parser.yp"
{ [ undef, @_[1, 3] ] }
	],
	[#Rule 50
		 'filter', 5,
sub
#line 106 "Parser.yp"
{ $factory->create(Filter => @{$_[2]}, $_[4]) }
	],
	[#Rule 51
		 'filter', 3,
sub
#line 108 "Parser.yp"
{ $factory->create(Filter => @{$_[3]}, $_[1]) }
	],
	[#Rule 52
		 'defblock', 5,
sub
#line 112 "Parser.yp"
{ $_[0]->define_block(@_[2, 4]); undef  }
	],
	[#Rule 53
		 'defblock', 4,
sub
#line 114 "Parser.yp"
{ $_[3] }
	],
	[#Rule 54
		 'perl', 4,
sub
#line 118 "Parser.yp"
{ $factory->create(Perl  => $_[3]) }
	],
	[#Rule 55
		 'macro', 3,
sub
#line 122 "Parser.yp"
{ $factory->create(Macro => @_[2, 3])    }
	],
	[#Rule 56
		 'macro', 6,
sub
#line 124 "Parser.yp"
{ $factory->create(Macro => @_[2, 6, 4]) }
	],
	[#Rule 57
		 'userdef', 1,
sub
#line 127 "Parser.yp"
{ $factory->create(Userdef => $_[1])     }
	],
	[#Rule 58
		 'userdef', 4,
sub
#line 129 "Parser.yp"
{ $factory->create(Userdef => @_[1, 3])  }
	],
	[#Rule 59
		 'debug', 2,
sub
#line 132 "Parser.yp"
{ $factory->create(Debug => $_[2])       }
	],
	[#Rule 60
		 'term', 1,
sub
#line 140 "Parser.yp"
{ [ OP_LITERAL, $_[1]    ] }
	],
	[#Rule 61
		 'term', 1,
sub
#line 141 "Parser.yp"
{ [ OP_IDENT,   $_[1]    ] }
	],
	[#Rule 62
		 'term', 2,
sub
#line 142 "Parser.yp"
{ [ OP_REF,     $_[2]    ] }
	],
	[#Rule 63
		 'term', 3,
sub
#line 143 "Parser.yp"
{ [ OP_RANGE,   $_[2]    ] }
	],
	[#Rule 64
		 'term', 3,
sub
#line 144 "Parser.yp"
{ [ OP_LIST,    $_[2]    ] }
	],
	[#Rule 65
		 'term', 6,
sub
#line 145 "Parser.yp"
{ [ OP_ITER,    @_[2, 5] ] }
	],
	[#Rule 66
		 'term', 3,
sub
#line 146 "Parser.yp"
{ [ OP_HASH,    $_[2]    ] }
	],
	[#Rule 67
		 'term', 3,
sub
#line 147 "Parser.yp"
{ [ OP_QUOTE,   $_[2]    ] }
	],
	[#Rule 68
		 'term', 3,
sub
#line 148 "Parser.yp"
{ push(@{$_[1]}, @{$_[3]}, 
						OP_BINOP, $_[2]); $_[1]  }
	],
	[#Rule 69
		 'ident', 3,
sub
#line 153 "Parser.yp"
{ push(@{$_[1]}, $_[3]); $_[1] }
	],
	[#Rule 70
		 'ident', 3,
sub
#line 154 "Parser.yp"
{ push(@{$_[1]}, [ $_[3], 0 ]); $_[1] }
	],
	[#Rule 71
		 'ident', 1,
sub
#line 155 "Parser.yp"
{ [ $_[1] ] }
	],
	[#Rule 72
		 'ident', 2,
sub
#line 156 "Parser.yp"
{ [ $_[2] ] }
	],
	[#Rule 73
		 'item', 3,
sub
#line 159 "Parser.yp"
{ [ $_[2], 0 ] }
	],
	[#Rule 74
		 'item', 6,
sub
#line 160 "Parser.yp"
{ [ @_[2, 5] ] }
	],
	[#Rule 75
		 'item', 4,
sub
#line 161 "Parser.yp"
{ [ @_[1, 3] ] }
	],
	[#Rule 76
		 'item', 1,
sub
#line 162 "Parser.yp"
{ [ $_[1], 0 ] }
	],
	[#Rule 77
		 'assign', 3,
sub
#line 165 "Parser.yp"
{ push(@{$_[3]}, OP_ASSIGN, $_[1]);
					  $_[3] }
	],
	[#Rule 78
		 'assign', 3,
sub
#line 167 "Parser.yp"
{ push(@{$_[3]}, OP_ASSIGN, $_[1]);
					  $_[3] }
	],
	[#Rule 79
		 'list', 2,
sub
#line 171 "Parser.yp"
{ push(@{$_[1]}, $_[2]); $_[1] }
	],
	[#Rule 80
		 'list', 2,
sub
#line 172 "Parser.yp"
{ $_[1] }
	],
	[#Rule 81
		 'list', 1,
sub
#line 173 "Parser.yp"
{ [ $_[1] ] }
	],
	[#Rule 82
		 'setlist', 2,
sub
#line 176 "Parser.yp"
{ push(@{$_[1]}, @{$_[2]}); $_[1] }
	],
	[#Rule 83
		 'setlist', 2,
sub
#line 177 "Parser.yp"
{ $_[1] }
	],
	[#Rule 84
		 'setlist', 1, undef
	],
	[#Rule 85
		 'setopt', 1, undef
	],
	[#Rule 86
		 'setopt', 0,
sub
#line 182 "Parser.yp"
{ [ ] }
	],
	[#Rule 87
		 'range', 3,
sub
#line 185 "Parser.yp"
{ [ @_[1, 3] ] }
	],
	[#Rule 88
		 'param', 3,
sub
#line 190 "Parser.yp"
{ [ $_[1], $_[3] ] }
	],
	[#Rule 89
		 'param', 3,
sub
#line 191 "Parser.yp"
{ [ $_[1], $_[3] ] }
	],
	[#Rule 90
		 'paramlist', 2,
sub
#line 194 "Parser.yp"
{ push(@{$_[1]}, $_[2]); $_[1] }
	],
	[#Rule 91
		 'paramlist', 2,
sub
#line 195 "Parser.yp"
{ $_[1] }
	],
	[#Rule 92
		 'paramlist', 1,
sub
#line 196 "Parser.yp"
{ [ $_[1] ] }
	],
	[#Rule 93
		 'params', 1, undef
	],
	[#Rule 94
		 'params', 0,
sub
#line 200 "Parser.yp"
{ [ ] }
	],
	[#Rule 95
		 'arg', 1, undef
	],
	[#Rule 96
		 'arg', 1,
sub
#line 204 "Parser.yp"
{ [ 0, $_[1] ] }
	],
	[#Rule 97
		 'arglist', 2,
sub
#line 207 "Parser.yp"
{ push(@{$_[1]}, $_[2]); $_[1] }
	],
	[#Rule 98
		 'arglist', 2,
sub
#line 208 "Parser.yp"
{ $_[1] }
	],
	[#Rule 99
		 'arglist', 1,
sub
#line 209 "Parser.yp"
{ [ $_[1] ] }
	],
	[#Rule 100
		 'args', 1,
sub
#line 212 "Parser.yp"
{ [ OP_ARGS, $_[1] ]  }
	],
	[#Rule 101
		 'args', 0,
sub
#line 213 "Parser.yp"
{ [ OP_ARGS, [ ] ] }
	],
	[#Rule 102
		 'mlist', 2,
sub
#line 217 "Parser.yp"
{ push(@{$_[1]}, $_[2]); $_[1] }
	],
	[#Rule 103
		 'mlist', 2,
sub
#line 218 "Parser.yp"
{ $_[1] }
	],
	[#Rule 104
		 'mlist', 1,
sub
#line 219 "Parser.yp"
{ [ $_[1] ] }
	],
	[#Rule 105
		 'expr', 3,
sub
#line 222 "Parser.yp"
{ push(@{$_[1]}, @{$_[3]}, 
						OP_BINOP, $_[2]); $_[1]  }
	],
	[#Rule 106
		 'expr', 3,
sub
#line 224 "Parser.yp"
{ push(@{$_[1]}, OP_AND, $_[3]); 
					  $_[1]                          }
	],
	[#Rule 107
		 'expr', 3,
sub
#line 226 "Parser.yp"
{ push(@{$_[1]}, OP_OR, $_[3]);
					  $_[1]                          }
	],
	[#Rule 108
		 'expr', 2,
sub
#line 228 "Parser.yp"
{ push(@{$_[2]}, OP_NOT);
					  $_[2]                          }
	],
	[#Rule 109
		 'expr', 3,
sub
#line 230 "Parser.yp"
{ $_[2]                          }
	],
	[#Rule 110
		 'expr', 1, undef
	],
	[#Rule 111
		 'expr', 1, undef
	],
	[#Rule 112
		 'file', 2,
sub
#line 240 "Parser.yp"
{ [ OP_IDENT, $_[2] ] }
	],
	[#Rule 113
		 'file', 3,
sub
#line 241 "Parser.yp"
{ [ OP_QUOTE, $_[2] ] }
	],
	[#Rule 114
		 'file', 2,
sub
#line 242 "Parser.yp"
{ '/' . $_[2]         }
	],
	[#Rule 115
		 'file', 1, undef
	],
	[#Rule 116
		 'file', 1, undef
	],
	[#Rule 117
		 'textdot', 3,
sub
#line 249 "Parser.yp"
{ $_[1] .= "$_[2]$_[3]"; $_[1] }
	],
	[#Rule 118
		 'textdot', 3,
sub
#line 250 "Parser.yp"
{ $_[1] .= "$_[2]$_[3]"; $_[1] }
	],
	[#Rule 119
		 'textdot', 1, undef
	],
	[#Rule 120
		 'useparam', 6,
sub
#line 256 "Parser.yp"
{ [ @_[3, 5, 1]         ] }
	],
	[#Rule 121
		 'useparam', 3,
sub
#line 257 "Parser.yp"
{ [ $_[3], undef, $_[1] ] }
	],
	[#Rule 122
		 'useparam', 4,
sub
#line 258 "Parser.yp"
{ [ $_[1], $_[3], undef ] }
	],
	[#Rule 123
		 'useparam', 1,
sub
#line 259 "Parser.yp"
{ [ $_[1], undef, undef ] }
	],
	[#Rule 124
		 'quoted', 2,
sub
#line 265 "Parser.yp"
{ push(@{$_[1]}, $_[2])
						if defined $_[2]; $_[1] }
	],
	[#Rule 125
		 'quoted', 0,
sub
#line 267 "Parser.yp"
{ [ ] }
	],
	[#Rule 126
		 'quotable', 1,
sub
#line 273 "Parser.yp"
{ [ OP_IDENT,   $_[1] ] }
	],
	[#Rule 127
		 'quotable', 1,
sub
#line 274 "Parser.yp"
{ [ OP_LITERAL, $_[1] ] }
	],
	[#Rule 128
		 'quotable', 1,
sub
#line 275 "Parser.yp"
{ undef }
	]
];



1;












