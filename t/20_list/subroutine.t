use strict;
use warnings;

use Test::More;
use Test::Stub::Generator qw(make_subroutine_from_list);

my $expects = [
    [0],
    [1],
];
my $return = [
    1,
    2,
];

my $increment = make_subroutine_from_list(
    expects => $expects,
    return  => $return,
    opts    => {
        display => 'increment',
    }
);

is( &$increment(0), 1, 'sub return are as You expected' );
is( &$increment(1), 2, 'sub return are as You expected' );

done_testing;
