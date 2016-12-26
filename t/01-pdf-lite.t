use v6;
use Test;

# ensure consistant document ID generation
srand(123456);

use PDF::Lite;
use PDF::Grammar::Test :is-json-equiv;
my PDF::Lite $pdf .= new;
my $page = $pdf.add-page;
my $header-font = $page.core-font( :family<Helvetica>, :weight<bold> );

$page.text: {
    .text-position = [200, 200];
    .font = [$header-font, 18];
    .say(:width(250),
	"Lorem ipsum dolor sit amet, consectetur adipiscing elit,
         sed do eiusmod tempor incididunt ut labore et dolore
         magna aliqua");
}

$page.graphics: {
    my $img = .load-image: "t/images/snoopy-happy-dance.jpg";
    .do($img, 100, 100);
}

lives-ok { $pdf.save-as: "t/lite.pdf" }, 'save';
lives-ok { $pdf = PDF::Lite.open("t/lite.pdf") }, 'reopen';

done-testing;
