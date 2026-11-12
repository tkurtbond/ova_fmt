--  Ova_Fmt.Format_Sheet - -S/--sheet: the official character sheet's
--  values as troff, typeset over the blank sheet by ova_sheet.sh (the
--  poc port's PLAN.md, "The official character sheet as PDF").
--
--  Raw troff, no macro package, at the sheet's A5 size, for groff -k
--  -Tpdf with the Noto Sans faces sheet_fonts.sh builds. For each
--  main entity, in input order: its copies of page 1 (Ova_Fmt.
--  Sheet_Map), then page 2, then, if anything didn't fit, plain
--  continuation pages. Every value on the sheet's pages is placed at
--  a point and broken into lines here, with the faces' widths
--  (Ova_Fmt.Sheet_Fonts), so nothing depends on how groff fills; only
--  the continuation pages are filled by groff. Each sheet page
--  reports itself on standard error ("ova-sheet-page 3 p1"), which
--  tells the script which page of the blank sheet goes under it.

with Ova_Fmt.Entities;

package Ova_Fmt.Format_Sheet is

   procedure Process_Entity (E : Entities.Entity);
   --  E's pages, after the troff preamble if E is the first entity.

end Ova_Fmt.Format_Sheet;
