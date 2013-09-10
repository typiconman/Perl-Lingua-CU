package Lingua::CU;

#require 5.014002;
use strict;
use warnings;
use utf8;

require Exporter;
require Carp;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Lingua::CU ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	arabicToCyrillic cyrillicToArabic resolve cu2ru
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( 
	
);

our $VERSION = '0.01';
my %definitions;
my @ones = ('', qw/а в г д є ѕ з и ѳ/);
my @tens = ('', qw/і к л м н ѯ о п ч/);
my @hundreds = ('', qw/р с т у ф х ѱ ѿ ц/);
my @letters = qw/а б в г д е є ж ѕ з ꙁ и і ї й к л м н о ѻ п р с т у ꙋ ф х ѡ ѿ ѽ ꙍ ц ч ш щ ъ ы ь ѣ ю ѧ ѫ ꙗ ѯ ѱ ѳ ѵ ѷ/;
my @LETTERS = qw/А Б В Г Д Е Є Ж Ѕ З Ꙁ И І Ї Й К Л М Н О Ѻ П Р С Т У Ꙋ Ф Х Ѡ Ѿ Ѽ Ꙍ Ц Ч Ш Щ Ъ Ы Ь Ѣ Ю Ѧ Ѫ Ꙗ Ѯ Ѱ Ѳ Ѵ Ѷ/;

my %resolver = (
	chr(0x0405) 	=> "З", # capital Zelo
	chr(0x0404)	=> "Е", # capital wide Est
	chr(0x0454)	=> "е", # lowercase wide est
	chr(0x0455)	=> "з", # lowercase zelo
	chr(0x0457)	=> chr(0x0456),	# double-dotted i
	chr(0x0460)	=> "О",	# capital Omega
	chr(0x0461)	=> "о",	# lowercase omega
	chr(0x0466)	=> "Я", # capital small Yus
	chr(0x0467)	=> "я",	# lowercase small yus
	chr(0x046E)	=> "Кс",	# capital Xi
	chr(0x046F)	=> "кс", #lowercase xi
	chr(0x0470)	=> "Пс",	# capital Psi
	chr(0x0471)	=> "пс",	# lowercase psi
	chr(0x0472)	=> "Ф",	# capital Theta
	chr(0x0473)	=> "ф", # lowercase theta
	chr(0x0474)	=> "В", # izhitsa
	chr(0x0475)	=> "в",	# izhitsa
	chr(0x0476)	=> "И",	# capital izhistsa with kendema
	chr(0x0477)	=> "и", # lowercase Izhitsa with kendema
	chr(0x0478)	=> "У", # Ou
	chr(0x0479)	=> "у", # ou
	chr(0x047A)	=> "О",	# wide O
	chr(0x047B)	=> "о", # wide o
	chr(0x047C)	=> "О", # omega with great apostrophe
	chr(0x047D)	=> "о", # omega with great apostrophe
	chr(0x047E)	=> "Отъ", # Ot
	chr(0x047F)	=> "отъ", # ot
	chr(0xA64A)	=> "У",	# Uk
	chr(0xA64B)	=> "у", # uk
	chr(0xA64C)	=> "О", # wide omega
	chr(0xA64D)	=> "о", # wide omega
	chr(0xA656)	=> "Я", # Ioted a
	chr(0xA657)	=> "я" # ioted a
);

INIT {
	# load the Titlo resolution Data into memory
	while (<DATA>) {
		next if (substr($_, 1, 1) eq "#");
		s/\r?\n//g;
		next unless (length $_);
		my @parts = split /\t/;
		$parts[0] =~ s/\./\\b/g;
		$definitions{$parts[0]} = $parts[1];
	}
	close DATA;
}

END {
	undef %definitions;
}

# Preloaded methods go here.
sub resolve ($) {
	my $text = shift;

	my $what = join("|", keys %definitions);
	$text =~ s/($what)/$definitions{$1}/g;
	return $text;
}

