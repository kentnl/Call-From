requires 'Exporter';
requires 'strict';
requires 'warnings';

on test => sub {
    requires 'Test::More';
    requires 'strict';
    requires 'warnings';
};

on develop => sub {
    requires 'CPAN::Meta::Prereqs';
    requires 'Carp';
    requires 'Module::CPANfile';
    requires 'Module::Metadata';
    requires 'PIR';
    requires 'Perl::PrereqScanner';
    requires 'lib';
    requires 'perl', '5.006';
    requires 'strict';
    requires 'warnings';
};
