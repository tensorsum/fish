#!/usr/bin/perl 

use strict;
use warnings;

use YAML::XS;
use Data::Dumper;
my $yaml = YAML::XS::LoadFile( "hello.yml" );
print Dumper($yaml);

