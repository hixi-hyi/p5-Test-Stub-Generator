package Test::Stub::Generator;
use 5.008005;
use strict;
use warnings;

use Test::More;
use Test::Deep;

use Exporter qw(import);
use Carp qw(croak);
use Class::Monadic;

our $VERSION   = "0.01";
our @EXPORT    = qw(make_subroutine make_subroutine_utils make_method make_method_utils);
our @EXPORT_OK = qw(make_subroutine_from_list make_method_from_list);

sub make_subroutine {
    my ($ers, $opts) = @_;
    $opts ||= {};
    return scalar _build_subroutine( $ers, { %{$opts}, is_object => 0 } );
}

sub make_subroutine_utils {
    my ($ers, $opts) = @_;
    $opts ||= {};
    return _build_subroutine( $ers, { %{$opts}, is_object => 0 } );
}

sub make_method {
    my ($ers, $opts) = @_;
    $opts ||= {};
    return scalar _build_subroutine( $ers, { %{$opts}, is_object => 1 } );
}

sub make_method_utils {
    my ($ers, $opts) = @_;
    $opts ||= {};
    return _build_subroutine( $ers, { %{$opts}, is_object => 1 } );
}

sub make_subroutine_from_list {
    my %args = @_;
    my $opts = $args{opts} || {};
    return scalar _from_list(
        $args{expects},
        $args{return},
        { %{ $opts }, is_object => 0 },
    );
}

sub make_subroutine_utils_from_list {
    my %args = @_;
    my $opts = $args{opts} || {};
    return _from_list(
        $args{expects},
        $args{return},
        { %{ $opts }, is_object => 0 },
    );
}

sub make_method_from_list {
    my %args = @_;
    my $opts = $args{opts} || {};
    return scalar _from_list(
        $args{expects},
        $args{return},
        { %{ $opts }, is_object => 1 },
    );
}

sub make_method_utils_from_list {
    my %args = @_;
    my $opts = $args{opts} || {};
    return _from_list(
        $args{expects},
        $args{return},
        { %{ $opts }, is_object => 1 },
    );
}

sub _from_list {
    my ( $expects, $return, $opts ) = @_;
    if( scalar @{$expects} != scalar @{$return} ) {
        croak "expects size and return size are different";
    }
    my $er_list = [];
    for (my $i = 0; $i < scalar @$expects; $i++){
        push @$er_list, {
            expects => $expects->[$i],
            return  => $return->[$i],
        };
    }

    return _build_subroutine( $er_list, $opts );
}

sub _build_subroutine {
    my ($er_list, $opts) = @_;

    my $display    = $opts->{display}   || 'stub';
    my $is_object  = $opts->{is_object} || 0;
    my $is_repeat  = $opts->{is_repeat} || 0;
    my $call_count = 0;

    my $method = sub {
        my $input = [@_];
        shift @$input if $is_object;
        $call_count++;

        my $er = $is_repeat? $er_list->[0] : shift @$er_list;
        unless ( defined $er ) {
            fail 'expects and return are already empty.';
            return undef;
        }

        my $expects = $er->{expects};
        my $return  = $er->{return};

        cmp_deeply($input, $expects, "[$display] arguments are as You expected")
            or note explain +{ input => $input, expects => $expects };

        return (ref $return eq 'CODE')? $return->() : $return;
    };

    if (!wantarray) {
        return $method;
    }

    my $util = bless( {}, 'Test::Stub::Generator::Util' );
    Class::Monadic->initialize($util)->add_methods(
        has_next => sub {
            return @$er_list ? 1 : 0;
        },
        is_repeat => sub {
            return $is_repeat;
        },
        called_count => sub {
            return $call_count;
        },
    );

    return ($method, $util);
}

1;
__END__

=encoding utf-8

=head1 NAME

Test::Stub::Generator - be able to generate stub (submodule and method) having check argument and control return value.

