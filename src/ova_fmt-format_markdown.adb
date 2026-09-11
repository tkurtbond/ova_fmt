with Ova_Fmt.Format_Common;

package body Ova_Fmt.Format_Markdown is

   procedure Process_Entity (E : Entities.Entity; Entity_No : Positive) is
   begin
      Ova_Fmt.Format_Common.Process_Entity (E, Entity_No);
   end Process_Entity;

end Ova_Fmt.Format_Markdown;
