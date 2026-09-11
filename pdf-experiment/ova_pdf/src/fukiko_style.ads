with PDF_Out; use PDF_Out;

--  Shared geometry/color constants and low-level drawing helpers for the
--  Fukiko two-page recreation. PDF_Out uses a bottom-left origin (y grows
--  upward); this package's "Top_XY"/"Top_Rect" helpers let the rest of the
--  program reason in the more natural "distance from top of page"
--  convention while still driving PDF_Out's actual coordinate system.

package Fukiko_Style is

   --  Reference page size: the OVA rulebook itself, ~419.528 x 595.276 pt
   --  (close to ISO A5), *not* US Letter or A4 -- matching the original's
   --  proportions matters more here than matching a "standard" size.
   Page_Width  : constant Real := 419.528;
   Page_Height : constant Real := 595.276;

   Page_Rect : constant Rectangle := (0.0, 0.0, Page_Width, Page_Height);

   --------------
   --  Colors  --
   --------------

   --  NB: PDF_Out.Convert takes its RGB_Code_Range as little-endian (red
   --  in the low byte), i.e. 0xBBGGRR, not the usual 0xRRGGBB -- these
   --  constants are built from R/G/B components directly instead, to
   --  avoid that footgun.
   function RGB (R, G, B : Natural) return Color_Type is
     (Real (R) / 255.0, Real (G) / 255.0, Real (B) / 255.0);

   Maroon        : constant Color_Type := RGB (16#73#, 16#1D#, 16#20#);
   Bright_Maroon : constant Color_Type := RGB (16#A1#, 16#1E#, 16#22#);
   Panel_Bg      : constant Color_Type := RGB (16#EB#, 16#E1#, 16#E1#);
   White         : constant Color_Type := RGB (16#FF#, 16#FF#, 16#FF#);
   Ink           : constant Color_Type := RGB (16#00#, 16#00#, 16#00#);

   --------------------------------------------------------
   --  Top-down coordinate convenience (see package note)  --
   --------------------------------------------------------

   --  A point at (x from left, y from top).
   function Top_XY (X, Y : Real) return Point;

   --  A rectangle whose top-left corner is (x from left, y from top),
   --  with the given width/height growing right/down as usual.
   function Top_Rect (X, Y, W, H : Real) return Rectangle;

   ---------------------------
   --  Rounded rectangles   --
   ---------------------------

   --  Per-corner radii, so a box can have only its top (or only one)
   --  corner(s) rounded -- e.g. a panel header bar that sits flush on
   --  top of the panel body below it.
   type Corner_Radii is record
      Top_Left, Top_Right, Bottom_Right, Bottom_Left : Real := 0.0;
   end record;

   function All_Corners (R : Real) return Corner_Radii;
   --  All four corners rounded by the same radius.

   Square_Corners : constant Corner_Radii := (others => 0.0);

   procedure Rounded_Rect
     (Pdf       : in out PDF_Out_Stream'Class;
      What      :        Rectangle;
      Radii     :        Corner_Radii;
      Rendering :        Path_Rendering_Mode);
   --  Draw (fill/stroke/both) a rectangle with the given per-corner
   --  radii. A zero radius on a corner makes that corner square.

   ------------------------------------
   --  Rules (horizontal separators)  --
   ------------------------------------

   procedure Solid_HRule
     (Pdf                : in out PDF_Out_Stream'Class;
      X1, X2, Y_From_Top :        Real;
      Width              :        Real := 0.75);
   --  A plain thin horizontal rule, e.g. under a section heading.

   procedure Dotted_HRule
     (Pdf                : in out PDF_Out_Stream'Class;
      X1, X2, Y_From_Top :        Real;
      Gap                :        Real := 4.0;
      Dot_Diameter       :        Real := 1.8);
   --  A rule of round dots (the motif used under the page header and at
   --  section breaks in the rulebook) -- built from a zero-length dash
   --  with a round line cap, the standard PDF "dotted line" trick: a
   --  0-length dash segment, stroked with a round cap, paints as a disc
   --  of diameter = line width.

   ----------------------------
   --  Text placement helper  --
   ----------------------------

   procedure Text
     (Pdf   : in out PDF_Out_Stream'Class;
      X, Y  :        Real;
      Font  :        Standard_Font_Type;
      Size  :        Real;
      Col   :        Color_Type;
      S     :        String);
   --  Set font/size/color and place S with its baseline-left origin at
   --  (X, Y) in top-down coordinates -- a one-call shorthand for the
   --  common case, since almost every piece of text on these two pages
   --  is a single short line with its own font/size/color combination.

   function Paragraph
     (Pdf     : in out PDF_Out_Stream'Class;
      X, Y    :        Real;
      Width   :        Real;
      Font    :        Standard_Font_Type;
      Size    :        Real;
      Leading :        Real;
      Col     :        Color_Type;
      S       :        String) return Real;
   --  Greedily word-wrap S (a single space-separated run of text, no
   --  embedded newlines) to fit Width, and draw it as left-aligned lines
   --  of the given font/size/color, starting with the first line's
   --  baseline at (X, Y) and moving down by Leading per line. PDF_Out
   --  has no built-in text wrapping -- this is the whole-word Bounding_Box
   --  measure-and-break used for every prose block on both pages. Returns
   --  the Y (top-down) where a following line would start, so callers can
   --  chain paragraphs (with their own added gap) without having to
   --  predict how many lines S will wrap to.

   procedure Solid_VRule
     (Pdf                          : in out PDF_Out_Stream'Class;
      X, Y1_From_Top, Y2_From_Top :        Real;
      Width                        :        Real := 0.5);
   --  A plain thin vertical rule, e.g. the column divider between the
   --  Abilities and Weaknesses lists, or between table columns.

end Fukiko_Style;
