use ExtUtils::MakeMaker;


WriteMakefile(
    'NAME'	   => 'Template',
    'DISTNAME'     => 'Template-Toolkit',
    'VERSION_FROM' => 'lib/Template.pm',
    'EXE_FILES'    => [ 'bin/tpage' ],
    'PMLIBDIRS'    => [ 'lib' ], 
    'dist'         => {
	'COMPRESS' => 'gzip',
	'SUFFIX'   => 'gz',
	'PREOP'    =>  build_docs(),
    },
);

sub build_docs {
    return <<EOF;
echo "Building documentation for version \$(VERSION)";    \\
\$(PERL) doc/bin/mkdoc README.pod | pod2text > README;    \\
\$(PERL) doc/bin/mkdoc Template.pod > lib/Template.pod
EOF
}


