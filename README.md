# perl6-PDF-Lite

`PDF::Lite` is a minimal class for creating or editing PDF documents, including:
- Basic Text (core fonts only)
- Simple forms and images (GIF, JPEG & PNG)
- Graphics and Drawing
- Content reuse (Pages and form objects)
```
use v6;
use PDF::Lite;

my $pdf = PDF::Lite.new;
my $page = $pdf.add-page;
$page.MediaBox = [0, 0, 200, 100];

$page.text: {
    .TextMove = [10, 10];
    .font = .core-font( :family<Helvetica>, :weight<bold>, :style<italic> );
    .say: 'Hello, world!';
}

my $info = $pdf.Info = {};
$info.CreationDate = DateTime.now;

$pdf.save-as: "examples/hello-world.pdf";
```

![example.pdf](examples/.previews/hello-world-001.png)

#### Text

`.say` and `.print` are simple convenience methods for displaying simple blocks of text with optional line-wrapping, alignment and kerning.

```
use PDF::Lite;
my $pdf = PDF::Lite.new;
my $page = $pdf.add-page;
$page.MediaBox = [0, 0, 500, 150];
my $font = $page.core-font( :family<Helvetica> );

$page.text: -> $txt {
    my $para = q:to"--END--";
    Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt
    ut labore et dolore magna aliqua.
    --END--
            
    $txt.font = $font, 12;
    # output a text box with left, top corner at (20, 100)
    $txt.say( $para, :width(200), :height(150), :position[ :left(20), :top(100)] );

    # output kerned paragraph, flow from right to left, right, top edge at (450, 100)
    $txt.say( $para, :width(200), :height(150), :align<right>, :kern, :position[450, 100] );
    # add another line of text, flowing on to the next line
    $txt.font = $page.core-font( :family<Helvetica>, :weight<bold> ), 12;
    $txt.say( "But wait, there's more!!", :align<right>, :kern );
}

$pdf.save-as: "examples/sample-text.pdf";
```

![sample-text.pdf](examples/.previews/sample-text-001.png)


#### Images (`.load-image` and  `.do` methods):

The `.image` method can be used to open an image.
The `.do` method can them be used to render it.

```
use PDF::Lite;
my $pdf = PDF::Lite.new;
my $page = $pdf.add-page;
$page.MediaBox = [0, 0, 450, 250];

$page.graphics: -> $gfx {
    my $img = $gfx.load-image("t/images/snoopy-happy-dance.jpg");
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

For a full table of `.set-graphics` options, please see PDF::Content::Ops, ExtGState enumeration.

### Text effects

To display card suits symbols, using the ZapfDingbats core-font, with diamonds and hearts colored red:

```
use PDF::Lite;
my $pdf = PDF::Lite.new;
my $page = $pdf.add-page;
$page.MediaBox = [0, 0, 400, 120];

$page.graphics: {

    $page.text: {
	.TextMove = [10, 70];
	.font = [ .core-font('ZapfDingbats'), 24];
	.WordSpacing = 16;
	my $nbsp = "\c[NO-BREAK SPACE]";
	.print("♠ ♣$nbsp");
	.FillColor = :DeviceRGB[ 1, .3, .3];  # reddish
	.say("♦ ♥");
    }

    # Display outline, slanted text, using the ShowText (`Td`) operator:

    my $header-font = $page.core-font( :family<Helvetica>, :weight<bold> );

    $page.text: {
	 use PDF::Content::Ops :TextMode;
	.font = ( $header-font, 12);
	.TextRender = TextMode::OutlineText;
	.LineWidth = .5;
        .text-transform( :skew[0, 12] );
	.text-transform( :translate[10, 30] );
	.ShowText('Outline Slanted Text @(10,30)');
    }
}

$pdf.save-as: "examples/text-effects.pdf";

```

![text-effects.pdf](examples/.previews/text-effects-001.png)

Note: only the PDF core fonts are supported: Courier, Times, Helvetica, ZapfDingbats and Symbol.

#### Forms

Forms are a reusable graphics component


#### Colors and Patterns

### Resources and Reuse

The `to-xobject` method can be used to convert a page to an XObject Form to lay-up one or more input pages on an output page.

```
use PDF::Lite;
my $pdf-with-images = PDF::Lite.open: "t/images.pdf";
my $pdf-with-text = PDF::Lite.open: "examples/sample-text.pdf";

my $new-doc = PDF::Lite.new;

# add a page; layup imported pages and images
my $page = $new-doc.add-page;
$page.MediaBox = [0, 0, 500, 400];

my $xobj-image = $pdf-with-images.page(1).images[6];
my $xobj-with-text  = $pdf-with-text.page(1).to-xobject;
my $xobj-with-images  = $pdf-with-images.page(1).to-xobject;

$page.graphics: {
     # scale up the image; use it as a background
    .do($xobj-image, 6, 6, :width(500), :height(400) );

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
    my $page = $pdf.page: $page-no;
    my %object = $page.resources('XObject');

    # also report on images embedded in the page content
    my $k = "(inline-0)";

    %object{++$k} = $_
        for $page.gfx.inline-images;

    for %object.keys -> $key {
        my $xobject = %object{$key};
        my $subtype = $xobject<Subtype>;
        my $size = $xobject.encoded.codes;
        say "\t$key: $subtype $size bytes"
    }
}