sub cyrillicToArabic ($) {
	my $number = shift;

	my %oDigits = map { $ones[$_] => $_ } 0..9;
	my %tDigits = map { $tens[$_] => 10 * $_ } 0..9;
	my %hDigits = map { $hundreds[$_] => 100 * $_ } 0..9;
	my %digits = (%oDigits, %tDigits, %hDigits);

	my $o = join ('|', keys %oDigits);
	my $t = join ('|', keys %tDigits);
	my $h = join ('|', keys %hDigits);

	# remove all occurences of titlo
	$number =~ s/\x{0483}//g;

	if ($number =~ /^(?:҂([$h]))*(?:҂([$t]))*(?:҂([$o]))*([$h]?)([клмнѯопч]?)([$o]?)$/) {
		$number =~ s/(?:҂([$h]))*(?:҂([$t]))*(?:҂([$o]))*([$h]?)([клмнѯопч]?)([$o]?)/1000 * ($digits{$1||''} + $digits{$2||''} + $digits{$3||''}) + $digits{$4} + $digits{$5} + $digits{$6}/e;
	} elsif ($number =~ /^(?:҂([$h]))*(?:҂([$t]))*(?:҂([$o]))*([$h]?)([$o]?)(і)$/) {
		$number =~ s/(?:҂([$h]))*(?:҂([$t]))*(?:҂([$o]))*([$h]?)([$o]?)(і)/1000 * ($digits{$1||''} + $digits{$2||''} + $digits{$3||''}) + $digits{$4} + $digits{$5} + $digits{$6}/e;
	} else {
		Carp::carp (__PACKAGE__ . "::cyrillicToArabic ($number) - Error: $number is not a valid Cyrillic number");
	}
	return $number;

}

