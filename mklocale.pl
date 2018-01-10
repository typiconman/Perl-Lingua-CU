#!/usr/bin/perl

# This script makes the CU Locale based on the version of DUCET being used
require 5.006;
use strict;
use utf8;
use Carp;
use Unicode::Collate '1.04';

BEGIN {
    unless ("A" eq pack('U', 0x41)) {
	die "Lingua::CU cannot stringify a Unicode code point\n";
    }
    unless (0x41 == unpack('U', 'A')) {
	die "Lingua::CU cannot get a Unicode code point\n";
    }
}

use constant SBase  => 0xAC00;
use constant SFinal => 0xD7A3;
use constant NCount =>    588;
use constant TCount =>     28;
use constant LBase  => 0x1100;
use constant VBase  => 0x1161;
use constant TBase  => 0x11A7;

use constant Min2Wt => 0x20;
use constant Min3Wt => 0x02;

my $OvCJK  = 'overrideCJK';
my $OvHang = 'overrideHangul';

my $vDUCET;	# from @version, such as "6.0.0"
my $DEFAULT_LOCALE_VERSION = Unicode::Collate->VERSION;
my $Use4th;	# Use 4th level (Unicode 6.2.0 or before)
my %Keys;		# "0300" => "[.0000.0035.0002.0300]"
my %Code;		# "[.0000.0035.0002.0300]" => "0300"
my %Name;		# "0300" => "COMBINING GRAVE ACCENT"
my %Equiv;		# "[.0000.0035.0002.0300]" => ["0340", "0953"]

