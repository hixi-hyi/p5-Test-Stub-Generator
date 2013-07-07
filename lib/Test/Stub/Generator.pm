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
    my $SINGLE      = 0;
    my @ARRAY       = ( 0, 1 );
    my %HASH        = ( a => 1 );
    my $A_REF       = [ 0, 1 ];
    my $H_REF       = { a => 1 };
    my @COMPLEX     = ( $SINGLE, $A_REF, $H_REF );
    
    *Some::Class::method = make_method(
        [
            # checking argument
            { expects => [ $SINGLE ],   return => $MEANINGLESS }, #1A single value
            { expects => [ @ARRAY ],    return => $MEANINGLESS }, #1B array
            { expects => [ %HASH ],     return => $MEANINGLESS }, #1C hash
            { expects => [ $A_REF ],    return => $MEANINGLESS }, #1D array_ref
            { expects => [ $H_REF ],    return => $MEANINGLESS }, #1E hash_ref
            { expects => [ @COMPLEX ],  return => $MEANINGLESS }, #1F multi value
            # cotrol return_values
            { expects => [$MEANINGLESS], return => $SINGLE }, #2A single
            { expects => [$MEANINGLESS], return => $A_REF }, #2B array_ref
            { expects => [$MEANINGLESS], return => $H_REF }, #2C hash_ref
            { expects => [$MEANINGLESS], return => [ @COMPLEX ] }, #2D multi value
            { expects => [$MEANINGLESS], return => sub{ @ARRAY } }, #2E array
            { expects => [$MEANINGLESS], return => sub{ %HASH } }, #2F hash
            # dont check argument (using Test::Deep)
            { expects => [ignore, 1], return => [$MEANINGLESS] },
            # checking type (using Test::Deep::Matcher)
            { expects => [is_integer], return => [$MEANINGLESS] },
            { expects => [is_string],  return => [$MEANINGLESS] },
        ],
        {
            display => 'synopisis'
        }
    );
    
    my $obj = Some::Class->new;
    
    subtest "auto check method argument" => sub {
        $obj->method($SINGLE);
        #{ expects => [ $SINGLE ], return => xxxx }, #1A single
    
        $obj->method(@ARRAY);
        #{ expects => [ @ARRAY ], return => xxxx }, #1B array
    
        $obj->method(%HASH); #1C hash
        #{ expects => [ %HASH ], return => xxxx }, #1C hash
    
        $obj->method($A_REF); #1D array_ref
        #{ expects => [ $A_REF ], return => xxxx }, #1D array_ref
    
        $obj->method($H_REF); #1E hash_ref
        #{ expects => [ $H_REF ], return => xxxx }, #1E hash_ref
    
        $obj->method(@COMPLEX); #1F multi value
        #{ expects => [ @COMPLEX ], return => xxxx }, #1F multi value
    };
    
    subtest "control return_values" => sub {
        is_deeply( $obj->method($MEANINGLESS), $SINGLE, '2A single value' );
        #{ expects => xxxx, return => $SINGLE }, #2A single
    
        is_deeply( $obj->method($MEANINGLESS), $A_REF, '2B array_ref' );
        #{ expects => xxxx, return => $A_REF }, #2B array_ref
    
        is_deeply( $obj->method($MEANINGLESS), $H_REF, '2C hash_ref' );
        #{ expects => xxxx, return => $H_REF }, #2C hash_ref
    
        is_deeply( $obj->method($MEANINGLESS), [ @COMPLEX ], '2D nested array_ref' );
        #{ expects => xxxx, return => [ @COMPLEX ] }, #2D multi value
    
        is_deeply( [$obj->method($MEANINGLESS)], [@ARRAY], '2E array' );
        #{ expects => xxxx, return => sub{ @ARRAY } }, #2E array
    
        is_deeply( [$obj->method($MEANINGLESS)], [%HASH], '2F hash' );
        #{ expects => xxxx, return => sub{ %HASH } }, #2F hash
    };
    
    subtest "dont check argument using type (Test::Deep)" => sub {
        $obj->method(sub{},1);
        #{ expects => [ignore, 1], return => xxxx },
    };
    
    subtest "check method argument using type (Test::Deep::Matcher)" => sub {
        $obj->method(1);
        #{ expects => [is_integer], return => xxxx },
        $obj->method("AAAA");
        #{ expects => [is_string],  return => xxxx },
    };

done_testing;


=head1 DESCRIPTION

Test::Stub::Generator is library for supports the programmer in wriring test code.

=head1 LICENSE

Copyright (C) Hiroyoshi Houchi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Hiroyoshi Houchi E<lt>hixi@cpan.orgE<gt>

=cut

