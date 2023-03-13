use v6;

use PDF;
use PDF::Content::Interface;

#| A minimal class for manipulating PDF graphical content
class PDF::Lite:ver<0.0.12>
    is PDF does PDF::Content::Interface {

    use PDF::COS;
    use PDF::COS::Tie;
    use PDF::COS::Tie::Hash;
    use PDF::COS::Loader;
    use PDF::COS::Dict;
    use PDF::COS::Stream;
    use PDF::COS::Util :from-ast;

    use PDF::Content::Font;
    use PDF::Content::Font::CoreFont;
    use PDF::Content::Canvas;
    use PDF::Content::Page;
    use PDF::Content::PageNode;
    use PDF::Content::PageTree;
    use PDF::Content::ResourceDict;
    use PDF::Content::XObject;

    my subset NinetyDegreeAngle of Int where { $_ %% 90}

    class XObject is PDF::COS::Stream {}

    class Font is PDF::COS::Dict does PDF::Content::Font {
    }

    my role ResourceDict
        does PDF::COS::Tie::Hash
        does PDF::Content::ResourceDict {
            has Font %.Font  is entry;
            has XObject %.XObject is entry;
            has PDF::COS::Dict $.ExtGState is entry;
    }

    my class XObject-Form
        is XObject
        does PDF::Content::XObject['Form']
        does PDF::Content::Canvas {
            has ResourceDict $.Resources is entry;
    }

    my class XObject-Image
        is XObject
        does PDF::Content::XObject['Image'] {
    }

    class Tiling-Pattern is XObject-Form {};

    class Page
        is PDF::COS::Dict
        does PDF::Content::Page
        does PDF::Content::PageNode {

        has ResourceDict $.Resources is entry(:inherit);
        #| inheritable page properties
        has Numeric @.MediaBox is entry(:inherit,:len(4));
        has Numeric @.CropBox  is entry(:inherit,:len(4));
        has Numeric @.BleedBox is entry(:len(4));
        has Numeric @.TrimBox  is entry(:len(4));
        has Numeric @.ArtBox   is entry(:len(4));
        has NinetyDegreeAngle $.Rotate is entry(:inherit, :alias<rotate>);

        has PDF::COS::Stream @.Contents is entry(:array-or-item);
    }

    class Pages
        is PDF::COS::Dict
        does PDF::Content::PageNode
        does PDF::Content::PageTree {

        #| inheritable page properties
        has ResourceDict $.Resources is entry(:inherit);
        has Numeric @.MediaBox is entry(:inherit,:len(4));
        has Numeric @.CropBox  is entry(:inherit,:len(4));
        has NinetyDegreeAngle $.Rotate is entry(:inherit, :alias<rotate>);

        has PDF::Content::PageNode @.Kids is entry(:required, :indirect);
        has UInt $.Count                  is entry(:required);
    }

    role Catalog
        does PDF::COS::Tie::Hash {
        has Pages $.Pages is entry(:required, :indirect);

        method cb-finish {
            self.Pages.?cb-finish;
        }

    }

    has Catalog $.Root is entry(:required, :indirect);

    has PDF::Content::Font::CoreFont::Cache $!cache .= new;
    method core-font(|c) {
        PDF::Content::Font::CoreFont.load-font(:$!cache, |c);
    }

    method cb-init {
        self<Root> //= { :Type( :name<Catalog> ), :Pages{ :Type( :name<Pages> ), :Kids[], :Count(0), } };
    }

    my class Loader is PDF::COS::Loader {
        constant %Classes = %( :Form(XObject-Form), :Image(XObject-Image), :Page(Page), :Pages(Pages), :Font(Font) );

        multi method load-delegate(Hash :$dict! where { from-ast($_) ~~ 'Form'|'Image' with .<Subtype> }) {
            %Classes{ from-ast($dict<Subtype>) };
        }
        multi method load-delegate(Hash :$dict! where { from-ast($_) ~~ 'Page'|'Pages'|'Font' with .<Type> }) {
            %Classes{ from-ast($dict<Type>) };
        }
        multi method load-delegate(Hash :$dict! where { from-ast($_) == 1 with .<PatternType> }) {
            Tiling-Pattern
        }
    }
    PDF::COS.loader = Loader;

    method Pages returns Pages handles <page pages add-page add-pages delete-page insert-page page-count media-box crop-box bleed-box trim-box art-box use-font rotate iterate-pages> { self.Root.Pages }

    # restrict to to PDF format; avoid FDF etc
    method open(|c) is hidden-from-backtrace { nextwith( :type<PDF>, |c); }

}
