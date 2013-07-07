use strict;
use warnings;

use Test::More;
use Test::Stub::Generator qw(make_method_from_list);

package Some::Class;
sub new { bless {}, shift }
sub increment;

package main;

my $expects = [
    [0],
    [1],
];
my $return = [
    1,
    2,
];

my $method = make_method_from_list(
    expects => $expects,
    return  => $return,
    opts    => {
        display => 'increment',
    }
);

my $obj = Some::Class->new;
*Some::Class::increment = $method;

is( $obj->increment(0), 1, 'sub return are as You expected' );
is( $obj->increment(1), 2, 'sub return are as You expected' );

done_testing;
