#! /usr/local/bin/perl -w

# vim: tabstop=4
# vim: syntax=perl

use strict;

use Test;

BEGIN {
	plan tests => 7;
}

use Locale::Recode;

sub int2utf8;

my $local2ucs = {};
my $ucs2local = {};

while (<DATA>) {
	my ($code, $ucs, undef) = map { oct $_ } split /\s+/, $_;
	$local2ucs->{$code} = $ucs;
	$ucs2local->{$ucs} = $code unless $ucs == 0xfffd;
}

my $cd_int = Locale::Recode->new (from => 'IBM420',
				  to => 'INTERNAL');
ok !$cd_int->getError;

my $cd_utf8 = Locale::Recode->new (from => 'IBM420',
				   to => 'UTF-8');
ok !$cd_utf8->getError;

my $cd_rev = Locale::Recode->new (from => 'INTERNAL',
				  to => 'IBM420');
ok !$cd_rev->getError;

# Convert into internal representation.
my $result_int = 1;
while (my ($code, $ucs) = each %$local2ucs) {
    my $outbuf = chr $code;
    my $result = $cd_int->recode ($outbuf);
    unless ($result && $outbuf->[0] == $ucs) {
	$result_int = 0;
	last;
    }
}
ok $result_int;

# Convert to UTF-8.
my $result_utf8 = 1;
while (my ($code, $ucs) = each %$local2ucs) {
    my $outbuf = chr $code;
    my $result = $cd_utf8->recode ($outbuf);
    unless ($result && $outbuf eq int2utf8 $ucs) {
        $result_utf8 = 0;
        last;
    }
}
ok $result_utf8;

# Convert from internal representation.
my $result_rev = 1;
while (my ($ucs, $code) = each %$ucs2local) {
    my $outbuf = [ $ucs ];
    my $result = $cd_rev->recode ($outbuf);
    unless ($result && $code == ord $outbuf) {
        $result_int = 0;
        last;
    }
}
ok $result_int;

# Check handling of unknown characters.
my $test_string1 = [ unpack 'c*', ' Supergirl ' ];
$test_string1->[0] = 0xad0be;
$test_string1->[-1] = 0xbeefbabe;
my $test_string2 = [ unpack 'c*', 'Supergirl' ];

my $unknown = "\xd0"; # Unknown character!

$cd_rev = Locale::Recode->new (from => 'INTERNAL',
		               to => 'IBM420',
				)
&& $cd_rev->recode ($test_string1)
&& $cd_rev->recode ($test_string2)
&& ($test_string2 = $unknown . $test_string2 . $unknown);

ok $test_string1 eq $test_string2;

sub int2utf8
{
    my $ucs4 = shift;
    
    if ($ucs4 <= 0x7f) {
	return chr $ucs4;
    } elsif ($ucs4 <= 0x7ff) {
	return pack ("C2", 
		     (0xc0 | (($ucs4 >> 6) & 0x1f)),
		     (0x80 | ($ucs4 & 0x3f)));
    } elsif ($ucs4 <= 0xffff) {
	return pack ("C3", 
		     (0xe0 | (($ucs4 >> 12) & 0xf)),
		     (0x80 | (($ucs4 >> 6) & 0x3f)),
		     (0x80 | ($ucs4 & 0x3f)));
    } elsif ($ucs4 <= 0x1fffff) {
	return pack ("C4", 
		     (0xf0 | (($ucs4 >> 18) & 0x7)),
		     (0x80 | (($ucs4 >> 12) & 0x3f)),
		     (0x80 | (($ucs4 >> 6) & 0x3f)),
		     (0x80 | ($ucs4 & 0x3f)));
    } elsif ($ucs4 <= 0x3ffffff) {
	return pack ("C5", 
		     (0xf0 | (($ucs4 >> 24) & 0x3)),
		     (0x80 | (($ucs4 >> 18) & 0x3f)),
		     (0x80 | (($ucs4 >> 12) & 0x3f)),
		     (0x80 | (($ucs4 >> 6) & 0x3f)),
		     (0x80 | ($ucs4 & 0x3f)));
    } else {
	return pack ("C6", 
		     (0xf0 | (($ucs4 >> 30) & 0x3)),
		     (0x80 | (($ucs4 >> 24) & 0x1)),
		     (0x80 | (($ucs4 >> 18) & 0x3f)),
		     (0x80 | (($ucs4 >> 12) & 0x3f)),
		     (0x80 | (($ucs4 >> 6) & 0x3f)),
		     (0x80 | ($ucs4 & 0x3f)));
    }
}

#Local Variables:
#mode: perl
#perl-indent-level: 4
#perl-continued-statement-offset: 4
#perl-continued-brace-offset: 0
#perl-brace-offset: -4
#perl-brace-imaginary-offset: 0
#perl-label-offset: -4
#tab-width: 4
#End:


