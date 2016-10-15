#!/usr/bin/perl 

#
# Read YAML play, generate Ruby driver, execute Ruby driver
#
# 2016 (c) Paul Tchistopolskii, http://www.pault.com
#
# License is BSD 
#

use strict;
no warnings 'all';
use feature qw(switch);

use YAML::XS;
use Data::Dumper;

my $yml_play = shift || die "Use: $0 play.yml";
my $y = YAML::XS::LoadFile( $yml_play );
#print Dumper($y);

die "Expecting list of pirimitives, got: ", Dumper($y) if (ref($y) ne "ARRAY");

my $VS = "";
my %VH = ();

# Globals
my $Browser = "ie";

# Bcode
my @BB = ();

sub B{ my @b = @_; push @BB, \@b; }

my %c2m = (
    'text-name-set' => 
        sub { B('set_text_by_name', $VH{'name'}, $VH{'set'}) },

    'radio-name-set' => 
        sub { B('set_radio_by_name', $VH{'name'}, $VH{'set'}) },

    'button-name-click' => 
        sub { B('click_button_by_name', $VH{'name'}, $VH{'click'}) },

    'page-get' => 
        sub { B('get_page', $VH{'get'}) }
);

sub BcontrolH($){
    my $ctype = shift;
    my $name = $VH{'name'};
    foreach my $op ( keys %VH ){
        next if ($op eq "name");
        my $param = $VH{$op};
        my $hoo_key = "$ctype-$op";
        $hoo_key = "$ctype-name-$op" if ($name);
        my $cback = $c2m{$hoo_key};
        &$cback();
        die "($hoo_key) bad control: ", Dumper(\%VH) if (!$cback);
    }
}

my %p2p = (
    'browser-'      => sub { $Browser = $VS },
    'page-'         => sub { B('goto_page', $VS) },
    'sleep-'        => sub { B('sleep', $VS) },
    'text-HASH'     => sub { BcontrolH('text') },
    'radio-HASH'    => sub { BcontrolH('radio') },
    'button-HASH'   => sub { BcontrolH('button') },
    'page-HASH'     => sub { BcontrolH('page') } 
);

# Pass 1
# Foreach element - validate it and produce Bcode

foreach my $e ( @{$y} ){
    $VS = ""; %VH = ();
    die "Bad element! Expected hash, got: ", Dumper($e) 
        if (ref($e) ne "HASH");
    die "Bad element! Expected 'name -> value', got: ", Dumper($e) 
        if (scalar(keys %{$e}) != 1);

    my ($K, $V) = ( (keys %{$e})[0], $e->{(keys %{$e})[0]} );
    #print Dumper($e); 
    #print "TYP:" , ref($V) . "\n";
    
    $VS = $V    if (ref(\$V) eq "SCALAR");
    %VH = %{$V} if (ref($V) eq "HASH");

    die "Bad element!", Dumper(\$V) if ( !$VS && !%VH );
    #print "$K -> VS: $VS VH:", Dumper(\%VH), "\n";

    my $hoo_key = "$K-" . ref($V);
    my $cback = $p2p{$hoo_key};

    die "($hoo_key) bad element: ", Dumper($e) if (!$cback);
    &$cback();
}

#print Dumper(\@BB);

# Pass 2. Dress the tree a little bit

my @browser_b = ( 'browser', $Browser );
unshift @BB, \@browser_b;

#print Dumper(\@BB);

# Pass 3. Generate
unlink("FishDriver.rb");

open(OUT, ">FishDriver.rb") || die "Can't write Fish Driver";

print OUT "require \"watir\"\n";

foreach my $e ( @BB ){
    my ($cmd, $p1, $p2) = @{$e};
    #print Dumper($e);
    given( $cmd ){
        when( 'browser' )   { print OUT "b = Watir::Browser.new :$p1\n";}
        when( 'goto_page' ) { print OUT "b.goto \"$p1\"\n";}
        when( 'sleep' )     { print OUT "sleep $p1\n"; }

        when( 'set_text_by_name' ){ 
            print OUT "b.text_field( :name => '$p1' ).set '$p2'\n";
        }

        when( 'set_radio_by_name' ){ 
            print OUT "b.radio( :name => '$p1' ).set '$p2'\n";
        }

        when( 'click_button_by_name' ){ 
            print OUT "b.button( :name => '$p1' ).click\n";
        }

        when( 'get_page' ){
            if ($p1 eq "html") {
                print OUT "puts b.html()\n";
            } else {
                print OUT "puts b.text\n";
            }
        }

        default{
            die "Unknown cmd: $cmd", Dumper($e);
        }
    }
    print OUT "sleep 1\n" if ($cmd ne 'sleep');
}

print OUT "sleep 3\nb.close\n";
close(OUT);

# We develop on *nix, we run on win
if ($^O =~ m/win/i) {
    system "ruby FishDriver.rb";
} else {
    system "cat FishDriver.rb";
}

