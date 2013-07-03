# NAME

Test::Stub::Generator - be able to generate submodule/method having check argument and control return value.

# SYNOPSIS

    use strict;
    use warnings;

    use Test::More;
    use Test::Deep qw(ignore);
    use Test::Deep::Matcher qw(is_integer is_string);
    use Test::Mock::Guard;
    use Test::Stub::Generator;

    package Some::Class;

    sub new { bless {}, shift }
    sub has_permission {
        my ($self, $user_id) = @_;
        return 0;
    }
    sub get_all_user_id {
        my ($self, $dbh) = @_;
        return 0;
    }
    sub get_user_by_id {
        my ($self, $dbh, $user_id) = @_;
        return 0;
    }
    sub validate {
        my ($self, $user) = @_;
        return 0;
    }
    sub get_authorized_user {
        my $self = shift;
        my $dbh = undef;
        my $user_ids = $self->get_all_user_id($dbh);
        my $authorized_users = [];
        for my $user_id (@$user_ids) {
            if($self->has_permission($user_id)) {
                my $user = $self->get_user_by_id($dbh, $user_id);
                push @$authorized_users, $user if $self->validate($user);
            }
        }
        return $authorized_users;
    }

    package main;

    my $has_permission = make_method(
        [
            { expects => [1], return => 1 },
            { expects => [2], return => 0 },
            { expects => [3], return => 1 },
            { expects => [4], return => 1 },
        ],
        { name => 'has_permission' }
    );

    my $get_user_by_id = make_method(
        [
            { expects => [ ignore, 1 ], return => { id => 1, name => 'user1' } },
            { expects => [ ignore, 3 ], return => { id => 3, name => 'user3' } },
            { expects => [ ignore, 4 ], return => { id => 4, name => 'user4' } },
        ],
        { name   => 'get_user_by_id' }
    );

    my $validate = make_method(
        [
            { expects => [ { id => is_integer, name => is_string } ], return => 1 },
        ],
        {
            is_repeat => 1,
            name      => 'validate',
        }
    );

    my $obj = Some::Class->new;
    my $guard = mock_guard(
        $obj => {
            'get_all_user_id' => [ 1, 2, 3, 4 ],
            'get_user_by_id'  => $get_user_by_id,
            'has_permission'  => $has_permission,
            'validate'        => $validate,
        }
    );

    is_deeply(
        $obj->get_authorized_user(),
        [
            { id => 1, name => 'user1' },
            { id => 3, name => 'user3' },
            { id => 4, name => 'user4' },
        ],
        'get_authorized_user is as You expected'
    );

    done_testing;

# DESCRIPTION

Test::Stub::Generator is library for supports the programmer in wriring test code.

# LICENSE

Copyright (C) Hiroyoshi Houchi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Hiroyoshi Houchi <hixi@cpan.org>
