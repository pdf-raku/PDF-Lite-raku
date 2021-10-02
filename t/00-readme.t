use Test;
plan 11;

my $read-me = "README.md".IO.slurp;

$read-me ~~ /^ $<waffle>=.*? +%% ["```" \n? $<code>=.*? "```" \n?] $/
    or die "README.md parse failed";

my $n;

for @<code> {
    my $snippet = ~$_;
    given $snippet {
	default {
	    $snippet .= subst('DateTime.now;', 'DateTime.new( :year(2015), :month(12), :day(25) );' );
	    # disable say
	    sub say(|c) { }

	    lives-ok {EVAL $snippet}, 'code sample'
                or note $snippet;
	}
    }
}

done-testing;
