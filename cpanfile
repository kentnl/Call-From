requires 'Exporter';
requires 'perl', '5.006';
requires 'strict';
requires 'warnings';

on test => sub {
    requires 'Test::More', '0.95_02';
    requires 'constant';
    requires 'strict';
    requires 'warnings';
};

on develop => sub {
    requires 'CPAN::Meta::Converter';
    requires 'CPAN::Meta::Prereqs';
    requires 'Carp';
    requires 'Config';
    requires 'Data::Dumper';
    requires 'Exporter';
    requires 'ExtUtils::MM';
    requires 'ExtUtils::MakeMaker';
    requires 'ExtUtils::Manifest';
    requires 'File::Find';
    requires 'File::Path';
    requires 'File::Spec';
    requires 'File::Temp';
    requires 'Getopt::Long';
    requires 'Module::CPANfile';
    requires 'Module::Metadata';
    requires 'PIR';
    requires 'Path::Tiny';
    requires 'Perl::PrereqScanner';
    requires 'base';
    requires 'lib';
    requires 'perl', '5.006';
    requires 'strict';
    requires 'warnings';
};
