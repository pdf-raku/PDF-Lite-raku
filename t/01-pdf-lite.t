use v6;
use Test;

use PDF::Lite;
use PDF::Grammar::Test :is-json-equiv;
my PDF::Lite $pdf .= new;
my $page = $pdf.add-page;
my $header-font = $pdf.core-font( :family<Helvetica>, :weight<bold> );

$page.text: {
    .text-position = [200, 200];
    .font = [$header-font, 18];
    .say(:width(250),
	"Lorem ipsum dolor sit amet, consectetur adipiscing elit,
         sed do eiusmod tempor incididunt ut labore et dolore
         magna aliqua");
}

$page.graphics: {
    my $img = .load-image: "t/images/lightbulb.gif";
    .do($img, 100, 100);
}

# deliberately leave the PDF in an untidy graphics state
# should wrap this in 'q' .. 'Q' when re-read
$page.gfx.strict = False;
$page.gfx.SetStrokeRGB(.3, .4, .5);
todo "PDF::Content v0.4.3+ required to pass this test"
    unless PDF::Content.^ver >= v0.4.3;
is-json-equiv $page.gfx.content-dump.head(8).list, (
    "BT",
    "1 0 0 1 200 200 Tm",
    "/F1 18 Tf",
    "(Lorem ipsum dolor sit amet,) Tj",
    "19.8 TL",
    "T*",
    "(consectetur adipiscing elit,) Tj",
    "T*",
    ),
    'presave graphics (head)';

# ensure consistant document ID generation
$pdf.id = $*PROGRAM-NAME.fmt('%-16s').substr(0,16);

lives-ok { $pdf.save-as("t/01-pdf-lite.pdf") }, 'save-as';

throws-like { $pdf.unknown-method }, X::Method::NotFound, message => "No such method 'unknown-method' for invocant of type 'PDF::Lite'", '$pdf unknown method';

lives-ok { $pdf = PDF::Lite.open("t/01-pdf-lite.pdf") }, 'open';
todo "PDF::Content v0.4.3+ required to pass this test"
    unless PDF::Content.^ver >= v0.4.3;
is-json-equiv $pdf.page(1).render.content-dump.head(8).list, (
    "q",
    "BT",
    "1 0 0 1 200 200 Tm",
    "/F1 18 Tf",
    "(Lorem ipsum dolor sit amet,) Tj",
    "19.8 TL",
    "T*",
    "(consectetur adipiscing elit,) Tj",
    ), 'reloaded graphics (head)';

is-json-equiv $pdf.page(1).gfx.ops.tail(2).list, (
    :RG[:real(.3), :real(.4), :real(.5)],
    :Q[],), 'reloaded graphics (tail)';

done-testing;
