with Ada.Characters.Handling;
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

   --  Override_Mark for a raw table's cell: "*" or "".
   function Mark (Overridden : Boolean) return String is
     (Common.Override_Mark (Overridden, Raw => True));

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
            "</td><td>" & Common.Signed_Img (I.Level) &
            Common.Half_TV_Text (I.Has_Threat_Value_Half, I.Threat_Value_Half) & "</td><td>" &
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
            Mark (S.Overrides (Entities.Endurance)) & "</td></tr>");
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
            "</td><td>" & Common.Number_Img (A.Roll) & Mark (A.Overrides (Entities.Roll)) &
            "</td><td>" & Html_Escape (To_String (A.Dx)) & Mark (A.Overrides (Entities.Dx)) &
            "</td><td>" & Common.Trim_Img (A.Endurance) &
            Mark (A.Overrides (Entities.Endurance)) & "</td><td>" &
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
        (Raw_Prefix & Indent & "<tr><td>" & Common.Trim_Img (C.Health) &
         Mark (C.Overrides (Entities.Health)) & "</td><td>" &
         Common.Trim_Img (C.Endurance) & Mark (C.Overrides (Entities.Endurance)) &
         "</td><td>" & Html_Escape (Common.Defense_Text (C, Raw => True)) & "</td><td>" &
         (if C.Has_Threat_Value
          then Common.Trim_Img (C.Threat_Value) & Mark (C.Overrides (Entities.Threat_Value))
          else "—") &
         "</td></tr>");
      IO.Put_Line (Raw_Prefix & Indent & "</table>");
      Print_Attacks_Table (C.Attacks, Caption & " — Attacks", Indent);
      --  One line: a line of a raw block must keep its indent.
      if C.Has_Notes then
         IO.Put_Line
           (Raw_Prefix & Indent & "<p><strong>Combat Notes:</strong> " &
            Html_Escape (Common.All_One_Line (To_String (C.Notes))) & "</p>");
      end if;
   end Print_Combat_Table;

   --  Fragment-style Companion/Vehicle (`fragment: true`): this
   --  content lives *inside* a `<td>` cell (Print_Linked_Content_Cell
   --  below), so unlike Groff_In_Rst's own fragment-style handling
   --  (Print_Groff_Tables, which drops all the way to plain reST by
   --  closing its raw block) there's no way to leave raw HTML mid-cell
   --  -- this renders a flatter version that's still valid HTML: one
   --  escaped "Attributes:" paragraph instead of two nested `<table>`s
   --  for Abilities/Weaknesses, Combat unchanged (a compact one-row-
   --  plus-Attacks table already, and HTML has no print-pagination
   --  concern the way Groff_In_Rst's own `hd` tables do, so there's no
   --  correctness reason to flatten it further here).
   procedure Print_Sub_Entity_Tables (SE : Entities.Sub_Entity_Access; Indent : String) is
      Who : constant String :=
        To_String (SE.Label) & ": " & To_String (SE.Name);
   begin
      if SE.Is_Fragment then
         --  Leads with "<strong>Who</strong> --" ("Companion: Azyrus"),
         --  same fix/reasoning as Ova_Fmt.Format_Common.
         --  Print_Sub_Entity_Fragment_Style's own doc comment: a
         --  Sub_Entity has no Background of its own to fall back on
         --  for identification the way a top-level Fragment does.
         if SE.Abilities.Is_Empty and then SE.Weaknesses.Is_Empty then
            IO.Put_Line
              (Raw_Prefix & Indent & "<p><strong>" & Html_Escape (Who) & "</strong>.</p>");
         else
            declare
               Line : Unbounded_String :=
                 To_Unbounded_String
                   ("<strong>" & Html_Escape (Who) & "</strong> -- <strong>Attributes:</strong> ") &
                 Html_Escape (Common.Join_Fragment_Sub_Items (SE.Abilities));
            begin
               if not SE.Abilities.Is_Empty and then not SE.Weaknesses.Is_Empty then
                  Line := Line & "; ";
               end if;
               Line := Line & Html_Escape (Common.Join_Fragment_Sub_Items (SE.Weaknesses));
               IO.Put_Line (Raw_Prefix & Indent & "<p>" & To_String (Line) & ".</p>");
            end;
         end if;
         Print_Combat_Table (SE.Combat, Who & " — Combat", Indent);
         return;
      end if;
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
         "</td><td>" & Common.Signed_Img (A.Level) &
         Common.Half_TV_Text (A.Has_Threat_Value_Half, A.Threat_Value_Half) & "</td><td>" &
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
      Print_Combat_Table
        (E.Combat,
         (if E.Has_NPC_Type then "Combat (" & Common.NPC_Type_Text (E) & ")" else "Combat"),
         "");
      IO.New_Line;
   end Print_Html_Tables;

   -----------------------------------------------------------------
   --  Groff_In_Rst: reST with `.. raw:: ms` blocks using groff's `hd`
   --  table macros (`hdtbl.tmac`, loaded via `.mso hdtbl.tmac`) --
   --  PLAN.md §7 (`hd`, not classic `tbl`, since `tbl` has no way to
   --  nest a table inside a cell). Header/tagline/summary/background/
   --  personality are shared with Terse/Html_In_Rst via
   --  Print_Header_And_Prose.
   --
   --  Laid out to match the rulebook's own Sample Characters spread
   --  (PLAN.md §2.1/§2.2, and the progress notes under §9 step 6),
   --  not Html_In_Rst's simpler sequential one-table-per-section
   --  shape: Abilities/Weaknesses side by side (an outer, borderless
   --  2-column `.TBL` whose cells each hold one complete bordered
   --  table -- hd's nesting again, just for layout rather than linked
   --  content), a combined "Attacks & Combat Stats (<NAME>)" box, and
   --  an "Other Statistics" box built from `fluff:` instead of
   --  Print_Tail's plain comma-joined line (so Print_Notes/
   --  Print_Options_If_Shown are called directly here instead of
   --  Print_Tail -- Notes/Creation Rules have no rulebook-box analog
   --  and stay exactly as every other format renders them).
   --
   --  Companion/Vehicle sub-entities print as their own separate
   --  section *after* the main character's whole write-up --
   --  structurally self-similar to a top-level entity (own side-by-
   --  side Abilities/Weaknesses, own Attacks & Combat Stats box) --
   --  rather than nested inside the granting Ability's table cell.
   --  Per the user, and confirmed against the rulebook's own Karis/
   --  Arasuni spread (§2.3: Arasuni gets his own separately-boxed
   --  "Attacks & Combat Stats (ARASUNI)," laid out alongside Karis's
   --  own), not merely a workaround for a real `hd` limitation found
   --  this session that this move also happens to fix: a single table
   --  taller than about 28 rows (at hd-layout-experiment.ms's font/
   --  margins) is silently dropped with no error at all, and a
   --  Companion/Vehicle's own nested Abilities/Weaknesses/Combat
   --  content was the one thing big enough to trigger that.
   --  Transformation's sub-abilities/sub-weaknesses and Magic's
   --  spells are unaffected -- short flat lists, no `combat:` block,
   --  nowhere near the ceiling -- and still nest directly in the
   --  granting row's own cell, as hd-experiment.ms first proved.
   --
   --  Every top-level `.TBL` is preceded by a `.ne <N>` (a plain
   --  core-troff "need N more lines or start a new page" request,
   --  nothing hd-specific) sized off that table's own row count --
   --  found this session that hd tables don't just fail past a one-
   --  page height ceiling, they fail to fit in whatever space is left
   --  on the *current* page and do NOT automatically flow onto a
   --  fresh page on their own; `.ne` is what makes that automatic
   --  instead of a matter of luck. The row-counting functions below
   --  and Table_Ne's 2-lines-per-row-plus-4 formula are a deliberately
   --  generous rule of thumb (covers one wrapped Perks/Flaws or
   --  description line per row), not real text-metrics -- confirmed
   --  sufficient against Karis/Arasuni's own worked example
   --  (hd-layout-experiment.ms/.rst), not proven in general; an
   --  unusually attack-heavy character's own Combat box is the
   --  residual risk this doesn't eliminate (PLAN.md §9 step 6).
   -----------------------------------------------------------------

   function Groff_Escape (S : String) return String is
      Result : Unbounded_String;
   begin
      for C of S loop
         if C = '\' then
            Result := Result & "\e";
         else
            Append (Result, C);
         end if;
      end loop;
      --  A leading '.' or ''' would otherwise be read as a troff
      --  control line when this text lands as a bare line of its own
      --  (a multi-line cell, e.g. an Ability with linked content) --
      --  `\&` is troff's zero-width escape for defusing exactly that.
      if Length (Result) > 0
        and then (Element (Result, 1) = '.' or else Element (Result, 1) = ''')
      then
         Result := "\&" & Result;
      end if;
      return To_String (Result);
   end Groff_Escape;

   --  " (half TV)" goes after the name, not the Level: the Level
   --  column is too narrow for it.
   function Ability_Cell_Text (A : Entities.Ability) return String is
      Result : Unbounded_String :=
        To_Unbounded_String
          (Common.Name_Detail (A.Name, A.Has_Detail, A.Detail) &
           Common.Half_TV_Text (A.Has_Threat_Value_Half, A.Threat_Value_Half));
   begin
      Result := Result & Common.Format_Modifiers_Bracket (A.Perks, A.Flaws);
      if A.Has_Note then
         Result := Result & " (" & A.Note & ")";
      end if;
      if A.Sub_Entity /= null then
         --  A literal em dash character, not the troff `\(em` escape --
         --  this text is passed through Groff_Escape below, which
         --  would otherwise mangle a hand-written backslash escape
         --  (it exists to neutralize backslashes in arbitrary
         --  user-authored text, not to distinguish "escape I meant"
         --  from "backslash the user typed"). groff renders the UTF-8
         --  character directly, same convention Format_Common/
         --  Print_Sub_Entity_Tables already use for their own
         --  "Name — Grants (...)"-style separators.
         Result := Result & " — see below";
      end if;
      return Groff_Escape (To_String (Result));
   end Ability_Cell_Text;

   function Weakness_Cell_Text (W : Entities.Weakness) return String is
     (Groff_Escape (Common.Name_Detail (W.Name, W.Has_Detail, W.Detail)));

   function Sub_Item_Cell_Text (S : Entities.Sub_Item) return String is
      Result : Unbounded_String :=
        To_Unbounded_String
          (Common.Name_Detail (S.Name, S.Has_Detail, S.Detail) &
           Common.Half_TV_Text (S.Has_Threat_Value_Half, S.Threat_Value_Half));
   begin
      Result := Result & Common.Format_Modifiers_Bracket (S.Perks, S.Flaws);
      if S.Has_Note then
         Result := Result & " (" & S.Note & ")";
      end if;
      return Groff_Escape (To_String (Result));
   end Sub_Item_Cell_Text;

   function Spell_Detail_Text (S : Entities.Spell) return String is
     (Groff_Escape
        (To_String (S.Ability) & " " & Common.Signed_Img (S.Level) & "; " &
         To_String (S.Endurance) & Mark (S.Overrides (Entities.Endurance)) & " Endurance"));

   --  Row-count estimators, walked with the same structure as the
   --  Print_* procedures below so a `.ne` emitted before a table
   --  covers everything that table is actually about to contain,
   --  nested content included.

   function Ability_Row_Count (A : Entities.Ability) return Natural is
      N : Natural := 1;
   begin
      if not A.Sub_Abilities.Is_Empty then
         N := N + Natural (A.Sub_Abilities.Length) + 2;
      end if;
      if not A.Sub_Weaknesses.Is_Empty then
         N := N + Natural (A.Sub_Weaknesses.Length) + 2;
      end if;
      if not A.Spells.Is_Empty then
         N := N + Natural (A.Spells.Length) + 2;
      end if;
      return N;
   end Ability_Row_Count;

   function Abilities_Table_Rows (Abilities : Entities.Ability_Vectors.Vector) return Natural is
      N : Natural := 2;  --  header + caption
   begin
      for A of Abilities loop
         N := N + Ability_Row_Count (A);
      end loop;
      return N;
   end Abilities_Table_Rows;

   function Weaknesses_Table_Rows (Weaknesses : Entities.Weakness_Vectors.Vector) return Natural is
     (if Weaknesses.Is_Empty then 0 else Natural (Weaknesses.Length) + 2);

   function Combat_Table_Rows (C : Entities.Combat_Stats) return Natural is
      N : Natural := 2;  --  caption + column-header row
   begin
      if not C.Has_Combat then
         return 0;
      end if;
      for A of C.Attacks loop
         N := N + 1;
         if Strip_Parens (Common.Format_Attack_Clause (A)) /= "" then
            N := N + 1;
         end if;
         if A.Has_Description then
            N := N + 1;
         end if;
      end loop;
      --  Combat Notes: a row, and one more per 80 characters, as
      --  generous as Table_Ne's own estimate.
      if C.Has_Notes then
         N := N + 1 + Length (C.Notes) / 80;
      end if;
      return N + 2;  --  Defense/Health/Endurance/TV header + values
   end Combat_Table_Rows;

   function Other_Statistics_Rows (F : Entities.Fluff_Block) return Natural is
      N : Natural := 1;  --  caption
   begin
      if F.Has_Concept then N := N + 1; end if;
      if F.Has_Birthday then N := N + 1; end if;
      if F.Has_Age then N := N + 1; end if;
      if F.Has_Gender then N := N + 1; end if;
      if F.Has_Height then N := N + 1; end if;
      if F.Has_Weight then N := N + 1; end if;
      if F.Has_Hair then N := N + 1; end if;
      if F.Has_Eyes then N := N + 1; end if;
      if F.Has_Association then N := N + 1; end if;
      if F.Has_Hobbies then N := N + 1; end if;
      if F.Has_Favorite_Food then N := N + 1; end if;
      if F.Has_Allies then N := N + 1; end if;
      if F.Has_Enemies then N := N + 1; end if;
      if F.Has_Love_Interests then N := N + 1; end if;
      return N;
   end Other_Statistics_Rows;

   procedure Emit_Ne (Rows : Natural) is
   begin
      IO.Put_Line (Raw_Prefix & ".ne " & Common.Trim_Img (2 * Rows + 4));
   end Emit_Ne;

   --  hdtbl's `.TD`/`.CPTN` scan EVERY trailing argument token for a
   --  `keyword=value` match against its whole fixed keyword list
   --  (hal, val, fst, bc, bgc, fgc, csp, cpd, cols, border, height,
   --  tal, width, rowspan, colspan) by comparing each token's own
   --  leading characters, NOT by requiring a literal '=' first --
   --  found this session when Fukiko's Barrier detail text ("...the
   --  second Defense value in Combat...") made hdtbl choke on the
   --  plain English word "value" with "Invalid vertical alignment
   --  'e'": the scanner read "value" as an attempted `val=` cell
   --  keyword. Confirmed fix: put any free-form/user-authored text
   --  (an Ability/Weakness/Attack/Fluff name, detail, note, or
   --  description -- anything not one of this package's own fixed
   --  column-header/caption-template strings) on its own following
   --  line instead of as a same-line trailing argument -- hdtbl's
   --  keyword scan only looks at the request line's own arguments,
   --  never at body text that follows, so a bare `.TD`/`.CPTN val=b`
   --  (only real keyword=value pairs on the request line itself, if
   --  any) followed by the actual text on the next line is immune,
   --  confirmed both against this exact failure and against a
   --  deliberately adversarial line of every reserved keyword name.
   --  Every call site below that carries real user text goes through
   --  these two helpers rather than ad hoc string concatenation, so
   --  this can't quietly regress by a future edit putting text back
   --  on the request line.
   procedure Put_Cell (Keyword_Args : String; Text : String) is
   begin
      if Keyword_Args = "" then
         IO.Put_Line (Raw_Prefix & ".TD");
      else
         IO.Put_Line (Raw_Prefix & ".TD " & Keyword_Args);
      end if;
      IO.Put_Line (Raw_Prefix & Text);
   end Put_Cell;

   --  Unlike Put_Cell, this keeps the caption as a same-line, quoted
   --  trailing argument (`.CPTN val=b "..."`) rather than moving it to
   --  a following line -- found while testing this fix through the
   --  real Pandoc/pdfroff pipeline (not just bare groff) that `.CPTN`'s
   --  own "read the caption from the next line" support does NOT
   --  survive that pipeline: the caption text gets emitted as ordinary
   --  body text ABOVE the table instead, leaving the table's actual
   --  caption blank. A double-quoted argument is grouped into a
   --  single token by troff's own request-line parsing (before
   --  hdtbl's keyword scan ever runs), so this is only at risk from
   --  the same-token-starts-with-a-reserved-keyword-name bug
   --  (Put_Cell's own header comment) if the caption's own leading
   --  characters happened to be a lowercase match -- every caption
   --  built by this package starts with either a fixed, controlled
   --  string ("Attacks & Combat Stats (...", "Other Statistics") or a
   --  user-authored Ability/entity name, and OVA ability/weakness/
   --  character names are conventionally capitalized throughout every
   --  fixture transcribed so far, so this residual risk is accepted
   --  rather than chased further.
   procedure Put_Caption (Text : String) is
   begin
      IO.Put_Line (Raw_Prefix & ".CPTN val=b """ & Text & """");
   end Put_Caption;

   function Sub_Items_Table_Rows (Items : Entities.Sub_Item_Vectors.Vector) return Natural is
     (if Items.Is_Empty then 0 else Natural (Items.Length) + 2);

   --  Compact (the default): a Transformation/Companion Ability's own
   --  granted sub-abilities/sub-weaknesses, genuinely nested inside
   --  that Ability's table cell -- tighter spacing since it's already
   --  indented one level. Compact => False: a Sub_Entity's *own*
   --  Abilities/Weaknesses, printed at full weight in its own
   --  trailing section (Print_Side_By_Side_Sub_Groff below) -- same
   --  visual weight as the main character's own tables, confirmed
   --  against hd-layout-experiment.ms's Arasuni tables.
   procedure Print_Sub_Item_Table_Groff
     (Items : Entities.Sub_Item_Vectors.Vector; Caption : String;
      Compact : Boolean := True)
   is
      Spacing : constant String := (if Compact then "csp=1p cpd=1p" else "csp=2p cpd=2p");
   begin
      if Items.Is_Empty then
         return;
      end if;
      IO.Put_Line
        (Raw_Prefix & ".TBL cols=2 border=.5p bc=black " & Spacing & " width='15% 85%'");
      Put_Caption (Groff_Escape (Caption));
      IO.Put_Line (Raw_Prefix & ".TR");
      IO.Put_Line (Raw_Prefix & ".TH Level");
      IO.Put_Line (Raw_Prefix & ".TH Name");
      for I of Items loop
         IO.Put_Line (Raw_Prefix & ".TR");
         IO.Put_Line (Raw_Prefix & ".TD hal=r " & Common.Signed_Img (I.Level));
         Put_Cell ("", Sub_Item_Cell_Text (I));
      end loop;
      IO.Put_Line (Raw_Prefix & ".ETB");
   end Print_Sub_Item_Table_Groff;

   procedure Print_Spells_Table_Groff
     (Spells : Entities.Spell_Vectors.Vector; Caption : String)
   is
   begin
      if Spells.Is_Empty then
         return;
      end if;
      IO.Put_Line
        (Raw_Prefix & ".TBL cols=2 border=.5p bc=black csp=1p cpd=1p width='30% 70%'");
      Put_Caption (Groff_Escape (Caption));
      IO.Put_Line (Raw_Prefix & ".TR");
      IO.Put_Line (Raw_Prefix & ".TH Name");
      IO.Put_Line (Raw_Prefix & ".TH Detail");
      for S of Spells loop
         IO.Put_Line (Raw_Prefix & ".TR");
         Put_Cell ("", Groff_Escape (To_String (S.Name)));
         Put_Cell ("", Spell_Detail_Text (S));
      end loop;
      IO.Put_Line (Raw_Prefix & ".ETB");
   end Print_Spells_Table_Groff;

   procedure Print_Ability_Row_Groff (A : Entities.Ability) is
   begin
      IO.Put_Line (Raw_Prefix & ".TR");
      IO.Put_Line (Raw_Prefix & ".TD hal=r " & Common.Signed_Img (A.Level));
      Put_Cell ("", Ability_Cell_Text (A));
      if not A.Sub_Abilities.Is_Empty or else not A.Sub_Weaknesses.Is_Empty
        or else not A.Spells.Is_Empty
      then
         Print_Sub_Item_Table_Groff
           (A.Sub_Abilities, To_String (A.Name) & " — Grants (Abilities)");
         Print_Sub_Item_Table_Groff
           (A.Sub_Weaknesses, To_String (A.Name) & " — Grants (Weaknesses)");
         Print_Spells_Table_Groff (A.Spells, To_String (A.Name) & " — Spells");
      end if;
   end Print_Ability_Row_Groff;

   procedure Print_Abilities_Table_Groff (Abilities : Entities.Ability_Vectors.Vector) is
   begin
      if Abilities.Is_Empty then
         return;
      end if;
      IO.Put_Line
        (Raw_Prefix & ".TBL cols=2 border=.5p bc=black csp=2p cpd=2p width='15% 85%'");
      IO.Put_Line (Raw_Prefix & ".CPTN val=b Abilities");
      IO.Put_Line (Raw_Prefix & ".TR");
      IO.Put_Line (Raw_Prefix & ".TH Level");
      IO.Put_Line (Raw_Prefix & ".TH Name");
      for A of Abilities loop
         Print_Ability_Row_Groff (A);
      end loop;
      IO.Put_Line (Raw_Prefix & ".ETB");
   end Print_Abilities_Table_Groff;

   procedure Print_Weaknesses_Table_Groff (Weaknesses : Entities.Weakness_Vectors.Vector) is
   begin
      if Weaknesses.Is_Empty then
         return;
      end if;
      IO.Put_Line
        (Raw_Prefix & ".TBL cols=2 border=.5p bc=black csp=2p cpd=2p width='15% 85%'");
      IO.Put_Line (Raw_Prefix & ".CPTN val=b Weaknesses");
      IO.Put_Line (Raw_Prefix & ".TR");
      IO.Put_Line (Raw_Prefix & ".TH Level");
      IO.Put_Line (Raw_Prefix & ".TH Name");
      for W of Weaknesses loop
         IO.Put_Line (Raw_Prefix & ".TR");
         IO.Put_Line (Raw_Prefix & ".TD hal=r " & Common.Signed_Img (W.Level));
         Put_Cell ("", Weakness_Cell_Text (W));
      end loop;
      IO.Put_Line (Raw_Prefix & ".ETB");
   end Print_Weaknesses_Table_Groff;

   procedure Print_Side_By_Side_Groff
     (Abilities  : Entities.Ability_Vectors.Vector;
      Weaknesses : Entities.Weakness_Vectors.Vector)
   is
   begin
      if Abilities.Is_Empty and then Weaknesses.Is_Empty then
         return;
      end if;
      if not Abilities.Is_Empty and then not Weaknesses.Is_Empty then
         Emit_Ne
           (Natural'Max
              (Abilities_Table_Rows (Abilities), Weaknesses_Table_Rows (Weaknesses)));
         IO.Put_Line (Raw_Prefix & ".TBL cols=2 border=0 csp=4p cpd=0");
         IO.Put_Line (Raw_Prefix & ".TR");
         IO.Put_Line (Raw_Prefix & ".TD");
         Print_Abilities_Table_Groff (Abilities);
         IO.Put_Line (Raw_Prefix & ".TD");
         Print_Weaknesses_Table_Groff (Weaknesses);
         IO.Put_Line (Raw_Prefix & ".ETB");
      elsif not Abilities.Is_Empty then
         Emit_Ne (Abilities_Table_Rows (Abilities));
         Print_Abilities_Table_Groff (Abilities);
      else
         Emit_Ne (Weaknesses_Table_Rows (Weaknesses));
         Print_Weaknesses_Table_Groff (Weaknesses);
      end if;
   end Print_Side_By_Side_Groff;

   procedure Print_Combat_Table_Groff (C : Entities.Combat_Stats; Label : String) is
   begin
      if not C.Has_Combat then
         return;
      end if;
      Emit_Ne (Combat_Table_Rows (C));
      IO.Put_Line
        (Raw_Prefix & ".TBL cols=4 border=.5p bc=black csp=2p cpd=2p width='25% 25% 25% 25%'");
      Put_Caption ("Attacks & Combat Stats (" & Groff_Escape (Label) & ")");
      IO.Put_Line (Raw_Prefix & ".TR");
      IO.Put_Line (Raw_Prefix & ".TH Name");
      IO.Put_Line (Raw_Prefix & ".TH Roll");
      IO.Put_Line (Raw_Prefix & ".TH DX");
      IO.Put_Line (Raw_Prefix & ".TH End");
      for A of C.Attacks loop
         IO.Put_Line (Raw_Prefix & ".TR");
         Put_Cell ("", "\fB" & Groff_Escape (To_String (A.Name)) & "\fP");
         IO.Put_Line
           (Raw_Prefix & ".TD hal=c " & Common.Number_Img (A.Roll) &
            Mark (A.Overrides (Entities.Roll)));
         Put_Cell ("hal=c", Groff_Escape (To_String (A.Dx) & Mark (A.Overrides (Entities.Dx))));
         IO.Put_Line
           (Raw_Prefix & ".TD hal=c " & Common.Trim_Img (A.Endurance) &
            Mark (A.Overrides (Entities.Endurance)));
         declare
            Clause : constant String := Strip_Parens (Common.Format_Attack_Clause (A));
         begin
            if Clause /= "" then
               IO.Put_Line (Raw_Prefix & ".TR");
               Put_Cell ("colspan=4", "[" & Groff_Escape (Clause) & "]");
            end if;
         end;
         if A.Has_Description then
            IO.Put_Line (Raw_Prefix & ".TR");
            Put_Cell ("colspan=4", "\fI" & Groff_Escape (To_String (A.Description)) & "\fP");
         end if;
      end loop;
      IO.Put_Line (Raw_Prefix & ".TR");
      IO.Put_Line (Raw_Prefix & ".TH Defense");
      IO.Put_Line (Raw_Prefix & ".TH Health");
      IO.Put_Line (Raw_Prefix & ".TH Endurance");
      IO.Put_Line (Raw_Prefix & ".TH TV");
      IO.Put_Line (Raw_Prefix & ".TR");
      Put_Cell ("hal=c", "\fB" & Groff_Escape (Common.Defense_Text (C, Raw => True)) & "\fP");
      IO.Put_Line
        (Raw_Prefix & ".TD hal=c \fB" & Common.Trim_Img (C.Health) &
         Mark (C.Overrides (Entities.Health)) & "\fP");
      IO.Put_Line
        (Raw_Prefix & ".TD hal=c \fB" & Common.Trim_Img (C.Endurance) &
         Mark (C.Overrides (Entities.Endurance)) & "\fP");
      IO.Put_Line
        (Raw_Prefix & ".TD hal=c \fB" &
         (if C.Has_Threat_Value
          then Common.Trim_Img (C.Threat_Value) & Mark (C.Overrides (Entities.Threat_Value))
          else "—") & "\fP");
      --  One line, as Put_Cell writes it.
      if C.Has_Notes then
         IO.Put_Line (Raw_Prefix & ".TR");
         Put_Cell
           ("colspan=4",
            "\fBCombat Notes:\fP " & Groff_Escape (Common.All_One_Line (To_String (C.Notes))));
      end if;
      IO.Put_Line (Raw_Prefix & ".ETB");
   end Print_Combat_Table_Groff;

   procedure Print_Other_Statistics_Groff (F : Entities.Fluff_Block) is
      procedure Row (Label : String; Value : Unbounded_String) is
      begin
         IO.Put_Line (Raw_Prefix & ".TR");
         IO.Put_Line (Raw_Prefix & ".TD \fB" & Label & "\fP");
         Put_Cell ("", Groff_Escape (To_String (Value)));
      end Row;
   begin
      if Other_Statistics_Rows (F) <= 1 then
         return;
      end if;
      Emit_Ne (Other_Statistics_Rows (F));
      IO.Put_Line
        (Raw_Prefix & ".TBL cols=2 border=.5p bc=black csp=2p cpd=2p width='25% 75%'");
      Put_Caption ("Other Statistics");
      if F.Has_Concept then Row ("Concept", F.Concept); end if;
      if F.Has_Birthday then Row ("Birthday", F.Birthday); end if;
      if F.Has_Age then Row ("Age", F.Age); end if;
      if F.Has_Gender then Row ("Gender", F.Gender); end if;
      if F.Has_Height then Row ("Height", F.Height); end if;
      if F.Has_Weight then Row ("Weight", F.Weight); end if;
      if F.Has_Hair then Row ("Hair", F.Hair); end if;
      if F.Has_Eyes then Row ("Eyes", F.Eyes); end if;
      if F.Has_Association then Row ("Association", F.Association); end if;
      if F.Has_Hobbies then Row ("Hobbies", F.Hobbies); end if;
      if F.Has_Favorite_Food then Row ("Fave Food", F.Favorite_Food); end if;
      if F.Has_Allies then Row ("Allies", F.Allies); end if;
      if F.Has_Enemies then Row ("Enemies", F.Enemies); end if;
      if F.Has_Love_Interests then Row ("Love Interests", F.Love_Interests); end if;
      IO.Put_Line (Raw_Prefix & ".ETB");
   end Print_Other_Statistics_Groff;

   procedure Print_Side_By_Side_Sub_Groff
     (Abilities, Weaknesses : Entities.Sub_Item_Vectors.Vector;
      Abilities_Caption, Weaknesses_Caption : String)
   is
   begin
      if Abilities.Is_Empty and then Weaknesses.Is_Empty then
         return;
      end if;
      if not Abilities.Is_Empty and then not Weaknesses.Is_Empty then
         Emit_Ne
           (Natural'Max
              (Sub_Items_Table_Rows (Abilities), Sub_Items_Table_Rows (Weaknesses)));
         IO.Put_Line (Raw_Prefix & ".TBL cols=2 border=0 csp=4p cpd=0");
         IO.Put_Line (Raw_Prefix & ".TR");
         IO.Put_Line (Raw_Prefix & ".TD");
         Print_Sub_Item_Table_Groff (Abilities, Abilities_Caption, Compact => False);
         IO.Put_Line (Raw_Prefix & ".TD");
         Print_Sub_Item_Table_Groff (Weaknesses, Weaknesses_Caption, Compact => False);
         IO.Put_Line (Raw_Prefix & ".ETB");
      elsif not Abilities.Is_Empty then
         Emit_Ne (Sub_Items_Table_Rows (Abilities));
         Print_Sub_Item_Table_Groff (Abilities, Abilities_Caption, Compact => False);
      else
         Emit_Ne (Sub_Items_Table_Rows (Weaknesses));
         Print_Sub_Item_Table_Groff (Weaknesses, Weaknesses_Caption, Compact => False);
      end if;
   end Print_Side_By_Side_Sub_Groff;

   --  No standalone ".B" heading line before these tables (an earlier
   --  version had one) -- found while testing that hd's own tables
   --  don't stay in the surrounding document's normal text flow the
   --  way ordinary prose does (the pre-existing "tables float ahead
   --  of surrounding prose" quirk, hd-experiment.ms's own findings),
   --  so plain heading text placed next to them can drift apart from
   --  the tables it's meant to label -- confirmed happening here:
   --  "Companion: Arasuni" rendered a full page *after* Arasuni's own
   --  Combat table instead of before his Abilities/Weaknesses. Folding
   --  "<Label>: <Name>" into each of his own table captions instead
   --  keeps the identifying text glued to the content it labels no
   --  matter how the tables themselves get placed -- and matches the
   --  rulebook's own convention more closely anyway (PLAN.md §2.3:
   --  Arasuni's own box is headed "Attacks & Combat Stats (ARASUNI),"
   --  not introduced by separate running prose).
   procedure Print_Sub_Entity_Section_Groff (SE : Entities.Sub_Entity_Access) is
      Who : constant String := To_String (SE.Label) & ": " & To_String (SE.Name);
   begin
      Print_Side_By_Side_Sub_Groff
        (SE.Abilities, SE.Weaknesses, Who & " — Abilities", Who & " — Weaknesses");
      Print_Combat_Table_Groff
        (SE.Combat, Ada.Characters.Handling.To_Upper (To_String (SE.Name)));
   end Print_Sub_Entity_Section_Groff;

   --  A fragment-style Companion/Vehicle needs to drop all the way out
   --  to plain reST (Common.Print_Sub_Entity_Fragment_Style -- no
   --  `hd` tables at all, matching a top-level Entity.Is_Fragment's
   --  own format-invariant rendering), which means closing the
   --  current `.. raw:: ms` block first and reopening a fresh one
   --  afterward if more raw content follows (another, non-fragment
   --  sub-entity, say) -- unlike Html_In_Rst, where a fragment-style
   --  sub-entity's content is nested *inside* a `<td>` cell and can't
   --  drop out of raw HTML mid-cell, Groff_In_Rst's own sub-entity
   --  sections are already separate top-level content (PLAN.md §9
   --  step 6's Companion/Vehicle-move-out design), so this is clean.
   procedure Print_Groff_Tables (E : Entities.Entity) is
      In_Raw : Boolean := False;

      procedure Ensure_Raw_Open is
      begin
         if not In_Raw then
            IO.Put_Line (".. raw:: ms");
            IO.New_Line;
            --  Pandoc ends the preceding prose paragraph without a
            --  break, so its last, still-filling output line would
            --  otherwise print after hd's tables, not before them.
            IO.Put_Line (Raw_Prefix & ".br");
            IO.Put_Line (Raw_Prefix & ".mso hdtbl.tmac");
            In_Raw := True;
         end if;
      end Ensure_Raw_Open;

      procedure Ensure_Raw_Closed is
      begin
         if In_Raw then
            IO.New_Line;
            In_Raw := False;
         end if;
      end Ensure_Raw_Closed;
   begin
      if E.Abilities.Is_Empty and then E.Weaknesses.Is_Empty
        and then not E.Combat.Has_Combat and then not E.Has_Fluff
      then
         return;
      end if;
      Ensure_Raw_Open;
      Print_Side_By_Side_Groff (E.Abilities, E.Weaknesses);
      --  "(HEROIC)", as the Sample NPCs' boxes have it, in place of
      --  the name: a Companion/Vehicle's own box still has its name.
      Print_Combat_Table_Groff
        (E.Combat,
         Ada.Characters.Handling.To_Upper
           (if E.Has_NPC_Type then Common.NPC_Type_Text (E) else To_String (E.Name)));
      if E.Has_Fluff then
         Print_Other_Statistics_Groff (E.Fluff);
      end if;
      for A of E.Abilities loop
         if A.Sub_Entity /= null then
            if A.Sub_Entity.Is_Fragment then
               Ensure_Raw_Closed;
               Common.Print_Sub_Entity_Fragment_Style (A.Sub_Entity);
            else
               Ensure_Raw_Open;
               Print_Sub_Entity_Section_Groff (A.Sub_Entity);
            end if;
         end if;
      end loop;
      Ensure_Raw_Closed;
   end Print_Groff_Tables;

   -----------------------------------------------------------------
   --  Process_Entity.
   -----------------------------------------------------------------

   procedure Process_Entity (E : Entities.Entity; Entity_No : Positive) is
   begin
      --  A Fragment renders identically under every format (no raw
      --  HTML/ms block, no tables -- Ova_Fmt.Format_Common.
      --  Process_Entity's own doc comment/header-comment note), so
      --  it's delegated to Format_Common along with plain Terse mode;
      --  only a non-Fragment entity in Html_In_Rst/Groff_In_Rst mode
      --  needs this package's own table rendering.
      if E.Is_Fragment then
         Common.Process_Entity (E, Entity_No);
         return;
      end if;
      case Config.Format is
         when Config.Html_In_Rst =>
            Common.Print_Header_And_Prose (E, Entity_No);
            Print_Html_Tables (E);
            Common.Print_Tail (E);
         when Config.Groff_In_Rst =>
            Common.Print_Header_And_Prose (E, Entity_No);
            Print_Groff_Tables (E);
            Common.Print_Notes (E);
            Common.Print_Options_If_Shown (E);
         when others =>
            Common.Process_Entity (E, Entity_No);
      end case;
   end Process_Entity;

end Ova_Fmt.Format_Rst;
