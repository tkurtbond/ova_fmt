with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Text_IO;
with Ova_Fmt.Config;
with Ova_Fmt.Format_Common;

package body Ova_Fmt.Format_Rst is

   package Config renames Ova_Fmt.Config;
   package Common renames Ova_Fmt.Format_Common;
   package IO renames Ada.Text_IO;
   use type Config.Output_Format;
   use type Entities.Sub_Entity_Access;

   -----------------------------------------------------------------
   --  Html_In_Rst: reST with one `.. raw:: html` block for the
   --  genuinely tabular/nestable content (Abilities/Weaknesses/
   --  Combat/Attacks) -- everything else (header/tagline/summary/
   --  background/personality/Notes/Fluff/Creation Rules) is plain
   --  reST, shared with Terse via Ova_Fmt.Format_Common
   --  (Print_Header_And_Prose/Print_Tail, called directly below). One
   --  `<table>` per section; a linked Ability's own row gets one
   --  extra `<td>` holding a full nested set of `<table>`s for its
   --  Companion/Vehicle/Transformation/Magic content -- real HTML
   --  nesting, which is the entire reason this backend exists (reST
   --  tables can't nest at all). Design confirmed with the user
   --  before writing this (a full worked Karis/Arasuni example), not
   --  invented silently.
   -----------------------------------------------------------------

   Raw_Prefix : constant String := "   ";
   --  The reST `.. raw:: html` block's own required indent -- same
   --  convention/width as besm2_fmt.Format_Raw_Ms's Raw_Prefix for
   --  its `.. raw:: ms` block.

   function Html_Escape (S : String) return String is
      Result : Unbounded_String;
   begin
      for C of S loop
         case C is
            when '&' => Result := Result & "&amp;";
            when '<' => Result := Result & "&lt;";
            when '>' => Result := Result & "&gt;";
            when others => Append (Result, C);
         end case;
      end loop;
      return To_String (Result);
   end Html_Escape;
   --  Every piece of free-form/author-written text (Name, Detail,
   --  Description, a Perk/Flaw's own text) that lands inside an HTML
   --  table cell needs this -- unlike Terse/Gemtext, where such text
   --  is passed straight through with no escaping concern at all,
   --  literal `&`/`<`/`>` here would corrupt the markup or be
   --  misread as a tag. `"` isn't escaped: nothing here writes it
   --  inside an HTML attribute value, only ever inside element text.

   function Strip_Parens (S : String) return String is
     (if S'Length >= 2 and then S (S'First) = '(' and then S (S'Last) = ')'
      then S (S'First + 1 .. S'Last - 1)
      else S);
   --  Format_Attack_Clause's own "(Affinity: ...; Perks: ...; Flaws:
   --  ...)" is built for an inline terse sentence; a table cell wants
   --  the same content without the wrapping parens.

   procedure Print_Sub_Item_Table
     (Items : Entities.Sub_Item_Vectors.Vector; Caption : String; Indent : String)
   is
   begin
      if Items.Is_Empty then
         return;
      end if;
      IO.Put_Line (Raw_Prefix & Indent & "<table>");
      IO.Put_Line (Raw_Prefix & Indent & "<caption>" & Html_Escape (Caption) & "</caption>");
      IO.Put_Line
        (Raw_Prefix & Indent &
         "<tr><th>Name</th><th>Level</th><th>Detail</th><th>Perks/Flaws</th></tr>");
      for I of Items loop
         IO.Put_Line
           (Raw_Prefix & Indent & "<tr><td>" & Html_Escape (To_String (I.Name)) &
            "</td><td>" & Common.Signed_Img (I.Level) & "</td><td>" &
            (if I.Has_Detail then Html_Escape (To_String (I.Detail)) else "") &
            "</td><td>" &
            Html_Escape (Strip_Parens (Common.Format_Modifiers_Bracket (I.Perks, I.Flaws))) &
            "</td></tr>");
      end loop;
      IO.Put_Line (Raw_Prefix & Indent & "</table>");
   end Print_Sub_Item_Table;

   procedure Print_Spells_Table
     (Spells : Entities.Spell_Vectors.Vector; Caption : String; Indent : String)
   is
   begin
      if Spells.Is_Empty then
         return;
      end if;
      IO.Put_Line (Raw_Prefix & Indent & "<table>");
      IO.Put_Line (Raw_Prefix & Indent & "<caption>" & Html_Escape (Caption) & "</caption>");
      IO.Put_Line
        (Raw_Prefix & Indent &
         "<tr><th>Name</th><th>Ability</th><th>Level</th><th>Endurance</th></tr>");
      for S of Spells loop
         IO.Put_Line
           (Raw_Prefix & Indent & "<tr><td>" & Html_Escape (To_String (S.Name)) &
            "</td><td>" & Html_Escape (To_String (S.Ability)) & "</td><td>" &
            Common.Signed_Img (S.Level) & "</td><td>" & Html_Escape (To_String (S.Endurance)) &
            "</td></tr>");
      end loop;
      IO.Put_Line (Raw_Prefix & Indent & "</table>");
   end Print_Spells_Table;

   procedure Print_Attacks_Table
     (Attacks : Entities.Attack_Vectors.Vector; Caption : String; Indent : String)
   is
   begin
      if Attacks.Is_Empty then
         return;
      end if;
      IO.Put_Line (Raw_Prefix & Indent & "<table>");
      IO.Put_Line (Raw_Prefix & Indent & "<caption>" & Html_Escape (Caption) & "</caption>");
      IO.Put_Line
        (Raw_Prefix & Indent &
         "<tr><th>Name</th><th>Roll</th><th>DX</th><th>Endurance Cost</th>" &
         "<th>Perks/Flaws</th><th>Description</th></tr>");
      for A of Attacks loop
         IO.Put_Line
           (Raw_Prefix & Indent & "<tr><td>" & Html_Escape (To_String (A.Name)) &
            "</td><td>" & Common.Number_Img (A.Roll) & "</td><td>" &
            Html_Escape (To_String (A.Dx)) &
            "</td><td>" & Common.Trim_Img (A.Endurance) & "</td><td>" &
            Html_Escape (Strip_Parens (Common.Format_Attack_Clause (A))) & "</td><td>" &
            (if A.Has_Description then Html_Escape (To_String (A.Description)) else "") &
            "</td></tr>");
      end loop;
      IO.Put_Line (Raw_Prefix & Indent & "</table>");
   end Print_Attacks_Table;

   procedure Print_Combat_Table
     (C : Entities.Combat_Stats; Caption : String; Indent : String)
   is
   begin
      if not C.Has_Combat then
         return;
      end if;
      IO.Put_Line (Raw_Prefix & Indent & "<table>");
      IO.Put_Line (Raw_Prefix & Indent & "<caption>" & Html_Escape (Caption) & "</caption>");
      IO.Put_Line
        (Raw_Prefix & Indent &
         "<tr><th>Health</th><th>Endurance</th><th>Defense</th><th>Threat Value</th></tr>");
      IO.Put_Line
        (Raw_Prefix & Indent & "<tr><td>" & Common.Trim_Img (C.Health) & "</td><td>" &
         Common.Trim_Img (C.Endurance) & "</td><td>" & Html_Escape (To_String (C.Defense)) &
         "</td><td>" & (if C.Has_Threat_Value then Common.Trim_Img (C.Threat_Value) else "—") &
         "</td></tr>");
      IO.Put_Line (Raw_Prefix & Indent & "</table>");
      Print_Attacks_Table (C.Attacks, Caption & " — Attacks", Indent);
   end Print_Combat_Table;

   procedure Print_Sub_Entity_Tables (SE : Entities.Sub_Entity_Access; Indent : String) is
      Who : constant String :=
        To_String (SE.Label) & ": " & To_String (SE.Name);
   begin
      Print_Sub_Item_Table (SE.Abilities, Who & " — Abilities", Indent);
      Print_Sub_Item_Table (SE.Weaknesses, Who & " — Weaknesses", Indent);
      Print_Combat_Table (SE.Combat, Who & " — Combat", Indent);
   end Print_Sub_Entity_Tables;

   --  The extra cell an Ability's own row gets when it grants linked
   --  content -- at most one of these three cases is ever populated
   --  for a real Ability (Ability's own doc comment), so there's no
   --  real ordering concern between them.
   procedure Print_Linked_Content_Cell (A : Entities.Ability; Indent : String) is
      Inner_Indent : constant String := Indent & "  ";
   begin
      if A.Sub_Entity /= null then
         Print_Sub_Entity_Tables (A.Sub_Entity, Inner_Indent);
      end if;
      if not A.Sub_Abilities.Is_Empty or else not A.Sub_Weaknesses.Is_Empty then
         Print_Sub_Item_Table
           (A.Sub_Abilities, To_String (A.Name) & " — Grants (Abilities)", Inner_Indent);
         Print_Sub_Item_Table
           (A.Sub_Weaknesses, To_String (A.Name) & " — Grants (Weaknesses)", Inner_Indent);
      end if;
      if not A.Spells.Is_Empty then
         Print_Spells_Table (A.Spells, To_String (A.Name) & " — Spells", Inner_Indent);
      end if;
   end Print_Linked_Content_Cell;

   procedure Print_Ability_Row (A : Entities.Ability; Indent : String) is
      Has_Linked : constant Boolean :=
        A.Sub_Entity /= null or else not A.Sub_Abilities.Is_Empty
        or else not A.Sub_Weaknesses.Is_Empty or else not A.Spells.Is_Empty;
   begin
      IO.Put
        (Raw_Prefix & Indent & "<tr><td>" & Html_Escape (To_String (A.Name)) &
         "</td><td>" & Common.Signed_Img (A.Level) & "</td><td>" &
         (if A.Has_Detail then Html_Escape (To_String (A.Detail)) else "") &
         "</td><td>" &
         Html_Escape (Strip_Parens (Common.Format_Modifiers_Bracket (A.Perks, A.Flaws))) &
         "</td>");
      if not Has_Linked then
         IO.Put_Line ("</tr>");
      else
         IO.New_Line;
         IO.Put_Line (Raw_Prefix & Indent & "  <td>");
         Print_Linked_Content_Cell (A, Indent & "  ");
         IO.Put_Line (Raw_Prefix & Indent & "  </td>");
         IO.Put_Line (Raw_Prefix & Indent & "</tr>");
      end if;
   end Print_Ability_Row;

   procedure Print_Abilities_Table (Abilities : Entities.Ability_Vectors.Vector) is
   begin
      if Abilities.Is_Empty then
         return;
      end if;
      IO.Put_Line (Raw_Prefix & "<table>");
      IO.Put_Line (Raw_Prefix & "<caption>Abilities</caption>");
      IO.Put_Line
        (Raw_Prefix & "<tr><th>Name</th><th>Level</th><th>Detail</th><th>Perks/Flaws</th></tr>");
      for A of Abilities loop
         Print_Ability_Row (A, "");
      end loop;
      IO.Put_Line (Raw_Prefix & "</table>");
      IO.New_Line;
   end Print_Abilities_Table;

   procedure Print_Weaknesses_Table (Weaknesses : Entities.Weakness_Vectors.Vector) is
   begin
      if Weaknesses.Is_Empty then
         return;
      end if;
      IO.Put_Line (Raw_Prefix & "<table>");
      IO.Put_Line (Raw_Prefix & "<caption>Weaknesses</caption>");
      IO.Put_Line (Raw_Prefix & "<tr><th>Name</th><th>Level</th><th>Detail</th></tr>");
      for W of Weaknesses loop
         IO.Put_Line
           (Raw_Prefix & "<tr><td>" & Html_Escape (To_String (W.Name)) & "</td><td>" &
            Common.Signed_Img (W.Level) & "</td><td>" &
            (if W.Has_Detail then Html_Escape (To_String (W.Detail)) else "") &
            "</td></tr>");
      end loop;
      IO.Put_Line (Raw_Prefix & "</table>");
      IO.New_Line;
   end Print_Weaknesses_Table;

   procedure Print_Html_Tables (E : Entities.Entity) is
   begin
      if E.Abilities.Is_Empty and then E.Weaknesses.Is_Empty
        and then not E.Combat.Has_Combat
      then
         return;
      end if;
      IO.Put_Line (".. raw:: html");
      IO.New_Line;
      Print_Abilities_Table (E.Abilities);
      Print_Weaknesses_Table (E.Weaknesses);
      Print_Combat_Table (E.Combat, "Combat", "");
      IO.New_Line;
   end Print_Html_Tables;

   -----------------------------------------------------------------
   --  Process_Entity.
   -----------------------------------------------------------------

   procedure Process_Entity (E : Entities.Entity; Entity_No : Positive) is
   begin
      --  A Fragment renders identically under every format (no raw
      --  HTML block, no tables -- Ova_Fmt.Format_Common.Process_Entity's
      --  own doc comment/header-comment note), so it's delegated to
      --  Format_Common along with plain Terse mode; only a non-
      --  Fragment entity in Html_In_Rst mode needs this package's own
      --  table rendering.
      if not E.Is_Fragment and then Config.Format = Config.Html_In_Rst then
         Common.Print_Header_And_Prose (E, Entity_No);
         Print_Html_Tables (E);
         Common.Print_Tail (E);
      else
         Common.Process_Entity (E, Entity_No);
      end if;
   end Process_Entity;

end Ova_Fmt.Format_Rst;
