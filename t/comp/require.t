#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '.';
    push @INC, '../lib';
}

# don't make this lexical
$i = 1;

my @fjles_to_delete = qw (bleah.pm bleah.do bleah.flg urkkk.pm urkkk.pmc
krunch.pm krunch.pmc whap.pm whap.pmc);


my $Is_EBCDIC = (ord('A') == 193) ? 1 : 0;
my $Is_UTF8   = (${^OPEN} || "") =~ /:utf8/;
my $total_tests = 35;
if ($Is_EBCDIC || $Is_UTF8) { $total_tests -= 3; }
print "1..$total_tests\n";

sub do_require {
    %INC = ();
    write_file('bleah.pm',@_);
    eval { require "bleah.pm" };
    my @a; # magic guard for scope violations (must be first lexical in file)
}

sub write_file {
    my $f = shift;
    open(REQ,">$f") or die "Can't write '$f': $!";
    binmode REQ;
    use bytes;
    print REQ @_;
    close REQ or die "Could not close $f: $!";
}

eval {require 5.005};
print "# $@\nnot " if $@;
print "ok ",$i++,"\n";

eval { require 5.005 };
print "# $@\nnot " if $@;
print "ok ",$i++,"\n";

eval { require 5.005; };
print "# $@\nnot " if $@;
print "ok ",$i++,"\n";

eval {
    require 5.005
};
print "# $@\nnot " if $@;
print "ok ",$i++,"\n";

# new style version numbers

eval { require v5.5.630; };
print "# $@\nnot " if $@;
print "ok ",$i++,"\n";

eval { require 10.0.2; };
print "# $@\nnot " unless $@ =~ /^Perl v10\.0\.2 required/;
print "ok ",$i++,"\n";

eval q{ use v5.5.630; };
print "# $@\nnot " if $@;
print "ok ",$i++,"\n";

eval q{ use 10.0.2; };
print "# $@\nnot " unless $@ =~ /^Perl v10\.0\.2 required/;
print "ok ",$i++,"\n";

my $ver = 5.005_63;
eval { require $ver; };
print "# $@\nnot " if $@;
print "ok ",$i++,"\n";

# check inaccurate fp
$ver = 10.2;
eval { require $ver; };
print "# $@\nnot " unless $@ =~ /^Perl v10\.200\.0 required/;
print "ok ",$i++,"\n";

$ver = 10.000_02;
eval { require $ver; };
print "# $@\nnot " unless $@ =~ /^Perl v10\.0\.20 required/;
print "ok ",$i++,"\n";

print "not " unless 5.5.1 gt v5.5;
print "ok ",$i++,"\n";

{
    print "not " unless v5.5.640 eq "\x{5}\x{5}\x{280}";
    print "ok ",$i++,"\n";

    print "not " unless v7.15 eq "\x{7}\x{f}";
    print "ok ",$i++,"\n";

    print "not "
      unless v1.20.300.4000.50000.600000 eq "\x{1}\x{14}\x{12c}\x{fa0}\x{c350}\x{927c0}";
    print "ok ",$i++,"\n";
}

# interaction with pod (see the eof)
write_file('bleah.pm', "print 'ok $i\n'; 1;\n");
require "bleah.pm";
$i++;

# run-time failure in require
do_require "0;\n";
print "# $@\nnot " unless $@ =~ /did not return a true/;
print "ok ",$i++,"\n";

# compile-time failure in require
do_require "1)\n";
# bison says 'parse error' instead of 'syntax error',
# various yaccs may or may not capitalize 'syntax'.
print "# $@\nnot " unless $@ =~ /(syntax|parse) error/mi;
print "ok ",$i++,"\n";

# successful require
do_require "1";
print "# $@\nnot " if $@;
print "ok ",$i++,"\n";

# do FILE shouldn't see any outside lexicals
my $x = "ok $i\n";
write_file("bleah.do", <<EOT);
\$x = "not ok $i\\n";
EOT
do "bleah.do" or die $@;
dofile();
sub dofile { do "bleah.do" or die $@; };
print $x;

# Test that scalar context is forced for require

write_file('bleah.pm', <<'**BLEAH**'
print "not " if !defined wantarray || wantarray ne '';
print "ok $i - require() context\n";
1;
**BLEAH**
);
                              delete $INC{"bleah.pm"}; ++$::i;
