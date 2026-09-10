--  Ova_Fmt.Format_Rst - every backend that emits a reST document fed
--  through Pandoc's reST reader: Terse (plain reST prose) and
--  Html_In_Rst (reST with one `.. raw:: html` block for nested
--  tables). A future groff-in-reST backend (PLAN.md §9 item 6, `.. raw::
--  ms` instead of `.. raw:: html`) belongs here too, for the same
--  reason -- see Ova_Fmt.Format_Common's header comment for the split
--  rationale (grouped by output *pipeline*, not by how much
--  content-assembly code happens to be shared underneath -- Terse
--  actually shares far more code with Gemtext, in Format_Common, than
--  with Html_In_Rst's own table renderers here).
--
--  Structure and conventions (name/detail/level order, "Perks: ...;
--  Flaws: ..." labeling, "Roll N dice", Affinity as its own labeled
--  clause) are grounded in the user-supplied Karis mockup (PLAN.md
--  §2.3, translated there from Markdown to reST) for the parts it
--  covered -- Abilities/Weaknesses/Combat-summary/Attacks -- and are
--  this session's own first-pass design, not yet user-reviewed, for
--  the parts it didn't: Background/Personality/Notes/Fluff, and how
--  a linked Ability's nested content (Transformation/Magic/Companion)
--  expands into its own section after the main Attacks block.
--
--  Html_In_Rst's own table layout was confirmed with the user before
--  implementing (a full worked Karis/Arasuni example) -- see
--  PLAN.md §9 item 4.

with Ova_Fmt.Entities;

package Ova_Fmt.Format_Rst is

   procedure Process_Entity (E : Entities.Entity; Entity_No : Positive);
   --  Writes E to Ada.Text_IO.Current_Output. Entity_No is 1 for the
   --  first entity in a file, 2 for the second, etc. -- selects
   --  between Config.Underliner and Config.Subunderliner for the
   --  header underline (Terse mode only), same convention as
   --  besm2_fmt.Format_Terse.

end Ova_Fmt.Format_Rst;
