# $Id: Makefile.PL,v 1.6 2001/11/06 15:00:23 abw Exp $

use lib qw( ../lib ./lib );
use ExtUtils::MakeMaker;
use Template;

WriteMakefile(
    'NAME'     => 'Template::Stash::XS',
    'C'        => [ qw( Stash.c ) ],
    'XS'       => { 'Stash.xs' => 'Stash.c' },
    'OBJECT'   => 'Stash.o',
    'VERSION'  => $Template::VERSION,
    'NORECURS' => 1,
    'MAN3PODS' => 'none'
);