$foo = eval q{require bleah}; delete $INC{"bleah.pm"}; ++$::i;
@foo = eval q{require bleah}; delete $INC{"bleah.pm"}; ++$::i;
       eval q{require bleah}; delete $INC{"bleah.pm"}; ++$::i;
       eval q{$_=$_+2;require bleah}; delete $INC{"bleah.pm"}; ++$::i;
$foo = eval  {require bleah}; delete $INC{"bleah.pm"}; ++$::i;
@foo = eval  {require bleah}; delete $INC{"bleah.pm"}; ++$::i;
       eval  {require bleah};

# Test for fix of RT #24404 : "require $scalar" may load a directory
my $r = "threads";
eval { require $r };
$i++;
if($@ =~ /Can't locate threads in \@INC/) {
    print "ok $i\n";
} else {
    print "not ok $i\n";
}


write_file('bleah.pm', qq(die "This is an expected error";\n));
delete $INC{"bleah.pm"}; ++$::i;
eval { CORE::require bleah; };
if ($@ =~ /^This is an expected error/) {
    print "ok $i\n";
} else {
    print "not ok $i\n";
}

sub write_file_not_thing {
    my ($file, $thing, $test) = @_;
    write_file($file, <<"EOT");
    print "not ok $test\n";
    die "The $thing file should not be loaded";
EOT
}

{
    # Right. We really really need Config here.
    require Config;
    die "Failed to load Config for some reason"
	unless $Config::Config{version};
    my $ccflags = $Config::Config{ccflags};
    die "Failed to get ccflags for some reason" unless defined $ccflags;

    my $simple = ++$i;
    my $pmc_older = ++$i;
    my $pmc_dies = ++$i;
    if ($ccflags =~ /(?:^|\s)-DPERL_DISABLE_PMC\b/) {
	print "# .pmc files are ignored, so test that\n";
	write_file_not_thing('krunch.pmc', '.pmc', $pmc_older);
	write_file('urkkk.pm', qq(print "ok $simple\n"));
	write_file('whap.pmc', qq(die "This is not an expected error"));

	print "# Sleeping for 2 seconds before creating some more files\n";
	sleep 2;

	write_file('krunch.pm', qq(print "ok $pmc_older\n"));
	write_file_not_thing('urkkk.pmc', '.pmc', $simple);
	write_file('whap.pm', qq(die "This is an expected error"));
    } else {
	# These are in the correct order for the 5.8.x behaviour
	# (newer file gets loaded)
	print "# .pmc files should be loaded, so test that\n";
	write_file_not_thing('krunch.pmc', '.pmc', $pmc_older);
	write_file_not_thing('urkkk.pm', '.pm', $simple);
	write_file_not_thing('whap.pm', '.pm', $pmc_dies);

	print "# Sleeping for 2 seconds before creating some more files\n";
	sleep 2;

	write_file('krunch.pm', qq(print "ok $pmc_older\n"));
	write_file('urkkk.pmc', qq(print "ok $simple\n";));
	write_file('whap.pmc', qq(die "This is an expected error"));
    }
    require urkkk;
    require krunch;
    eval {CORE::require whap; 1} and die;

    if ($@ =~ /^This is an expected error/) {
	print "ok $pmc_dies\n";
    } else {
	print "not ok $pmc_dies # $@\n";
    }
}

##########################################
# What follows are UTF-8 specific tests. #
# Add generic tests before this point.   #
##########################################

# UTF-encoded things - skipped on EBCDIC machines and on UTF-8 input

if ($Is_EBCDIC || $Is_UTF8) { exit; }

my $utf8 = chr(0xFEFF);

$i++; do_require(qq(${utf8}print "ok $i\n"; 1;\n));

sub bytes_to_utf16 {
    my $utf16 = pack("$_[0]*", unpack("C*", $_[1]));
    return @_ == 3 && $_[2] ? pack("$_[0]", 0xFEFF) . $utf16 : $utf16;
}

$i++; do_require(bytes_to_utf16('n', qq(print "ok $i\\n"; 1;\n), 1)); # BE
$i++; do_require(bytes_to_utf16('v', qq(print "ok $i\\n"; 1;\n), 1)); # LE

END {
    foreach my $file (@fjles_to_delete) {
	1 while unlink $file;
    }
}

# ***interaction with pod (don't put any thing after here)***

=pod
