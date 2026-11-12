--  Ova_Fmt.Format_Form - -X/--form: the official character sheet's
--  form fields, as JSON for ova_form.sh, which fills the sheet's PDF
--  with qpdf and jq (the poc port's PLAN.md, "The form script,
--  ova_form.sh").
--
--  The output is one JSON array holding an array of fills per main
--  entity, in input order, across every input file. A fill is one
--  filled copy of the sheet:
--
--     {"pages": [1, 2], "sub": ["Ability 8"], "fields": {"Character Name": "Fukiko", ...}}
--
--  The first is the main sheet, both pages. Then come copies of page
--  1 (Ova_Fmt.Sheet_Map: rows, attacks and sub-entities that didn't
--  fit, titled "Fukiko (continued)" or "Arasuni (Karis's
--  Companion)"), then copies of page 2 holding what the sheet has no
--  room or place for, each part opening with a label line of the
--  program's own ("Fukiko: Appearance (continued)"). `sub` names the
--  fields holding built-under rows, which the script sets smaller;
--  `fields` holds only the fields with values.
--
--  The form's fields can't grow, so the prose is fitted here: with
--  Helvetica's widths (the face ova_form.sh restyles the fields in)
--  and each field's size, a field takes the words that fit and the
--  rest goes on. A one-line field clips, so a row too wide for its
--  line is repeated in full on a page-2 copy.

with Ova_Fmt.Entities;

package Ova_Fmt.Format_Form is

   procedure Process_Entity (E : Entities.Entity);
   --  E's fills, after a `[` or `,` as needed.

   procedure Finish;
   --  Close the array (or write `[]` if there were no entities).
   --  Call once, after the last entity of the last file.

end Ova_Fmt.Format_Form;