sub arabicToCyrillic ($) {
	my $number = shift;

	# check if $number is in fact numeric
	unless ($number =~ /^\d+$/) {
		Carp::carp (__PACKAGE__ . "::arabicToCyrillic ($number) - Error: $number is not a valid Arabic number");
	}
	my @numerals = (\@ones, \@tens, \@hundreds);

	my $size = 10 ** (length($number) - 1);
	my $output = "";

	for (my $key = 0; $key < length $number; $key++) {
		$output .= "҂" if (log ($size / 10 ** $key) / log (10) > 2);
		$output .= $numerals[sprintf(q{%.0f}, log ($size / 10 ** $key) / log (10)) % 3][substr($number, $key, 1)];
	}

	# reverse the teens if we need to
	$output =~ s/і(҂?)([авгдєѕзиѳ])/$2$1і/g;

	# add the titlo character
	my $pos = length ($output) - 2 * ($output =~ tr/҂//);
	return $output unless $pos;
	if ($pos == 1) {
		return $output . chr(0x0483);
	} else {
		$output =~ s/(.+)([авгдєѕзиѳіклмнѯопч])/$1\x{0483}$2/;
		return $output;
	}
}

sub cu2ru {
	my $text = shift;
	my $params = shift; # params: noaccent, modernrules

	unless (length $text) {
		Carp::carp (__PACKAGE__ . "::cu2ru ($text) - Error: argument is empty");
	}

	study $text;
	$text =~ s/\r?\n//g;
	# resolve titli via the dictionary
	unless (exists $params->{skiptitlos}) {
 		$text = resolve $text;
	}

	### STEP ONE: CONVERT YEROK TO HARD SIGN
	$text =~ s/\x{033E}|\x{2E2F}/ъ/g;

	## STEP TWO: CONVERT GRAVE AND CIRCUMFLEX ACCENTS TO ACUTE
	$text =~ s/\x{0300}|\x{0311}/\x{0301}/g;

	### STEP THREE: CONVERT IZHITSA
	$text =~ s/\x{0474}([\x{0486}\x{0301}])/И$1/g;
	$text =~ s/\x{0475}([\x{0486}\x{0301}])/и$1/g;

	## STEP FOUR: REMOVE ALL BREATHING MARKS AND DOUBLE DOTS
	$text =~ s/\x{0486}|\x{A67C}|\x{A67E}|\x{0308}//g;

	## STEP FIVE: CHARACTER INITIALIZATION
	# RESOLVE DIAGRAPH OU TO U
	$text =~ s/оу|ѹ/у/g;
	$text =~ s/Оу|Ѹ/У/g;

	# RESOLVE ALL FORMS OF IZHITSA WITH ACCENT
	$text =~ s/\x{0474}\x{0301}/И\x{0301}/g;
	$text =~ s/\x{0475}\x{0301}/и\x{0301}/g;

	# REMOVE ALL VARIATION SELECTORS
	$text =~ s/\x{FE00}|\x{FE01}//g;

	# convert semicolon to question mark
	$text =~ s/;/\?/g;

	### AT THIS POINT, ATTEMPT TO RESOLVE ANY NUMERALS
	# XXX: WE CAN ONLY CONVERT IN THIS WAY NUMERALS BELOW ONE THOUSAND
	my $who = join ("|", (@ones, @tens, @hundreds));

	$text =~ s/([$who][$who][\x{0483}][$who])/&cyrillicToArabic($1)/ge;
	$text =~ s/([$who][\x{0483}][$who])/&cyrillicToArabic($1)/ge;
	$text =~ s/([$who][$who][\x{0483}])/&cyrillicToArabic($1)/ge;
	$text =~ s/([$who][\x{0483}])/&cyrillicToArabic($1)/ge;

	$who = join("|", keys %resolver);
	## STEP SIX: RESOLVE LETTERS PECULIAR TO CHURCH SLAVONIC
	$text =~ s/($who)/$resolver{$1}/g;

	## STEP SEVEN: STANDARDIZE RUSSIAN-STYLE SPELLING
	# ъи => ы
	$text =~ s/ъи/ы/g;
	# жы, шы, щы => и
	$text =~ s/([жшщ])ы/$1и/g;
	# жя, шя, щя, чя => а
	$text =~ s/([жшщч])я/$1а/g;
	# отъ[consonant|hard vowel] -> от$1
	$text =~ s/([оО])тъ([абвгджзклмнопрстуфхцчшщ])/$1т$2/g;
	## other normalizations may be performed here, if desired

	if (exists $params->{modernrules}) {
		### STEP EIGHT: ADDITIONAL CONVERSIONS FOR MODERN ORTHOGRAPHY
		# GET RID OF THE DECIMAL I
		$text =~ s/\x{0406}/И/g;
		$text =~ s/\x{0456}/и/g;

		## GET RID OF THE YAT
		$text =~ s/\x{0462}/Е/g;
		$text =~ s/\x{0463}/е/g;

		## GET RID OF ALL TRAILING HARD SIGNS
		$text =~ s/ъ\b|Ъ\b//g;
	}

	if (exists $params->{noaccents}) {
		### STEP NINE: IF DESIRED, REMOVE STRESS MARK (ACUTE ACCENT)
		$text =~ s/\x{0301}//g;
	}

	return $text;
}

1;

=pod

=encoding utf8

=head1 NAME

Lingua::CU - Perl extension for working with Church Slavonic text in Unicode

=head1 SYNOPSIS

  use Lingua::CU ':all';
  arabicToCyrillic (21); # returns к҃а
  cyrillicToArabic ("к҃а"); # returns 21
  resolve ("ст҃ъ"); # returns свѧ́тъ
  cu2ru ("ст҃ъ"); # returns свя́тъ
  cu2ru ("ст҃ъ", { noaccents => 1, modernrules => 1 }); # returns свят

=head1 DESCRIPTION

Lingua::CU is a module for performing various operations with Church Slavonic texts.

It includes the following capabilities:

=over 4

=item Resolve Church Slavonic abbreviations and I<nomina sacra>

=item Convert between Cyrillic and Arabic numerals

=item Perform basic conversions between the Julian and Gregorian calendars (TODO)

=item Convert Church Slavonic text to Russian characters (both traditional and reformed orthography)

=item Romanize (transliterate to Latin) Church Slavonic text using various systems (TODO)

=item Convert between Unicode and legacy UCS and HIP encodings (TODO)

=item Sort Church Slavonic words using a tailoring of the DUCET (TODO)

=item Perform stemming of Church Slavonic words (TODO)

=back

All text supplied to this library must be encoded in UTF-8 and, unless otherwise specified, is assumed to be
in Unicode. For more on Church Slavonic using Unicode, please see the paper
I<Roadmap for Church Slavonic Typography in the Unicode Standard> available at 
http://www.ponomar.net/.

This program is ALPHA STAGE SOFTWARE and is provided with ABSOLUTELY NO WARRANTY of any kind,
express or implied, not even the implied warranties of merchantability, fitness for a purpose, or non-infringement.

=head2 EXPORT

No methods are exported by default.

The following methods may be exported if specified explicitly: C<arabicToCyrillic> C<cyrillicToArabic> C<resolve> C<cu2ru>.

You may also export all of the above methods by writing: C<use Lingua::CU ':all';>.

=head1 METHODS

=head2 arabicToCyrillic

Usage: C<arabicToCyrillic( $number )>

Takes an Arabic number and returns the corresponding Cyrillic numeral. Croaks if C<$number> is not numeric.

Example: C<arabicToCyrillic ( 121 )> returns C<рк҃а>.

=head2 cyrillicToArabic

Usage: C<cyrillicToArabic( $numeral )>

Takes a Cyrillic numeral and returns the corresponding Arabic number. Carps if C<$numeral> is not a well-formatted Slavonic number.

Example: C<cyrillicToArabic("рк҃а")> returns C<121>.

=head2 resolve

Usage: C<resolve( $word )>

Takes a word that is written with a titlo or lettered titlo (as an abbreviation or I<nomen sacrum>) and writes it out in full, resolving the abbreviation.

Bugs: correct placement of stress marks and capitalization are not guaranteed. Titlo resolution relies on a list that can still be improved.

Warning: the Slavonic word B<сн҃а> could both be an abbreviation for Сы́на and a numeral (251). Thus,
C<resolve('сн҃а')> will return C<Сы́на> but C<cyrillicToArabic('сн҃а')> will return C<251>.

=head2 cu2ru

Usage: C<cu2ru( $text, [modernrules = 0, noaccents = 0, skiptitlos = 0])>

Takes well-formatted Church Slavonic C<$text> and transforms it into Russian (civil) orthography. The following operations are performed: 

=over 4

=item Titli and lettered titli are resolved (if the C<skiptitlos> parameter is not zero, this step is skipped;
this is only useful if you are converting text known to have no abbreviations and wish to save time or
if you are writing your own titlo processor for non standard text like text with XML markup or pre-Nikonian editions)

=item Cyrillic numerals are resolved to Arabic numbers (but see note above concerning B<сн҃а>)

=item Stress marks are transformed to the acute accent (U+0301) and all other diacritical marks are removed

=item Letters that do not occur in Russian are transformed into their Russian analogs (e.g., ѧ is transformed to я)

=item Some spelling is normalized to agree with common Russian rules (e.g., шы is transformed to ши)

=item If optional parameter C<noaccents> is not zero, all stress marks are removed; otherwise, 
stress indications remain in the text, but only as the acute accent (U+0301)

=item If optional parameter C<modernrules> is not zero, the text is further simplified into modern Russian orthography 
(that means that і is resolved to и, ѣ is resolved to е, and trailing ъ is removed); otherwise, traditional (pre-1918) orthography is assumed

=back

=head1 SEE ALSO

This software is part of the Ponomar Project (see http://www.ponomar.net/​).

Be sure to read the I<Roadmap for Church Slavonic Typography in the Unicode Standard> and to download the 
Unicode-compatible Hirmos Ponomar font.

Be sure to read as well C<perluniintro> and C<perllocale> in the Perl manual.

=head1 AUTHOR

Aleksandr Andreev <aleksandr.andreev@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012, 2013 by Aleksandr Andreev

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl you may have available.

=cut

__DATA__
## THIS IS A LIST OF RULES FOR THE RESOLUTION OF TITLI IN CHURCH SLAVONIC
## LINES BEGINNING WITH # ARE IGNORED
## COLUMNS ARE SEPARATED BY TAB
гг҃л	нгел
пⷭ҇л	по́стол
пⷭ҇тол	по́стол
пⷭ҇тѡл	по́стѡл
пⷭ҇кп	пи́скоп
пⷭ҇коп	пи́скоп
гг҃єл	нгєл
бг҃а.	Бо́га
бг҃ови.	Бо́гови
.бг҃ома́т	Богома́т
.бг҃омлад	Богомлад
.бг҃омт҃	Богома́т
бг҃ом	бо́гом
.бг҃оро́д	Богоро́д
.бг҃ꙋ.	Бо́гу
бг҃ъ	Бо́гъ
бг҃	бог
Бг҃	Бог
.бж҃е.	Бо́же
бж҃е	боже
Бж҃е	Боже
бж҃ї	бо́жї
Бж҃ї	Бо́жї
бжⷭ҇т	боже́ст
Бжⷭ҇т	Боже́ст
бз҃и	бози
Бз҃и	Бози
.бз҃ѣ	Бозѣ
бз҃ѣ	бозѣ
Бз҃ѣ	Бозѣ
блгⷣт	благода́т
Блгⷣт	Благода́т
блгⷭ҇в	благослов
Блгⷭ҇в	Благослов
.бл҃га.	бла́га
.бл҃ги.	бла́ги
.бл҃го.	бла́го
.бл҃гъ.	бла́гъ
бл҃г	благ
Бл҃г	Благ
бл҃ж	блаж
Бл҃ж	Блаж
бл҃з	блаз
Бл҃з	Блаз
.бцⷣ	Богоро́диц
бцⷣ	богоро́диц
Бцⷣ	Богоро́диц
бчⷣ	богоро́дич
Бчⷣ	Богоро́дич
.влⷣк	Влады́к
влⷣк	влады́к
Влⷣк	Влады́к
влⷣц	влады́ц
Влⷣц	Влады́ц
влⷣч	влады́ч
Влⷣч	Влады́ч
кр҃с	кре́с
кр҃л	кре́сл
кр҃ш	креш
крⷭ҇и	креси
крⷭ҇	кре́с
гдⷭ҇а	Го́спода
гдⷭ҇ви	Го́сподеви
гдⷭ҇е	Го́споде
гдⷭ҇и.	Го́споди
Гдⷭ҇	Го́спод
гдⷭ҇и́н	господи́н
гдⷭ҇и	Го́споди
гдⷭ҇к	госпо́дск
гдⷭ҇н	госпо́дн
гдⷭ҇о	господо
гдⷭ҇р	госуда́р
гдⷭ҇с	госпо́дс
гдⷭ҇ꙋ.	Го́сподꙋ
гдⷭ҇ь.	Госпо́дь
гдⷭ҇ь	госпо́дь
гдⷭ҇ѣ	Го́сподѣ
глаⷡ҇	глава̀
гл҃а	глаго́ла
Гл҃а	Глаго́ла
гл҃г	глаг
Гл҃г	Глаг
гл҃е	глаго́ле
Гл҃е	Глаго́ле
гл҃и	глаго́ли
Гл҃и	Глаго́ли
гл҃ꙋ	глаго́лꙋ
Гл҃ꙋ	Глаго́лꙋ
гл҃ъ	глаго́лъ
Гл҃ъ	Глаго́лъ
гл҃ю	глаго́лю
Гл҃ю	Глаго́лю
гл҃ѧ	глаго́лѧ
Гл҃ѧ	Глаго́лѧ
глⷡ҇а	глава̀
Глⷡ҇а	Глава̀
гпⷭ҇ж	госпож
Гпⷭ҇ж	Госпож
дваⷤ	два́жды
Дваⷤ	Два́жды
.дв҃а	Дѣ́ва
дв҃а	дѣ́ва
дв҃д	Дави́д
Дв҃д	Дави́д
дв҃и́	дѣви́
дв҃и̑	дѣви̑
.дв҃о	Дѣ́во
дв҃о	дѣ́во
дв҃с	дѣ́вс
.дв҃ꙋ	Дѣ́вꙋ
дв҃ꙋ	дѣ́вꙋ
дв҃ц	дѣ́виц
дв҃ч	дѣви́ч
.дв҃ы	Дѣ́вы
дв҃ы	дѣ́вы
.дв҃ѣ	Дѣ́вѣ
дв҃ѣ	дѣ́вѣ
двⷭ҇т	дѣ́вст
Дв҃	Дѣ́в
дс҃ѣ	ду́сѣ
Дс҃	Ду́с
дх҃а	ду́ха
дх҃и	ду́хи
дх҃н	духн
дх҃о	духо
дх҃ѡ	духѡ
дх҃ꙋ	ду́хꙋ
дх҃ъ	ду́хъ
дх҃ѣ	ду́хѣ
Дх҃	Ду́х
дш҃а	душа
дш҃е.	ду́ше
дш҃е	душе
дш҃и	души
дш҃ꙋ	ду́шꙋ
дш҃ы	ду́шы
Дш҃	Душ
ѵⷢ҇л	ѵа́нгел
заⷱ҇	зача́ло
Заⷱ҇	Зача́ло
мⷬ҇к	мѧрѣ́к
рⷭ҇л	русал
і҆и҃л	І҆сра́ил
і҆и҃с	І҆исꙋ́с
кн҃г	кнѧг
кн҃же.	кнѧ́же
кн҃ж	кнѧж
кн҃з	кнѧ́з
Кн҃	Кнѧ́
кр҃с	крес
кр҃щ	крещ
крⷭ҇т	крест
Крⷭ҇т	Крест
мл҃т	моли́т
Мл҃т	Моли́т
млⷣн	младе́н
Млⷣн	Младе́н
млⷭ҇р	милосѣ́р
Млⷭ҇р	Милосѣ́р
млⷭ҇т	ми́лост
Млⷭ҇т	Ми́лост
мнⷭ҇т	монаст
Мнⷭ҇т	Монаст
мр҃і	Марі
мр҃ї	Марї
Мр҃і	Марі
Мр҃ї	Марї
мт҃е	ма́те
.мт҃и	Ма́ти
мт҃и	ма́ти
мт҃р	ма́тер
мт҃ь	ма́ть
Мт҃	Ма́т
мцⷭ҇	мѣ́сѧц
Мцⷭ҇	Мѣ́сѧц
мч҃е	му́че
Мч҃е	Му́че
мч҃є	му́чє
Мч҃є	Му́чє
мч҃н	му́чен
Мч҃н	Му́чен
мчⷭ҇н	мѣ́сѧчн
м҃-ц	четыредесѧ́тниц
мⷭ҇ц	мѣ́сѧц
Мⷭ҇ц	Мѣ́сѧц
мⷭ҇ч	мѣ́сѧч
Мⷭ҇ч	Mѣ́сѧч
нб҃а	не́ба
нб҃е	небе
нб҃о	не́бо
нб҃с	небе́с
нб҃ꙋ	не́бꙋ
нб҃ѣ	не́бѣ
Нб҃	Не́б
нбⷭ҇н	небе́сн
Нбⷭ҇н	Небе́сн
нлⷣ	недѣ́л
Нлⷣ	Недѣ́л
нн҃ѣ	ны́нѣ
Нн҃ѣ	Ны́нѣ
ѻ҆ц҃а̀	ѻ҆тца̀
Ѻ҆ц҃а̀	Ѻ҆тца̀
ѻ҆ц҃а́	ѻ҆тца́
Ѻ҆ц҃а́	Ѻ҆тца́
ѻ҆ц҃е́	ѻ҆тце́
ѻ҆ц҃е́	ѻ҆тце́
Ѻ҆ц҃е́	Ѻ҆тце́
ѻ҆ц҃ꙋ̀	ѻ҆тцꙋ̀
Ѻ҆ц҃ꙋ̀	Ѻ҆тцꙋ̀
ѻ҆ц҃ꙋ́	ѻ҆тцꙋ́
Ѻ҆ц҃ꙋ́	Ѻ҆тцꙋ́
ѻ҆ц҃ъ	ѻ҆те́цъ
Ѻ҆ц҃ъ	Ѻ҆те́цъ
ѻ҆ц҃ы̀	ѻ҆тцы̀
Ѻ҆ц҃ы̀	Ѻ҆тцы̀
ѻ҆ц҃ѣ̀	ѻ҆тцѣ̀
Ѻ҆ц҃ѣ̀	Ѻ҆тцѣ̀
ѻ҆ч҃ес	ѻ҆те́чес
Ѻ҆ч҃ес	Ѻ҆те́чес
ѻ҆ч҃єс	ѻ҆те́чєс
Ѻ҆ч҃єс	Ѻ҆те́чєс
ѻ҆ч҃е	ѻ҆́тче
Ѻ҆ч҃е	Ѻ҆тче
ѻ҆ч҃с	ѻ҆те́чес
Ѻ҆ч҃с	Ѻ҆те́чес
ѻ҆ч҃ь	ѻ҆те́чь
Ѻ҆ч҃ь	Ѻ҆те́чь
ѻ҆́ч҃а	ѻ҆́тча
Ѻ҆́ч҃а	Ѻ҆́тча
ѻ҆́ч҃ес	ѻ҆́течес
Ѻ҆́ч҃ес	Ѻ҆́течес
ѻ҆́ч҃е	ѻ҆́тче
Ѻ҆́ч҃е	Ѻ҆́тче
Ѻ҆́ч҃е	Ѻ҆́тче
ѻ҆́ч҃и	ѻ҆́тчи
Ѻ҆́ч҃и	Ѻ҆́тчи
ѻ҆́ч҃ї	ѻ҆́тчї
Ѻ҆́ч҃ї	Ѻ҆́тчї
ѻ҆́ч҃ꙋ	ѻ҆́тчꙋ
Ѻ҆́ч҃ꙋ	Ѻ҆́тчꙋ
ѻ҆́ч҃ь	ѻ҆́течь
Ѻ҆́ч҃ь	Ѻ҆́течь
ѡⷮ	ѿ
ѡ҆сщ҃а́	ѡ҆свѧща́
Ѡ҆сщ҃а́	Ѡ҆свѧща́
ѡ҆чⷭ҇т	ѡ҆чи́ст
Ѡ҆чⷭ҇т	Ѡ҆чи́ст
ѻц҃а	ѻтца
Ѻц҃а	Ѻтца
ѻц҃є	ѻтцє
ѻ҆ц҃є́	ѻ҆тцє́
Ѻц҃є	Ѻтцє
ѻц҃ꙋ	ѻтцꙋ
Ѻц҃ꙋ	Ѻтцꙋ
ѻц҃ъ	ѻтецъ
Ѻц҃ъ	Ѻтецъ
ѻц҃ы	ѻтцы
Ѻц҃ы	Ѻтцы
ѻц҃ѣ	ѻтцѣ
Ѻц҃ѣ	Ѻтцѣ
ѻч҃е	ѻтече
Ѻч҃е	Ѻтече
ѻч҃є	ѻтечє
Ѻч҃є	Ѻтечє
ѻч҃и	ѻтчи
Ѻч҃и	Ѻтчи
ѻч҃ї	ѻтчї
Ѻч҃ї	Ѻтчї
ѻц҃ъ	ѻтецъ
Ѻц҃ъ	Ѻтецъ
пл҃т	пло́т
Пл҃т	Пло́т
поⷣ	подо́бенъ
Поⷣ	Подо́бенъ
првⷣ	пра́вед
Првⷣ	Пра́вед
пречⷭ҇т	пречи́ст
Пречⷭ҇т	Пречи́ст
мⷣр	му́др
прпⷣб	преподо́б
Прпⷣб	Преподо́б
пⷣб	подо́б
прпⷣн	преподо́бн
Прпⷣн	Преподо́бн
прⷣт	предт
Прⷣт	Предт
прⷪ҇рк	проро́к
Прⷪ҇рк	Проро́к
прⷪ҇р	прор
Прⷪ҇р	Прор
прⷭ҇н	присн
Прⷭ҇н	Присн
прⷭ҇т	прест
Прⷭ҇т	Прест
пѧⷦ҇	пѧто́къ
Пѧⷦ҇	Пѧто́къ
ржⷭ҇т	рождест
Ржⷭ҇т	Рождест
рожⷭ҇т	рождест
Рожⷭ҇т	Рождест
сл҃н	со́лн
Сл҃н	Со́лн
см҃рт	сме́рт
См҃рт	Сме́рт
сн҃а	сы́на
Сн҃а	Сы́на
сн҃е	сы́не
Сн҃е	Сы́не
сн҃є	сы́нє
Сн҃є	Сы́нє
сн҃о	сыно
Сн҃о	Сыно
сн҃ѡ	сынѡ
Сн҃ѡ	Сынѡ
сн҃ꙋ	сы́нꙋ
Сн҃ꙋ	Сы́нꙋ
сн҃ъ	сы́нъ
Сн҃ъ	Сы́нъ
сн҃ы	сы́ны
Сн҃ы	Сы́ны
сн҃ѣ	сы́нѣ
Сн҃ѣ	Сы́нѣ
сп҃са.	Cпа́са
сп҃са	спаса
сп҃се.	Cпа́се
сп҃сѐ	спасѐ
сп҃се́	спасе́
сп҃сє́	спасє́
сп҃си	спаси
сп҃сл	спасл
сп҃со	спасо
сп҃сѡ	спасѡ
сп҃сс	спа́сс
сп҃ст	спаст
сп҃сꙋ	спасꙋ
сп҃сш	спа́сш
сп҃съ	Спа́съ
сп҃сы	спасы
сп҃сѣ	спа́сѣ
Сп҃с	Спас
спⷭ҇л	спа́сл
Cпⷭ҇л	Cпа́сл
спⷭ҇н	спасе́н
Cпⷭ҇н	Cпасе́н
спⷭ҇т	спаст
Cпⷭ҇т	Cпаст
спⷭ҇ш	спа́сш
Cпⷭ҇ш	Cпа́сш
срⷣц	се́рдц
Срⷣц	Се́рдц
стрⷭ҇ти	стра́сти
стрⷭ҇тї	стра́стї
стрⷭ҇ть	стра́сть
стрⷭ҇т	страст
Стрⷭ҇т	Стра́ст
ст҃а.	свѧ́та
ст҃а	свѧта
ст҃е	свѧ́те
ст҃и	свѧти
ст҃і	свѧті
ст҃л	свѧти́тел
ст҃о	свѧ́то
ст҃ѡ	свѧ́тѡ
ст҃ꙋ	свѧ́тꙋ
ст҃ъ	свѧ́тъ
ст҃ы	свѧты
ст҃ѣ	свѧтѣ
ст҃ѧ	свѧтѧ
Ст҃	Свѧт
сꙋⷠ҇	сꙋббо́та
Cꙋⷠ҇	Cꙋббо́та
сщ҃е	свѧще
сщ҃є	свѧщє
сщ҃ꙋ	свѧщꙋ
Сщ҃	Свѧщ
сⷯ	сти́хъ
трⷪ҇ц	Тро́иц
Трⷪ҇ц	Тро́иц
трⷪ҇ч	тро́ич
Трⷪ҇ч	Тро́ич
трⷭ҇т	трисвѧт
Трⷭ҇т	Трисвѧт
триⷤ	три́жды
Триⷤ	Три́жды
ѹ҆чн҃и	ѹ҆чени
Ѹ҆чн҃и	Ѹ҆чени
у҆чн҃и	у҆чени
ѹ҆ч҃ни	ѹ҆чени
Ѹ҆ч҃ни	Ѹ҆чени
у҆ч҃ни	у҆чени
ѹ҆ч҃н	ѹ҆чен
Ѹ҆ч҃н	Ѹ҆чен
у҆ч҃н	у҆чен
ѹ҆чн҃к	ѹ҆ченик
Ѹ҆чн҃к	Ѹ҆ченик
у҆чн҃к	у҆ченик
ѹ҆чн҃ц	ѹ҆чениц
Ѹ҆чн҃ц	Ѹ҆чениц
у҆чн҃ц	у҆чениц
ѹ҆чт҃л	ѹ҆чи́тел
Ѹ҆чт҃л	Ѹ҆чи́тел
у҆чт҃л	у҆чи́тел
ѹ҆ч҃нї	ѹ҆че́нї
Ѹ҆ч҃нї	Ѹ҆че́нї
у҆ч҃нї	у҆че́нї
ѹ҆ч҃те	ѹ҆чи́те
Ѹ҆ч҃те	Ѹ҆чи́те
у҆ч҃те	у҆чи́те
ѹ҆ч҃тл	ѹ҆чите́л
Ѹ҆ч҃тл	Ѹ҆чите́л
у҆ч҃тл	у҆чите́л
хрⷭ҇т	Христ
Хрⷭ҇т	Христ
х҃с	Христо́съ
цр҃е	царе
Цр҃е	Царе
цр҃є	царє
Цр҃є	Царє
цр҃и	цари
Цр҃и	Цари
цр҃ї	ца́рї
Цр҃ї	Ца́рї
цр҃ква	це́рква
Цр҃ква	Це́рква
цр҃кве	церкве́
Цр҃кве	Церкве́
цр҃кви	це́ркви
Цр҃кви	Це́ркви
цр҃квь	це́рковь
Цр҃квь	Це́рковь
цр҃ков	це́рков
Цр҃ков	Це́рков
цр҃ко́в	церко́в
Цр҃ко́в	Церко́в
цр҃кѡ́в	церкѡ́в
Цр҃кѡ́в	Церкѡ́в
цр҃с	ца́рс
Цр҃с	Ца́рс
цр҃ц	цари́ц
Цр҃ц	Цари́ц
цр҃ь	ца́рь
Цр҃ь	Ца́рь
цр҃ѣ	царѣ
Цр҃ѣ	Царѣ
цр҃ю	царю
Цр҃ю	Царю
цр҃ѧ	царѧ
Цр҃ѧ	Царѧ
црⷭ҇к	ца́рск
Црⷭ҇к	Ца́рск
црⷭ҇т	ца́рст
Црⷭ҇т	Ца́рст
чеⷦ҇	человѣ́къ
Чеⷦ҇	Человѣ́къ
чл҃вѣ	человѣ
Чл҃вѣ	Человѣ
чл҃к	человѣк
Чл҃к	Человѣк
чтⷭ҇а	чи́ста
Чтⷭ҇а	Чи́ста
чтⷭ҇е	че́сте
Чтⷭ҇е	Че́сте
чтⷭ҇ї	чи́стї
Чтⷭ҇ї	Чи́стї
чтⷭ҇н	че́стн
Чтⷭ҇н	Че́стн
чтⷭ҇о	чи́сто
Чтⷭ҇о	Чи́сто
чтⷭ҇ꙋ	чи́стꙋ
Чтⷭ҇ꙋ	Чи́стꙋ
чтⷭ҇ъ	чи́стъ
Чтⷭ҇ъ	Чи́стъ
чтⷭ҇ы	чи́сты
Чтⷭ҇ы	Чи́сты
чтⷭ҇ь	че́сть
Чтⷭ҇ь	Че́сть
чтⷭ҇ѣ	чи́стѣ
Чтⷭ҇ѣ	Чи́стѣ
чⷭ҇та	чи́ста
Чⷭ҇та	Чи́ста
чⷭ҇те	че́сте
Чⷭ҇те	Че́сте
чⷭ҇тї	чи́стї
Чⷭ҇тї	Чи́стї
чⷭ҇тн	че́стн
Чⷭ҇тн	Че́стн
чⷭ҇то	чи́сто
Чⷭ҇то	Чи́сто
чⷭ҇тꙋ	чи́стꙋ
Чⷭ҇тꙋ	Чи́стꙋ
чⷭ҇ты	чи́сты
Чⷭ҇ты	Чи́сты
чⷭ҇тѣ	чи́стѣ
Чⷭ҇тѣ	Чи́стѣ
