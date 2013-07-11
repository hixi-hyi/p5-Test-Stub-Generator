use strict;
use warnings;

use Test::More;
use Test::Mock::Guard;
use Test::Stub::Generator;

###
# sample package (for mocking test)
###
package Some::Class;

sub new { bless {}, shift }

# not implementation
sub get_user_by_id {
    my ($self, $user_id) = @_;
    return 0;
}

# target method
sub get_users {
    my ($self, $user_ids) = @_;
    my $users = [];
    for my $user_id (@$user_ids) {
        my $user = $self->get_user_by_id($user_id);
        push @$users, $user;
    }
    return $users;
}

###
# testcode
###
package main;

subtest 'can get all users info' => sub {
    my $obj = Some::Class->new;
    my $get_user_by_id = make_method(
        [
            # checking arguments and control return_values
            { expects => [ 1 ], return => { id => 1, name => 'user1' } },
            { expects => [ 2 ], return => { id => 2, name => 'user2' } },
        ],
        { display  => 'get_user_by_id' }
    );
    my $guard = mock_guard(
        $obj => {
            'get_user_by_id' => $get_user_by_id,
        },
    );

    # check
    is_deeply(
        $obj->get_users([1,2]),
        [
            { id => 1, name => 'user1' },
            { id => 2, name => 'user2' },
        ],
        'get_users is as You expected'
    );
};

subtest 'cannot get users info' => sub {
    my $obj = Some::Class->new;
    my $guard = mock_guard(
        $obj => {
            'get_user_by_id' => scalar make_method(
                [
                    # checking arguments and control return_values
                    { expects => [ 1 ], return => undef },
                ],
                { display  => 'get_user_by_id' }
            ),
        },
    );

    # check
    is_deeply(
        $obj->get_users([1]),
        [
            undef,
        ],
        'get_users is as You expected'
    );
};

done_testing;