=head1 SYNOPSIS
    use strict;
    use warnings;

    use Test::More;
    use Test::Deep;
    use Test::Deep::Matcher;
    use Test::Stub::Generator;

    ###
    # sample package
    ###
    package Some::Class;
    sub new { bless {}, shift };
    sub method;

    ###
    # test code
    ###
    package main;

    my $MEANINGLESS = -1;

    my ($method, $util) = make_method_utils(
    #my $method = make_method(
        [
            # automatic checking method arguments
            { expects => [ 0, 1 ], return => $MEANINGLESS },
            # control return_values
            { expects => [$MEANINGLESS], return => [ 0, 1 ] },

            # expects supported ignore(Test::Deep) and type(Test::Deep::Matcher)
            { expects => [ignore, 1], return => $MEANINGLESS },
            { expects => [is_integer], return => $MEANINGLESS },
        ],
        {
            display => 'synopisis'
        }
    );

    *Some::Class::method = $method;
    my $obj = Some::Class->new;

    # { expects => [ 0, 1 ], return => xxxx }
    $obj->method( 0, 1 );
    # ok xxxx- [synopisis] arguments are as You expected
    # ( automaic checking method arguments )

    # { expects => xxxx, return => [ 0, 1 ] }
    is_deeply( $obj->method($MEANINGLESS), [ 0, 1 ], 'return values are as You expected' );
    # ok xxxx- return values are as You expected
    # ( control method return_value )

    # { expects => [ignore, 1], return => xxxx }
    $obj->method( sub{}, 1 );
    # ok xxxx- [synopisis] arguments are as You expected
    # ( automatic checking to exclude ignore fields )

    # { expects => [is_integer], return => xxxx }
    $obj->method(1);
    # ok xxxx- [synopisis] arguments are as You expected
    # ( automatic checking to use Test::Deep::Matcher )

    ok(!$util->has_next, 'empty');
    is $util->called_count, 4, 'called_count is 4';

    done_testing;

=head1 DESCRIPTION

Test::Stub::Generator is library for supports the programmer in wriring test code.

=head1 Functions

=head2 make_subroutine($expects_and_return_list, $opts)

simulate subroutine (do not receive $self)

=head2 make_method($expects_and_return_list, $opts)

simulate object method (receive $self)

=head1 Parameters

=head2 $expects_and_return_list(first arguments)

  my $method = make_method(
    [
      { expects => [1], return => 2 }
    ]
  );

=item expects

automaic checking $method_argument

    $method->(1); # ok xxxx- [stub] arguments are as You expected

=item return

control return_value

    my $return = $method->(1); # $return = 2;

=head2 $opts(second arguments)

  my $method = make_method(
    [
      { expects => [1], return => 2 }
    ],
    { display => "display name", is_repeat => 1 }
  );

=item display

change displayed name when testing

=item is_repeat

repeat mode ( repeating $expects_and_return_list->{0] )

=head1 Utility Method (second return_value method)

  my ($method, $util) = make_subroutine_utils($expects_and_return_list, $opts)
  my ($method, $util) = make_method_utils($expects_and_return_list, $opts)

=item $util->called_count

return a number of times that was method called

=item $util->has_next

return a boolean.
if there are still more $expects_and_return_list, then true(1).
if there are not, then false(0).

=item $util->is_repeat

return a value $opt->{is_repeat}

=head1 Setting Sheat

=head2 single value

    # { expects => [ 1 ], return => xxxx }
    $obj->method(1);

    # { expects => xxxx, return => 1 }
    is_deeply( $obj->method($MEANINGLESS), 1, 'single' );

=head2 array value

    # { expects => [ ( 0, 1 ) ], return => xxxx }
    $obj->method( 0, 1 );

    # { expects => xxxx, return => sub{ ( 0, 1 ) } }
    is_deeply( [$obj->method($MEANINGLESS)], [ ( 0, 1 ) ], 'array' );

=head2 hash value

    # { expects => [ a => 1 ], return => xxxx }
    $obj->method(a => 1);

    # { expects => xxxx, return => sub{ a => 1 } }
    is_deeply( [$obj->method($MEANINGLESS)], [ a => 1 ], 'hash' );

=head2 array ref

    # { expects => [ [ 0, 1 ] ], return => xxxx }
    $obj->method( [ 0, 1 ] );

    # { expects => xxxx, return => [ 0, 1 ] }
    is_deeply( $obj->method($MEANINGLESS), [ 0, 1 ], 'array_ref' );

=head2 hash ref

    # { expects => [ { a => 1 } ], return => xxxx }
    $obj->method( { a => 1 } );

    # { expects => xxxx, return => { a => 1 } }
    is_deeply( $obj->method($MEANINGLESS), { a => 1 }, 'hash_ref' );

=head2 complex values

    # { expects => [ 0, [ 0, 1 ], { a => 1 } ], return => xxxx }
    $obj->method( 0, [ 0, 1 ], { a => 1 } );

    # { expects => xxxx, return => [ 0, [ 0, 1 ], { a => 1 } ] }
    is_deeply( $obj->method($MEANINGLESS), [ 0, [ 0, 1 ], { a => 1 } ], 'complex' );

=head2 dont check arguments (Test::Deep)

    # { expects => [ignore, 1], return => xxxx }
    $obj->method(sub{},1);

=head2 check argument using type (Test::Deep::Matcher)

    # { expects => [is_integer], return => xxxx }
    $obj->method(1);

    # { expects => [is_string],  return => xxxx }
    $obj->method("AAAA");

=head1 LICENSE

Copyright (C) Hiroyoshi Houchi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Hiroyoshi Houchi E<lt>hixi@cpan.orgE<gt>

=cut

