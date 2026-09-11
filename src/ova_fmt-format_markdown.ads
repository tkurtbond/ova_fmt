--  Ova_Fmt.Format_Markdown - the Markdown backend, first-pass: plain
--  Markdown prose, the same terse bulleted-list shape as
--  Ova_Fmt.Format_Rst's Terse mode (PLAN.md's already-settled
--  rationale: reST/Markdown's inline `**bold**`/`*italic*` markup is
--  identical, only heading syntax differs). All the actual content
--  assembly lives in Ova_Fmt.Format_Common, whose primitives (Bold/
--  Italic/Section_Header/Bullet, Print_Header_And_Prose's heading
--  choice) already gate on Config.Format = Config.Markdown internally
--  where it differs from Terse -- so this package is a thin entry
--  point, not a place that duplicates any logic, same as
--  Ova_Fmt.Format_Gemini.
--
--  A nested-table Markdown mode analogous to Format_Rst's
--  Html_In_Rst/Groff_In_Rst (for OVA's Abilities/Weaknesses/Combat
--  tables) is not yet designed -- this is Terse-equivalent only, per
--  the build order Terse/Gemtext/Html_In_Rst/Hmm/Groff_In_Rst already
--  followed (PLAN.md §9).

with Ova_Fmt.Entities;

package Ova_Fmt.Format_Markdown is

   procedure Process_Entity (E : Entities.Entity; Entity_No : Positive);
   --  Writes E to Ada.Text_IO.Current_Output, in Markdown.

end Ova_Fmt.Format_Markdown;
