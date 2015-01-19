package FFI::Platypus::Type::StringPointer;

use strict;
use warnings;
use FFI::Platypus;
use Config ();

# ABSTRACT: Convert a pointer to a string and back
# VERSION

=head1 SYNOPSIS

In your C code:

 void string_pointer_argument(const char **string)
 {
   ...
 }
 const char ** string_pointer_return(void)
 {
   ...
 }

In your Platypus::FFI code:

 use FFI::Platypus::Declare;
 
 load_custom_type StringPointer => 'my_string_pointer';
 
 attach string_pointer_argument => ['my_string_pointer'] => 'void';
 attach string_pointer_return   => [] => 'my_string_pointer';
 
 my $string = "foo";
 
 string_pointer_argument(\$string); # $string may be modified
 
 $ref = string_pointer_return();
 
 print $$ref;  # print the string pointed to by $ref

=head1 DESCRIPTION

This module provides a L<FFI::Platypus> custom type for pointers to
strings.

=cut

use constant _incantation =>
  $^O eq 'MSWin32' && $Config::Config{archname} =~ /MSWin32-x64/
  ? 'Q'
  : 'L!';
use constant _pointer_buffer => "P" . FFI::Platypus->new->sizeof('opaque');

my @stack;

sub perl_to_native
{
  if(defined $_[0])
  {
    my $packed = pack 'P', ${$_[0]};
    my $pointer_pointer = pack 'P', $packed;
    my $unpacked = unpack _incantation, $pointer_pointer;
    push @stack, [ \$packed, \$pointer_pointer ];
    return $unpacked;
  }
  else
  {
    push @stack, [];
    return undef;
  }
}

sub perl_to_native_post
{
  my($packed) = @{ pop @stack };
  return unless defined $packed;
  # TODO: doing an eval here to ignore ro value
  # modification.  Can we instead check for
  # ro on the scalar and if so would that be
  # faster than the eval
  eval { ${$_[0]} = unpack 'p', $$packed };
}

sub native_to_perl
{
  return unless defined $_[0];
  my $pointer_pointer = unpack(_incantation, unpack(_pointer_buffer, pack(_incantation, $_[0])));
  $pointer_pointer ? \unpack('p', pack(_incantation, $pointer_pointer)) : \undef;
}

sub ffi_custom_type_api_1
{
  return {
    native_type         => 'opaque',
    perl_to_native      => \&perl_to_native,
    perl_to_native_post => \&perl_to_native_post,
    native_to_perl      => \&native_to_perl,
  }
}

1;

=head1 SEE ALSO

=over 4

=item L<FFI::Platypus>

Main Platypus documentation.

=item L<FFI::Platypus::Declare>

Declarative interface for Platypus.

=item L<FFI::Platypus::Type>

Platypus types documentation.

=back

=cut
