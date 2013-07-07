package Test::Stub::Generator;
use 5.008005;
use strict;
use warnings;

use Test::More;
use Test::Deep;

use Exporter qw(import);
use Carp qw(croak);

our $VERSION   = "0.01";
our @EXPORT    = qw(make_subroutine make_method);
our @EXPORT_OK = qw(make_subroutine_from_list make_method_from_list);

sub make_subroutine {
    my ($ers, $opts) = @_;
    $opts ||= {};
    return _build_subroutine( $ers, { %{$opts}, is_object => 0 } );
}

sub make_method {
    my ($ers, $opts) = @_;
    $opts ||= {};
    return _build_subroutine( $ers, { %{$opts}, is_object => 1 } );
}

sub make_subroutine_from_list {
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

    my $display   = $opts->{display}   || 'stub';
    my $is_object = $opts->{is_object} || 0;
    my $is_repeat = $opts->{is_repeat} || 0;

    return sub {
        my $input = [@_];
        shift @$input if $is_object;

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
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Test::Stub::Generator - be able to generate submodule/method having check argument and control return value.

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

    *Some::Class::method = make_method(
        [
            # checking argument
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

    my $obj = Some::Class->new;

    $obj->method( 0, 1 );
    # { expects => [ 0, 1 ], return => xxxx }
    # ok xxxx- [synopisis] arguments are as You expected

    is_deeply( $obj->method($MEANINGLESS), [ 0, 1 ], 'return values are as You expected' );
    # { expects => xxxx, return => [ 0, 1 ] }
    # ok xxxx- return values are as You expected

    $obj->method( sub{}, 1 );
    # { expects => [ignore, 1], return => xxxx }
    # ok xxxx- [synopisis] arguments are as You expected

    $obj->method(1);
    # { expects => [is_integer], return => xxxx }
    # ok xxxx- [synopisis] arguments are as You expected

    done_testing;

=head1 DESCRIPTION

Test::Stub::Generator is library for supports the programmer in wriring test code.

=head1 CheatSheet

=head2 single value
    $obj->method(1);
    #{ expects => [ 1 ], return => xxxx }

    is_deeply( $obj->method($MEANINGLESS), 1, 'single' );
    #{ expects => xxxx, return => 1 }

=head2 array value
    $obj->method( 0, 1 );
    #{ expects => [ ( 0, 1 ) ], return => xxxx }

    is_deeply( [$obj->method($MEANINGLESS)], [ ( 0, 1 ) ], 'array' );
    #{ expects => xxxx, return => sub{ ( 0, 1 ) } }

=head2 hash value
    $obj->method(a => 1);
    #{ expects => [ a => 1 ], return => xxxx }

    is_deeply( [$obj->method($MEANINGLESS)], [ a => 1 ], 'hash' );
    #{ expects => xxxx, return => sub{ a => 1 } }

=head2 array ref
    $obj->method( [ 0, 1 ] );
    #{ expects => [ [ 0, 1 ] ], return => xxxx }

    is_deeply( $obj->method($MEANINGLESS), [ 0, 1 ], 'array_ref' );
    #{ expects => xxxx, return => [ 0, 1 ] }

=head2 hash ref
    $obj->method( { a => 1 } );
    #{ expects => [ { a => 1 } ], return => xxxx }

    is_deeply( $obj->method($MEANINGLESS), { a => 1 }, 'hash_ref' );
    #{ expects => xxxx, return => { a => 1 } }

=head2 complex values
    $obj->method( 0, [ 0, 1 ], { a => 1 } );
    #{ expects => [ 0, [ 0, 1 ], { a => 1 } ], return => xxxx }

    is_deeply( $obj->method($MEANINGLESS), [ 0, [ 0, 1 ], { a => 1 } ], 'complex' );
    #{ expects => xxxx, return => [ 0, [ 0, 1 ], { a => 1 } ] }

=head2 dont check arguments (Test::Deep)
    $obj->method(sub{},1);
    #{ expects => [ignore, 1], return => xxxx }

=head2 check argument using type (Test::Deep::Matcher)
    $obj->method(1);
    #{ expects => [is_integer], return => xxxx }

    $obj->method("AAAA");
    #{ expects => [is_string],  return => xxxx }

=head1 LICENSE

Copyright (C) Hiroyoshi Houchi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Hiroyoshi Houchi E<lt>hixi@cpan.orgE<gt>

=cut

