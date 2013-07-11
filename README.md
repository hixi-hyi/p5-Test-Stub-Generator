# NAME

Test::Stub::Generator - be able to generate stub (submodule and method) having check argument and control return value.

# SYNOPSIS
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

# DESCRIPTION

Test::Stub::Generator is library for supports the programmer in wriring test code.

# Functions

## make\_subroutine($expects\_and\_return\_list, $opts)

simulate subroutine (do not receive $self)

## make\_method($expects\_and\_return\_list, $opts)

simulate object method (receive $self)

# Parameters

## $expects\_and\_return\_list(first arguments)

    my $method = make_method(
      [
        { expects => [1], return => 2 }
      ]
    );

- expects

automaic checking $method\_argument

    $method->(1); # ok xxxx- [stub] arguments are as You expected

- return

control return\_value

    my $return = $method->(1); # $return = 2;

## $opts(second arguments)

    my $method = make_method(
      [
        { expects => [1], return => 2 }
      ],
      { display => "display name", is_repeat => 1 }
    );

- display

change displayed name when testing

- is\_repeat

repeat mode ( repeating $expects\_and\_return\_list->{0\] )

# Utility Method (second return\_value method)

    my ($method, $util) = make_subroutine_utils($expects_and_return_list, $opts)
    my ($method, $util) = make_method_utils($expects_and_return_list, $opts)

- $util->called\_count

return a number of times that was method called

- $util->has\_next

return a boolean.
if there are still more $expects\_and\_return\_list, then true(1).
if there are not, then false(0).

- $util->is\_repeat

return a value $opt->{is\_repeat}

# Setting Sheat

## single value

    # { expects => [ 1 ], return => xxxx }
    $obj->method(1);

    # { expects => xxxx, return => 1 }
    is_deeply( $obj->method($MEANINGLESS), 1, 'single' );

## array value

    # { expects => [ ( 0, 1 ) ], return => xxxx }
    $obj->method( 0, 1 );

    # { expects => xxxx, return => sub{ ( 0, 1 ) } }
    is_deeply( [$obj->method($MEANINGLESS)], [ ( 0, 1 ) ], 'array' );

## hash value

    # { expects => [ a => 1 ], return => xxxx }
    $obj->method(a => 1);

    # { expects => xxxx, return => sub{ a => 1 } }
    is_deeply( [$obj->method($MEANINGLESS)], [ a => 1 ], 'hash' );

## array ref

    # { expects => [ [ 0, 1 ] ], return => xxxx }
    $obj->method( [ 0, 1 ] );

    # { expects => xxxx, return => [ 0, 1 ] }
    is_deeply( $obj->method($MEANINGLESS), [ 0, 1 ], 'array_ref' );

## hash ref

    # { expects => [ { a => 1 } ], return => xxxx }
    $obj->method( { a => 1 } );

    # { expects => xxxx, return => { a => 1 } }
    is_deeply( $obj->method($MEANINGLESS), { a => 1 }, 'hash_ref' );

## complex values

    # { expects => [ 0, [ 0, 1 ], { a => 1 } ], return => xxxx }
    $obj->method( 0, [ 0, 1 ], { a => 1 } );

    # { expects => xxxx, return => [ 0, [ 0, 1 ], { a => 1 } ] }
    is_deeply( $obj->method($MEANINGLESS), [ 0, [ 0, 1 ], { a => 1 } ], 'complex' );

## dont check arguments (Test::Deep)

    # { expects => [ignore, 1], return => xxxx }
    $obj->method(sub{},1);

## check argument using type (Test::Deep::Matcher)

    # { expects => [is_integer], return => xxxx }
    $obj->method(1);

    # { expects => [is_string],  return => xxxx }
    $obj->method("AAAA");

# LICENSE

Copyright (C) Hiroyoshi Houchi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Hiroyoshi Houchi <hixi@cpan.org>