__DATA__
0x00	0x0000
0x01	0x0001
0x02	0x0002
0x03	0x0003
0x04	0x009c
0x05	0x0009
0x06	0x0086
0x07	0x007f
0x08	0x0097
0x09	0x008d
0x0a	0x008e
0x0b	0x000b
0x0c	0x000c
0x0d	0x000d
0x0e	0x000e
0x0f	0x000f
0x10	0x0010
0x11	0x0011
0x12	0x0012
0x13	0x0013
0x14	0x009d
0x15	0x0085
0x16	0x0008
0x17	0x0087
0x18	0x0018
0x19	0x0019
0x1a	0x0092
0x1b	0x008f
0x1c	0x001c
0x1d	0x001d
0x1e	0x001e
0x1f	0x001f
0x20	0x0080
0x21	0x0081
0x22	0x0082
0x23	0x0083
0x24	0x0084
0x25	0x000a
0x26	0x0017
0x27	0x001b
0x28	0x0088
0x29	0x0089
0x2a	0x008a
0x2b	0x008b
0x2c	0x008c
0x2d	0x0005
0x2e	0x0006
0x2f	0x0007
0x30	0x0090
0x31	0x0091
0x32	0x0016
0x33	0x0093
0x34	0x0094
0x35	0x0095
0x36	0x0096
0x37	0x0004
0x38	0x0098
0x39	0x0099
0x3a	0x009a
0x3b	0x009b
0x3c	0x0014
0x3d	0x0015
0x3e	0x009e
0x3f	0x001a
0x40	0x0020
0x41	0x00a0
0x42	0x0651
0x43	0xfe7d
0x44	0x0640
0x46	0xfffd
0x46	0x0621
0x47	0x0622
0x48	0xfe82
0x49	0x0623
0x4a	0x00a2
0x4b	0x002e
0x4c	0x003c
0x4d	0x0028
0x4e	0x002b
0x4f	0x007c
0x50	0x0026
0x51	0xfe84
0x52	0x0624
0x55	0xfffd
0x55	0xfffd
0x55	0x0626
0x56	0x0627
0x57	0xfe8e
0x58	0x0628
0x59	0xfe91
0x5a	0x0021
0x5b	0x0024
0x5c	0x002a
0x5d	0x0029
0x5e	0x003b
0x5f	0x00ac
0x60	0x002d
0x61	0x002f
0x62	0x0629
0x63	0x062a
0x64	0xfe97
0x65	0x062b
0x66	0xfe9b
0x67	0x062c
0x68	0xfe9f
0x69	0x062d
0x6a	0x00a6
0x6b	0x002c
0x6c	0x0025
0x6d	0x005f
0x6e	0x003e
0x6f	0x003f
0x70	0xfea3
0x71	0x062e
0x72	0xfea7
0x73	0x062f
0x74	0x0630
0x75	0x0631
0x76	0x0632
0x77	0x0633
0x78	0xfeb3
0x79	0x060c
0x7a	0x003a
0x7b	0x0023
0x7c	0x0040
0x7d	0x0027
0x7e	0x003d
0x7f	0x0022
0x80	0x0634
0x81	0x0061
0x82	0x0062
0x83	0x0063
0x84	0x0064
0x85	0x0065
0x86	0x0066
0x87	0x0067
0x88	0x0068
0x89	0x0069
0x8a	0xfeb7
0x8b	0x0635
0x8c	0xfebb
0x8d	0x0636
0x8e	0xfebf
0x8f	0x0637
0x90	0x0638
0x91	0x006a
0x92	0x006b
0x93	0x006c
0x94	0x006d
0x95	0x006e
0x96	0x006f
0x97	0x0070
0x98	0x0071
0x99	0x0072
0x9a	0x0639
0x9b	0xfeca
0x9c	0xfecb
0x9d	0xfecc
0x9e	0x063a
0x9f	0xfece
0xa0	0xfecf
0xa1	0x00f7
0xa2	0x0073
0xa3	0x0074
0xa4	0x0075
0xa5	0x0076
0xa6	0x0077
0xa7	0x0078
0xa8	0x0079
0xa9	0x007a
0xaa	0xfed0
0xab	0x0641
0xac	0xfed3
0xad	0x0642
0xae	0xfed7
0xaf	0x0643
0xb0	0xfedb
0xb1	0x0644
0xb2	0xfef5
0xb3	0xfef6
0xb4	0xfef7
0xb5	0xfef8
0xb8	0xfffd
0xb8	0xfffd
0xb8	0xfefb
0xb9	0xfefc
0xba	0xfedf
0xbb	0x0645
0xbc	0xfee3
0xbd	0x0646
0xbe	0xfee7
0xbf	0x0647
0xc0	0x061b
0xc1	0x0041
0xc2	0x0042
0xc3	0x0043
0xc4	0x0044
0xc5	0x0045
0xc6	0x0046
0xc7	0x0047
0xc8	0x0048
0xc9	0x0049
0xca	0x00ad
0xcb	0xfeeb
0xcd	0xfffd
0xcd	0xfeec
0xcf	0xfffd
0xcf	0x0648
0xd0	0x061f
0xd1	0x004a
0xd2	0x004b
0xd3	0x004c
0xd4	0x004d
0xd5	0x004e
0xd6	0x004f
0xd7	0x0050
0xd8	0x0051
0xd9	0x0052
0xda	0x0649
0xdb	0xfef0
0xdc	0x064a
0xdd	0xfef2
0xde	0xfef3
0xdf	0x0660
0xe0	0x00d7
0xe2	0xfffd
0xe2	0x0053
0xe3	0x0054
0xe4	0x0055
0xe5	0x0056
0xe6	0x0057
0xe7	0x0058
0xe8	0x0059
0xe9	0x005a
0xea	0x0661
0xeb	0x0662
0xed	0xfffd
0xed	0x0663
0xee	0x0664
0xef	0x0665
0xf0	0x0030
0xf1	0x0031
0xf2	0x0032
0xf3	0x0033
0xf4	0x0034
0xf5	0x0035
0xf6	0x0036
0xf7	0x0037
0xf8	0x0038
0xf9	0x0039
0xfb	0xfffd
0xfb	0x0666
0xfc	0x0667
0xfd	0x0668
0xfe	0x0669
0xff	0x009f
