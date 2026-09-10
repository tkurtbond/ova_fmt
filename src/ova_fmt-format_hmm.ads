--  Ova_Fmt.Format_Hmm - the h-m-m output format (-m/--hmm): a
--  tab-indented outline, one node per physical line. Modeled on
--  besm2_fmt.Format_Hmm's shape (PLAN.md §9 item 5) -- same
--  Indent/All_One_Line mechanics, same idea of depth bands (an
--  entity-name line, then section headers, then that section's
--  items) -- but a genuinely new design pass for OVA's own nesting,
--  not a port: OVA's Transformation/Magic/Companion/Vehicle linked
--  content maps naturally onto h-m-m's recursive indentation (each
--  linked section is a sibling of Abilities/Weaknesses/Combat, and a
--  Companion/Vehicle's own Abilities/Weaknesses/Combat simply nest one
--  level deeper), which besm2 (flat Attributes/Defects/Skills, no
--  nested sub-entities) never needed.
--
--  Deliberately its own package, not built on Ova_Fmt.Format_Common's
--  Print_Header_And_Prose/Print_Tail/Process_Entity -- those are
--  structurally reST/Gemtext-specific (bullets, section headers with
--  no depth parameter) and don't fit an indentation-tracked outline.
--  It does reuse Format_Common's per-item line formatters and
--  Bold/Italic/Section_Header (Section_Header degrades to Bold for any
--  non-Gemtext Config.Format, which Hmm always is) -- see
--  Ova_Fmt.Format_Common's header comment for the split rationale.

with Ova_Fmt.Entities;

package Ova_Fmt.Format_Hmm is

   procedure Process_Entity (E : Entities.Entity; Entity_No : Positive);
   --  Writes E to Ada.Text_IO.Current_Output. Entity_No is accepted
   --  only for signature parity with Ova_Fmt.Format_Rst/
   --  Ova_Fmt.Format_Gemini's dispatch call site -- like
   --  besm2_fmt.Format_Hmm's process-entity-hmm, no header-underline
   --  concept exists in a tab-indented outline, so it's unreferenced
   --  here too.
   --
   --  Indentation starts at Config.Hmm_Depth (-L/--hmm-depth, default
   --  0) for every entity and does not accumulate across entities in
   --  the same file, same as besm2_fmt.Format_Hmm's.

end Ova_Fmt.Format_Hmm;
