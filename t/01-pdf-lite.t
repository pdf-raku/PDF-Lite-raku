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
    my $img = .load-image: "t/images/basn0g01.png";
    .do($img, 100, 100);
}

# deliberately leave the PDF in an untidy graphics state
# should wrap this in 'q' .. 'Q' when re-read
$page.gfx.strict = False;
$page.gfx.SetStrokeRGB(.3, .4, .5);

lives-ok { $pdf.save-as("t/lite.pdf") }, 'save-as';

throws-like { $pdf.unknown-method }, X::Method::NotFound, '$pdf unknown method';

lives-ok { $pdf = PDF::Lite.open("t/lite.pdf") }, 'open';
is-json-equiv $pdf.page(1).gfx.ops[0..6], (
    :q[], 
    :BT[],
    :Tm[:int(1), :int(0), :int(0), :int(1), :int(200), :int(200)],
    :Tf[:name<F1>, :int(18)],
    :TL[:real(19.8)],
    :Tj[:literal("Lorem ipsum dolor sit amet,")],
    "T*" => [],), 'reloaded graphics (head)';

is-json-equiv $pdf.page(1).gfx.ops[*-2..*], (
    :RG[:real(.3), :real(.4), :real(.5)],
    :Q[],), 'reloaded graphics (tail)';

done-testing;
