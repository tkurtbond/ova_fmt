--  Ova_Fmt.Format_Gemini - the Gemtext backend (Gemini protocol
--  hypertext, geminiprotocol.net/docs/gemtext.gmi). Not reST, and
--  never runs through Pandoc, unlike Ova_Fmt.Format_Rst's members --
--  see Ova_Fmt.Format_Common's header comment for the full split
--  rationale. All the actual content assembly lives in
--  Ova_Fmt.Format_Common, whose primitives (Bold/Italic/
--  Section_Header/Bullet, Print_Header_And_Prose's heading choice,
--  Print_Attack's list-item shape) already gate on
--  Config.Format = Config.Gemtext internally, so this package is a
--  thin entry point, not a place that duplicates any logic.

with Ova_Fmt.Entities;

package Ova_Fmt.Format_Gemini is

   procedure Process_Entity (E : Entities.Entity; Entity_No : Positive);
   --  Writes E to Ada.Text_IO.Current_Output, in gemtext.

end Ova_Fmt.Format_Gemini;
