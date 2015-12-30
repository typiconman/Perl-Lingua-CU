package Lingua::CU::Scripts::UCS;

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

unless (%dictionary = do "Lingua/CU/Scripts/ucsequivs") {
	croak "Couldn't parse ucsequivs: $@" if ($@);
	croak "Couldn't do ucsequivs: $!" unless (%dictionary);
	croak "Couldn't run ucsequivs" unless (keys %dictionary);
}

sub convert {
	my $string = shift;
	study $string;
	my $what = join("|", map (quotemeta, keys %dictionary));
	$string =~ s/($what)/$dictionary{$1}/g;
	return NFC($string);
}

1;

=head1 NAME

Lingua::CU::Scripts::UCS - process UCS (Universal Church Slavonic) legacy encoding

=head1 AUTHOR

Aleksandr Andreev L<aleksandr.andreev@gmail.com>. 

=head1 LICENSING

Copyright (c) 2015 Aleksandr Andreev (http://sci.ponomar.net/)

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl you may have available.

=cut
