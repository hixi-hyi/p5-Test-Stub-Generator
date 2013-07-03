requires 'perl', '5.008001';

requires 'Test::More';
requires 'Test::Deep';

requires 'Exporter';
requires 'Carp';

on 'test' => sub {
    requires 'Test::Tester';
    requires 'Test::Deep::Matcher';
};

