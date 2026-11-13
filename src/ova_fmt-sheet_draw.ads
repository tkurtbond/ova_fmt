--  Ova_Fmt.Sheet_Draw - -R/--redraw, with -S/--sheet: troff that draws
--  the official character sheet's frames and labels, so that the
--  output needs no blank sheet under it and can be shared (the poc
--  port's PLAN.md, "Redrawing the sheet").
--
--  The frames are measured from the blank sheet's own drawing: its
--  panels, boxes and rules, as rounded rectangles, rules and dots, in
--  its colours; its labels in Noto Sans, each scaled across to the
--  width it has on the sheet. The logo, the spiral binding on page 2
--  and the vertical "Character Record" are left out.

package Ova_Fmt.Sheet_Draw is

   procedure Put_Preamble (One_Column : Boolean);
   --  The colours and macros, for the end of Format_Sheet's preamble,
   --  and with One_Column (-C/--one-column) Page_1_One_Column's and
   --  Rule's. Its first line, `.\" ova-sheet-redrawn`, tells
   --  ova_sheet.sh not to lay the blank sheet under the pages.

   Page_1 : constant String := ".FR-p1";
   Page_2 : constant String := ".FR-p2";
   --  Draw page 1's or page 2's frames, under its text: right after
   --  the page's .SP.

   Page_1_One_Column : constant String := ".FR-p1c";
   --  -C's page 1 in place of Page_1: the sheet's header, then one
   --  column for the Abilities and Weaknesses beside an Attacks &
   --  Combat Stats box (Acacia's block in the rulebook).

   Rule : constant String := ".CR";
   --  Rule & " Y": -C's faint rule across the column between the
   --  Abilities and the Weaknesses, its top Y points from the top.

end Ova_Fmt.Sheet_Draw;
