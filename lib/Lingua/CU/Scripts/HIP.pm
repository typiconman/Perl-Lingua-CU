package Lingua::CU::Scripts::HIP;

use warnings;
use strict;
use utf8;

use vars qw($VERSION @ISA);
use Unicode::Normalize;
use Tie::IxHash;
use Carp qw( croak );

our $VERSION = '0.04';
our @ISA = ();

tie my %dictionary, "Tie::IxHash";
tie my %latin, "Tie::IxHash";
tie my %civil, "Tie::IxHash";

my %numsigns = (
	"<тьма>&" => chr(0x20DD),
	"<легион>&" => chr(0x0488),
	"<леодр>&" => chr(0x0489),
	"<вран>&" => chr(0xA670),
	"<колода>&" => chr(0xA671)
);
my $diactrics = join('', map { chr($_) } ((0x0300 .. 0x036F), (0x0483 .. 0x0487), (0x2DE0 .. 0x2DFF)));
unless (%dictionary = do "Lingua/CU/Scripts/hipequivs") {
	croak "Couldn't parse hipequivs: $@" if ($@);
	croak "Couldn't do hipequivs: $!" unless (%dictionary);
	croak "Couldn't run hipequivs" unless (keys %dictionary);
}
unless (%latin = do "Lingua/CU/Scripts/hipequivs_Latn") {
	croak "Couldn't parse hipequivs_Latn: $@" if ($@);
	croak "Couldn't do hipequivs_Latn: $!" unless (%latin);
	croak "Couldn't run hipequivs_Latn" unless (keys %latin);
}
unless (%civil = do "Lingua/CU/Scripts/hipequivs_Cyrl") {
	croak "Couldn't parse hipequivs_Cyrl: $@" if ($@);
	croak "Couldn't do hipequivs_Cyrl: $!" unless (%civil);
	croak "Couldn't run hipequivs_Cyrl" unless (keys %civil);
}

sub convert_Latn {
	my $string = shift;
	study $string;
	my $what = join("|", map (quotemeta, keys %latin));
	$string =~ s/($what)/$latin{$1}/g;
	return NFC($string);
}

sub convert_Cyrl {
	my $string = shift;
	study $string;
	my $what = join("|", map (quotemeta, keys %civil));
	$string =~ s/($what)/$civil{$1}/g;
	return NFC($string);
}

sub convert_Zf {
	my $string = shift;

	# add in the additional equivs used by ZF
	my %zfequivs = ();
	unless (%zfequivs = do "Lingua/CU/Scripts/hipequivs_Zf") {
		croak "Couldn't parse hipequivs_Zf: $@" if ($@);
		croak "Couldn't do hipequivs_Zf: $!" unless (%civil);
		croak "Couldn't run hipequivs_Zf" unless (keys %civil);
	}

	@dictionary{keys %zfequivs} = values %zfequivs;
	delete $dictionary{'*'};
	study $string;
	my $what = join("|", map (quotemeta, keys %dictionary));
	$string =~ s/($what)/$dictionary{$1}/g;

	# dot the i's
	$what = chr(0x0456) . "([^$diactrics])";
	$string =~ s/$what/\x{0456}\x{0308}$1/g;
	$string =~ s/\x{F8FF}/\x{0456}/g;
	return NFC($string);
}

sub convert {
	my $string = shift;
	
	study $string;
	my $what = join("|", map (quotemeta, keys %dictionary));
	foreach my $number (keys %numsigns) {
		next unless index($string, $number) != -1;
		s/$number\{(\w+)\}/$1$numsigns{$number}/g;
	}

	$string =~ s/($what)/$dictionary{$1}/g;

	# dot the i's
	$what = chr(0x0456) . "([^$diactrics])";
	$string =~ s/$what/\x{0456}\x{0308}$1/g;
	$string =~ s/\x{F8FF}/\x{0456}/g;
	return NFC($string);
}

1;

=head1 NAME

Lingua::CU::Scripts::HIP - process HIP (HyperInvariant Presentation) pseudocoding

=head1 AUTHOR

Aleksandr Andreev L<aleksandr.andreev@gmail.com>. 

=head1 LICENSING

Copyright (c) 2015 Aleksandr Andreev (http://sci.ponomar.net/)

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl you may have available.

=cut
