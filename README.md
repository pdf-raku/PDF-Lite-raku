[[Raku PDF Project]](https://pdf-raku.github.io)
 / [PDF::Lite](https://pdf-raku.github.io/PDF-Lite-raku)

[![Actions Status](https://github.com/pdf-raku/PDF-Lite-raku/workflows/test/badge.svg)](https://github.com/pdf-raku/PDF-Lite-raku/actions)
<a href="https://ci.appveyor.com/project/dwarring/PDF-Lite-raku/branch/master"><img src="https://ci.appveyor.com/api/projects/status/github/pdf-raku/PDF-Lite-raku?branch=master&passingText=Windows%20-%20OK&failingText=Windows%20-%20FAIL&pendingText=Windows%20-%20pending&svg=true"></a>

# PDF::Lite

`PDF::Lite` is a minimal class for creating or editing PDF documents, including:
- Basic Text
- Simple forms and images (GIF, JPEG & PNG)
- Graphics and Drawing
- Content reuse (Pages and form objects)

```
use v6;
use PDF::Lite;

my PDF::Lite $pdf .= new;
$pdf.media-box = 'Letter';
my PDF::Lite::Page $page = $pdf.add-page;
constant X-Margin = 10;
constant Padding = 10;

$page.graphics: {
    enum <x0 y0 x1 y1>;
    my $font = $pdf.core-font( :family<Helvetica>, :weight<bold>, :style<italic> );
    my @position = [10, 10];
    my @box = .say: "Hello World", :@position, :$font;

    my PDF::Lite::XObject $img = .load-image: "t/images/lightbulb.gif";
    .do: $img, :position[@box[x1] + Padding, 10];
}

given $pdf.Info //= {} {
    .CreationDate = DateTime.now;
}

$pdf.save-as: "examples/hello-world.pdf";
```

![example.pdf](examples/.previews/hello-world-001.png)

#### Text

`.say` and `.print` are simple convenience methods for displaying simple blocks of text with encoding, optional line-wrapping, alignment and kerning.

These methods return a rectangle given the rendered text region;

```
use PDF::Lite;
enum <x0 y0 x1 y1>;
my PDF::Lite $pdf .= new;
$pdf.media-box = [0, 0, 500, 150];
my PDF::Lite::Page $page = $pdf.add-page;
my $font = $pdf.core-font( :family<Helvetica> );

$page.text: -> $txt {
    my $width := 200;
    my $text = q:to"--END--";
    Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt
    ut labore et dolore magna aliqua.
    --END--
            
    $txt.font = $font, 12;
    # output text with left, top corner at (20, 100)
    my @box = $txt.say: $text, :$width, :position[:left(20), :top(100)];
    note "text height: {@box[y1] - @box[y0]}";

    # output kerned paragraph, flow from right to left, right, top edge at (450, 100)
    $txt.say( $text, :$width, :height(150), :align<right>, :kern, :position[450, 100] );
    # add another line of text, flowing on to the next line
    $txt.font = $pdf.core-font( :family<Helvetica>, :weight<bold> ), 12;
    $txt.say( "But wait, there's more!!", :align<right>, :kern );
}

$pdf.save-as: "examples/sample-text.pdf";
```

![sample-text.pdf](examples/.previews/sample-text-001.png)


#### Images (`.load-image` and  `.do` methods):

The `.load-image` method can be used to open an image.
The `.do` method can them be used to render it.

```
use PDF::Lite;
my PDF::Lite $pdf .= new;
$pdf.media-box = [0, 0, 450, 250];
my PDF::Lite::Page $page = $pdf.add-page;

$page.graphics: -> $gfx {
    my PDF::Lite::XObject $img = $gfx.load-image("t/images/snoopy-happy-dance.jpg");
    $gfx.do($img, 50, 40, :width(150) );

    # displays the image again, semi-transparently with translation, rotation and scaling

    $gfx.transform( :translate[180, 100]);
    $gfx.transform( :rotate(-.5), :scale(.75) );
    $gfx.FillAlpha = 0.5;
    $gfx.do($img, :width(150) );
}
$pdf.save-as: "examples/sample-image.pdf";
```

![sample-image.pdf](examples/.previews/sample-image-001.png)


Note: at this stage, only the `JPEG`, `GIF` and `PNG` image formats are supported.

### Text effects

To display card suits symbols, using the ZapfDingbats core-font, with diamonds and hearts colored red:

```
use PDF::Lite;
use PDF::Content::Color :rgb;
my PDF::Lite $pdf .= new;
$pdf.media-box = [0, 0, 400, 120];
my PDF::Lite::Page $page = $pdf.add-page;

$page.graphics: {

    $page.text: {
	.text-position = [20, 70];
	.font = [ $pdf.core-font('ZapfDingbats'), 24];
	.WordSpacing = 16;
	.print("♠ ♣\c[NO-BREAK SPACE]");
	.FillColor = rgb(1, .3, .3);  # reddish
	.say("♦ ♥");
    }

    # Display outline, slanted text

    my $header-font = $pdf.core-font( :family<Helvetica>, :weight<bold> );

    $page.text: {
	 use PDF::Content::Ops :TextMode;
	.font = ( $header-font, 18);
	.TextRender = TextMode::FillOutlineText;
	.LineWidth = .5;
        .text-transform( :skew[0, -6], :translate[10, 30] );
	.FillColor = rgb(.6, .7, .9);
	.print('Outline Slanted Text @(10,30)');
    }
}

$pdf.save-as: "examples/text-effects.pdf";

```

![text-effects.pdf](examples/.previews/text-effects-001.png)

## Fonts

This module has build-in support for the PDF core fonts: Courier, Times, Helvetica, ZapfDingbats and Symbol.

The companion module [PDF::Font::Loader](https://pdf-raku.github.io/PDF-Font-Loader-raku) can be used to access a wider range of fonts:

    use PDF::Lite;
    use PDF::Font::Loader :load-font;
    my PDF::Lite $pdf .= new;
    $pdf.media-box = [0, 0, 400, 120];
    my PDF::Lite::Page $page = $pdf.add-page;
    my $noto = load-font( :file<t/fonts/NotoSans-Regular.ttf> );
    # or find a system font by family and attributes (also requires fontconfig)
    # $noto = load-font: :family<NotoSans>, :weight<book>;

    $page.text: {
        .text-position = [10,100];
        .font = $noto;
        .say: "Noto Sans Regular";
    }

    $pdf.save-as: "examples/fonts.pdf";

![example.pdf](examples/.previews/fonts-001.png)

## Forms and Patterns

Forms are a reusable graphics component. They can be used whereever
images can be used.

A pattern can be used to fill an area with a repeating graphic.

```
use PDF::Lite;
use PDF::Content::Color :rgb;
my PDF::Lite $pdf .= new;
$pdf.media-box = [0, 0, 400, 120];
my PDF::Lite::Page $page = $pdf.add-page;

$page.graphics: {
    my $font = $pdf.core-font( :family<Helvetica> );
    my PDF::Lite::XObject $form = .xobject-form(:BBox[0, 0, 95, 25]);
    $form.graphics: {
        # Set a background color
        .FillColor = rgb(.8, .9, .9);
        .Rectangle: |$form<BBox>;
        .paint: :fill;
        .font = $font;
        .FillColor = rgb(1, .3, .3);  # reddish
        .say("Simple Form", :position[2, 5]);
    }
     # display a simple form a couple of times
    .do($form, 10, 10);
    .transform: :translate(10,40), :rotate(.1), :scale(.75);
    .do($form, 10, 10);
}

$page.graphics: {
    my PDF::Lite::Tiling-Pattern $pattern = .tiling-pattern(:BBox[0, 0, 25, 25], );
    $pattern.graphics: {
        # Set a background color
        .FillColor = rgb(.8, .8, .9);
        .Rectangle: |$pattern<BBox>;
        .paint: :fill;
        # Display an image
        my PDF::Lite::XObject $img = .load-image("t/images/lightbulb.gif");
        .do($img, 6, 2 );
    }
    # fill a rectangle using this pattern
    .FillColor = .use-pattern($pattern);
    .Rectangle(125, 10, 200, 100);
    .paint: :stroke, :fill;
}

$pdf.save-as: "examples/forms-and-patterns.pdf";

```

![forms-and-patterns.pdf](examples/.previews/forms-and-patterns-001.png)


### Resources and Reuse

The `to-xobject` method can be used to convert a page to an XObject Form to lay-up one or more input pages on an output page.

```
use PDF::Lite;
my $pdf-with-images = PDF::Lite.open: "t/images.pdf";
my $pdf-with-text = PDF::Lite.open: "examples/sample-text.pdf";

my PDF::Lite $new-doc .= new;
$new-doc.media-box = [0, 0, 500, 400];

# add a page; layup imported pages and images
my PDF::Lite::Page $page = $new-doc.add-page;

my PDF::Lite::XObject $xobj-image = $pdf-with-images.page(1).images[6];
my PDF::Lite::XObject $xobj-with-text = $pdf-with-text.page(1).to-xobject;
my PDF::Lite::XObject $xobj-with-images = $pdf-with-images.page(1).to-xobject;

$page.graphics: {
    # scale up an image; use it as a semi-transparent background
    .FillAlpha = 0.5; 
    .do($xobj-image, 0, 0, :width(500), :height(400) );
    };

$page.graphics: {
    # overlay pages; scale these down
    .do($xobj-with-text, 20, 100, :width(300) );
    .do($xobj-with-images, 300, 100, :width(200) );
}

# copy whole pages from a document
for 1 .. $pdf-with-text.page-count -> $page-no {
    $new-doc.add-page: $pdf-with-text.page($page-no);
}

$new-doc.save-as: "examples/reuse.pdf";

```

![reuse.pdf Page 1](examples/.previews/reuse-001.png)
![reuse.pdf Page 2](examples/.previews/reuse-002.png)


To list all images and forms for each page
```
use PDF::Lite;
my $pdf = PDF::Lite.open: "t/images.pdf";
for 1 ... $pdf.page-count -> $page-no {
    say "page: $page-no";
    my PDF::Lite::Page $page = $pdf.page: $page-no;
    # get all X-Objects (images and forms) on the page
    my PDF::Lite::XObject %object = $page.resources('XObject');

    # also report on images embedded in the page content
    my $k = "(inline-0)";

    %object{++$k} = $_
        for $page.gfx.inline-images;

    for %object.keys -> $key {
        my $xobject = %object{$key};
        my $subtype = $xobject<Subtype>;
        my $size = $xobject.encoded.codes;
        say "\t$key: $subtype {$xobject.width}x{$xobject.height} $size bytes"
    }
}

```

Resource types are: `ExtGState` (graphics state), `ColorSpace`, `Pattern`, `Shading`, `XObject` (forms and images) and `Properties`.

Resources of type `Pattern` and `XObject/Image` may have further associated resources.

Whole pages or individual resources may be copied from one PDF to another.

## Graphics Operations

A full range of general graphics is available for drawing and displaying text.

```
use PDF::Lite;
my PDF::Lite $pdf .= new;
my $page = $pdf.add-page;

# Draw a simple Bézier curve:

# ------------------------
# Alternative 1: Using operator functions (see PDF::Content)

sub draw-curve1($gfx) {
    $gfx.Save;
    $gfx.MoveTo(175, 720);
    $gfx.LineTo(175, 700);
    $gfx.CurveToInitial( 300, 800,  400, 720 );
    $gfx.ClosePath;
    $gfx.Stroke;
    $gfx.Restore;
}

draw-curve1($page.gfx);

# ------------------------
# Alternative 2: draw from content instructions string:

sub draw-curve2($gfx) {
    $gfx.ops: q:to"--END--"
        q                     % save
          175 720 m           % move-to
          175 700 l           % line-to
          300 800 400 720 v   % curve-to
          h                   % close
          S                   % stroke
        Q                     % restore
        --END--
}
draw-curve2($pdf.add-page.gfx);

# ------------------------
# Alternative 3: draw from raw data

sub draw-curve3($gfx) {
    $gfx.ops: [
         'q',               # save,
         :m[175, 720],      # move-to
         :l[175, 700],      # line-to 
         :v[300, 800,
            400, 720],      # curve-to
         :h[],              # close (or equivalently, 'h')
         'S',               # stroke (or equivalently, :S[])
         'Q',               # restore
     ];
}
draw-curve3($pdf.add-page.gfx);

```

Please see [PDF::API6 Appendix I - Graphics](https://pdf-raku.github.io/PDF-API6#appendix-i-graphics) for a description of available operators and graphics.

Graphics can also be read from an existing PDF file:

```
use PDF::Lite;
my $pdf = PDF::Lite.open: "examples/hello-world.pdf";
say $pdf.page(1).gfx.ops;
```

## Graphics and Rendering

A number of variables are maintained that describe the graphics state. In many cases these may be set directly:

```
use PDF::Lite;
my PDF::Lite $pdf .= new;
my PDF::Lite::Page $page = $pdf.add-page;
$page.graphics: {
    .text: {  # start a text block
        .CharSpacing = 1.0;     # show text with wide spacing
        # Set the font to twelve point helvetica
        my $face = $pdf.core-font( :family<Helvetica>, :weight<bold>, :style<italic> );
        .font = [ $face, 10 ];
        .TextLeading = 12; # new-line advances 12 points
        .text-position = 10, 20;
        .say("Sample Text", :position[10, 20]);
        # '$gfx.say' has updated the text position to the next line
        say .text-position;
    } # restore previous text state
    say .CharSpacing; # restored to 0
}
```

A renderer callback can be specified when reading content. This will be called for each graphics operation and has access to the graphics state, via
the `$*gfx` dynamic variable.

```
use PDF::Lite;
use PDF::Content::Ops :OpCode;
my PDF::Lite $pdf .= open: "examples/hello-world.pdf";

my &callback = -> $op, *@args {
   given $op {
       when SetTextMatrix {
           say "text matrix set to: {$*gfx.TextMatrix}";
       }
   }
}
my $gfx = $pdf.page(1).render(:&callback);
# text matrix set to: 1 0 0 1 10 10
```

## See also

- [PDF::Font::Loader](https://pdf-raku.github.io/PDF-Font-Loader-raku) for using Postscript, TrueType and OpenType fonts.

- [HTML::Canvas::To::PDF](https://pdf-raku.github.io/HTML-Canvas-To-PDF-raku/) HTML Canvas renderer

- This module (PDF::Lite) is based on [PDF](https://pdf-raku.github.io/PDF-raku) and has all of it methods available. This includes:

    - `open` to read an existing PDF or JSON file
    - `save-as` to save to PDF or JSON
    - `update` to perform an in-place incremental update of the PDF
    - `Info` to access document meta-data

- [PDF::API6 Graphics Documentation](https://pdf-raku.github.io/PDF-API6#readme) for a fuller description of methods, operators and graphics variables, which are also applicable to this module. In particular:

    - [Section II: Content Methods](https://pdf-raku.github.io/PDF-API6#section-ii-content-methods-inherited-from-pdfclass) for a description of available content methods.

    - [Appendix I - Graphics](https://pdf-raku.github.io/PDF-API6#appendix-i-graphics) for a description of available operators and graphics.



