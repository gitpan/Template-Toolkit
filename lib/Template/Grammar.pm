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
# $Id: Grammar.pm,v 1.21 1999/08/01 13:43:12 abw Exp $
#
#========================================================================

package Template::Grammar;

require 5.004;

use strict;
use vars qw( $VERSION );

use Template::Constants qw( :ops );

$VERSION = sprintf("%d.%02d", q$Revision: 1.21 $ =~ /(\d+)\.(\d+)/);

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
	GET SET DEFAULT IF UNLESS ELSE ELSIF FOR INCLUDE USE
	THROW CATCH ERROR RETURN STOP BLOCK END AND OR NOT
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
#    '/'       => 'END',
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
			'RETURN' => 28,
			'GET' => 1,
			'CATCH' => 29,
			'INCLUDE' => 3,
			'TEXT' => 5,
			'DEFAULT' => 4,
			'STOP' => 7,
			'DEBUG' => 33,
			'FOR' => 9,
			"{" => 34,
			"[" => 13,
			'ERROR' => 35,
			'BLOCK' => 16,
			'SET' => 17,
			'LITERAL' => 40,
			"\${" => 39,
			'USE' => 18,
			'IF' => 42,
			"\"" => 43,
			'SEPARATOR' => -14,
			"\$" => 45,
			'THROW' => 47,
			'IDENT' => 46,
			'UNLESS' => 23
		},
		DEFAULT => -2,
		GOTOS => {
			'return' => 27,
			'get' => 26,
			'catch' => 2,
			'include' => 30,
			'assign' => 31,
			'text' => 6,
			'node' => 32,
			'stop' => 8,
			'debug' => 11,
			'condition' => 10,
			'setlist' => 12,
			'lvalue' => 14,
			'error' => 15,
			'block' => 36,
			'set' => 38,
			'chunks' => 37,
			'use' => 41,
			'atomdir' => 44,
			'nparams' => 19,
			'ident' => 20,
			'throw' => 21,
			'term' => 48,
			'chunk' => 22,
			'loop' => 24,
			'defblock' => 25,
			'directive' => 49
		}
	},
	{#State 1
		ACTIONS => {
			"\"" => 43,
			"{" => 34,
			"[" => 13,
			"\$" => 52,
			'IDENT' => 46,
			"\${" => 39,
			'LITERAL' => 51
		},
		GOTOS => {
			'term' => 53,
			'ident' => 50,
			'node' => 32
		}
	},
	{#State 2
		DEFAULT => -9
	},
	{#State 3
		ACTIONS => {
			"\"" => 57,
			"\$" => 58,
			'IDENT' => 59,
			'LITERAL' => 56
		},
		GOTOS => {
			'incparam' => 54,
			'textdot' => 55
		}
	},
	{#State 4
		ACTIONS => {
			"\$" => 63,
			'IDENT' => 46,
			'LITERAL' => 62,
			"\${" => 39
		},
		GOTOS => {
			'setlist' => 60,
			'lvalue' => 14,
			'nparams' => 19,
			'ident' => 61,
			'assign' => 31,
			'node' => 32
		}
	},
	{#State 5
		DEFAULT => -22
	},
	{#State 6
		DEFAULT => -5
	},
	{#State 7
		DEFAULT => -37
	},
	{#State 8
		DEFAULT => -21
	},
	{#State 9
		ACTIONS => {
			"\"" => 43,
			"{" => 34,
			"[" => 13,
			"\$" => 52,
			'IDENT' => 64,
			"\${" => 39,
			'LITERAL' => 51
		},
		GOTOS => {
			'term' => 65,
			'ident' => 50,
			'node' => 32
		}
	},
	{#State 10
		DEFAULT => -11
	},
	{#State 11
		DEFAULT => -10
	},
	{#State 12
		DEFAULT => -27
	},
	{#State 13
		DEFAULT => -76,
		GOTOS => {
			'list' => 66
		}
	},
	{#State 14
		ACTIONS => {
			'ASSIGN' => 67
		}
	},
	{#State 15
		DEFAULT => -19
	},
	{#State 16
		ACTIONS => {
			'IDENT' => 69
		},
		GOTOS => {
			'textdot' => 68
		}
	},
	{#State 17
		ACTIONS => {
			"\$" => 63,
			'IDENT' => 46,
			'LITERAL' => 62,
			"\${" => 39
		},
		GOTOS => {
			'setlist' => 70,
			'lvalue' => 14,
			'nparams' => 19,
			'ident' => 61,
			'assign' => 31,
			'node' => 32
		}
	},
	{#State 18
		ACTIONS => {
			'IDENT' => 73
		},
		GOTOS => {
			'textdot' => 71,
			'useparam' => 72
		}
	},
	{#State 19
		ACTIONS => {
			"\$" => 63,
			'IDENT' => 46,
			"\${" => 39,
			'LITERAL' => 62,
			'COMMA' => 75
		},
		DEFAULT => -82,
		GOTOS => {
			'lvalue' => 14,
			'ident' => 61,
			'assign' => 74,
			'node' => 32
		}
	},
	{#State 20
		ACTIONS => {
			'ASSIGN' => -58,
			'DOT' => 76
		},
		DEFAULT => -68
	},
	{#State 21
		DEFAULT => -18
	},
	{#State 22
		DEFAULT => -3
	},
	{#State 23
		ACTIONS => {
			"\"" => 43,
			'NOT' => 77,
			"\$" => 52,
			'IDENT' => 46,
			"(" => 79,
			"[" => 13,
			"{" => 34,
			'LITERAL' => 51,
			"\${" => 39
		},
		GOTOS => {
			'term' => 80,
			'ident' => 50,
			'node' => 32,
			'expr' => 78
		}
	},
	{#State 24
		DEFAULT => -12
	},
	{#State 25
		DEFAULT => -13
	},
	{#State 26
		DEFAULT => -15
	},
	{#State 27
		DEFAULT => -20
	},
	{#State 28
		DEFAULT => -36
	},
	{#State 29
		ACTIONS => {
			'SEPARATOR' => 81,
			'IDENT' => 82
		}
	},
	{#State 30
		DEFAULT => -17
	},
	{#State 31
		DEFAULT => -81
	},
	{#State 32
		DEFAULT => -62
	},
	{#State 33
		ACTIONS => {
			'TEXT' => 83
		}
	},
	{#State 34
		ACTIONS => {
			"\$" => 63,
			'IDENT' => 46,
			'LITERAL' => 62,
			"\${" => 39
		},
		DEFAULT => -78,
		GOTOS => {
			'lvalue' => 14,
			'nparams' => 84,
			'params' => 85,
			'ident' => 61,
			'assign' => 31,
			'node' => 32
		}
	},
	{#State 35
		ACTIONS => {
			"\"" => 43,
			"{" => 34,
			"[" => 13,
			"\$" => 52,
			'IDENT' => 46,
			"\${" => 39,
			'LITERAL' => 51
		},
		GOTOS => {
			'term' => 86,
			'ident' => 50,
			'node' => 32
		}
	},
	{#State 36
		ACTIONS => {
			'' => 87
		}
	},
	{#State 37
		ACTIONS => {
			'RETURN' => 28,
			'GET' => 1,
			'CATCH' => 29,
			'INCLUDE' => 3,
			'TEXT' => 5,
			'DEFAULT' => 4,
			'STOP' => 7,
			'DEBUG' => 33,
			'FOR' => 9,
			"{" => 34,
			"[" => 13,
			'ERROR' => 35,
			'BLOCK' => 16,
			'SET' => 17,
			'LITERAL' => 40,
			"\${" => 39,
			'USE' => 18,
			'IF' => 42,
			"\"" => 43,
			'SEPARATOR' => -14,
			"\$" => 45,
			'THROW' => 47,
			'IDENT' => 46,
			'UNLESS' => 23
		},
		DEFAULT => -1,
		GOTOS => {
			'get' => 26,
			'return' => 27,
			'catch' => 2,
			'include' => 30,
			'assign' => 31,
			'text' => 6,
			'node' => 32,
			'stop' => 8,
			'debug' => 11,
			'condition' => 10,
			'setlist' => 12,
			'lvalue' => 14,
			'error' => 15,
			'set' => 38,
			'use' => 41,
			'atomdir' => 44,
			'nparams' => 19,
			'ident' => 20,
			'throw' => 21,
			'term' => 48,
			'chunk' => 88,
			'defblock' => 25,
			'loop' => 24,
			'directive' => 49
		}
	},
	{#State 38
		DEFAULT => -16
	},
	{#State 39
		ACTIONS => {
			"\"" => 43,
			"{" => 34,
			"[" => 13,
			"\$" => 52,
			'IDENT' => 46,
			"\${" => 39,
			'LITERAL' => 51
		},
		GOTOS => {
			'term' => 89,
			'ident' => 50,
			'node' => 32
		}
	},
	{#State 40
		ACTIONS => {
			'ASSIGN' => -60
		},
		DEFAULT => -73
	},
	{#State 41
		DEFAULT => -8
	},
	{#State 42
		ACTIONS => {
			"\"" => 43,
			'NOT' => 77,
			"\$" => 52,
			'IDENT' => 46,
			"(" => 79,
			"[" => 13,
			"{" => 34,
			'LITERAL' => 51,
			"\${" => 39
		},
		GOTOS => {
			'term' => 80,
			'ident' => 50,
			'node' => 32,
			'expr' => 90
		}
	},
	{#State 43
		DEFAULT => -94,
		GOTOS => {
			'quoted' => 91
		}
	},
	{#State 44
		ACTIONS => {
			'UNLESS' => 93,
			'IF' => 94,
			'FOR' => 92
		},
		DEFAULT => -7
	},
	{#State 45
		ACTIONS => {
			'IDENT' => 46,
			"\${" => 39
		},
		GOTOS => {
			'ident' => 95,
			'node' => 32
		}
	},
	{#State 46
		ACTIONS => {
			"(" => 96
		},
		DEFAULT => -65
	},
	{#State 47
		ACTIONS => {
			'IDENT' => 97
		}
	},
	{#State 48
		ACTIONS => {
			'COMPOP' => 98
		},
		DEFAULT => -24
	},
	{#State 49
		ACTIONS => {
			'SEPARATOR' => 99
		}
	},
	{#State 50
		ACTIONS => {
			'DOT' => 76
		},
		DEFAULT => -68
	},
	{#State 51
		DEFAULT => -73
	},
	{#State 52
		ACTIONS => {
			'IDENT' => 46,
			"\${" => 39
		},
		GOTOS => {
			'ident' => 100,
			'node' => 32
		}
	},
	{#State 53
		ACTIONS => {
			'COMPOP' => 98
		},
		DEFAULT => -23
	},
	{#State 54
		ACTIONS => {
			"\$" => 63,
			'IDENT' => 46,
			"\${" => 39,
			'LITERAL' => 62
		},
		DEFAULT => -78,
		GOTOS => {
			'lvalue' => 14,
			'nparams' => 84,
			'params' => 102,
			'ident' => 61,
			'assign' => 31,
			'node' => 32,
			'inclist' => 101
		}
	},
	{#State 55
		ACTIONS => {
			'DOT' => 103,
			"/" => 104
		},
		DEFAULT => -86
	},
	{#State 56
		DEFAULT => -87
	},
	{#State 57
		DEFAULT => -94,
		GOTOS => {
			'quoted' => 105
		}
	},
	{#State 58
		ACTIONS => {
			'IDENT' => 46,
			"\${" => 39
		},
		GOTOS => {
			'ident' => 106,
			'node' => 32
		}
	},
	{#State 59
		ACTIONS => {
			'ASSIGN' => 107
		},
		DEFAULT => -92
	},
	{#State 60
		DEFAULT => -26
	},
	{#State 61
		ACTIONS => {
			'DOT' => 76
		},
		DEFAULT => -58
	},
	{#State 62
		DEFAULT => -60
	},
	{#State 63
		ACTIONS => {
			'IDENT' => 46,
			"\${" => 39
		},
		GOTOS => {
			'ident' => 108,
			'node' => 32
		}
	},
	{#State 64
		ACTIONS => {
			'ASSIGN' => 109,
			"(" => 96
		},
		DEFAULT => -65
	},
	{#State 65
		ACTIONS => {
			'SEPARATOR' => 110,
			'COMPOP' => 98
		}
	},
	{#State 66
		ACTIONS => {
			"\"" => 43,
			"\$" => 52,
			'IDENT' => 46,
			"[" => 13,
			"{" => 34,
			"]" => 111,
			'LITERAL' => 51,
			"\${" => 39,
			'COMMA' => 112
		},
		GOTOS => {
			'term' => 113,
			'ident' => 50,
			'node' => 32
		}
	},
	{#State 67
		ACTIONS => {
			"\"" => 43,
			"{" => 34,
			"[" => 13,
			"\$" => 52,
			'IDENT' => 46,
			"\${" => 39,
			'LITERAL' => 51
		},
		GOTOS => {
			'term' => 114,
			'ident' => 50,
			'node' => 32
		}
	},
	{#State 68
		ACTIONS => {
			'SEPARATOR' => 115,
			"/" => 104,
			'DOT' => 103
		}
	},
	{#State 69
		DEFAULT => -92
	},
	{#State 70
		DEFAULT => -25
	},
	{#State 71
		ACTIONS => {
			"/" => 104,
			"(" => 116,
			'DOT' => 103
		},
		DEFAULT => -89
	},
	{#State 72
		DEFAULT => -30
	},
	{#State 73
		ACTIONS => {
			'ASSIGN' => 117
		},
		DEFAULT => -92
	},
	{#State 74
		DEFAULT => -79
	},
	{#State 75
		DEFAULT => -80
	},
	{#State 76
		ACTIONS => {
			'IDENT' => 46,
			"\${" => 39
		},
		GOTOS => {
			'node' => 118
		}
	},
	{#State 77
		ACTIONS => {
			"\"" => 43,
			'NOT' => 77,
			"\$" => 52,
			'IDENT' => 46,
			"(" => 79,
			"[" => 13,
			"{" => 34,
			'LITERAL' => 51,
			"\${" => 39
		},
		GOTOS => {
			'term' => 80,
			'ident' => 50,
			'node' => 32,
			'expr' => 119
		}
	},
	{#State 78
		ACTIONS => {
			'SEPARATOR' => 122,
			'OR' => 120,
			'AND' => 121
		}
	},
	{#State 79
		ACTIONS => {
			"\"" => 43,
			'NOT' => 77,
			"\$" => 45,
			'IDENT' => 46,
			"(" => 79,
			"[" => 13,
			"{" => 34,
			"\${" => 39,
			'LITERAL' => 40
		},
		GOTOS => {
			'term' => 80,
			'lvalue' => 14,
			'ident' => 20,
			'assign' => 124,
			'node' => 32,
			'expr' => 123
		}
	},
	{#State 80
		ACTIONS => {
			'COMPOP' => 98
		},
		DEFAULT => -56
	},
	{#State 81
		ACTIONS => {
			'RETURN' => 28,
			'GET' => 1,
			'CATCH' => 29,
			'INCLUDE' => 3,
			'TEXT' => 5,
			'DEFAULT' => 4,
			'STOP' => 7,
			'DEBUG' => 33,
			'FOR' => 9,
			"{" => 34,
			"[" => 13,
			'ERROR' => 35,
			'BLOCK' => 16,
			'SET' => 17,
			'LITERAL' => 40,
			"\${" => 39,
			'USE' => 18,
			'IF' => 42,
			"\"" => 43,
			'SEPARATOR' => -14,
			"\$" => 45,
			'THROW' => 47,
			'IDENT' => 46,
			'UNLESS' => 23
		},
		DEFAULT => -2,
		GOTOS => {
			'get' => 26,
			'return' => 27,
			'catch' => 2,
			'include' => 30,
			'assign' => 31,
			'text' => 6,
			'node' => 32,
			'stop' => 8,
			'debug' => 11,
			'condition' => 10,
			'setlist' => 12,
			'lvalue' => 14,
			'error' => 15,
			'block' => 125,
			'chunks' => 37,
			'set' => 38,
			'use' => 41,
			'atomdir' => 44,
			'nparams' => 19,
			'ident' => 20,
			'throw' => 21,
			'term' => 48,
			'chunk' => 22,
			'defblock' => 25,
			'loop' => 24,
			'directive' => 49
		}
	},
	{#State 82
		ACTIONS => {
			'SEPARATOR' => 126
		}
	},
	{#State 83
		DEFAULT => -50
	},
	{#State 84
		ACTIONS => {
			"\$" => 63,
			'IDENT' => 46,
			"\${" => 39,
			'LITERAL' => 62,
			'COMMA' => 75
		},
		DEFAULT => -77,
		GOTOS => {
			'lvalue' => 14,
			'ident' => 61,
			'assign' => 74,
			'node' => 32
		}
	},
	{#State 85
		ACTIONS => {
			"}" => 127
		}
	},
	{#State 86
		ACTIONS => {
			'COMPOP' => 98
		},
		DEFAULT => -35
	},
	{#State 87
		DEFAULT => -0
	},
	{#State 88
		DEFAULT => -4
	},
	{#State 89
		ACTIONS => {
			"}" => 128,
			'COMPOP' => 98
		}
	},
	{#State 90
		ACTIONS => {
			'SEPARATOR' => 129,
			'OR' => 120,
			'AND' => 121
		}
	},
	{#State 91
		ACTIONS => {
			"\"" => 132,
			'SEPARATOR' => 133,
			'IDENT' => 46,
			"\${" => 39,
			'TEXT' => 130
		},
		GOTOS => {
			'ident' => 131,
			'quotable' => 134,
			'node' => 32
		}
	},
	{#State 92
		ACTIONS => {
			"\"" => 43,
			"{" => 34,
			"[" => 13,
			"\$" => 52,
			'IDENT' => 135,
			"\${" => 39,
			'LITERAL' => 51
		},
		GOTOS => {
			'term' => 136,
			'ident' => 50,
			'node' => 32
		}
	},
	{#State 93
		ACTIONS => {
			"\"" => 43,
			'NOT' => 77,
			"\$" => 52,
			'IDENT' => 46,
			"(" => 79,
			"[" => 13,
			"{" => 34,
			'LITERAL' => 51,
			"\${" => 39
		},
		GOTOS => {
			'term' => 80,
			'ident' => 50,
			'node' => 32,
			'expr' => 137
		}
	},
	{#State 94
		ACTIONS => {
			"\"" => 43,
			'NOT' => 77,
			"\$" => 52,
			'IDENT' => 46,
			"(" => 79,
			"[" => 13,
			"{" => 34,
			'LITERAL' => 51,
			"\${" => 39
		},
		GOTOS => {
			'term' => 80,
			'ident' => 50,
			'node' => 32,
			'expr' => 138
		}
	},
	{#State 95
		ACTIONS => {
			'ASSIGN' => -59,
			'DOT' => 76
		},
		DEFAULT => -67
	},
	{#State 96
		DEFAULT => -76,
		GOTOS => {
			'list' => 139
		}
	},
	{#State 97
		ACTIONS => {
			"\"" => 43,
			"{" => 34,
			"[" => 13,
			"\$" => 52,
			'IDENT' => 46,
			"\${" => 39,
			'LITERAL' => 51
		},
		GOTOS => {
			'term' => 140,
			'ident' => 50,
			'node' => 32
		}
	},
	{#State 98
		ACTIONS => {
			"\"" => 43,
			"{" => 34,
			"[" => 13,
			"\$" => 52,
			'IDENT' => 46,
			"\${" => 39,
			'LITERAL' => 51
		},
		GOTOS => {
			'term' => 141,
			'ident' => 50,
			'node' => 32
		}
	},
	{#State 99
		DEFAULT => -6
	},
	{#State 100
		ACTIONS => {
			'DOT' => 76
		},
		DEFAULT => -67
	},
	{#State 101
		DEFAULT => -28
	},
	{#State 102
		DEFAULT => -83
	},
	{#State 103
		ACTIONS => {
			'IDENT' => 142
		}
	},
	{#State 104
		ACTIONS => {
			'IDENT' => 143
		}
	},
	{#State 105
		ACTIONS => {
			"\"" => 144,
			'SEPARATOR' => 133,
			'IDENT' => 46,
			"\${" => 39,
			'TEXT' => 130
		},
		GOTOS => {
			'ident' => 131,
			'quotable' => 134,
			'node' => 32
		}
	},
	{#State 106
		ACTIONS => {
			'DOT' => 76
		},
		DEFAULT => -84
	},
	{#State 107
		ACTIONS => {
			"\"" => 57,
			"\$" => 58,
			'IDENT' => 69,
			'LITERAL' => 56
		},
		GOTOS => {
			'incparam' => 145,
			'textdot' => 55
		}
	},
	{#State 108
		ACTIONS => {
			'DOT' => 76
		},
		DEFAULT => -59
	},
	{#State 109
		ACTIONS => {
			"\"" => 43,
			"{" => 34,
			"[" => 13,
			"\$" => 52,
			'IDENT' => 46,
			"\${" => 39,
			'LITERAL' => 51
		},
		GOTOS => {
			'term' => 146,
			'ident' => 50,
			'node' => 32
		}
	},
	{#State 110
		ACTIONS => {
			'RETURN' => 28,
			'GET' => 1,
			'CATCH' => 29,
			'INCLUDE' => 3,
			'TEXT' => 5,
			'DEFAULT' => 4,
			'STOP' => 7,
			'DEBUG' => 33,
			'FOR' => 9,
			"{" => 34,
			"[" => 13,
			'ERROR' => 35,
			'BLOCK' => 16,
			'SET' => 17,
			'LITERAL' => 40,
			"\${" => 39,
			'USE' => 18,
			'IF' => 42,
			"\"" => 43,
			'SEPARATOR' => -14,
			"\$" => 45,
			'THROW' => 47,
			'IDENT' => 46,
			'UNLESS' => 23
		},
		DEFAULT => -2,
		GOTOS => {
			'get' => 26,
			'return' => 27,
			'catch' => 2,
			'include' => 30,
			'assign' => 31,
			'text' => 6,
			'node' => 32,
			'stop' => 8,
			'debug' => 11,
			'condition' => 10,
			'setlist' => 12,
			'lvalue' => 14,
			'error' => 15,
			'block' => 147,
			'chunks' => 37,
			'set' => 38,
			'use' => 41,
			'atomdir' => 44,
			'nparams' => 19,
			'ident' => 20,
			'throw' => 21,
			'term' => 48,
			'chunk' => 22,
			'defblock' => 25,
			'loop' => 24,
			'directive' => 49
		}
	},
	{#State 111
		ACTIONS => {
			"(" => 148
		},
		DEFAULT => -69
	},
	{#State 112
		DEFAULT => -75
	},
	{#State 113
		ACTIONS => {
			'COMPOP' => 98
		},
		DEFAULT => -74
	},
	{#State 114
		ACTIONS => {
			'COMPOP' => 98
		},
		DEFAULT => -57
	},
	{#State 115
		ACTIONS => {
			'RETURN' => 28,
			'GET' => 1,
			'CATCH' => 29,
			'INCLUDE' => 3,
			'TEXT' => 5,
			'DEFAULT' => 4,
			'STOP' => 7,
			'DEBUG' => 33,
			'FOR' => 9,
			"{" => 34,
			"[" => 13,
			'ERROR' => 35,
			'BLOCK' => 16,
			'SET' => 17,
			'LITERAL' => 40,
			"\${" => 39,
			'USE' => 18,
			'IF' => 42,
			"\"" => 43,
			'SEPARATOR' => -14,
			"\$" => 45,
			'THROW' => 47,
			'IDENT' => 46,
			'UNLESS' => 23
		},
		DEFAULT => -2,
		GOTOS => {
			'get' => 26,
			'return' => 27,
			'catch' => 2,
			'include' => 30,
			'assign' => 31,
			'text' => 6,
			'node' => 32,
			'stop' => 8,
			'debug' => 11,
			'condition' => 10,
			'setlist' => 12,
			'lvalue' => 14,
			'error' => 15,
			'block' => 149,
			'chunks' => 37,
			'set' => 38,
			'use' => 41,
			'atomdir' => 44,
			'nparams' => 19,
			'ident' => 20,
			'throw' => 21,
			'term' => 48,
			'chunk' => 22,
			'defblock' => 25,
			'loop' => 24,
			'directive' => 49
		}
	},
	{#State 116
		DEFAULT => -76,
		GOTOS => {
			'list' => 150
		}
	},
	{#State 117
		ACTIONS => {
			'IDENT' => 69
		},
		GOTOS => {
			'textdot' => 71,
			'useparam' => 151
		}
	},
	{#State 118
		DEFAULT => -61
	},
	{#State 119
		ACTIONS => {
			'OR' => 120,
			'AND' => 121
		},
		DEFAULT => -53
	},
	{#State 120
		ACTIONS => {
			"\"" => 43,
			'NOT' => 77,
			"\$" => 52,
			'IDENT' => 46,
			"(" => 79,
			"[" => 13,
			"{" => 34,
			'LITERAL' => 51,
			"\${" => 39
		},
		GOTOS => {
			'term' => 80,
			'ident' => 50,
			'node' => 32,
			'expr' => 152
		}
	},
	{#State 121
		ACTIONS => {
			"\"" => 43,
			'NOT' => 77,
			"\$" => 52,
			'IDENT' => 46,
			"(" => 79,
			"[" => 13,
			"{" => 34,
			'LITERAL' => 51,
			"\${" => 39
		},
		GOTOS => {
			'term' => 80,
			'ident' => 50,
			'node' => 32,
			'expr' => 153
		}
	},
	{#State 122
		ACTIONS => {
			'RETURN' => 28,
			'GET' => 1,
			'CATCH' => 29,
			'INCLUDE' => 3,
			'TEXT' => 5,
			'DEFAULT' => 4,
			'STOP' => 7,
			'DEBUG' => 33,
			'FOR' => 9,
			"{" => 34,
			"[" => 13,
			'ERROR' => 35,
			'BLOCK' => 16,
			'SET' => 17,
			'LITERAL' => 40,
			"\${" => 39,
			'USE' => 18,
			'IF' => 42,
			"\"" => 43,
			'SEPARATOR' => -14,
			"\$" => 45,
			'THROW' => 47,
			'IDENT' => 46,
			'UNLESS' => 23
		},
		DEFAULT => -2,
		GOTOS => {
			'get' => 26,
			'return' => 27,
			'catch' => 2,
			'include' => 30,
			'assign' => 31,
			'text' => 6,
			'node' => 32,
			'stop' => 8,
			'debug' => 11,
			'condition' => 10,
			'setlist' => 12,
			'lvalue' => 14,
			'error' => 15,
			'block' => 154,
			'chunks' => 37,
			'set' => 38,
			'use' => 41,
			'atomdir' => 44,
			'nparams' => 19,
			'ident' => 20,
			'throw' => 21,
			'term' => 48,
			'chunk' => 22,
			'defblock' => 25,
			'loop' => 24,
			'directive' => 49
		}
	},
	{#State 123
		ACTIONS => {
			'OR' => 120,
			'AND' => 121,
			")" => 155
		}
	},
	{#State 124
		ACTIONS => {
			")" => 156
		}
	},
	{#State 125
		ACTIONS => {
			'END' => 157
		}
	},
	{#State 126
		ACTIONS => {
			'RETURN' => 28,
			'GET' => 1,
			'CATCH' => 29,
			'INCLUDE' => 3,
			'TEXT' => 5,
			'DEFAULT' => 4,
			'STOP' => 7,
			'DEBUG' => 33,
			'FOR' => 9,
			"{" => 34,
			"[" => 13,
			'ERROR' => 35,
			'BLOCK' => 16,
			'SET' => 17,
			'LITERAL' => 40,
			"\${" => 39,
			'USE' => 18,
			'IF' => 42,
			"\"" => 43,
			'SEPARATOR' => -14,
			"\$" => 45,
			'THROW' => 47,
			'IDENT' => 46,
			'UNLESS' => 23
		},
		DEFAULT => -2,
		GOTOS => {
			'get' => 26,
			'return' => 27,
			'catch' => 2,
			'include' => 30,
			'assign' => 31,
			'text' => 6,
			'node' => 32,
			'stop' => 8,
			'debug' => 11,
			'condition' => 10,
			'setlist' => 12,
			'lvalue' => 14,
			'error' => 15,
			'block' => 158,
			'chunks' => 37,
			'set' => 38,
			'use' => 41,
			'atomdir' => 44,
			'nparams' => 19,
			'ident' => 20,
			'throw' => 21,
			'term' => 48,
			'chunk' => 22,
			'defblock' => 25,
			'loop' => 24,
			'directive' => 49
		}
	},
	{#State 127
		DEFAULT => -71
	},
	{#State 128
		DEFAULT => -63
	},
	{#State 129
		ACTIONS => {
			'RETURN' => 28,
			'GET' => 1,
			'CATCH' => 29,
			'INCLUDE' => 3,
			'TEXT' => 5,
			'DEFAULT' => 4,
			'STOP' => 7,
			'DEBUG' => 33,
			'FOR' => 9,
			"{" => 34,
			"[" => 13,
			'ERROR' => 35,
			'BLOCK' => 16,
			'SET' => 17,
			'LITERAL' => 40,
			"\${" => 39,
			'USE' => 18,
			'IF' => 42,
			"\"" => 43,
			'SEPARATOR' => -14,
			"\$" => 45,
			'THROW' => 47,
			'IDENT' => 46,
			'UNLESS' => 23
		},
		DEFAULT => -2,
		GOTOS => {
			'get' => 26,
			'return' => 27,
			'catch' => 2,
			'include' => 30,
			'assign' => 31,
			'text' => 6,
			'node' => 32,
			'stop' => 8,
			'debug' => 11,
			'condition' => 10,
			'setlist' => 12,
			'lvalue' => 14,
			'error' => 15,
			'block' => 159,
			'chunks' => 37,
			'set' => 38,
			'use' => 41,
			'atomdir' => 44,
			'nparams' => 19,
			'ident' => 20,
			'throw' => 21,
			'term' => 48,
			'chunk' => 22,
			'defblock' => 25,
			'loop' => 24,
			'directive' => 49
		}
	},
	{#State 130
		DEFAULT => -96
	},
	{#State 131
		ACTIONS => {
			'DOT' => 76
		},
		DEFAULT => -95
	},
	{#State 132
		DEFAULT => -72
	},
	{#State 133
		DEFAULT => -97
	},
	{#State 134
		DEFAULT => -93
	},
	{#State 135
		ACTIONS => {
			'ASSIGN' => 160,
			"(" => 96
		},
		DEFAULT => -65
	},
	{#State 136
		ACTIONS => {
			'COMPOP' => 98
		},
		DEFAULT => -48
	},
	{#State 137
		ACTIONS => {
			'OR' => 120,
			'AND' => 121
		},
		DEFAULT => -41
	},
	{#State 138
		ACTIONS => {
			'OR' => 120,
			'AND' => 121
		},
		DEFAULT => -40
	},
	{#State 139
		ACTIONS => {
			"\"" => 43,
			"\$" => 52,
			'IDENT' => 46,
			")" => 161,
			"[" => 13,
			"{" => 34,
			'LITERAL' => 51,
			"\${" => 39,
			'COMMA' => 112
		},
		GOTOS => {
			'term' => 113,
			'ident' => 50,
			'node' => 32
		}
	},
	{#State 140
		ACTIONS => {
			'COMPOP' => 98
		},
		DEFAULT => -32
	},
	{#State 141
		DEFAULT => -66
	},
	{#State 142
		DEFAULT => -90
	},
	{#State 143
		DEFAULT => -91
	},
	{#State 144
		DEFAULT => -85
	},
	{#State 145
		ACTIONS => {
			"\$" => 63,
			'IDENT' => 46,
			"\${" => 39,
			'LITERAL' => 62
		},
		DEFAULT => -78,
		GOTOS => {
			'lvalue' => 14,
			'nparams' => 84,
			'params' => 102,
			'ident' => 61,
			'assign' => 31,
			'node' => 32,
			'inclist' => 162
		}
	},
	{#State 146
		ACTIONS => {
			'SEPARATOR' => 163,
			'COMPOP' => 98
		}
	},
	{#State 147
		ACTIONS => {
			'END' => 164
		}
	},
	{#State 148
		ACTIONS => {
			"\$" => 63,
			'IDENT' => 46,
			'LITERAL' => 62,
			"\${" => 39
		},
		DEFAULT => -78,
		GOTOS => {
			'lvalue' => 14,
			'nparams' => 84,
			'params' => 165,
			'ident' => 61,
			'assign' => 31,
			'node' => 32
		}
	},
	{#State 149
		ACTIONS => {
			'END' => 166
		}
	},
	{#State 150
		ACTIONS => {
			"\"" => 43,
			"\$" => 52,
			'IDENT' => 46,
			")" => 167,
			"[" => 13,
			"{" => 34,
			'LITERAL' => 51,
			"\${" => 39,
			'COMMA' => 112
		},
		GOTOS => {
			'term' => 113,
			'ident' => 50,
			'node' => 32
		}
	},
	{#State 151
		DEFAULT => -31
	},
	{#State 152
		DEFAULT => -52
	},
	{#State 153
		ACTIONS => {
			'OR' => 120
		},
		DEFAULT => -51
	},
	{#State 154
		ACTIONS => {
			'ELSE' => 169,
			'ELSIF' => 168
		},
		DEFAULT => -42,
		GOTOS => {
			'else' => 170
		}
	},
	{#State 155
		DEFAULT => -54
	},
	{#State 156
		DEFAULT => -55
	},
	{#State 157
		DEFAULT => -34
	},
	{#State 158
		ACTIONS => {
			'END' => 171
		}
	},
	{#State 159
		ACTIONS => {
			'ELSE' => 169,
			'ELSIF' => 168
		},
		DEFAULT => -42,
		GOTOS => {
			'else' => 172
		}
	},
	{#State 160
		ACTIONS => {
			"\"" => 43,
			"{" => 34,
			"[" => 13,
			"\$" => 52,
			'IDENT' => 46,
			"\${" => 39,
			'LITERAL' => 51
		},
		GOTOS => {
			'term' => 173,
			'ident' => 50,
			'node' => 32
		}
	},
	{#State 161
		DEFAULT => -64
	},
	{#State 162
		DEFAULT => -29
	},
	{#State 163
		ACTIONS => {
			'RETURN' => 28,
			'GET' => 1,
			'CATCH' => 29,
			'INCLUDE' => 3,
			'TEXT' => 5,
			'DEFAULT' => 4,
			'STOP' => 7,
			'DEBUG' => 33,
			'FOR' => 9,
			"{" => 34,
			"[" => 13,
			'ERROR' => 35,
			'BLOCK' => 16,
			'SET' => 17,
			'LITERAL' => 40,
			"\${" => 39,
			'USE' => 18,
			'IF' => 42,
			"\"" => 43,
			'SEPARATOR' => -14,
			"\$" => 45,
			'THROW' => 47,
			'IDENT' => 46,
			'UNLESS' => 23
		},
		DEFAULT => -2,
		GOTOS => {
			'get' => 26,
			'return' => 27,
			'catch' => 2,
			'include' => 30,
			'assign' => 31,
			'text' => 6,
			'node' => 32,
			'stop' => 8,
			'debug' => 11,
			'condition' => 10,
			'setlist' => 12,
			'lvalue' => 14,
			'error' => 15,
			'block' => 174,
			'chunks' => 37,
			'set' => 38,
			'use' => 41,
			'atomdir' => 44,
			'nparams' => 19,
			'ident' => 20,
			'throw' => 21,
			'term' => 48,
			'chunk' => 22,
			'defblock' => 25,
			'loop' => 24,
			'directive' => 49
		}
	},
	{#State 164
		DEFAULT => -46
	},
	{#State 165
		ACTIONS => {
			")" => 175
		}
	},
	{#State 166
		DEFAULT => -49
	},
	{#State 167
		DEFAULT => -88
	},
	{#State 168
		ACTIONS => {
			"\"" => 43,
			'NOT' => 77,
			"\$" => 52,
			'IDENT' => 46,
			"(" => 79,
			"[" => 13,
			"{" => 34,
			'LITERAL' => 51,
			"\${" => 39
		},
		GOTOS => {
			'term' => 80,
			'ident' => 50,
			'node' => 32,
			'expr' => 176
		}
	},
	{#State 169
		ACTIONS => {
			'SEPARATOR' => 177
		}
	},
	{#State 170
		ACTIONS => {
			'END' => 178
		}
	},
	{#State 171
		DEFAULT => -33
	},
	{#State 172
		ACTIONS => {
			'END' => 179
		}
	},
	{#State 173
		ACTIONS => {
			'COMPOP' => 98
		},
		DEFAULT => -47
	},
	{#State 174
		ACTIONS => {
			'END' => 180
		}
	},
	{#State 175
		DEFAULT => -70
	},
	{#State 176
		ACTIONS => {
			'SEPARATOR' => 181,
			'OR' => 120,
			'AND' => 121
		}
	},
	{#State 177
		ACTIONS => {
			'RETURN' => 28,
			'GET' => 1,
			'CATCH' => 29,
			'INCLUDE' => 3,
			'TEXT' => 5,
			'DEFAULT' => 4,
			'STOP' => 7,
			'DEBUG' => 33,
			'FOR' => 9,
			"{" => 34,
			"[" => 13,
			'ERROR' => 35,
			'BLOCK' => 16,
			'SET' => 17,
			'LITERAL' => 40,
			"\${" => 39,
			'USE' => 18,
			'IF' => 42,
			"\"" => 43,
			'SEPARATOR' => -14,
			"\$" => 45,
			'THROW' => 47,
			'IDENT' => 46,
			'UNLESS' => 23
		},
		DEFAULT => -2,
		GOTOS => {
			'get' => 26,
			'return' => 27,
			'catch' => 2,
			'include' => 30,
			'assign' => 31,
			'text' => 6,
			'node' => 32,
			'stop' => 8,
			'debug' => 11,
			'condition' => 10,
			'setlist' => 12,
			'lvalue' => 14,
			'error' => 15,
			'block' => 182,
			'chunks' => 37,
			'set' => 38,
			'use' => 41,
			'atomdir' => 44,
			'nparams' => 19,
			'ident' => 20,
			'throw' => 21,
			'term' => 48,
			'chunk' => 22,
			'defblock' => 25,
			'loop' => 24,
			'directive' => 49
		}
	},
	{#State 178
		DEFAULT => -39
	},
	{#State 179
		DEFAULT => -38
	},
	{#State 180
		DEFAULT => -45
	},
	{#State 181
		ACTIONS => {
			'RETURN' => 28,
			'GET' => 1,
			'CATCH' => 29,
			'INCLUDE' => 3,
			'TEXT' => 5,
			'DEFAULT' => 4,
			'STOP' => 7,
			'DEBUG' => 33,
			'FOR' => 9,
			"{" => 34,
			"[" => 13,
			'ERROR' => 35,
			'BLOCK' => 16,
			'SET' => 17,
			'LITERAL' => 40,
			"\${" => 39,
			'USE' => 18,
			'IF' => 42,
			"\"" => 43,
			'SEPARATOR' => -14,
			"\$" => 45,
			'THROW' => 47,
			'IDENT' => 46,
			'UNLESS' => 23
		},
		DEFAULT => -2,
		GOTOS => {
			'get' => 26,
			'return' => 27,
			'catch' => 2,
			'include' => 30,
			'assign' => 31,
			'text' => 6,
			'node' => 32,
			'stop' => 8,
			'debug' => 11,
			'condition' => 10,
			'setlist' => 12,
			'lvalue' => 14,
			'error' => 15,
			'block' => 183,
			'chunks' => 37,
			'set' => 38,
			'use' => 41,
			'atomdir' => 44,
			'nparams' => 19,
			'ident' => 20,
			'throw' => 21,
			'term' => 48,
			'chunk' => 22,
			'defblock' => 25,
			'loop' => 24,
			'directive' => 49
		}
	},
	{#State 182
		DEFAULT => -43
	},
	{#State 183
		ACTIONS => {
			'ELSE' => 169,
			'ELSIF' => 168
		},
		DEFAULT => -42,
		GOTOS => {
			'else' => 184
		}
	},
	{#State 184
		DEFAULT => -44
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
		 'directive', 0, undef
	],
	[#Rule 15
		 'atomdir', 1, undef
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
		 'set', 1,
sub
#line 78 "Parser.yp"
{ Template::Directive->new($_[1])                }
	],
	[#Rule 28
		 'include', 3,
sub
#line 82 "Parser.yp"
{ Template::Directive::Include->new(@_[2, 3])    }
	],
	[#Rule 29
		 'include', 5,
sub
#line 85 "Parser.yp"
{ Template::Directive::Include->new(@_[4, 5, 2]) }
	],
	[#Rule 30
		 'use', 2,
sub
#line 89 "Parser.yp"
{ Template::Directive::Use->new(@{$_[2]})        }
	],
	[#Rule 31
		 'use', 4,
sub
#line 91 "Parser.yp"
{ Template::Directive::Use->new($_[4]->[0], 
						$_[4]->[1], $_[2])       }
	],
	[#Rule 32
		 'throw', 3,
sub
#line 96 "Parser.yp"
{ Template::Directive::Throw->new(@_[2, 3])      }
	],
	[#Rule 33
		 'catch', 5,
sub
#line 100 "Parser.yp"
{ Template::Directive::Catch->new(@_[2, 4])      }
	],
	[#Rule 34
		 'catch', 4,
sub
#line 102 "Parser.yp"
{ Template::Directive::Catch->new(undef, $_[3])  }
	],
	[#Rule 35
		 'error', 2,
sub
#line 106 "Parser.yp"
{ Template::Directive::Error->new($_[2])         }
	],
	[#Rule 36
		 'return', 1,
sub
#line 109 "Parser.yp"
{ Template::Directive::Return->new(
			      Template::Constants::STATUS_RETURN)        }
	],
	[#Rule 37
		 'stop', 1,
sub
#line 113 "Parser.yp"
{ Template::Directive::Return->new(
			      Template::Constants::STATUS_STOP)          }
	],
	[#Rule 38
		 'condition', 6,
sub
#line 118 "Parser.yp"
{ Template::Directive::If->new(@_[2, 4, 5])      }
	],
	[#Rule 39
		 'condition', 6,
sub
#line 120 "Parser.yp"
{ push(@{ $_[2] }, OP_NOT);   # negate expression
			  Template::Directive::If->new(@_[2, 4, 5])      }
	],
	[#Rule 40
		 'condition', 3,
sub
#line 123 "Parser.yp"
{ Template::Directive::If->new(@_[3, 1])         }
	],
	[#Rule 41
		 'condition', 3,
sub
#line 125 "Parser.yp"
{ push(@{ $_[3] }, OP_NOT);   # negate expression
			  Template::Directive::If->new(@_[3, 1])         }
	],
	[#Rule 42
		 'else', 0,
sub
#line 130 "Parser.yp"
{ undef }
	],
	[#Rule 43
		 'else', 3,
sub
#line 132 "Parser.yp"
{ $_[3] }
	],
	[#Rule 44
		 'else', 5,
sub
#line 134 "Parser.yp"
{ Template::Directive::If->new(@_[2, 4, 5])      }
	],
	[#Rule 45
		 'loop', 7,
sub
#line 138 "Parser.yp"
{ Template::Directive::For->new(@_[4, 6, 2])     }
	],
	[#Rule 46
		 'loop', 5,
sub
#line 140 "Parser.yp"
{ Template::Directive::For->new(@_[2, 4])        }
	],
	[#Rule 47
		 'loop', 5,
sub
#line 142 "Parser.yp"
{ Template::Directive::For->new(@_[5, 1, 3])     }
	],
	[#Rule 48
		 'loop', 3,
sub
#line 144 "Parser.yp"
{ Template::Directive::For->new(@_[3, 1])        }
	],
	[#Rule 49
		 'defblock', 5,
sub
#line 149 "Parser.yp"
{ $_[0]->define_block(@_[2, 4]); undef           }
	],
	[#Rule 50
		 'debug', 2,
sub
#line 153 "Parser.yp"
{ Template::Directive::Debug->new($_[2])         }
	],
	[#Rule 51
		 'expr', 3,
sub
#line 161 "Parser.yp"
{ push(@{$_[1]}, @{$_[3]}, OP_AND);
					  $_[1]                             }
	],
	[#Rule 52
		 'expr', 3,
sub
#line 163 "Parser.yp"
{ push(@{$_[1]}, @{$_[3]}, OP_OR);
					  $_[1]                             }
	],
	[#Rule 53
		 'expr', 2,
sub
#line 165 "Parser.yp"
{ push(@{$_[2]}, OP_NOT); 
					  $_[2]                             }
	],
	[#Rule 54
		 'expr', 3,
sub
#line 167 "Parser.yp"
{ $_[2]                             }
	],
	[#Rule 55
		 'expr', 3,
sub
#line 168 "Parser.yp"
{ unshift(@{$_[2]}, OP_ROOT); $_[2] }
	],
	[#Rule 56
		 'expr', 1,
sub
#line 169 "Parser.yp"
{ unshift(@{$_[1]}, OP_TOLERANT);
					  $_[1]                             }
	],
	[#Rule 57
		 'assign', 3,
sub
#line 173 "Parser.yp"
{ [ @{$_[1]}, @{$_[3]}, 
								OP_ASSIGN ] }
	],
	[#Rule 58
		 'lvalue', 1,
sub
#line 177 "Parser.yp"
{ [ @{ shift @{$_[1]} },
	     				    (map { (OP_LDOT, @$_) } @{$_[1]}), 
					  ]                                 }
	],
	[#Rule 59
		 'lvalue', 2,
sub
#line 180 "Parser.yp"
{ [ @{ shift @{$_[2]} },
	     				    (map { (OP_LDOT, @$_) } @{$_[2]}), 
					  ]                                 }
	],
	[#Rule 60
		 'lvalue', 1,
sub
#line 183 "Parser.yp"
{ [ [$_[1]], OP_LIST ]              }
	],
	[#Rule 61
		 'ident', 3,
sub
#line 186 "Parser.yp"
{ push(@{$_[1]}, $_[3]); $_[1]      }
	],
	[#Rule 62
		 'ident', 1,
sub
#line 187 "Parser.yp"
{ [ $_[1] ]                         }
	],
	[#Rule 63
		 'node', 3,
sub
#line 190 "Parser.yp"
{ push(@{$_[2]}, OP_LIST); $_[2]    }
	],
	[#Rule 64
		 'node', 4,
sub
#line 191 "Parser.yp"
{ [ [$_[1]], @{$_[3]}  ]            }
	],
	[#Rule 65
		 'node', 1,
sub
#line 192 "Parser.yp"
{ [ [$_[1]], OP_LIST ]              }
	],
	[#Rule 66
		 'term', 3,
sub
#line 195 "Parser.yp"
{ push(@{$_[1]}, @{$_[3]},
						[$_[2]], OP_BINOP);
					  $_[1]                             }
	],
	[#Rule 67
		 'term', 2,
sub
#line 198 "Parser.yp"
{ [ OP_ROOT, ( map { (@$_, OP_DOT)  }
						@{$_[2]} ) ]                }
	],
	[#Rule 68
		 'term', 1,
sub
#line 200 "Parser.yp"
{ [ OP_ROOT, ( map { (@$_, OP_DOT)  }
						@{$_[1]} ) ]                }
	],
	[#Rule 69
		 'term', 3,
sub
#line 202 "Parser.yp"
{ $_[2]                             }
	],
	[#Rule 70
		 'term', 6,
sub
#line 204 "Parser.yp"
{ push(@{$_[2]}, [ {} ], 
							@{$_[5]}, OP_ITER);
					  $_[2]                             }
	],
	[#Rule 71
		 'term', 3,
sub
#line 207 "Parser.yp"
{ unshift(@{$_[2]}, [ {} ]);
					  $_[2]                             }
	],
	[#Rule 72
		 'term', 3,
sub
#line 209 "Parser.yp"
{ unshift(@{$_[2]}, [ "" ]);
					  $_[2]                             }
	],
	[#Rule 73
		 'term', 1,
sub
#line 211 "Parser.yp"
{ [ [$_[1]] ]                       }
	],
	[#Rule 74
		 'list', 2,
sub
#line 214 "Parser.yp"
{ push(@{$_[1]}, @{$_[2]}, OP_PUSH);
					  $_[1]                             }
	],
	[#Rule 75
		 'list', 2,
sub
#line 216 "Parser.yp"
{ $_[1]                             }
	],
	[#Rule 76
		 'list', 0,
sub
#line 217 "Parser.yp"
{ [ OP_LIST ]                       }
	],
	[#Rule 77
		 'params', 1, undef
	],
	[#Rule 78
		 'params', 0,
sub
#line 221 "Parser.yp"
{ [ ]                               }
	],
	[#Rule 79
		 'nparams', 2,
sub
#line 224 "Parser.yp"
{ push(@{$_[1]}, OP_DUP, 
							@{$_[2]}, OP_POP);
				      	  $_[1]                             }
	],
	[#Rule 80
		 'nparams', 2,
sub
#line 227 "Parser.yp"
{ $_[1]                             }
	],
	[#Rule 81
		 'nparams', 1,
sub
#line 228 "Parser.yp"
{ unshift(@{$_[1]}, OP_DUP);
					  push(@{$_[1]}, OP_POP);
					  $_[1]                             }
	],
	[#Rule 82
		 'setlist', 1,
sub
#line 233 "Parser.yp"
{ unshift(@{$_[1]}, OP_ROOT);
					     push(@{$_[1]}, OP_POP);
					   $_[1]                            }
	],
	[#Rule 83
		 'inclist', 1,
sub
#line 237 "Parser.yp"
{ unshift(@{$_[1]}, OP_ROOT);
					     push(@{$_[1]}, OP_POP);
					   $_[1]                            }
	],
	[#Rule 84
		 'incparam', 2,
sub
#line 242 "Parser.yp"
{ [ OP_ROOT, ( map { (@$_, OP_DOT) }
						@{$_[2]} ) ]                }
	],
	[#Rule 85
		 'incparam', 3,
sub
#line 244 "Parser.yp"
{ unshift(@{$_[2]}, [ "" ]);
					  $_[2]                             }
	],
	[#Rule 86
		 'incparam', 1,
sub
#line 246 "Parser.yp"
{ [ [$_[1]] ]                       }
	],
	[#Rule 87
		 'incparam', 1,
sub
#line 247 "Parser.yp"
{ [ [$_[1]] ]                       }
	],
	[#Rule 88
		 'useparam', 4,
sub
#line 250 "Parser.yp"
{ [ @_[1, 3] ]                      }
	],
	[#Rule 89
		 'useparam', 1,
sub
#line 251 "Parser.yp"
{ [ $_[1] ]                         }
	],
	[#Rule 90
		 'textdot', 3,
sub
#line 254 "Parser.yp"
{ $_[1] .= "$_[2]$_[3]"; $_[1]      }
	],
	[#Rule 91
		 'textdot', 3,
sub
#line 255 "Parser.yp"
{ $_[1] .= "$_[2]$_[3]"; $_[1]      }
	],
	[#Rule 92
		 'textdot', 1, undef
	],
	[#Rule 93
		 'quoted', 2,
sub
#line 259 "Parser.yp"
{ push(@{$_[1]}, @{$_[2]}, OP_CAT)
						if defined $_[2];
					  $_[1]                             }
	],
	[#Rule 94
		 'quoted', 0,
sub
#line 262 "Parser.yp"
{ [  ]                              }
	],
	[#Rule 95
		 'quotable', 1,
sub
#line 265 "Parser.yp"
{ [ OP_ROOT, ( map { (@$_, OP_DOT) } 
						@{$_[1]} ) ]                }
	],
	[#Rule 96
		 'quotable', 1,
sub
#line 267 "Parser.yp"
{ [ [$_[1]] ]                       }
	],
	[#Rule 97
		 'quotable', 1,
sub
#line 268 "Parser.yp"
{ undef }
	]
];



1;












