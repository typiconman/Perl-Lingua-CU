package Lingua::CU::Collate;

require 5.006;
use strict;
use warnings;
use utf8;

require Exporter;
require Carp;

no warnings 'utf8';
use Unicode::Collate '1.04';

our @ISA = qw(Exporter Unicode::Collate);
our $VERSION = '1.04'; ## XXX: keep version alligned with version of Unicode::Collate

my $return;

unless ($return = do 'Lingua/CU/cu.pl') {
	Carp::carp( "Couldn't get result of cu.pl: $@" ) if $@;
        Carp::carp( "couldn't do cu.pl: $!" ) unless defined $return;
        Carp::carp( "couldn't run cu.pl" )  unless $return;
}

sub new {
	my $class = shift;
	my %tailoring = @_;

	while (my ($k, $v) = each %$return) {
		if (!exists $tailoring{$k}) {
			$tailoring{$k} = $v;
		} elsif ($k eq "entry") {
			$tailoring{$k} = $v . $tailoring{$k};
		} else {
			Carp::croak (__PACKAGE__ . "::new - Error: $k is reserved and cannot be overwritten");
		}
	}

	return new Unicode::Collate(%tailoring);
}

1;

=pod

=encoding utf8

=head1 NAME

Lingua::CU::Collate - Collation for Church Slavonic in Unicode

=head1 SYNOPSIS

  use Lingua::CU::Collate;
 #construct
 $Collator = Lingua::CU::Collate->new(); # custom %tailoring may also be specified
 
 #sort
 @sorted = $Collator->sort(@not_sorted);
 
 #compare
 $result = $Collator->cmp($a, $b); # returns 1, 0, or -1.

=head1 DESCRIPTION

Lingua::CU::Collate is a wrapper around Unicode::Collate that provides a custom collation tailoring for Church Slavonic

All text supplied to this library must be encoded in UTF-8 and, unless otherwise specified, is assumed to be
in Unicode. For more on Church Slavonic using Unicode, and for a description of the tailoring, please see the paper
I<Roadmap for Church Slavonic Typography in the Unicode Standard> available at 
http://www.ponomar.net/.

This program is ALPHA STAGE SOFTWARE and is provided with ABSOLUTELY NO WARRANTY of any kind,
express or implied, not even the implied warranties of merchantability, fitness for a purpose, or non-infringement.

=head2 EXPORT

This module provides no methods except for new. It only serves as a wrapper around Unicode::Collate.

=head1 METHODS

=head2 new

Usage: C<new( %tailoring )>

Creates a new Unicode::Collate object. The same keys in C<tailoring> may be specified as would be specified in creating Unicode::Collate directly
however the following are reserved by Lingua::CU::Collate and may not be overwritten: C<suppress>, C<locale_version> 
and C<upper_before_lower>. If C<entry> is specified, it is appended to the entries specified by Lingua::CU::Collate.

=head1 SEE ALSO

This software is part of the Ponomar Project (see http://www.ponomar.net/​).

Be sure to read the I<Roadmap for Church Slavonic Typography in the Unicode Standard> and to download the 
Unicode-compatible Hirmos Ponomar font.

Be sure to read as well C<perluniintro> and C<perllocale> in the Perl manual.

=head1 AUTHOR

Aleksandr Andreev <aleksandr.andreev@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-2014 by Aleksandr Andreev

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl you may have available.

=cut

