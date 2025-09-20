package Lingua::CU::Scripts::Unicode2UCS;

use warnings;
use strict;
use utf8;

use vars qw($VERSION @ISA);
use Unicode::Normalize;
use Tie::IxHash;
use Carp qw( croak );

our $VERSION = '0.01';
our @ISA = ();

tie my %dictionary, "Tie::IxHash";

unless (%dictionary = do "Lingua/CU/Scripts/unicode2ucsequivs") {
	croak "Couldn't parse unicode2ucsequivs: $@" if ($@);
	croak "Couldn't do unicode2ucsequivs: $!" unless (%dictionary);
	croak "Couldn't run unicode2ucsequivs" unless (keys %dictionary);
}

# Helper function to determine if a character is lowercase Cyrillic
sub _is_lowercase_cyrillic {
	my $char = shift;
	return 0 unless defined $char;
	my $code = ord($char);

	# Basic Cyrillic lowercase range and extended characters
	return (($code >= 0x0430 && $code <= 0x044F) ||
			$code == 0x0450 || $code == 0x0451 || $code == 0x0452 || $code == 0x0453 ||
			$code == 0x0454 || $code == 0x0455 || $code == 0x0456 || $code == 0x0457 ||
			$code == 0x0458 || $code == 0x0459 || $code == 0x045A || $code == 0x045B ||
			$code == 0x045C || $code == 0x045D || $code == 0x045E || $code == 0x045F ||
			$code == 0x0461 || $code == 0x0463 || $code == 0x0465 || $code == 0x0467 ||
			$code == 0x0469 || $code == 0x046B || $code == 0x046D || $code == 0x046F ||
			$code == 0x0471 || $code == 0x0473 || $code == 0x0475 || $code == 0x0477 ||
			$code == 0x0479 || $code == 0x047B || $code == 0x047D || $code == 0x047F ||
			$code == 0x0481 || $code == 0x1C82 || $code == 0xA64B || $code == 0xA657);
}

sub convert {
	my $string = shift;

	# Normalize the input string to NFD
	$string = NFD($string);
	study $string;

	# Create accent mappings based on case
	my %lowercase_accents = (
		chr(0x0301) => '1',  # acute
		chr(0x0300) => '2',  # grave
		chr(0x0486) => '3',  # psili
		chr(0x0486) . chr(0x0301) => '4',  # psili + acute
		chr(0x0486) . chr(0x0300) => '5',  # psili + grave
		chr(0x0311) => '6',  # inverted breve
		chr(0x0483) => '7',  # titlo
		chr(0x033E) => '8',  # vertical tilde
	);

	my %uppercase_accents = (
		chr(0x0301) => '~',  # acute
		chr(0x0300) => '@',  # grave
		chr(0x0486) => '#',  # psili
		chr(0x0486) . chr(0x0301) => '$',  # psili + acute
		chr(0x0486) . chr(0x0300) => '%',  # psili + grave
		chr(0x0311) => '^',  # inverted breve
		chr(0x0483) => '&',  # titlo
		chr(0x033E) => '_',  # vertical tilde
	);

	# Sort keys by length (longest first) for proper matching
	my @sorted_sequences = sort { length($b) <=> length($a) || $a cmp $b } keys %dictionary;
	my @accent_sequences = sort { length($b) <=> length($a) } keys %lowercase_accents;

	my @result;
	my $i = 0;
	my @chars = split //, $string;

	while ($i < @chars) {
		my $matched = 0;

		# Special case: и + breve (U+0306) = й
		if ($i > 0 && $chars[$i] eq chr(0x0306)) {
			my $prev_char = @result ? $result[-1] : '';
			if ($prev_char eq 'и') {
				$result[-1] = 'й';
				$i++;
				$matched = 1;
			} elsif ($prev_char eq 'И') {
				$result[-1] = 'Й';
				$i++;
				$matched = 1;
			}
		}

		# Check for accent sequences
		if (!$matched && $i > 0) {
			for my $accent_seq (@accent_sequences) {
				my $seq_len = length($accent_seq);
				if ($i + $seq_len <= @chars) {
					my $candidate = join('', @chars[$i..$i+$seq_len-1]);
					if ($candidate eq $accent_seq) {
						my $prev_char = @result ? $result[-1] : '';

						if (_is_lowercase_cyrillic($prev_char)) {
							push @result, $lowercase_accents{$accent_seq};
						} else {
							push @result, $uppercase_accents{$accent_seq} || $accent_seq;
						}

						$i += $seq_len;
						$matched = 1;
						last;
					}
				}
			}
		}

		# Check for full sequence mappings
		if (!$matched) {
			for my $unicode_seq (@sorted_sequences) {
				my $seq_len = length($unicode_seq);
				if ($i + $seq_len <= @chars) {
					my $candidate = join('', @chars[$i..$i+$seq_len-1]);
					if ($candidate eq $unicode_seq) {
						push @result, $dictionary{$unicode_seq};
						$i += $seq_len;
						$matched = 1;
						last;
					}
				}
			}
		}

		# If no match found, keep the character as-is
		if (!$matched) {
			push @result, $chars[$i];
			$i++;
		}
	}

	return join('', @result);
}

1;

=head1 NAME

Lingua::CU::Scripts::Unicode2UCS - convert Unicode Church Slavonic text to UCS (Universal Church Slavonic) legacy encoding

=head1 SYNOPSIS

  use Lingua::CU::Scripts::Unicode2UCS;
  my $ucs_text = Lingua::CU::Scripts::Unicode2UCS::convert($unicode_text);

=head1 DESCRIPTION

This module provides functionality to convert Unicode Church Slavonic text back to the
UCS (Universal Church Slavonic) 8-bit legacy encoding. This is the reverse operation
of the UCS to Unicode conversion provided by Lingua::CU::Scripts::UCS.

The module handles:
- Case-sensitive accent encoding (digits 1-8 for lowercase, symbols ~@#$%^&_ for uppercase)
- Complex character sequences and combining characters
- Special Church Slavonic characters and diacritical marks
- Proper conversion of decomposed Unicode sequences to UCS equivalents

=head1 METHODS

=head2 convert($string)

Converts a Unicode string containing Church Slavonic text to UCS8 encoding.

=cut