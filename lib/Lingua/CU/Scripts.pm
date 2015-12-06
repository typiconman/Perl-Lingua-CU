package Lingua::CU::Scripts;

use strict;

our $VERSION = '0.01';

1;

=head1 NAME

Lingua::CU::Scripts - Script supporting modules and scripts for Church Slavonic implementation

=head1 DESCRIPTION

This module contains a number of useful command-line programs for working with Church Slavonic:

  hip2unicode  - converts legacy HyperInvariant Presentation (HIP) encoding to Unicode
  ucs2unicode    - converts legacy Universal Church Slavonic (UCS) encoding to Unicode

When executed without parameters, most commands will emit usage message.

=head1 SEE ALSO

L<hip2unicode>,
L<ucs2unciode>.

=head1 AUTHOR

Aleksandr Andreev L<aleksandr.andreev@gmail.com>.

=head1 LICENSING

Copyright (c) 2015 Aleksandr Andreev (http://sci.ponomar.net/)

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl you may have available.

