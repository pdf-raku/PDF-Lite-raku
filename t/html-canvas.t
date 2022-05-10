use v6;
use Test;
plan 2;

use PDF::Lite;
my PDF::Lite $pdf .= new;
my PDF::Lite::Page $page = $pdf.add-page;
my $header-font = $pdf.core-font( :family<Helvetica>, :weight<bold> );

unless try {require HTML::Canvas::To::PDF; 1} {
    skip-rest 'HTML::Canvas::To::PDF required to run canvas tests';
    exit;
}

$page.html-canvas: {
    .beginPath();
    .arc(95, 50, 40, 0, 2 * pi);
    .stroke();
    .fillText("Hello World", 10, 50);
}

# ensure consistant document ID generation
$pdf.id =  $*PROGRAM-NAME.fmt('%-16.16s');
lives-ok { $pdf.save-as("t/html-canvas.pdf", :!info) }, 'save-as';

throws-like { $pdf.unknown-method }, X::Method::NotFound, '$pdf unknown method';

done-testing;
