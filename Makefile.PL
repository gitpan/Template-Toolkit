use ExtUtils::MakeMaker;


WriteMakefile(
    'DISTNAME'     => 'Template-Toolkit',
    'NAME'	   => 'Template',
    'VERSION_FROM' => 'lib/Template.pm',
    'EXE_FILES'    => [ 'bin/tpage' ],
    'PMLIBDIRS'    => [ 'lib', 'lib/Template' ],
    'dist'         => {
	'COMPRESS' => 'gzip',
	'SUFFIX'   => 'gz',
    },
);



