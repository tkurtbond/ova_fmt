--  Ova_Fmt.Sheet_Fonts - text widths in the Noto Sans faces -S sets,
--  from the tables in Ova_Fmt.Sheet_Widths, so that the program, not
--  groff, decides where a line breaks (the poc port's PLAN.md, "-S:
--  what goes where"), and the golden files fix it.
--
--  Units are integers, so the poc port agrees to the byte: a width in
--  thousandths of an em times a size in tenths of a point is in
--  ten-thousandths of a point.

with Ova_Fmt.Sheet_Widths;

package Ova_Fmt.Sheet_Fonts is

   subtype Face is Sheet_Widths.Face;

   function Name (F : Face) return String;
   --  The face's groff name: "NSR", "NSI", ...

   function Char_Width (Code : Natural; F : Face) return Natural;
   --  Code's width in F, in thousandths of an em; 1000, wider than any
   --  measured character, for one that wasn't measured.

   Max_Text_Width : constant := 1_000_000;
   --  Where Text_Width stops counting: 1,000 ems, wider than any line
   --  on the sheet, and small enough that times a size in tenths of a
   --  point (180 at most) it is still a Natural. A word of a million
   --  characters would otherwise overflow it.

   function Text_Width (S : String; F : Face) return Natural;
   --  The width of S, UTF-8, in F, in thousandths of an em, up to
   --  Max_Text_Width. A byte that doesn't start or continue a valid
   --  sequence counts as an unmeasured character.

   function Upper (S : String) return String;
   --  S with ASCII letters in upper case, the faked small caps. Only
   --  ASCII: Latin-1's upper case would change UTF-8's bytes.

end Ova_Fmt.Sheet_Fonts;