```

Resource types are: `ExtGState` (graphics state), `ColorSpace`, `Pattern`, `Shading`, `XObject` (forms and images) and `Properties`.

Resources of type `Pattern` and `XObject/Image` may have further associated resources.

Whole pages or individual resources may be copied from one PDF to another.

## Operators

PDF::Content inherits from PDF::Content::Op, which implements the full range of PDF content operations for handling text, images and graphics coordinates:

```
use PDF::Lite;
my $pdf = PDF::Lite.new;
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
For a full list of operators, please see PDF::Content::Ops.

## Graphics State

A number of variables are maintained that describe the graphics state. In many cases
these may be set directly:

```
my $page = (require PDF::Lite).new.add-page;
$page.graphics: {

    .Save;  # save current graphics state
    .CharSpacing = 1.0;     # show text with wide spacing
    # Set the font to twelve point helvetica
    my $face = .core-font( :family<Helvetica>, :weight<bold>, :style<italic> );
    .font = [ $face, 12 ];
    .TextLeading = 12; # new-line advances 12 points
    .TextMove = [10, 20];
    .say("Sample Text");
    # 'say' has updated the text position to the next line
    dd .TextMove;
    .Restore; # restore previous graphics state

}
```

### Text

Accessor | Code | Description | Default | Example Setters
-------- | ------ | ----------- | ------- | -------
TextMatrix | Tm | Text transformation matrix | [1,0,0,1,0,0] | .TextMatrix = :scale(1.5) );
CharSpacing | Tc | Character spacing | 0.0 | .CharSpacing = 1.0
WordSpacing | Tw | Word extract spacing | 0.0 | .WordSpacing = 2.5
HorizScaling | Th | Horizontal scaling (percent) | 100 | .HorizScaling = 150
TextLeading | Tl | New line Leading | 0.0 | .TextLeading = 12; 
Font | [Tf, Tfs] | Text font and size | | .font = [ .core-font( :family\<Helvetica> ), 12 ]
TextRender | Tmode | Text rendering mode | 0 | .TextRender = TextMode::Outline::Text
TextRise | Trise | Text rise | 0.0 | .TextRise = 3

### General Graphics - Common

Accessor | Code | Description | Default | Example Setters
-------- | ------ | ----------- | ------- | -------
CTM |  | The current transformation matrix | [1,0,0,1,0,0] | use PDF::Content::Matrix :scale;<br>.ConcatMatrix: :scale(1.5); 
StrokeColor| | current stroke colorspace and color | :DeviceGray[0.0] | .StrokeColor = :DeviceRGB[.7,.2,.2]
FillColor| | current fill colorspace and color | :DeviceGray[0.0] | .FillColor = :DeviceCMYK[.7,.2,.2,.1]
LineCap  |  LC | A code specifying the shape of the endpoints for any open path that is stroked | 0 (butt) | .LineCap = LineCaps::RoundCaps;
LineJoin | LJ | A code specifying the shape of joints between connected segments of a stroked path | 0 (miter) | .LineJoin = LineJoin::RoundJoin
DashPattern | D |  A description of the dash pattern to be used when paths are stroked | solid | .DashPattern = [[3, 5], 6];
StrokeAlpha | CA | The constant shape or constant opacity value to be used when paths are stroked | 1.0 | .StrokeAlpha = 0.5;
FillAlpha | ca | The constant shape or constant opacity value to be used for other painting operations | 1.0 | .FillAlpha = 0.25


### General Graphics - Advanced

Accessor | Code | Description | Default
-------- | ------ | ----------- | -------
MiterLimit | ML | number The maximum length of mitered line joins for stroked paths |
RenderingIntent | RI | The rendering intent to be used when converting CIE-based colours to device colours | RelativeColorimetric
StrokeAdjust | SA | A flag specifying whether to compensate for possible rasterization effects when stroking a path with a line | false
BlendMode | BM | The current blend mode to be used in the transparent imaging model |
SoftMask | SMask | A soft-mask dictionary specifying the mask shape or mask opacity values to be used in the transparent imaging model, or the name: None | None
AlphaSource | AIS | A flag specifying whether the current soft mask and alpha constant parameters shall be interpreted as shape values or opacity values. This flag also governs the interpretation of the SMask entry | false |
OverPrintMode | OPM | A flag specifying whether painting in one set of colorants should cause the corresponding areas of other colorants to be erased or left unchanged | false
OverPrintPaint | OP | A code specifying whether a colour component value of 0 in a DeviceCMYK colour space should erase that component (0) or leave it unchanged (1) when overprinting | 0
OverPrintStroke | OP | " | 0
BlackGeneration | BG2 | A function that calculates the level of the black colour component to use when converting RGB colours to CMYK
UndercolorRemovalFunction | UCR2 | A function that calculates the reduction in the levels of the cyan, magenta, and yellow colour components to compensate for the amount of black added by black generation
TransferFunction | TR2 |  A function that adjusts device gray or colour component levels to compensate for nonlinear response in a particular output device
Halftone dictionary | HT |  A halftone screen for gray and colour rendering
FlatnessTolerance | FT | The precision with which curves shall be rendered on the output device. The value of this parameter gives the maximum error tolerance, measured in output device pixels; smaller numbers give smoother curves at the expense of more computation | 1.0 
SmoothnessTolerance | ST | The precision with which colour gradients are to be rendered on the output device. The value of this parameter (0 to 1.0) gives the maximum error tolerance, expressed as a fraction of the range of each colour component; smaller numbers give smoother colour transitions at the expense of more computation and memory use.



