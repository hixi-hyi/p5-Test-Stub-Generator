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

*Some::Class::method = $method;
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

ok(!$util->has_next, 'empty');
is $util->called_count, 4, 'called_count is 4';

done_testing;

