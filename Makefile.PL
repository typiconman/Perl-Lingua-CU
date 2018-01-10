use 5.014002;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my @scripts = grep {-f && !m/\./o && !m/~$/o } glob("scripts/*");

## generate the cu.pl file
print "Generating collation tailoring for Church Slavonic...\n";
unless (my $return = do 'mklocale.pl') {
	die "Couldn't create collation tailoring: $@" if $@;
        die "couldn't do mklocale.pl: $!"    unless defined $return;
        die "couldn't run mklocale.pl"       unless $return;
}

WriteMakefile(
    NAME              => 'Lingua::CU',
   clean => { FILES => "lib/Lingua/CU/cu.pl" },
    VERSION_FROM      => 'lib/Lingua/CU.pm', # finds $VERSION
    PREREQ_PM         => { 'Tie::IxHash' => 0 }, # TODO: remove dependency on Tie::IxHash
    EXE_FILES => \@scripts,
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Lingua/CU.pm', # retrieve abstract from module
       AUTHOR         => 'Aleksandr Andreev <aleksandr.andreev@gmail.com>') : ()),
);
