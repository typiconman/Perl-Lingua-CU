# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Lingua-CU.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;
use utf8;

use Test::More tests => 6;
BEGIN { use_ok('Lingua::CU', qw(cyrillicToArabic arabicToCyrillic resolve cu2ru)) };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
# set up UTF8 crap
 my $builder = Test::More->builder;
    binmode $builder->output,         ":utf8";
    binmode $builder->failure_output, ":utf8";
    binmode $builder->todo_output,    ":utf8";

# test if numeral conversion is sane
my @input;
my @output;
for (my $i = 0; $i < 1000; $i++) {
	# generate random number between 1 and 9999
	push (@input, int(rand(9998)) + 1);
	push (@output, cyrillicToArabic(arabicToCyrillic($input[$i])));
}

is_deeply (\@output, \@input, "Numeral conversion is sane");

# test if Titlo resolution works fine
is (resolve ("ст҃ъ"), "свѧ́тъ", "Titlo resolution works");

# test if Slavonic can be converted to Russian
is (cu2ru ("ст҃ъ"), "свя́тъ", "Slavonic to Russian conversion works");
is (cu2ru ("ст҃ъ", { noaccents => 1 }), "святъ", "noaccents option is honored");
is (cu2ru ("ст҃ъ", { noaccents => 1, modernrules => 1 }), "свят", "modernrules option is honored");



