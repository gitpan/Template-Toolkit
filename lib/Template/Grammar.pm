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
# $Id: Grammar.pm,v 1.23 1999/08/10 11:09:07 abw Exp $
#
#========================================================================

package Template::Grammar;

require 5.004;

use strict;
use vars qw( $VERSION );

use Template::Constants qw( :ops );

$VERSION = sprintf("%d.%02d", q$Revision: 1.23 $ =~ /(\d+)\.(\d+)/);

my (@RESERVED, $LEXTABLE, $RULES, $STATES);


sub new {
    my $class = shift;
    bless {
	LEXTABLE => $LEXTABLE,
	STATES   => $STATES,
	RULES    => $RULES,
    };
}



#========================================================================
# Reserved Words
#========================================================================

@RESERVED = qw( 
	GET SET DEFAULT IMPORT INCLUDE PROCESS 
	IF UNLESS ELSE ELSIF FOR WHILE USE FILTER 
	THROW CATCH ERROR RETURN STOP BREAK 
	BLOCK END AND OR NOT
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
    '.'       => 'DOT',
    '..'      => 'TO',
    ';'       => 'SEPARATOR',
    '='       => 'ASSIGN',
    '=>'      => 'ASSIGN',
#    '/'      => 'END',
    ','       => 'COMMA',
    'and'     => 'AND',		# explicitly specified so that qw( and or
    'or'      => 'OR',		# not ) can always be used in lower case, 
    'not'     => 'NOT'		# regardless of CASE sensitivity flag
};

