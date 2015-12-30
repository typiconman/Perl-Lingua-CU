use 5.014002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
my @scripts = grep {-f && !m/\./o && !m/~$/o } glob("scripts/*");

WriteMakefile(
    NAME              => 'Lingua::CU',
    VERSION_FROM      => 'lib/Lingua/CU.pm', # finds $VERSION
    PREREQ_PM         => { 'Tie::IxHash' => 0 }, # TODO: remove dependency on Tie::IxHash
    EXE_FILES => \@scripts,
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Lingua/CU.pm', # retrieve abstract from module
       AUTHOR         => 'Aleksandr Andreev <aleksandr.andreev@gmail.com>') : ()),
);
