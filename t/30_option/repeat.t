use strict;
use warnings;

use Test::More;
use Test::Stub::Generator;

my $repeat = make_subroutine(
    [
        { expects => [0], return => 1, },
    ],
    {
        is_repeat => 1
    },
);
is( &$repeat(0), 1, 'repeat 1' );
is( &$repeat(0), 1, 'repeat 2' );

done_testing;
