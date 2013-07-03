use strict;
use warnings;

use Test::More;
use Test::Stub::Generator;

my $increment = make_subroutine(
    [
        { expects => [0], return => 1, },
        { expects => [1], return => 2, },
    ],
);

is( &$increment(0), 1, 'sub return are as You expected' );
is( &$increment(1), 2, 'sub return are as You expected' );

done_testing;