# localise the temporary variables needed to complete lexer table
{ 
    my @tokens   = qw< ( ) [ ] { } ${ $ / >;
    my @compop   = qw( == != < <= > >= );

    # fill lexer table, slice by slice, with reserved words and operators
    @$LEXTABLE{ @RESERVED, @compop, @tokens } 
	= ( @RESERVED, ('COMPOP') x @compop, @tokens );
}


#========================================================================
# States
#========================================================================

$STATES = [
	{#State 0
		ACTIONS => {
			'RETURN' => 29,
			'GET' => 1,
			'CATCH' => 30,
			'INCLUDE' => 3,
			'TEXT' => 6,
			'DEFAULT' => 5,
			'BREAK' => 4,
			'FILTER' => 34,
			'STOP' => 8,
			'DEBUG' => 36,
			'FOR' => 9,
			"{" => 37,
			"[" => 13,
			'ERROR' => 38,
			'BLOCK' => 16,
			'SET' => 17,
			'LITERAL' => 43,
			"\${" => 42,
			'USE' => 18,
			'IF' => 45,
			"\"" => 46,
			'SEPARATOR' => -15,
			"\$" => 48,
			'THROW' => 50,
			'IDENT' => 49,
			'WHILE' => 52,
			'UNLESS' => 23,
			'IMPORT' => 53,
			'PROCESS' => 26
		},
		DEFAULT => -2,
		GOTOS => {
			'return' => 28,
			'get' => 27,
			'catch' => 2,
			'include' => 31,
			'assign' => 32,
			'text' => 7,
			'filter' => 35,
			'node' => 33,
			'debug' => 11,
			'condition' => 10,
			'setlist' => 12,
			'lvalue' => 14,
			'error' => 15,
			'block' => 39,
			'set' => 41,
			'chunks' => 40,
			'use' => 44,
			'atomdir' => 47,
			'nparams' => 19,
			'ident' => 20,
			'throw' => 21,
			'term' => 51,
			'chunk' => 22,
			'loop' => 24,
			'defblock' => 25,
			'directive' => 54
		}
	},
	{#State 1
		ACTIONS => {
			"\"" => 46,
			"{" => 37,
			"[" => 13,
			"\$" => 57,
			'IDENT' => 49,
			"\${" => 42,
			'LITERAL' => 56
		},
		GOTOS => {
			'term' => 58,
			'ident' => 55,
			'node' => 33
		}
	},
	{#State 2
		DEFAULT => -9
	},
	{#State 3
		ACTIONS => {
			"\"" => 62,
			"\$" => 63,
			'IDENT' => 64,
			'LITERAL' => 61
		},
		GOTOS => {
			'incparam' => 59,
			'textdot' => 60
		}
	},
	{#State 4
		DEFAULT => -39
	},
	{#State 5
		ACTIONS => {
			"\$" => 68,
			'IMPORT' => 69,
			'IDENT' => 49,
			'LITERAL' => 67,
			"\${" => 42
		},
		GOTOS => {
			'setlist' => 65,
			'lvalue' => 14,
			'nparams' => 19,
			'ident' => 66,
			'assign' => 32,
			'node' => 33
		}
	},
	{#State 6
		DEFAULT => -22
	},
	{#State 7
		DEFAULT => -5
	},
	{#State 8
		DEFAULT => -38
	},
	{#State 9
		ACTIONS => {
			"\"" => 46,
			"{" => 37,
			"[" => 13,
			"\$" => 57,
			'IDENT' => 70,
			"\${" => 42,
			'LITERAL' => 56
		},
		GOTOS => {
			'term' => 71,
			'ident' => 55,
			'node' => 33
		}
	},
	{#State 10
		DEFAULT => -11
	},
	{#State 11
		DEFAULT => -10
	},
	{#State 12
		DEFAULT => -28
	},
	{#State 13
		DEFAULT => -85,
		GOTOS => {
			'list' => 72
		}
	},
	{#State 14
		ACTIONS => {
			'ASSIGN' => 73
		}
	},
	{#State 15
		DEFAULT => -20
	},
	{#State 16
		ACTIONS => {
			'IDENT' => 64
		},
		GOTOS => {
			'textdot' => 74
		}
	},
	{#State 17
		ACTIONS => {
			"\$" => 68,
			'IMPORT' => 69,
			'IDENT' => 49,
			'LITERAL' => 67,
			"\${" => 42
		},
		GOTOS => {
			'setlist' => 75,
			'lvalue' => 14,
			'nparams' => 19,
			'ident' => 66,
			'assign' => 32,
			'node' => 33
		}
	},
	{#State 18
		ACTIONS => {
			'IDENT' => 78
		},
		GOTOS => {
			'textdot' => 76,
			'useparam' => 77
		}
	},
	{#State 19
		ACTIONS => {
			"\$" => 68,
			'IDENT' => 49,
			'IMPORT' => 69,
			"\${" => 42,
			'LITERAL' => 67,
			'COMMA' => 80
		},
		DEFAULT => -91,
		GOTOS => {
			'lvalue' => 14,
			'ident' => 66,
			'assign' => 79,
			'node' => 33
		}
	},
	{#State 20
		ACTIONS => {
			'ASSIGN' => -66,
			'DOT' => 81
		},
		DEFAULT => -77
	},
	{#State 21
		DEFAULT => -19
	},
	{#State 22
		DEFAULT => -3
	},
	{#State 23
		ACTIONS => {
			"\"" => 46,
			'NOT' => 82,
			"\$" => 57,
			'IDENT' => 49,
			"(" => 84,
			"[" => 13,
			"{" => 37,
			'LITERAL' => 56,
			"\${" => 42
		},
		GOTOS => {
			'term' => 85,
			'ident' => 55,
			'node' => 33,
			'expr' => 83
		}
	},
	{#State 24
		DEFAULT => -12
	},
	{#State 25
		DEFAULT => -14
	},
	{#State 26
		ACTIONS => {
			"\"" => 62,
			"\$" => 63,
			'IDENT' => 64,
			'LITERAL' => 61
		},
		GOTOS => {
			'incparam' => 86,
			'textdot' => 60
		}
	},
	{#State 27
		DEFAULT => -16
	},
	{#State 28
		DEFAULT => -21
	},
	{#State 29
		DEFAULT => -37
	},
	{#State 30
		ACTIONS => {
			'SEPARATOR' => 87,
			'IDENT' => 88
		}
	},
	{#State 31
		DEFAULT => -18
	},
	{#State 32
		DEFAULT => -90
	},
	{#State 33
		DEFAULT => -71
	},
	{#State 34
		ACTIONS => {
			'IDENT' => 90
		},
		GOTOS => {
			'textdot' => 76,
			'useparam' => 89
		}
	},
	{#State 35
		DEFAULT => -13
	},
	{#State 36
		ACTIONS => {
			'TEXT' => 91
		}
	},
	{#State 37
		ACTIONS => {
			"\$" => 68,
			'IMPORT' => 69,
			'IDENT' => 49,
			'LITERAL' => 67,
			"\${" => 42
		},
		DEFAULT => -87,
		GOTOS => {
			'lvalue' => 14,
			'nparams' => 92,
			'params' => 93,
			'ident' => 66,
			'assign' => 32,
			'node' => 33
		}
	},
	{#State 38
		ACTIONS => {
			"\"" => 46,
			"{" => 37,
			"[" => 13,
			"\$" => 57,
			'IDENT' => 49,
			"\${" => 42,
			'LITERAL' => 56
		},
		GOTOS => {
			'term' => 94,
			'ident' => 55,
			'node' => 33
		}
	},
	{#State 39
		ACTIONS => {
			'' => 95
		}
	},
	{#State 40
		ACTIONS => {
			'GET' => 1,
			'INCLUDE' => 3,
			'TEXT' => 6,
			'DEFAULT' => 5,
			'BREAK' => 4,
			'STOP' => 8,
			'FOR' => 9,
			"[" => 13,
			'BLOCK' => 16,
			'SET' => 17,
			'USE' => 18,
			'UNLESS' => 23,
			'PROCESS' => 26,
			'RETURN' => 29,
			'CATCH' => 30,
			'FILTER' => 34,
			'DEBUG' => 36,
			"{" => 37,
			'ERROR' => 38,
			"\${" => 42,
			'LITERAL' => 43,
			'IF' => 45,
			"\"" => 46,
			'SEPARATOR' => -15,
			"\$" => 48,
			'IDENT' => 49,
			'THROW' => 50,
			'WHILE' => 52,
			'IMPORT' => 53
		},
		DEFAULT => -1,
		GOTOS => {
			'get' => 27,
			'return' => 28,
			'catch' => 2,
			'include' => 31,
			'assign' => 32,
			'text' => 7,
			'filter' => 35,
			'node' => 33,
			'debug' => 11,
			'condition' => 10,
			'setlist' => 12,
			'lvalue' => 14,
			'error' => 15,
			'set' => 41,
			'use' => 44,
			'atomdir' => 47,
			'nparams' => 19,
			'ident' => 20,
			'throw' => 21,
			'term' => 51,
			'chunk' => 96,
			'defblock' => 25,
			'loop' => 24,
			'directive' => 54
		}
	},
	{#State 41
		DEFAULT => -17
	},
	{#State 42
		ACTIONS => {
			"\"" => 46,
			"{" => 37,
			"[" => 13,
			"\$" => 57,
			'IDENT' => 49,
			"\${" => 42,
			'LITERAL' => 56
		},
		GOTOS => {
			'term' => 97,
			'ident' => 55,
			'node' => 33
		}
	},
	{#State 43
		ACTIONS => {
			'ASSIGN' => -68
		},
		DEFAULT => -82
	},
	{#State 44
		DEFAULT => -8
	},
	{#State 45
		ACTIONS => {
			"\"" => 46,
			'NOT' => 82,
			"\$" => 57,
			'IDENT' => 49,
			"(" => 84,
			"[" => 13,
			"{" => 37,
			'LITERAL' => 56,
			"\${" => 42
		},
		GOTOS => {
			'term' => 85,
			'ident' => 55,
			'node' => 33,
			'expr' => 98
		}
	},
	{#State 46
		DEFAULT => -103,
		GOTOS => {
			'quoted' => 99
		}
	},
	{#State 47
		ACTIONS => {
			'WHILE' => 104,
			'UNLESS' => 101,
			'FILTER' => 102,
			'IF' => 103,
			'FOR' => 100
		},
		DEFAULT => -7
	},
	{#State 48
		ACTIONS => {
			'IDENT' => 49,
			"\${" => 42
		},
		GOTOS => {
			'ident' => 105,
			'node' => 33
		}
	},
	{#State 49
		ACTIONS => {
			"(" => 106
		},
		DEFAULT => -74
	},
	{#State 50
		ACTIONS => {
			'IDENT' => 107
		}
	},
	{#State 51
		ACTIONS => {
			'COMPOP' => 108
		},
		DEFAULT => -24
	},
	{#State 52
		ACTIONS => {
			"\"" => 46,
			'NOT' => 82,
			"\$" => 57,
			'IDENT' => 49,
			"(" => 84,
			"[" => 13,
			"{" => 37,
			'LITERAL' => 56,
			"\${" => 42
		},
		GOTOS => {
			'term' => 85,
			'ident' => 55,
			'node' => 33,
			'expr' => 109
		}
	},
	{#State 53
		ACTIONS => {
			"\"" => 46,
			"\$" => 57,
			'IDENT' => 49,
			"[" => 13,
			"{" => 37,
			'LITERAL' => 56,
			"\${" => 42
		},
		DEFAULT => -69,
		GOTOS => {
			'term' => 110,
			'ident' => 55,
			'node' => 33
		}
	},
	{#State 54
		ACTIONS => {
			'SEPARATOR' => 111
		}
	},
	{#State 55
		ACTIONS => {
			'DOT' => 81
		},
		DEFAULT => -77
	},
	{#State 56
		DEFAULT => -82
	},
	{#State 57
		ACTIONS => {
			'IDENT' => 49,
			"\${" => 42
		},
		GOTOS => {
			'ident' => 112,
			'node' => 33
		}
	},
	{#State 58
		ACTIONS => {
			'COMPOP' => 108
		},
		DEFAULT => -23
	},
	{#State 59
		ACTIONS => {
			"\$" => 68,
			'IDENT' => 49,
			'IMPORT' => 69,
			"\${" => 42,
			'LITERAL' => 67
		},
		DEFAULT => -87,
		GOTOS => {
			'lvalue' => 14,
			'nparams' => 92,
			'params' => 114,
			'ident' => 66,
			'assign' => 32,
			'node' => 33,
			'inclist' => 113
		}
	},
	{#State 60
		ACTIONS => {
			'DOT' => 115,
			"/" => 116
		},
		DEFAULT => -95
	},
	{#State 61
		DEFAULT => -96
	},
	{#State 62
		DEFAULT => -103,
		GOTOS => {
			'quoted' => 117
		}
	},
	{#State 63
		ACTIONS => {
			'IDENT' => 49,
			"\${" => 42
		},
		GOTOS => {
			'ident' => 118,
			'node' => 33
		}
	},
	{#State 64
		DEFAULT => -101
	},
	{#State 65
		DEFAULT => -26
	},
	{#State 66
		ACTIONS => {
			'DOT' => 81
		},
		DEFAULT => -66
	},
	{#State 67
		DEFAULT => -68
	},
	{#State 68
		ACTIONS => {
			'IDENT' => 49,
			"\${" => 42
		},
		GOTOS => {
			'ident' => 119,
			'node' => 33
		}
	},
	{#State 69
		DEFAULT => -69
	},
	{#State 70
		ACTIONS => {
			'ASSIGN' => 120,
			"(" => 106
		},
		DEFAULT => -74
	},
	{#State 71
		ACTIONS => {
			'SEPARATOR' => 121,
			'COMPOP' => 108
		}
	},
	{#State 72
		ACTIONS => {
			"\"" => 46,
			"\$" => 57,
			'IDENT' => 49,
			"[" => 13,
			"{" => 37,
			"]" => 122,
			'LITERAL' => 56,
			"\${" => 42,
			'COMMA' => 123
		},
		GOTOS => {
			'term' => 124,
			'ident' => 55,
			'node' => 33
		}
	},
	{#State 73
		ACTIONS => {
			"\"" => 46,
			"{" => 37,
			"[" => 13,
			"\$" => 57,
			'IDENT' => 49,
			"\${" => 42,
			'LITERAL' => 56
		},
		GOTOS => {
			'term' => 125,
			'ident' => 55,
			'node' => 33
		}
	},
	{#State 74
		ACTIONS => {
			'SEPARATOR' => 126,
			"/" => 116,
			'DOT' => 115
		}
	},
	{#State 75
		DEFAULT => -25
	},
	{#State 76
		ACTIONS => {
			"/" => 116,
			"(" => 127,
			'DOT' => 115
		},
		DEFAULT => -98
	},
	{#State 77
		DEFAULT => -31
	},
	{#State 78
		ACTIONS => {
			'ASSIGN' => 128
		},
		DEFAULT => -101
	},
	{#State 79
		DEFAULT => -88
	},
	{#State 80
		DEFAULT => -89
	},
	{#State 81
		ACTIONS => {
			'IDENT' => 49,
			"\${" => 42
		},
		GOTOS => {
			'node' => 129
		}
	},
	{#State 82
		ACTIONS => {
			"\"" => 46,
			'NOT' => 82,
			"\$" => 57,
			'IDENT' => 49,
			"(" => 84,
			"[" => 13,
			"{" => 37,
			'LITERAL' => 56,
			"\${" => 42
		},
		GOTOS => {
			'term' => 85,
			'ident' => 55,
			'node' => 33,
			'expr' => 130
		}
	},
	{#State 83
		ACTIONS => {
			'SEPARATOR' => 133,
			'OR' => 131,
			'AND' => 132
		}
	},
	{#State 84
		ACTIONS => {
			"\"" => 46,
			'NOT' => 82,
			"\$" => 48,
			'IDENT' => 49,
			"(" => 84,
			"[" => 13,
			"{" => 37,
			'IMPORT' => 69,
			"\${" => 42,
			'LITERAL' => 43
		},
		GOTOS => {
			'term' => 85,
			'lvalue' => 14,
			'ident' => 20,
			'assign' => 135,
			'node' => 33,
			'expr' => 134
		}
	},
	{#State 85
		ACTIONS => {
			'COMPOP' => 108
		},
		DEFAULT => -64
	},
	{#State 86
		ACTIONS => {
			"\$" => 68,
			'IDENT' => 49,
			'IMPORT' => 69,
			"\${" => 42,
			'LITERAL' => 67
		},
		DEFAULT => -87,
		GOTOS => {
			'lvalue' => 14,
			'nparams' => 92,
			'params' => 114,
			'ident' => 66,
			'assign' => 32,
			'node' => 33,
			'inclist' => 136
		}
	},
	{#State 87
		ACTIONS => {
			'RETURN' => 29,
			'GET' => 1,
			'CATCH' => 30,
			'INCLUDE' => 3,
			'TEXT' => 6,
			'DEFAULT' => 5,
			'BREAK' => 4,
			'FILTER' => 34,
			'STOP' => 8,
			'DEBUG' => 36,
			'FOR' => 9,
			"{" => 37,
			"[" => 13,
			'ERROR' => 38,
			'BLOCK' => 16,
			'SET' => 17,
			'LITERAL' => 43,
			"\${" => 42,
			'USE' => 18,
			'IF' => 45,
			"\"" => 46,
			'SEPARATOR' => -15,
			"\$" => 48,
			'THROW' => 50,
			'IDENT' => 49,
			'WHILE' => 52,
			'UNLESS' => 23,
			'IMPORT' => 53,
			'PROCESS' => 26
		},
		DEFAULT => -2,
		GOTOS => {
			'get' => 27,
			'return' => 28,
			'catch' => 2,
			'include' => 31,
			'assign' => 32,
			'text' => 7,
			'filter' => 35,
			'node' => 33,
			'debug' => 11,
			'condition' => 10,
			'setlist' => 12,
			'lvalue' => 14,
			'error' => 15,
			'block' => 137,
			'chunks' => 40,
			'set' => 41,
			'use' => 44,
			'atomdir' => 47,
			'nparams' => 19,
			'ident' => 20,
			'throw' => 21,
			'term' => 51,
			'chunk' => 22,
			'defblock' => 25,
			'loop' => 24,
			'directive' => 54
		}
	},
	{#State 88
		ACTIONS => {
			'SEPARATOR' => 138
		}
	},
	{#State 89
		ACTIONS => {
			'SEPARATOR' => 139
		}
	},
	{#State 90
		ACTIONS => {
			'ASSIGN' => 140
		},
		DEFAULT => -101
	},
	{#State 91
		DEFAULT => -58
	},
	{#State 92
		ACTIONS => {
			"\$" => 68,
			'IDENT' => 49,
			'IMPORT' => 69,
			"\${" => 42,
			'LITERAL' => 67,
			'COMMA' => 80
		},
		DEFAULT => -86,
		GOTOS => {
			'lvalue' => 14,
			'ident' => 66,
			'assign' => 79,
			'node' => 33
		}
	},
	{#State 93
		ACTIONS => {
			"}" => 141
		}
	},
	{#State 94
		ACTIONS => {
			'COMPOP' => 108
		},
		DEFAULT => -36
	},
	{#State 95
		DEFAULT => -0
	},
	{#State 96
		DEFAULT => -4
	},
	{#State 97
		ACTIONS => {
			"}" => 142,
			'COMPOP' => 108
		}
	},
	{#State 98
		ACTIONS => {
			'SEPARATOR' => 143,
			'OR' => 131,
			'AND' => 132
		}
	},
	{#State 99
		ACTIONS => {
			"\"" => 146,
			'SEPARATOR' => 147,
			'IDENT' => 49,
			"\${" => 42,
			'TEXT' => 144
		},
		GOTOS => {
			'ident' => 145,
			'quotable' => 148,
			'node' => 33
		}
	},
	{#State 100
		ACTIONS => {
			"\"" => 46,
			"{" => 37,
			"[" => 13,
			"\$" => 57,
			'IDENT' => 149,
			"\${" => 42,
			'LITERAL' => 56
		},
		GOTOS => {
			'term' => 150,
			'ident' => 55,
			'node' => 33
		}
	},
	{#State 101
		ACTIONS => {
			"\"" => 46,
			'NOT' => 82,
			"\$" => 57,
			'IDENT' => 49,
			"(" => 84,
			"[" => 13,
			"{" => 37,
			'LITERAL' => 56,
			"\${" => 42
		},
		GOTOS => {
			'term' => 85,
			'ident' => 55,
			'node' => 33,
			'expr' => 151
		}
	},
	{#State 102
		ACTIONS => {
			'IDENT' => 153
		},
		GOTOS => {
			'textdot' => 76,
			'useparam' => 152
		}
	},
	{#State 103
		ACTIONS => {
			"\"" => 46,
			'NOT' => 82,
			"\$" => 57,
			'IDENT' => 49,
			"(" => 84,
			"[" => 13,
			"{" => 37,
			'LITERAL' => 56,
			"\${" => 42
		},
		GOTOS => {
			'term' => 85,
			'ident' => 55,
			'node' => 33,
			'expr' => 154
		}
	},
	{#State 104
		ACTIONS => {
			"\"" => 46,
			'NOT' => 82,
			"\$" => 57,
			'IDENT' => 49,
			"(" => 84,
			"[" => 13,
			"{" => 37,
			'LITERAL' => 56,
			"\${" => 42
		},
		GOTOS => {
			'term' => 85,
			'ident' => 55,
			'node' => 33,
			'expr' => 155
		}
	},
	{#State 105
		ACTIONS => {
			'ASSIGN' => -67,
			'DOT' => 81
		},
		DEFAULT => -76
	},
	{#State 106
		DEFAULT => -85,
		GOTOS => {
			'list' => 156
		}
	},
	{#State 107
		ACTIONS => {
			"\"" => 46,
			"{" => 37,
			"[" => 13,
			"\$" => 57,
			'IDENT' => 49,
			"\${" => 42,
			'LITERAL' => 56
		},
		GOTOS => {
			'term' => 157,
			'ident' => 55,
			'node' => 33
		}
	},
	{#State 108
		ACTIONS => {
			"\"" => 46,
			"{" => 37,
			"[" => 13,
			"\$" => 57,
			'IDENT' => 49,
			"\${" => 42,
			'LITERAL' => 56
		},
		GOTOS => {
			'term' => 158,
			'ident' => 55,
			'node' => 33
		}
	},
	{#State 109
		ACTIONS => {
			'SEPARATOR' => 159,
			'OR' => 131,
			'AND' => 132
		}
	},
	{#State 110
		ACTIONS => {
			'COMPOP' => 108
		},
		DEFAULT => -27
	},
	{#State 111
		DEFAULT => -6
	},
	{#State 112
		ACTIONS => {
			'DOT' => 81
		},
		DEFAULT => -76
	},
	{#State 113
		DEFAULT => -29
	},
	{#State 114
		DEFAULT => -92
	},
	{#State 115
		ACTIONS => {
			'IDENT' => 160
		}
	},
	{#State 116
		ACTIONS => {
			'IDENT' => 161
		}
	},
	{#State 117
		ACTIONS => {
			"\"" => 162,
			'SEPARATOR' => 147,
			'IDENT' => 49,
			"\${" => 42,
			'TEXT' => 144
		},
		GOTOS => {
			'ident' => 145,
			'quotable' => 148,
			'node' => 33
		}
	},
	{#State 118
		ACTIONS => {
			'DOT' => 81
		},
		DEFAULT => -93
	},
	{#State 119
		ACTIONS => {
			'DOT' => 81
		},
		DEFAULT => -67
	},
	{#State 120
		ACTIONS => {
			"\"" => 46,
			"{" => 37,
			"[" => 13,
			"\$" => 57,
			'IDENT' => 49,
			"\${" => 42,
			'LITERAL' => 56
		},
		GOTOS => {
			'term' => 163,
			'ident' => 55,
			'node' => 33
		}
	},
	{#State 121
		ACTIONS => {
			'RETURN' => 29,
			'GET' => 1,
			'CATCH' => 30,
			'INCLUDE' => 3,
			'TEXT' => 6,
			'DEFAULT' => 5,
			'BREAK' => 4,
			'FILTER' => 34,
			'STOP' => 8,
			'DEBUG' => 36,
			'FOR' => 9,
			"{" => 37,
			"[" => 13,
			'ERROR' => 38,
			'BLOCK' => 16,
			'SET' => 17,
			'LITERAL' => 43,
			"\${" => 42,
			'USE' => 18,
			'IF' => 45,
			"\"" => 46,
			'SEPARATOR' => -15,
			"\$" => 48,
			'THROW' => 50,
			'IDENT' => 49,
			'WHILE' => 52,
			'UNLESS' => 23,
			'IMPORT' => 53,
			'PROCESS' => 26
		},
		DEFAULT => -2,
		GOTOS => {
			'get' => 27,
			'return' => 28,
			'catch' => 2,
			'include' => 31,
			'assign' => 32,
			'text' => 7,
			'filter' => 35,
			'node' => 33,
			'debug' => 11,
			'condition' => 10,
			'setlist' => 12,
			'lvalue' => 14,
			'error' => 15,
			'block' => 164,
			'chunks' => 40,
			'set' => 41,
			'use' => 44,
			'atomdir' => 47,
			'nparams' => 19,
			'ident' => 20,
			'throw' => 21,
			'term' => 51,
			'chunk' => 22,
			'defblock' => 25,
			'loop' => 24,
			'directive' => 54
		}
	},
	{#State 122
		ACTIONS => {
			"(" => 165
		},
		DEFAULT => -78
	},
	{#State 123
		DEFAULT => -84
	},
	{#State 124
		ACTIONS => {
			'COMPOP' => 108
		},
		DEFAULT => -83
	},
	{#State 125
		ACTIONS => {
			'COMPOP' => 108
		},
		DEFAULT => -65
	},
	{#State 126
		ACTIONS => {
			'RETURN' => 29,
			'GET' => 1,
			'CATCH' => 30,
			'INCLUDE' => 3,
			'TEXT' => 6,
			'DEFAULT' => 5,
			'BREAK' => 4,
			'FILTER' => 34,
			'STOP' => 8,
			'DEBUG' => 36,
			'FOR' => 9,
			"{" => 37,
			"[" => 13,
			'ERROR' => 38,
			'BLOCK' => 16,
			'SET' => 17,
			'LITERAL' => 43,
			"\${" => 42,
			'USE' => 18,
			'IF' => 45,
			"\"" => 46,
			'SEPARATOR' => -15,
			"\$" => 48,
			'THROW' => 50,
			'IDENT' => 49,
			'WHILE' => 52,
			'UNLESS' => 23,
			'IMPORT' => 53,
			'PROCESS' => 26
		},
		DEFAULT => -2,
		GOTOS => {
			'get' => 27,
			'return' => 28,
			'catch' => 2,
			'include' => 31,
			'assign' => 32,
			'text' => 7,
			'filter' => 35,
			'node' => 33,
			'debug' => 11,
			'condition' => 10,
			'setlist' => 12,
			'lvalue' => 14,
			'error' => 15,
			'block' => 166,
			'chunks' => 40,
			'set' => 41,
			'use' => 44,
			'atomdir' => 47,
			'nparams' => 19,
			'ident' => 20,
			'throw' => 21,
			'term' => 51,
			'chunk' => 22,
			'defblock' => 25,
			'loop' => 24,
			'directive' => 54
		}
	},
	{#State 127
		DEFAULT => -85,
		GOTOS => {
			'list' => 167
		}
	},
	{#State 128
		ACTIONS => {
			'IDENT' => 64
		},
		GOTOS => {
			'textdot' => 76,
			'useparam' => 168
		}
	},
	{#State 129
		DEFAULT => -70
	},
	{#State 130
		ACTIONS => {
			'OR' => 131,
			'AND' => 132
		},
		DEFAULT => -61
	},
	{#State 131
		ACTIONS => {
			"\"" => 46,
			'NOT' => 82,
			"\$" => 57,
			'IDENT' => 49,
			"(" => 84,
			"[" => 13,
			"{" => 37,
			'LITERAL' => 56,
			"\${" => 42
		},
		GOTOS => {
			'term' => 85,
			'ident' => 55,
			'node' => 33,
			'expr' => 169
		}
	},
	{#State 132
		ACTIONS => {
			"\"" => 46,
			'NOT' => 82,
			"\$" => 57,
			'IDENT' => 49,
			"(" => 84,
			"[" => 13,
			"{" => 37,
			'LITERAL' => 56,
			"\${" => 42
		},
		GOTOS => {
			'term' => 85,
			'ident' => 55,
			'node' => 33,
			'expr' => 170
		}
	},
	{#State 133
		ACTIONS => {
			'GET' => 1,
			'INCLUDE' => 3,
			'TEXT' => 6,
			'DEFAULT' => 5,
			'BREAK' => 4,
			'STOP' => 8,
			'FOR' => 9,
			"[" => 13,
			'BLOCK' => 16,
			'SET' => 17,
			'USE' => 18,
			'UNLESS' => 23,
			'PROCESS' => 26,
			'RETURN' => 29,
			'CATCH' => 30,
			'FILTER' => 34,
			'DEBUG' => 36,
			"{" => 37,
			'ERROR' => 38,
			"\${" => 42,
			'LITERAL' => 43,
			'IF' => 45,
			"\"" => 46,
			'SEPARATOR' => -15,
			"\$" => 48,
			'IDENT' => 49,
			'THROW' => 50,
			'WHILE' => 52,
			'IMPORT' => 53
		},
		DEFAULT => -2,
		GOTOS => {
			'get' => 27,
			'return' => 28,
			'catch' => 2,
			'include' => 31,
			'assign' => 32,
			'text' => 7,
			'filter' => 35,
			'node' => 33,
			'debug' => 11,
			'condition' => 10,
			'setlist' => 12,
			'lvalue' => 14,
			'error' => 15,
			'block' => 171,
			'chunks' => 40,
			'set' => 41,
			'use' => 44,
			'atomdir' => 47,
			'nparams' => 19,
			'ident' => 20,
			'throw' => 21,
			'term' => 51,
			'chunk' => 22,
			'defblock' => 25,
			'loop' => 24,
			'directive' => 54
		}
	},
	{#State 134
		ACTIONS => {
			'OR' => 131,
			'AND' => 132,
			")" => 172
		}
	},
	{#State 135
		ACTIONS => {
			")" => 173
		}
	},
	{#State 136
		DEFAULT => -30
	},
	{#State 137
		ACTIONS => {
			'END' => 174
		}
	},
	{#State 138
		ACTIONS => {
			'RETURN' => 29,
			'GET' => 1,
			'CATCH' => 30,
			'INCLUDE' => 3,
			'TEXT' => 6,
			'DEFAULT' => 5,
			'BREAK' => 4,
			'FILTER' => 34,
			'STOP' => 8,
			'DEBUG' => 36,
			'FOR' => 9,
			"{" => 37,
			"[" => 13,
			'ERROR' => 38,
			'BLOCK' => 16,
			'SET' => 17,
			'LITERAL' => 43,
			"\${" => 42,
			'USE' => 18,
			'IF' => 45,
			"\"" => 46,
			'SEPARATOR' => -15,
			"\$" => 48,
			'THROW' => 50,
			'IDENT' => 49,
			'WHILE' => 52,
			'UNLESS' => 23,
			'IMPORT' => 53,
			'PROCESS' => 26
		},
		DEFAULT => -2,
		GOTOS => {
			'get' => 27,
			'return' => 28,
			'catch' => 2,
			'include' => 31,
			'assign' => 32,
			'text' => 7,
			'filter' => 35,
			'node' => 33,
			'debug' => 11,
			'condition' => 10,
			'setlist' => 12,
			'lvalue' => 14,
			'error' => 15,
			'block' => 175,
			'chunks' => 40,
			'set' => 41,
			'use' => 44,
			'atomdir' => 47,
			'nparams' => 19,
			'ident' => 20,
			'throw' => 21,
			'term' => 51,
			'chunk' => 22,
			'defblock' => 25,
			'loop' => 24,
			'directive' => 54
		}
	},
	{#State 139
		ACTIONS => {
			'RETURN' => 29,
			'GET' => 1,
			'CATCH' => 30,
			'INCLUDE' => 3,
			'TEXT' => 6,
			'DEFAULT' => 5,
			'BREAK' => 4,
			'FILTER' => 34,
			'STOP' => 8,
			'DEBUG' => 36,
			'FOR' => 9,
			"{" => 37,
			"[" => 13,
			'ERROR' => 38,
			'BLOCK' => 16,
			'SET' => 17,
			'LITERAL' => 43,
			"\${" => 42,
			'USE' => 18,
			'IF' => 45,
			"\"" => 46,
			'SEPARATOR' => -15,
			"\$" => 48,
			'THROW' => 50,
			'IDENT' => 49,
			'WHILE' => 52,
			'UNLESS' => 23,
			'IMPORT' => 53,
			'PROCESS' => 26
		},
		DEFAULT => -2,
		GOTOS => {
			'get' => 27,
			'return' => 28,
			'catch' => 2,
			'include' => 31,
			'assign' => 32,
			'text' => 7,
			'filter' => 35,
			'node' => 33,
			'debug' => 11,
			'condition' => 10,
			'setlist' => 12,
			'lvalue' => 14,
			'error' => 15,
			'block' => 176,
			'chunks' => 40,
			'set' => 41,
			'use' => 44,
			'atomdir' => 47,
			'nparams' => 19,
			'ident' => 20,
			'throw' => 21,
			'term' => 51,
			'chunk' => 22,
			'defblock' => 25,
			'loop' => 24,
			'directive' => 54
		}
	},
	{#State 140
		ACTIONS => {
			'IDENT' => 64
		},
		GOTOS => {
			'textdot' => 76,
			'useparam' => 177
		}
	},
	{#State 141
		DEFAULT => -80
	},
	{#State 142
		DEFAULT => -72
	},
	{#State 143
		ACTIONS => {
			'GET' => 1,
			'INCLUDE' => 3,
			'TEXT' => 6,
			'DEFAULT' => 5,
			'BREAK' => 4,
			'STOP' => 8,
			'FOR' => 9,
			"[" => 13,
			'BLOCK' => 16,
			'SET' => 17,
			'USE' => 18,
			'UNLESS' => 23,
			'PROCESS' => 26,
			'RETURN' => 29,
			'CATCH' => 30,
			'FILTER' => 34,
			'DEBUG' => 36,
			"{" => 37,
			'ERROR' => 38,
			"\${" => 42,
			'LITERAL' => 43,
			'IF' => 45,
			"\"" => 46,
			'SEPARATOR' => -15,
			"\$" => 48,
			'IDENT' => 49,
			'THROW' => 50,
			'WHILE' => 52,
			'IMPORT' => 53
		},
		DEFAULT => -2,
		GOTOS => {
			'get' => 27,
			'return' => 28,
			'catch' => 2,
			'include' => 31,
			'assign' => 32,
			'text' => 7,
			'filter' => 35,
			'node' => 33,
			'debug' => 11,
			'condition' => 10,
			'setlist' => 12,
			'lvalue' => 14,
			'error' => 15,
			'block' => 178,
			'chunks' => 40,
			'set' => 41,
			'use' => 44,
			'atomdir' => 47,
			'nparams' => 19,
			'ident' => 20,
			'throw' => 21,
			'term' => 51,
			'chunk' => 22,
			'defblock' => 25,
			'loop' => 24,
			'directive' => 54
		}
	},
	{#State 144
		DEFAULT => -105
	},
	{#State 145
		ACTIONS => {
			'DOT' => 81
		},
		DEFAULT => -104
	},
	{#State 146
		DEFAULT => -81
	},
	{#State 147
		DEFAULT => -106
	},
	{#State 148
		DEFAULT => -102
	},
	{#State 149
		ACTIONS => {
			'ASSIGN' => 179,
			"(" => 106
		},
		DEFAULT => -74
	},
	{#State 150
		ACTIONS => {
			'COMPOP' => 108
		},
		DEFAULT => -51
	},
	{#State 151
		ACTIONS => {
			'OR' => 131,
			'AND' => 132
		},
		DEFAULT => -43
	},
	{#State 152
		DEFAULT => -55
	},
	{#State 153
		ACTIONS => {
			'ASSIGN' => 180
		},
		DEFAULT => -101
	},
	{#State 154
		ACTIONS => {
			'OR' => 131,
			'AND' => 132
		},
		DEFAULT => -42
	},
	{#State 155
		ACTIONS => {
			'OR' => 131,
			'AND' => 132
		},
		DEFAULT => -52
	},
	{#State 156
		ACTIONS => {
			"\"" => 46,
			"\$" => 57,
			'IDENT' => 49,
			")" => 181,
			"[" => 13,
			"{" => 37,
			'LITERAL' => 56,
			"\${" => 42,
			'COMMA' => 123
		},
		GOTOS => {
			'term' => 124,
			'ident' => 55,
			'node' => 33
		}
	},
	{#State 157
		ACTIONS => {
			'COMPOP' => 108
		},
		DEFAULT => -33
	},
	{#State 158
		DEFAULT => -75
	},
	{#State 159
		ACTIONS => {
			'RETURN' => 29,
			'GET' => 1,
			'CATCH' => 30,
			'INCLUDE' => 3,
			'TEXT' => 6,
			'DEFAULT' => 5,
			'BREAK' => 4,
			'FILTER' => 34,
			'STOP' => 8,
			'DEBUG' => 36,
			'FOR' => 9,
			"{" => 37,
			"[" => 13,
			'ERROR' => 38,
			'BLOCK' => 16,
			'SET' => 17,
			'LITERAL' => 43,
			"\${" => 42,
			'USE' => 18,
			'IF' => 45,
			"\"" => 46,
			'SEPARATOR' => -15,
			"\$" => 48,
			'THROW' => 50,
			'IDENT' => 49,
			'WHILE' => 52,
			'UNLESS' => 23,
			'IMPORT' => 53,
			'PROCESS' => 26
		},
		DEFAULT => -2,
		GOTOS => {
			'get' => 27,
			'return' => 28,
			'catch' => 2,
			'include' => 31,
			'assign' => 32,
			'text' => 7,
			'filter' => 35,
			'node' => 33,
			'debug' => 11,
			'condition' => 10,
			'setlist' => 12,
			'lvalue' => 14,
			'error' => 15,
			'block' => 182,
			'chunks' => 40,
			'set' => 41,
			'use' => 44,
			'atomdir' => 47,
			'nparams' => 19,
			'ident' => 20,
			'throw' => 21,
			'term' => 51,
			'chunk' => 22,
			'defblock' => 25,
			'loop' => 24,
			'directive' => 54
		}
	},
	{#State 160
		DEFAULT => -99
	},
	{#State 161
		DEFAULT => -100
	},
	{#State 162
		DEFAULT => -94
	},
	{#State 163
		ACTIONS => {
			'SEPARATOR' => 183,
			'COMPOP' => 108
		}
	},
	{#State 164
		ACTIONS => {
			'END' => 184
		}
	},
	{#State 165
		ACTIONS => {
			"\$" => 68,
			'IMPORT' => 69,
			'IDENT' => 49,
			'LITERAL' => 67,
			"\${" => 42
		},
		DEFAULT => -87,
		GOTOS => {
			'lvalue' => 14,
			'nparams' => 92,
			'params' => 185,
			'ident' => 66,
			'assign' => 32,
			'node' => 33
		}
	},
	{#State 166
		ACTIONS => {
			'END' => 186
		}
	},
	{#State 167
		ACTIONS => {
			"\"" => 46,
			"\$" => 57,
			'IDENT' => 49,
			")" => 187,
			"[" => 13,
			"{" => 37,
			'LITERAL' => 56,
			"\${" => 42,
			'COMMA' => 123
		},
		GOTOS => {
			'term' => 124,
			'ident' => 55,
			'node' => 33
		}
	},
	{#State 168
		DEFAULT => -32
	},
	{#State 169
		DEFAULT => -60
	},
	{#State 170
		ACTIONS => {
			'OR' => 131
		},
		DEFAULT => -59
	},
	{#State 171
		ACTIONS => {
			'ELSE' => 189,
			'ELSIF' => 188
		},
		DEFAULT => -44,
		GOTOS => {
			'else' => 190
		}
	},
	{#State 172
		DEFAULT => -62
	},
	{#State 173
		DEFAULT => -63
	},
	{#State 174
		DEFAULT => -35
	},
	{#State 175
		ACTIONS => {
			'END' => 191
		}
	},
	{#State 176
		ACTIONS => {
			'END' => 192
		}
	},
	{#State 177
		ACTIONS => {
			'SEPARATOR' => 193
		}
	},
	{#State 178
		ACTIONS => {
			'ELSE' => 189,
			'ELSIF' => 188
		},
		DEFAULT => -44,
		GOTOS => {
			'else' => 194
		}
	},
	{#State 179
		ACTIONS => {
			"\"" => 46,
			"{" => 37,
			"[" => 13,
			"\$" => 57,
			'IDENT' => 49,
			"\${" => 42,
			'LITERAL' => 56
		},
		GOTOS => {
			'term' => 195,
			'ident' => 55,
			'node' => 33
		}
	},
	{#State 180
		ACTIONS => {
			'IDENT' => 64
		},
		GOTOS => {
			'textdot' => 76,
			'useparam' => 196
		}
	},
	{#State 181
		DEFAULT => -73
	},
	{#State 182
		ACTIONS => {
			'END' => 197
		}
	},
	{#State 183
		ACTIONS => {
			'RETURN' => 29,
			'GET' => 1,
			'CATCH' => 30,
			'INCLUDE' => 3,
			'TEXT' => 6,
			'DEFAULT' => 5,
			'BREAK' => 4,
			'FILTER' => 34,
			'STOP' => 8,
			'DEBUG' => 36,
			'FOR' => 9,
			"{" => 37,
			"[" => 13,
			'ERROR' => 38,
			'BLOCK' => 16,
			'SET' => 17,
			'LITERAL' => 43,
			"\${" => 42,
			'USE' => 18,
			'IF' => 45,
			"\"" => 46,
			'SEPARATOR' => -15,
			"\$" => 48,
			'THROW' => 50,
			'IDENT' => 49,
			'WHILE' => 52,
			'UNLESS' => 23,
			'IMPORT' => 53,
			'PROCESS' => 26
		},
		DEFAULT => -2,
		GOTOS => {
			'get' => 27,
			'return' => 28,
			'catch' => 2,
			'include' => 31,
			'assign' => 32,
			'text' => 7,
			'filter' => 35,
			'node' => 33,
			'debug' => 11,
			'condition' => 10,
			'setlist' => 12,
			'lvalue' => 14,
			'error' => 15,
			'block' => 198,
			'chunks' => 40,
			'set' => 41,
			'use' => 44,
			'atomdir' => 47,
			'nparams' => 19,
			'ident' => 20,
			'throw' => 21,
			'term' => 51,
			'chunk' => 22,
			'defblock' => 25,
			'loop' => 24,
			'directive' => 54
		}
	},
	{#State 184
		DEFAULT => -48
	},
	{#State 185
		ACTIONS => {
			")" => 199
		}
	},
	{#State 186
		DEFAULT => -57
	},
	{#State 187
		DEFAULT => -97
	},
	{#State 188
		ACTIONS => {
			"\"" => 46,
			'NOT' => 82,
			"\$" => 57,
			'IDENT' => 49,
			"(" => 84,
			"[" => 13,
			"{" => 37,
			'LITERAL' => 56,
			"\${" => 42
		},
		GOTOS => {
			'term' => 85,
			'ident' => 55,
			'node' => 33,
			'expr' => 200
		}
	},
	{#State 189
		ACTIONS => {
			'SEPARATOR' => 201
		}
	},
	{#State 190
		ACTIONS => {
			'END' => 202
		}
	},
	{#State 191
		DEFAULT => -34
	},
	{#State 192
		DEFAULT => -53
	},
	{#State 193
		ACTIONS => {
			'RETURN' => 29,
			'GET' => 1,
			'CATCH' => 30,
			'INCLUDE' => 3,
			'TEXT' => 6,
			'DEFAULT' => 5,
			'BREAK' => 4,
			'FILTER' => 34,
			'STOP' => 8,
			'DEBUG' => 36,
			'FOR' => 9,
			"{" => 37,
			"[" => 13,
			'ERROR' => 38,
			'BLOCK' => 16,
			'SET' => 17,
			'LITERAL' => 43,
			"\${" => 42,
			'USE' => 18,
			'IF' => 45,
			"\"" => 46,
			'SEPARATOR' => -15,
			"\$" => 48,
			'THROW' => 50,
			'IDENT' => 49,
			'WHILE' => 52,
			'UNLESS' => 23,
			'IMPORT' => 53,
			'PROCESS' => 26
		},
		DEFAULT => -2,
		GOTOS => {
			'get' => 27,
			'return' => 28,
			'catch' => 2,
			'include' => 31,
			'assign' => 32,
			'text' => 7,
			'filter' => 35,
			'node' => 33,
			'debug' => 11,
			'condition' => 10,
			'setlist' => 12,
			'lvalue' => 14,
			'error' => 15,
			'block' => 203,
			'chunks' => 40,
			'set' => 41,
			'use' => 44,
			'atomdir' => 47,
			'nparams' => 19,
			'ident' => 20,
			'throw' => 21,
			'term' => 51,
			'chunk' => 22,
			'defblock' => 25,
			'loop' => 24,
			'directive' => 54
		}
	},
	{#State 194
		ACTIONS => {
			'END' => 204
		}
	},
	{#State 195
		ACTIONS => {
			'COMPOP' => 108
		},
		DEFAULT => -50
	},
	{#State 196
		DEFAULT => -56
	},
	{#State 197
		DEFAULT => -49
	},
	{#State 198
		ACTIONS => {
			'END' => 205
		}
	},
	{#State 199
		DEFAULT => -79
	},
	{#State 200
		ACTIONS => {
			'SEPARATOR' => 206,
			'OR' => 131,
			'AND' => 132
		}
	},
	{#State 201
		ACTIONS => {
			'RETURN' => 29,
			'GET' => 1,
			'CATCH' => 30,
			'INCLUDE' => 3,
			'TEXT' => 6,
			'DEFAULT' => 5,
			'BREAK' => 4,
			'FILTER' => 34,
			'STOP' => 8,
			'DEBUG' => 36,
			'FOR' => 9,
			"{" => 37,
			"[" => 13,
			'ERROR' => 38,
			'BLOCK' => 16,
			'SET' => 17,
			'LITERAL' => 43,
			"\${" => 42,
			'USE' => 18,
			'IF' => 45,
			"\"" => 46,
			'SEPARATOR' => -15,
			"\$" => 48,
			'THROW' => 50,
			'IDENT' => 49,
			'WHILE' => 52,
			'UNLESS' => 23,
			'IMPORT' => 53,
			'PROCESS' => 26
		},
		DEFAULT => -2,
		GOTOS => {
			'get' => 27,
			'return' => 28,
			'catch' => 2,
			'include' => 31,
			'assign' => 32,
			'text' => 7,
			'filter' => 35,
			'node' => 33,
			'debug' => 11,
			'condition' => 10,
			'setlist' => 12,
			'lvalue' => 14,
			'error' => 15,
			'block' => 207,
			'chunks' => 40,
			'set' => 41,
			'use' => 44,
			'atomdir' => 47,
			'nparams' => 19,
			'ident' => 20,
			'throw' => 21,
			'term' => 51,
			'chunk' => 22,
			'defblock' => 25,
			'loop' => 24,
			'directive' => 54
		}
	},
	{#State 202
		DEFAULT => -41
	},
	{#State 203
		ACTIONS => {
			'END' => 208
		}
	},
	{#State 204
		DEFAULT => -40
	},
	{#State 205
		DEFAULT => -47
	},
	{#State 206
		ACTIONS => {
			'GET' => 1,
			'INCLUDE' => 3,
			'TEXT' => 6,
			'DEFAULT' => 5,
			'BREAK' => 4,
			'STOP' => 8,
			'FOR' => 9,
			"[" => 13,
			'BLOCK' => 16,
			'SET' => 17,
			'USE' => 18,
			'UNLESS' => 23,
			'PROCESS' => 26,
			'RETURN' => 29,
			'CATCH' => 30,
			'FILTER' => 34,
			'DEBUG' => 36,
			"{" => 37,
			'ERROR' => 38,
			"\${" => 42,
			'LITERAL' => 43,
			'IF' => 45,
			"\"" => 46,
			'SEPARATOR' => -15,
			"\$" => 48,
			'IDENT' => 49,
			'THROW' => 50,
			'WHILE' => 52,
			'IMPORT' => 53
		},
		DEFAULT => -2,
		GOTOS => {
			'get' => 27,
			'return' => 28,
			'catch' => 2,
			'include' => 31,
			'assign' => 32,
			'text' => 7,
			'filter' => 35,
			'node' => 33,
			'debug' => 11,
			'condition' => 10,
			'setlist' => 12,
			'lvalue' => 14,
			'error' => 15,
			'block' => 209,
			'chunks' => 40,
			'set' => 41,
			'use' => 44,
			'atomdir' => 47,
			'nparams' => 19,
			'ident' => 20,
			'throw' => 21,
			'term' => 51,
			'chunk' => 22,
			'defblock' => 25,
			'loop' => 24,
			'directive' => 54
		}
	},
	{#State 207
		DEFAULT => -45
	},
	{#State 208
		DEFAULT => -54
	},
	{#State 209
		ACTIONS => {
			'ELSE' => 189,
			'ELSIF' => 188
		},
		DEFAULT => -44,
		GOTOS => {
			'else' => 210
		}
	},
	{#State 210
		DEFAULT => -46
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
#line 15 "Parser.yp"
{ Template::Directive::Block->new($_[1]) }
	],
	[#Rule 2
		 'block', 0,
sub
#line 17 "Parser.yp"
{ Template::Directive::Block->new([])    }
	],
	[#Rule 3
		 'chunks', 1,
sub
#line 27 "Parser.yp"
{ return defined $_[1] ? [ $_[1] ] : [ ] }
	],
	[#Rule 4
		 'chunks', 2,
sub
#line 29 "Parser.yp"
{ push(@{ $_[1] }, $_[2]) if defined $_[2]; $_[1] }
	],
	[#Rule 5
		 'chunk', 1,
sub
#line 33 "Parser.yp"
{ $_[1] }
	],
	[#Rule 6
		 'chunk', 2,
sub
#line 35 "Parser.yp"
{ $_[1] }
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
		 'directive', 0, undef
	],
	[#Rule 16
		 'atomdir', 1, undef
	],
	[#Rule 17
		 'atomdir', 1, undef
	],
	[#Rule 18
		 'atomdir', 1, undef
	],
	[#Rule 19
		 'atomdir', 1, undef
	],
	[#Rule 20
		 'atomdir', 1, undef
	],
	[#Rule 21
		 'atomdir', 1, undef
	],
	[#Rule 22
		 'text', 1,
sub
#line 63 "Parser.yp"
{ Template::Directive::Text->new($_[1])          }
	],
	[#Rule 23
		 'get', 2,
sub
#line 67 "Parser.yp"
{ Template::Directive->new($_[2])                }
	],
	[#Rule 24
		 'get', 1,
sub
#line 70 "Parser.yp"
{ Template::Directive->new($_[1])                }
	],
	[#Rule 25
		 'set', 2,
sub
#line 74 "Parser.yp"
{ Template::Directive->new($_[2])                }
	],
	[#Rule 26
		 'set', 2,
sub
#line 76 "Parser.yp"
{ unshift(@{$_[2]}, OP_DEFAULT);  # enable DEFAULT
			  Template::Directive->new($_[2])                }
	],
	[#Rule 27
		 'set', 2,
sub
#line 79 "Parser.yp"
{ Template::Directive->new([ OP_ROOT, ['IMPORT'],
				OP_LIST,  @{$_[2]}, OP_ASSIGN, OP_POP ]) }
	],
	[#Rule 28
		 'set', 1,
sub
#line 81 "Parser.yp"
{ Template::Directive->new($_[1])                }
	],
	[#Rule 29
		 'include', 3,
sub
#line 85 "Parser.yp"
{ Template::Directive::Include->new(@_[2, 3])    }
	],
	[#Rule 30
		 'include', 3,
sub
#line 88 "Parser.yp"
{ Template::Directive::Process->new(@_[2, 3])    }
	],
	[#Rule 31
		 'use', 2,
sub
#line 92 "Parser.yp"
{ Template::Directive::Use->new(@{$_[2]})        }
	],
	[#Rule 32
		 'use', 4,
sub
#line 94 "Parser.yp"
{ Template::Directive::Use->new($_[4]->[0], 
						$_[4]->[1], $_[2])       }
	],
	[#Rule 33
		 'throw', 3,
sub
#line 99 "Parser.yp"
{ Template::Directive::Throw->new(@_[2, 3])      }
	],
	[#Rule 34
		 'catch', 5,
sub
#line 103 "Parser.yp"
{ Template::Directive::Catch->new(@_[2, 4])      }
	],
	[#Rule 35
		 'catch', 4,
sub
#line 105 "Parser.yp"
{ Template::Directive::Catch->new(undef, $_[3])  }
	],
	[#Rule 36
		 'error', 2,
sub
#line 109 "Parser.yp"
{ Template::Directive::Error->new($_[2])         }
	],
	[#Rule 37
		 'return', 1,
sub
#line 112 "Parser.yp"
{ Template::Directive::Return->new(
			      Template::Constants::STATUS_RETURN)        }
	],
	[#Rule 38
		 'return', 1,
sub
#line 115 "Parser.yp"
{ Template::Directive::Return->new(
			      Template::Constants::STATUS_STOP)          }
	],
	[#Rule 39
		 'return', 1,
sub
#line 118 "Parser.yp"
{ Template::Directive::Return->new(
			      Template::Constants::STATUS_DONE)          }
	],
	[#Rule 40
		 'condition', 6,
sub
#line 123 "Parser.yp"
{ Template::Directive::If->new(@_[2, 4, 5])      }
	],
	[#Rule 41
		 'condition', 6,
sub
#line 125 "Parser.yp"
{ push(@{ $_[2] }, OP_NOT);   # negate expression
			  Template::Directive::If->new(@_[2, 4, 5])      }
	],
	[#Rule 42
		 'condition', 3,
sub
#line 128 "Parser.yp"
{ Template::Directive::If->new(@_[3, 1])         }
	],
	[#Rule 43
		 'condition', 3,
sub
#line 130 "Parser.yp"
{ push(@{ $_[3] }, OP_NOT);   # negate expression
			  Template::Directive::If->new(@_[3, 1])         }
	],
	[#Rule 44
		 'else', 0,
sub
#line 135 "Parser.yp"
{ undef }
	],
	[#Rule 45
		 'else', 3,
sub
#line 137 "Parser.yp"
{ $_[3] }
	],
	[#Rule 46
		 'else', 5,
sub
#line 139 "Parser.yp"
{ Template::Directive::If->new(@_[2, 4, 5])      }
	],
	[#Rule 47
		 'loop', 7,
sub
#line 143 "Parser.yp"
{ Template::Directive::For->new(@_[4, 6, 2])     }
	],
	[#Rule 48
		 'loop', 5,
sub
#line 145 "Parser.yp"
{ Template::Directive::For->new(@_[2, 4])        }
	],
	[#Rule 49
		 'loop', 5,
sub
#line 147 "Parser.yp"
{ Template::Directive::While->new(@_[2, 4])      }
	],
	[#Rule 50
		 'loop', 5,
sub
#line 149 "Parser.yp"
{ Template::Directive::For->new(@_[5, 1, 3])     }
	],
	[#Rule 51
		 'loop', 3,
sub
#line 151 "Parser.yp"
{ Template::Directive::For->new(@_[3, 1])        }
	],
	[#Rule 52
		 'loop', 3,
sub
#line 153 "Parser.yp"
{ Template::Directive::While->new(@_[3, 1])      }
	],
	[#Rule 53
		 'filter', 5,
sub
#line 157 "Parser.yp"
{ Template::Directive::Filter->new(
				$_[2]->[0], $_[2]->[1], $_[4])   }
	],
	[#Rule 54
		 'filter', 7,
sub
#line 160 "Parser.yp"
{ Template::Directive::Filter->new(
				$_[4]->[0], $_[4]->[1], @_[6,2]) }
	],
	[#Rule 55
		 'filter', 3,
sub
#line 163 "Parser.yp"
{ Template::Directive::Filter->new(
				$_[3]->[0], $_[3]->[1], $_[1])   }
	],
	[#Rule 56
		 'filter', 5,
sub
#line 166 "Parser.yp"
{ Template::Directive::Filter->new(
				$_[5]->[0], $_[5]->[1], @_[1,3]) }
	],
	[#Rule 57
		 'defblock', 5,
sub
#line 171 "Parser.yp"
{ $_[0]->define_block(@_[2, 4]); undef           }
	],
	[#Rule 58
		 'debug', 2,
sub
#line 175 "Parser.yp"
{ Template::Directive::Debug->new($_[2])         }
	],
	[#Rule 59
		 'expr', 3,
sub
#line 183 "Parser.yp"
{ push(@{$_[1]}, @{$_[3]}, OP_AND);
					  $_[1]                             }
	],
	[#Rule 60
		 'expr', 3,
sub
#line 185 "Parser.yp"
{ push(@{$_[1]}, @{$_[3]}, OP_OR);
					  $_[1]                             }
	],
	[#Rule 61
		 'expr', 2,
sub
#line 187 "Parser.yp"
{ push(@{$_[2]}, OP_NOT); 
					  $_[2]                             }
	],
	[#Rule 62
		 'expr', 3,
sub
#line 189 "Parser.yp"
{ $_[2]                             }
	],
	[#Rule 63
		 'expr', 3,
sub
#line 190 "Parser.yp"
{ unshift(@{$_[2]}, OP_TOLERANT,
					    OP_ROOT); $_[2] }
	],
	[#Rule 64
		 'expr', 1,
sub
#line 192 "Parser.yp"
{ unshift(@{$_[1]}, OP_TOLERANT);
					  $_[1]                             }
	],
	[#Rule 65
		 'assign', 3,
sub
#line 196 "Parser.yp"
{ [ @{$_[1]}, @{$_[3]}, OP_ASSIGN ] }
	],
	[#Rule 66
		 'lvalue', 1,
sub
#line 199 "Parser.yp"
{ [ @{ shift @{$_[1]} },
	     				    (map { (OP_LDOT, @$_) } @{$_[1]}), 
					  ]                                 }
	],
	[#Rule 67
		 'lvalue', 2,
sub
#line 202 "Parser.yp"
{ [ @{ shift @{$_[2]} },
	     				    (map { (OP_LDOT, @$_) } @{$_[2]}), 
					  ]                                 }
	],
	[#Rule 68
		 'lvalue', 1,
sub
#line 205 "Parser.yp"
{ [ [$_[1]], OP_LIST ]              }
	],
	[#Rule 69
		 'lvalue', 1,
sub
#line 206 "Parser.yp"
{ [ ['IMPORT'], OP_LIST ]           }
	],
	[#Rule 70
		 'ident', 3,
sub
#line 209 "Parser.yp"
{ push(@{$_[1]}, $_[3]); $_[1]      }
	],
	[#Rule 71
		 'ident', 1,
sub
#line 210 "Parser.yp"
{ [ $_[1] ]                         }
	],
	[#Rule 72
		 'node', 3,
sub
#line 213 "Parser.yp"
{ push(@{$_[2]}, OP_LIST); $_[2]    }
	],
	[#Rule 73
		 'node', 4,
sub
#line 214 "Parser.yp"
{ [ [$_[1]], @{$_[3]}  ]            }
	],
	[#Rule 74
		 'node', 1,
sub
#line 215 "Parser.yp"
{ [ [$_[1]], OP_LIST ]              }
	],
	[#Rule 75
		 'term', 3,
sub
#line 218 "Parser.yp"
{ push(@{$_[1]}, @{$_[3]},
						[$_[2]], OP_BINOP);
					  $_[1]                             }
	],
	[#Rule 76
		 'term', 2,
sub
#line 221 "Parser.yp"
{ [ OP_ROOT, ( map { (@$_, OP_DOT)  }
						@{$_[2]} ) ]                }
	],
	[#Rule 77
		 'term', 1,
sub
#line 223 "Parser.yp"
{ [ OP_ROOT, ( map { (@$_, OP_DOT)  }
						@{$_[1]} ) ]                }
	],
	[#Rule 78
		 'term', 3,
sub
#line 225 "Parser.yp"
{ $_[2]                             }
	],
	[#Rule 79
		 'term', 6,
sub
#line 227 "Parser.yp"
{ push(@{$_[2]}, [ {} ], 
							@{$_[5]}, OP_ITER);
					  $_[2]                             }
	],
	[#Rule 80
		 'term', 3,
sub
#line 230 "Parser.yp"
{ unshift(@{$_[2]}, [ {} ]);
					  $_[2]                             }
	],
	[#Rule 81
		 'term', 3,
sub
#line 232 "Parser.yp"
{ unshift(@{$_[2]}, [ "" ]);
					  $_[2]                             }
	],
	[#Rule 82
		 'term', 1,
sub
#line 234 "Parser.yp"
{ [ [$_[1]] ]                       }
	],
	[#Rule 83
		 'list', 2,
sub
#line 237 "Parser.yp"
{ push(@{$_[1]}, @{$_[2]}, OP_PUSH);
					  $_[1]                             }
	],
	[#Rule 84
		 'list', 2,
sub
#line 239 "Parser.yp"
{ $_[1]                             }
	],
	[#Rule 85
		 'list', 0,
sub
#line 240 "Parser.yp"
{ [ OP_LIST ]                       }
	],
	[#Rule 86
		 'params', 1, undef
	],
	[#Rule 87
		 'params', 0,
sub
#line 244 "Parser.yp"
{ [ ]                               }
	],
	[#Rule 88
		 'nparams', 2,
sub
#line 247 "Parser.yp"
{ push(@{$_[1]}, OP_DUP, 
							@{$_[2]}, OP_POP);
				      	  $_[1]                             }
	],
	[#Rule 89
		 'nparams', 2,
sub
#line 250 "Parser.yp"
{ $_[1]                             }
	],
	[#Rule 90
		 'nparams', 1,
sub
#line 251 "Parser.yp"
{ unshift(@{$_[1]}, OP_DUP);
					  push(@{$_[1]}, OP_POP);
					  $_[1]                             }
	],
	[#Rule 91
		 'setlist', 1,
sub
#line 256 "Parser.yp"
{ unshift(@{$_[1]}, OP_ROOT);
					     push(@{$_[1]}, OP_POP);
					   $_[1]                            }
	],
	[#Rule 92
		 'inclist', 1,
sub
#line 261 "Parser.yp"
{ unshift(@{$_[1]}, OP_ROOT);
					     push(@{$_[1]}, OP_POP);
					   $_[1]                            }
	],
	[#Rule 93
		 'incparam', 2,
sub
#line 266 "Parser.yp"
{ [ OP_ROOT, ( map { (@$_, OP_DOT) }
						@{$_[2]} ) ]                }
	],
	[#Rule 94
		 'incparam', 3,
sub
#line 268 "Parser.yp"
{ unshift(@{$_[2]}, [ "" ]);
					  $_[2]                             }
	],
	[#Rule 95
		 'incparam', 1,
sub
#line 270 "Parser.yp"
{ [ [$_[1]] ]                       }
	],
	[#Rule 96
		 'incparam', 1,
sub
#line 271 "Parser.yp"
{ [ [$_[1]] ]                       }
	],
	[#Rule 97
		 'useparam', 4,
sub
#line 274 "Parser.yp"
{ [ @_[1, 3] ]                      }
	],
	[#Rule 98
		 'useparam', 1,
sub
#line 275 "Parser.yp"
{ [ $_[1] ]                         }
	],
	[#Rule 99
		 'textdot', 3,
sub
#line 278 "Parser.yp"
{ $_[1] .= "$_[2]$_[3]"; $_[1]      }
	],
	[#Rule 100
		 'textdot', 3,
sub
#line 279 "Parser.yp"
{ $_[1] .= "$_[2]$_[3]"; $_[1]      }
	],
	[#Rule 101
		 'textdot', 1, undef
	],
	[#Rule 102
		 'quoted', 2,
sub
#line 283 "Parser.yp"
{ push(@{$_[1]}, @{$_[2]}, OP_CAT)
						if defined $_[2];
					  $_[1]                             }
	],
	[#Rule 103
		 'quoted', 0,
sub
#line 286 "Parser.yp"
{ [  ]                              }
	],
	[#Rule 104
		 'quotable', 1,
sub
#line 289 "Parser.yp"
{ [ OP_ROOT, ( map { (@$_, OP_DOT) } 
						@{$_[1]} ) ]                }
	],
	[#Rule 105
		 'quotable', 1,
sub
#line 291 "Parser.yp"
{ [ [$_[1]] ]                       }
	],
	[#Rule 106
		 'quotable', 1,
sub
#line 292 "Parser.yp"
{ undef }
	]
];



1;