sub get_resource_by_name {
	my $path = shift;
	my @found = ();
	INC_ENTRY:
	foreach my $inc_entry (@INC) {
		if ( ref $inc_entry ) {
			warn q{Don't know how to handle @INC entries of type: } . ref $inc_entry;
			next INC_ENTRY;
		}
		my $full_path = File::Spec->join($inc_entry, $path);
		if ( -e $full_path ) {
			if ( ! wantarray ) {
				return $full_path;
			}
			push @found, $full_path;
		}
	}
	wantarray ? return @found : return;
}

sub trim { $_[0] =~ s/^\ +//; $_[0] =~ s/\ +\z// }
sub _getHexArray { map hex, $_[0] =~ /([0-9A-Fa-f]+)/g }
sub ce {
	my $var = shift;
	my $vc = $var ? '*' : '.';
	my $hx = join '.', map { sprintf '%04X', $_ } @_;
	return "[$vc$hx]";
}


# figure out where DUCET is located
my $ducet = get_resource_by_name('Unicode/Collate/allkeys.txt');
my $ENT_FMT = "%-9s ; %s # %s\n";
my $RE_CE   = '(?:\[[0-9A-Fa-f\.\*]+\])';

croak "Unable to locate DUCET. Execution stopped " unless (defined $ducet);
croak "Unable to locate DUCET. Execution stopped " unless (length $ducet);
croak "Unable to locate DUCET. Execution stopped " unless (-e $ducet);

# now read DUCET
open (DUCET, $ducet) || croak ("Unable to read from DUCET. Maybe you need to be root?");
while (my $line = <DUCET>) {
	chomp $line;
	next if $line =~ /^\s*#/;
	$vDUCET = $1 if $line =~ /^\@version\s*(\S*)/;

	next if $line !~ /^\s*[0-9A-Fa-f]/;
	my $name = ($line =~ s/[#%]\s*(.*)//) ? $1 : '';
	my($e, $k) = split /;/, $line;
	trim($e);
	trim($k);
	$name =~ s/; QQ[A-Z]+//;
	$name =~ s/^ ?\[[0-9A-F]+\] ?//;

	if ($k =~ /\[\.0000\.0000\.0000(\.?0*)\]/) {
		$Use4th = 1 if $1;
		$Name{$e} = $name;
		next;
	}
	croak "Wrong Entry: <charList> must be separated by ';' " . "from <collElement>" if ! $k;
	push @{ $Equiv{$k} }, $e if exists $Code{$k};

	$Keys{$e} = $k;
	$Code{$k} = $e if !exists $Code{$k};
	$Name{$e} = $name;
	# ignoring all the CJK stuff -- not needed for Church Slavic
}
close (DUCET);

# $Code{$k} : precomposed (such as 04D1, CYRILLIC SMALL LETTER A WITH BREVE)
# $eqs      : equivalent sequence (such as <0430><0306>)
# $starter  : starter codepoint (integer such as hex '0430')
my @Contractions; # store Cyrillic, currently required, and others.
for my $k (sort keys %Equiv) {
	if ($Code{$k} !~ / / && $Equiv{$k}[0] =~ / /) {
		(my $eqs = "<$Equiv{$k}[0]>") =~ s/ /></g;
		my $starter = $eqs =~ /^<([0-9A-Fa-f]+)>/ ? hex($1) : '';
		push @Contractions, [$starter, "$Code{$k};$eqs"];
	}
}

# read the cu.txt file
my $in = "cu.txt";
my $out = "lib/Lingua/CU/cu.pl";
my %locale_keys;

open (INPUT, "< $in") || croak "Cannot read from collate definition file cu.txt: $!";
open (OUTPUT, "> $out") || croak "Cannot create output file cu.pl: $!";
binmode OUTPUT;

my $ptxt  = '';
my $entry = '';
my $locale_version = $DEFAULT_LOCALE_VERSION;

while (<INPUT>) {
	chomp;
	next if /^\s*\z/;
	if (s/^locale_version//) {
		$locale_version = $1 if /(\S+)/;
		next;
	}
	if (/^(alternate)\s+(\S+)/) {
		my $v = "variable";
		$ptxt .= "   $v => '$2',\n";
		$ptxt .= "   $1 => '$2',\n";
		next;
	}
	if (/^backwards$/) {
		$ptxt .= "   backwards => 2,\n";
		next;
	}
	if (/^upper$/) {
		$ptxt .= "   upper_before_lower => 1,\n";
		next;
	}
	if (s/^suppress//) { #/
		s/\s*-\s*/../g;
		my @c = split;
		s/(?:0[Xx])?([0-9A-Fa-f]+)/0x$1/g for @c;
		my $list = join ", ", @c;
		$ptxt .= "   suppress => [$list],\n";
		next;
	}
	if (/^([\s\-0-9A-Fa-fXx]+)\z/) { # continue the last list
		s/\s*-\s*/../g;
		my @c = split;
		s/(?:0[Xx])?([0-9A-Fa-f]+)/0x$1/g for @c;
		my $list = join ", ", @c;
		$ptxt =~ s/\](,$)/$1/;
		$ptxt .= "\t\t$list],\n";
		next;
	}
	if (/^\s*(#\s*)/) {
		$ptxt .= "$_\n" if $1 ne '#';
		next;
	}

	$entry .= parse_entry($_, \%locale_keys);
}

# precomposed chars to be suppressed as additional equivalents
if ($ptxt =~ /suppress => \[(.*)\]/s) {
	my @suplist = eval $1;
	my %suppressed;
	@suppressed{@suplist} = (1) x @suplist;

	for my $contract (@Contractions) {
		my $starter = $contract->[0];
		my $addline = $contract->[1];
		next if ! $suppressed{$starter};
		$entry .= parse_entry($addline, \%locale_keys);
	}
}

if ($entry) {
	my $v = $vDUCET ? " # for DUCET v$vDUCET" : '';
	$ptxt .= "   entry => <<'ENTRY',$v\n";
	$ptxt .= $entry;
	$ptxt .= "ENTRY\n";
}

my $lv = "   locale_version => $locale_version,\n";
print OUTPUT "+{\n$lv$ptxt};\n";

close (OUTPUT);
close (INPUT);

sub parse_entry {
	my $line = shift;
	my $lockeys = shift;

	my($e,$rule) = split_e_rule($line);
	my $name = getname($e);
	my $eq_rule = $rule eq '=';
	$rule = join '', map "<$_>", split ' ', $e if $eq_rule;
	my ($newce, $simpdec) = parse_rule($e, $rule, $lockeys);

	my $newentry = '';

	if (!$lockeys->{$e}) {
		$newentry .= sprintf $ENT_FMT, $e, $newce, $name if !$eq_rule;
		$lockeys->{$e} = $newce;
	} else {
		$newentry .= "# already tailored: $_\n";
	}

	if (!$simpdec && $Keys{$e}) { # duplicate for the decomposition
		my $key = $Keys{$e};
		my @ce = $key =~ /$RE_CE/go;
		if (@ce > 1) {
			my $ok = 1;
			my $ee = '';
			for my $c (@ce) {
				$ok = 0, last if !$Code{$c};
				$ee .= ' ' if $ee ne '';
				$ee .= $Code{$c};
			}
			if ($ok && !$lockeys->{$ee}) {
				$newentry .= sprintf $ENT_FMT, $ee, $newce, $name;
				$lockeys->{$ee} = $newce;
			}
			if ($ee =~ s/ 030([01])/ 034$1/ && $ok && !$lockeys->{$ee}) {
				$newentry .= sprintf $ENT_FMT, $ee, $newce, $name;
				$lockeys->{$ee} = $newce;
			}
		}
		if ($Equiv{$key}) {
			for my $eq (@{ $Equiv{$key} }) {
				next if $key =~ /^\[\.0000\.[^]]+\]\z/; # primary ignorable
				next if $lockeys->{$eq};
				next if $eq eq '3038'; # 3038 is identical to 2F17 in DUCET,
				$newentry .= sprintf $ENT_FMT, $eq, $newce, $Name{$eq};
				$lockeys->{$eq} = $newce;
			}
		}
	}
	return $newentry;
}

sub getunicode {
	return join ' ', map { sprintf '%04X', $_ } unpack 'U*', shift;
}

sub parse_element {
	my $e = shift;
	$e =~ s/\{([A-Za-z']+)\}/' '.getunicode($1).' '/ge;
	$e =~ s/ +/ /g;
	trim($e);
	return $e;
}

sub split_e_rule {
	my $line = shift;
	my($e, $r) = split /;/, $line;
	return (parse_element($e), $r);
}

sub getname {
	my $e = shift;
	return $Name{$e} if $Name{$e};  # single collation element (without <>)
	my @e = split ' ', $e;
	my @name = map { $Name{$_} ? $Name{$_} :
		/^FD[DE][0-9A-F]\z/ ? "noncharacter-$_" :
		'unknown' } @e;
	return sprintf '<%s>', join ', ', @name;
}

sub parse_rule {
	my $e    = shift;
	my $e1   = $e =~ /^([0-9A-F]+)/ ? $1 : '';
	my $rule = shift;
	my $lockeys = shift;
	my $result = '';
	my $simple_decomp = 1; # rules containing only [A-Za-z'"] or <XXXX>

	for (my $prerule = $rule; $rule ne ''; $prerule = $rule) {
		$rule =~ s/^ +//;
		last if $rule =~ /^#/;
		if ($rule =~ s/^($RE_CE)//o) {
			my $k = $1;
			my $var = $k =~ /^\[\*/ ? 1 : 0;
			my @c = _getHexArray($k);
			@c = @c[0..2] if !$Use4th;
			$result .= ce($var, @c);
			next;
		}

		if ($rule =~ s/^(<([0-9A-F ]+)>\+\+\+\?)//) {
			my $cr = $1;
			my @c = split ' ', $2;
			my $compat = $Keys{$e};
			my $decomp = join '', map {
				$Keys{$_} ? $Keys{$_} : $Keys{$_} #simple_cjk_deriv($_)
			} @c;
			my $regexp = $decomp;
			$regexp =~ s/([\[\]\.\*])/\\$1/g;
			$regexp =~ s/\.00(?:0[1-9A-F]|1[0-9A-F])(?:\\\.[0-9A-F]+|)\\\]
				/.(00(?:0[1-9A-F]|1[0-9A-F]))(?:\\.[0-9A-F]+|)\\\]/gx;
			# tertiary weights of 01-1F (excluding 00)
			my @tD = map hex($_), $decomp =~ /^$regexp\z/;
			my @tC = map hex($_), $compat =~ /^$regexp\z/;
			croak "wrong at $cr" unless @c == @tD && @c == @tC;
			my $r = join ' ', map "<$c[$_]>+++".($tC[$_] - $tD[$_]), 0..@c-1;
			$rule = $r.$rule;
			next;
		}

		my $key;
		if ($rule =~ s/^(<[0-9A-Za-z'{ }]+>|[A-Za-z'"])//) {
			my $e = $1;
			my $c = $e =~ tr/<>//d ? parse_element($e) : getunicode($e);
			croak "<$c> is too short" if 4 > length $c;
			$key = $lockeys->{$c} || $Keys{$c};
			if (!defined $key) {
				my $u = hex $c;
				my @u = $Use4th ? ($u) : ();
				my @r;
				if (SBase <= $u && $u <= SFinal) {
					@r = $lockeys->{$OvHang}->($u) if $lockeys->{$OvHang};
				} else {
					# but no check if $u is in CJK ideographs
					@r = $lockeys->{$OvCJK} ->($u) if $lockeys->{$OvCJK};
				}
				if (@r) {
					$key = join '', map {
						ref $_ ? ce(0, @$_) : ce(0, $_, Min2Wt, Min3Wt, @u)
					} @r;
				}
			}
		}

		my @base;
		for my $k ($key =~ /$RE_CE/go) {
			my $var = $k =~ /^\[\*/ ? 1 : 0;
			push @base, [$var, _getHexArray($k)];
		}
		croak "the rule seems wrong at $prerule" if !@base;

		my $replaced = 0;
		while ($rule =~ s/^(([+-])\2*)(\d+)//) {
			my $idx = length($1);
			my $num = $2 eq '-' ? -$3 : $3;
			$base[0][$idx] += $num;
			++$replaced;
		}

		$simple_decomp = 0 if $replaced;
		for my $c (@base) {
			$c->[4] = hex $e1 if $replaced && $Use4th;
			$result .= ce(@$c);
		}
		croak "something wrong at $rule" if $prerule eq $rule;
    	}
    	return($result, $simple_decomp);
}

