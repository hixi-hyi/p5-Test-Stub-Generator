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

=head1 DESCRIPTION

Test::Stub::Generator is library for supports the programmer in wriring test code.

=head1 LICENSE

Copyright (C) Hiroyoshi Houchi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Hiroyoshi Houchi E<lt>hixi@cpan.orgE<gt>

=cut

