--  Ova_Fmt.Format_Terse - the terse (reST prose) output format, and
--  for now the only one implemented -- see PLAN.md §7/§9: OVA has no
--  BESM-style default grid-table format at all (reST tables can't
--  represent nested abilities), so terse prose is both the default
--  and the first backend built.
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

with Ova_Fmt.Entities;

package Ova_Fmt.Format_Terse is

   procedure Process_Entity (E : Entities.Entity; Entity_No : Positive);
   --  Writes E to Ada.Text_IO.Current_Output. Entity_No is 1 for the
   --  first entity in a file, 2 for the second, etc. -- selects
   --  between Config.Underliner and Config.Subunderliner for the
   --  header underline, same convention as besm2_fmt.Format_Terse.

end Ova_Fmt.Format_Terse;
