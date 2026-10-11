with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Text_IO;
with Ova_Fmt.Config;

package body Ova_Fmt.Format_Common is

   package Config renames Ova_Fmt.Config;
   package IO renames Ada.Text_IO;
   use type Entities.Sub_Entity_Access;
   use type Config.Output_Format;

   -----------------------------------------------------------------
   --  Terse/Gemtext primitives.
   -----------------------------------------------------------------

   --  Terse and Html_In_Rst always want reST's own emphasis markup, and
   --  so does Hmm by default (Ova_Fmt.Format_Hmm reuses Bold/Italic/
   --  Section_Header directly, plus Format_Attack_Line/
   --  Format_Combat_Summary_Line below, whose own Bold/Italic calls
   --  aren't otherwise reachable from outside this package) -- but
   --  Gemtext's spec has no inline emphasis at all, so these only wrap
   --  for Gemtext when Config.Gemtext_Emphasis opts in (its own doc
   --  comment), and per the user, Hmm output can turn emphasis off
   --  entirely via Config.Hmm_Plain (-p/--hmm-plain, off by default --
   --  its own doc comment).
   function No_Emphasis return Boolean is
     ((Config.Format = Config.Gemtext and then not Config.Gemtext_Emphasis)
      or else (Config.Format = Config.Hmm and then Config.Hmm_Plain));

   function Bold (S : String) return String is
     (if No_Emphasis then S else "**" & S & "**");

   function Italic (S : String) return String is
     (if No_Emphasis then S else "*" & S & "*");

   --  A structural section label ("Notes", "Fluff", "Companion: X",
   --  ...) -- a real gemtext `##` heading in Gemtext output (headings
   --  are a distinct, always-available line type, not inline
   --  emphasis, so this doesn't gate on Gemtext_Emphasis the way
   --  Bold/Italic do), a bolded line otherwise.
   function Section_Header (S : String) return String is
     (if Config.Format = Config.Gemtext then "## " & S else Bold (S));

   --  The list-item prefix Terse's reST bullets and Gemtext's own list
   --  syntax each need -- "- " does nothing special in gemtext (its
   --  spec: "Using - instead of * like in Markdown will not do
   --  anything"), and gemtext lists don't nest, so this is also used
   --  for what Terse renders as an indented sub-bullet (Print_Attack).
   function Bullet return String is
     (if Config.Format = Config.Gemtext then "* " else "- ");

   -----------------------------------------------------------------
   --  Numbers/text.
   -----------------------------------------------------------------

   function Trim_Img (N : Integer) return String is
     (Ada.Strings.Fixed.Trim (Integer'Image (N), Ada.Strings.Left));

   function Minus_Glyph return String is
     (if Config.Unicode_Minus then "−" else "-");
   --  Same besm2_fmt.Text_Layout.Minus_Glyph design (and, per user
   --  request, the same default-on polarity besm2_fmt uses): Unicode
   --  MINUS SIGN (U+2212) by default for a negative number this
   --  program builds itself, ASCII hyphen-minus under
   --  -n/--no-unicode-minus. Content the program doesn't interpret
   --  (`detail` text, etc.) is untouched either way.

   function Number_Img (N : Integer) return String is
     (if N < 0 then Minus_Glyph & Trim_Img (abs N) else Trim_Img (N));

   function Signed_Img (N : Integer) return String is
     (if N >= 0 then "+" & Trim_Img (N) else Number_Img (N));

   function End_With_Period (S : String) return String is
     (if S'Length > 0 and then S (S'Last) = '.' then S else S & ".");
   --  Avoids a doubled "..": free-form author text (a `fluff:` value
   --  in particular -- "enemies: Malicron Corp.") can legitimately
   --  already end with a period.

   function All_One_Line (S : String) return String is
      Result : String := S;
   begin
      for C of Result loop
         if C = ASCII.LF then
            C := ' ';
         end if;
      end loop;
      return Result;
   end All_One_Line;

   -----------------------------------------------------------------
   --  The keys added for the character generator (PLAN.md §9 step
   --  9).
   -----------------------------------------------------------------

   --  Gemtext and h-m-m have no inline markup to escape from (h-m-m's
   --  `**` is only a convention, never parsed); every other format's
   --  prose is reST or Markdown, where a bare `*` after a number can
   --  open emphasis. Both read `\*` as a literal `*`.
   function Override_Mark (Overridden : Boolean; Raw : Boolean := False) return String is
     (if not Overridden then ""
      elsif Raw or else Config.Format = Config.Gemtext or else Config.Format = Config.Hmm
      then "*"
      else "\*");

   function Defense_Text (C : Entities.Combat_Stats; Raw : Boolean := False) return String is
      use type Entities.Override_Key;
      D      : constant String := To_String (C.Defense);
      Result : Unbounded_String;
      Key    : Entities.Override_Key := Entities.Defense;
      From   : Positive := D'First;
      Slash  : Natural;
   begin
      loop
         Slash := Ada.Strings.Fixed.Index (D (From .. D'Last), "/");
         if Slash = 0 or else Key = Entities.Defense_3 then
            return To_String (Result & D (From .. D'Last) & Override_Mark (C.Overrides (Key), Raw));
         end if;
         Result := Result & D (From .. Slash - 1) & Override_Mark (C.Overrides (Key), Raw) & "/";
         From := Slash + 1;
         Key := Entities.Override_Key'Succ (Key);
      end loop;
   end Defense_Text;

   function Half_TV_Text (Has, Half : Boolean) return String is
     (if Config.Show_Options and then Has and then Half then " (half TV)" else "");

   function Entity_Title (E : Entities.Entity) return String is
     (Name_Detail
        (E.Name,
         E.Has_Fluff and then E.Fluff.Has_Concept,
         (if E.Has_Fluff then E.Fluff.Concept else Null_Unbounded_String)) &
      (if E.Has_Player then ", played by " & To_String (E.Player) else ""));

   function Options_Text (O : Entities.Options_Block) return String is
      Line  : Unbounded_String;

      procedure Add (Item : String) is
      begin
         if Length (Line) > 0 then
            Line := Line & ", ";
         end if;
         Line := Line & Item;
      end Add;
   begin
      if O.Has_Base_Zero then
         Add ("Base Zero (±" & Trim_Img (O.Base_Zero) & ")");
      end if;
      if O.Has_Power_Ceiling then
         Add ("Power Ceiling (" & Trim_Img (O.Power_Ceiling) & ")");
      end if;
      if O.Has_Starting_Levels then
         Add ("Starting Levels (" & Trim_Img (O.Starting_Levels) & ")");
      end if;
      if O.Scaled_Cost then
         Add ("Scaled Cost");
      end if;
      if O.Half_Cost_Knowledge then
         Add ("Half-Cost Knowledge");
      end if;
      if O.Combined_Effectiveness then
         Add ("Combined Effectiveness");
      end if;
      return To_String (Line);
   end Options_Text;

   -----------------------------------------------------------------
   --  Perks/Flaws.
   -----------------------------------------------------------------

   function Format_Perk_Flaw (PF : Entities.Perk_Flaw) return String is
      Result : Unbounded_String := PF.Name;
   begin
      if PF.Has_Detail then
         Result := Result & ": " & PF.Detail;
      end if;
      if PF.Has_Counts_As then
         Result := Result & " x" & Trim_Img (PF.Counts_As);
      end if;
      if PF.Has_Cost then
         Result := Result & " (" & Number_Img (PF.Cost) & ")";
      end if;
      return To_String (Result);
   end Format_Perk_Flaw;

   function Format_Perk_Flaw_List
     (Vec : Entities.Perk_Flaw_Vectors.Vector) return String
   is
      Result : Unbounded_String;
   begin
      for I in Vec.First_Index .. Vec.Last_Index loop
         if I > Vec.First_Index then
            Result := Result & ", ";
         end if;
         Result := Result & Format_Perk_Flaw (Vec (I));
      end loop;
      return To_String (Result);
   end Format_Perk_Flaw_List;

   function Format_Modifiers_Bracket
     (Perks, Flaws         : Entities.Perk_Flaw_Vectors.Vector;
      Has_Endurance        : Boolean := False;
      Endurance            : Integer := 0;
      Endurance_Overridden : Boolean := False;
      Raw                  : Boolean := False) return String
   is
      Parts : Unbounded_String;

      procedure Add (Text : String) is
      begin
         if Length (Parts) > 0 then
            Parts := Parts & "; ";
         end if;
         Parts := Parts & Text;
      end Add;
   begin
      if not Perks.Is_Empty then
         Add ("Perks: " & Format_Perk_Flaw_List (Perks));
      end if;
      if not Flaws.Is_Empty then
         Add ("Flaws: " & Format_Perk_Flaw_List (Flaws));
      end if;
      if Has_Endurance then
         Add (Trim_Img (Endurance) & Override_Mark (Endurance_Overridden, Raw) & " Endurance");
      end if;
      if Length (Parts) = 0 then
         return "";
      end if;
      return " [" & To_String (Parts) & "]";
   end Format_Modifiers_Bracket;

   --  Affinity/Perks/Flaws clause for one attack -- "(Affinity: ...;
   --  Perks: ...; Flaws: ...)", each clause present only if
   --  applicable, "" if none apply at all. Affinity is its own
   --  labeled clause here (not folded into Perks the way the
   --  character-sheet layout does, PLAN.md §2.1) since this format
   --  already labels Perks/Flaws explicitly -- folding Affinity in
   --  under the "Perks:" label read as misleading rather than
   --  faithful once that label exists.
   function Format_Attack_Clause (A : Entities.Attack) return String is
      Parts : Unbounded_String;

      procedure Add (Label : String; Text : String) is
      begin
         if Length (Parts) > 0 then
            Parts := Parts & "; ";
         end if;
         Parts := Parts & Label & ": " & Text;
      end Add;
   begin
      if A.Has_Affinity then
         Add ("Affinity", To_String (A.Affinity));
      end if;
      if not A.Perks.Is_Empty then
         Add ("Perks", Format_Perk_Flaw_List (A.Perks));
      end if;
      if not A.Flaws.Is_Empty then
         Add ("Flaws", Format_Perk_Flaw_List (A.Flaws));
      end if;
      if Length (Parts) = 0 then
         return "";
      end if;
      return "(" & To_String (Parts) & ")";
   end Format_Attack_Clause;

   -----------------------------------------------------------------
   --  Ability / Weakness / Sub_Item lines: "Name (detail) Level
   --  [Perks: ...; Flaws: ...] (note)".
   -----------------------------------------------------------------

   function Name_Detail (Name : Unbounded_String; Has_Detail : Boolean;
                          Detail : Unbounded_String) return String is
     (To_String (Name) &
      (if Has_Detail then " (" & To_String (Detail) & ")" else ""));

   function Format_Ability_Line (A : Entities.Ability) return String is
      Result : Unbounded_String :=
        To_Unbounded_String
          (Name_Detail (A.Name, A.Has_Detail, A.Detail) & " " & Signed_Img (A.Level) &
           Half_TV_Text (A.Has_Threat_Value_Half, A.Threat_Value_Half));
   begin
      Result := Result & Format_Modifiers_Bracket
        (A.Perks, A.Flaws, A.Has_Endurance, A.Endurance, A.Overrides (Entities.Endurance));
      if A.Has_Note then
         Result := Result & " (" & A.Note & ")";
      end if;
      return To_String (Result);
   end Format_Ability_Line;

   function Format_Weakness_Line (W : Entities.Weakness) return String is
     (Name_Detail (W.Name, W.Has_Detail, W.Detail) & " " & Signed_Img (W.Level));

   --  NPC Fragment (rulebook p. 142) Ability/Weakness line order is
   --  "Name Level (detail)", confirmed against two of the rulebook's
   --  own examples ("Quirk -1 (Always Wears Sunglasses)", "Knowledge
   --  +2 (Kendo)") -- detail *after* the level, the opposite of
   --  Format_Ability_Line/Format_Weakness_Line's "Name (detail)
   --  Level" used everywhere else. No rulebook Fragment example has
   --  Perks/Flaws or a note, so there's nothing to confirm their
   --  placement against, but appending them after (matching the
   --  normal lines' own order) is the least surprising choice if a
   --  Fragment ever needs one.
   function Format_Fragment_Ability_Line (A : Entities.Ability) return String is
      Result : Unbounded_String :=
        To_Unbounded_String
          (To_String (A.Name) & " " & Signed_Img (A.Level) &
           Half_TV_Text (A.Has_Threat_Value_Half, A.Threat_Value_Half));
   begin
      if A.Has_Detail then
         Result := Result & " (" & A.Detail & ")";
      end if;
      Result := Result & Format_Modifiers_Bracket
        (A.Perks, A.Flaws, A.Has_Endurance, A.Endurance, A.Overrides (Entities.Endurance));
      if A.Has_Note then
         Result := Result & " (" & A.Note & ")";
      end if;
      return To_String (Result);
   end Format_Fragment_Ability_Line;

   function Format_Fragment_Weakness_Line (W : Entities.Weakness) return String is
     (To_String (W.Name) & " " & Signed_Img (W.Level) &
      (if W.Has_Detail then " (" & To_String (W.Detail) & ")" else ""));

   function Format_Sub_Item_Line (S : Entities.Sub_Item) return String is
      Result : Unbounded_String :=
        To_Unbounded_String
          (Name_Detail (S.Name, S.Has_Detail, S.Detail) & " " & Signed_Img (S.Level) &
           Half_TV_Text (S.Has_Threat_Value_Half, S.Threat_Value_Half));
   begin
      Result := Result & Format_Modifiers_Bracket
        (S.Perks, S.Flaws, S.Has_Endurance, S.Endurance, S.Overrides (Entities.Endurance));
      if S.Has_Note then
         Result := Result & " (" & S.Note & ")";
      end if;
      return To_String (Result);
   end Format_Sub_Item_Line;

   --  Same "Name Level (detail)" reordering as Format_Fragment_Ability_
   --  Line, for a fragment-style Companion/Vehicle's own Abilities/
   --  Weaknesses (both stored as Sub_Item -- Entities.Sub_Entity_Record's
   --  own doc comment).
   function Format_Fragment_Sub_Item_Line (S : Entities.Sub_Item) return String is
      Result : Unbounded_String :=
        To_Unbounded_String
          (To_String (S.Name) & " " & Signed_Img (S.Level) &
           Half_TV_Text (S.Has_Threat_Value_Half, S.Threat_Value_Half));
   begin
      if S.Has_Detail then
         Result := Result & " (" & S.Detail & ")";
      end if;
      Result := Result & Format_Modifiers_Bracket
        (S.Perks, S.Flaws, S.Has_Endurance, S.Endurance, S.Overrides (Entities.Endurance));
      if S.Has_Note then
         Result := Result & " (" & S.Note & ")";
      end if;
      return To_String (Result);
   end Format_Fragment_Sub_Item_Line;

   function Format_Spell_Line (S : Entities.Spell) return String is
     (To_String (S.Name) & " (" & To_String (S.Ability) & " " &
      Signed_Img (S.Level) & "; " & To_String (S.Endurance) &
      Override_Mark (S.Overrides (Entities.Endurance)) & " Endurance)");

   function Join_Abilities (Vec : Entities.Ability_Vectors.Vector) return String is
      Result : Unbounded_String;
   begin
      for I in Vec.First_Index .. Vec.Last_Index loop
         if I > Vec.First_Index then
            Result := Result & ", ";
         end if;
         Result := Result & Format_Ability_Line (Vec (I));
      end loop;
      return To_String (Result);
   end Join_Abilities;

   function Join_Weaknesses (Vec : Entities.Weakness_Vectors.Vector) return String is
      Result : Unbounded_String;
   begin
      for I in Vec.First_Index .. Vec.Last_Index loop
         if I > Vec.First_Index then
            Result := Result & ", ";
         end if;
         Result := Result & Format_Weakness_Line (Vec (I));
      end loop;
      return To_String (Result);
   end Join_Weaknesses;

   function Join_Fragment_Abilities (Vec : Entities.Ability_Vectors.Vector) return String is
      Result : Unbounded_String;
   begin
      for I in Vec.First_Index .. Vec.Last_Index loop
         if I > Vec.First_Index then
            Result := Result & ", ";
         end if;
         Result := Result & Format_Fragment_Ability_Line (Vec (I));
      end loop;
      return To_String (Result);
   end Join_Fragment_Abilities;

   function Join_Fragment_Weaknesses (Vec : Entities.Weakness_Vectors.Vector) return String is
      Result : Unbounded_String;
   begin
      for I in Vec.First_Index .. Vec.Last_Index loop
         if I > Vec.First_Index then
            Result := Result & ", ";
         end if;
         Result := Result & Format_Fragment_Weakness_Line (Vec (I));
      end loop;
      return To_String (Result);
   end Join_Fragment_Weaknesses;

   function Join_Sub_Items (Vec : Entities.Sub_Item_Vectors.Vector) return String is
      Result : Unbounded_String;
   begin
      for I in Vec.First_Index .. Vec.Last_Index loop
         if I > Vec.First_Index then
            Result := Result & ", ";
         end if;
         Result := Result & Format_Sub_Item_Line (Vec (I));
      end loop;
      return To_String (Result);
   end Join_Sub_Items;

   function Join_Fragment_Sub_Items (Vec : Entities.Sub_Item_Vectors.Vector) return String is
      Result : Unbounded_String;
   begin
      for I in Vec.First_Index .. Vec.Last_Index loop
         if I > Vec.First_Index then
            Result := Result & ", ";
         end if;
         Result := Result & Format_Fragment_Sub_Item_Line (Vec (I));
      end loop;
      return To_String (Result);
   end Join_Fragment_Sub_Items;

   function Join_Spells (Vec : Entities.Spell_Vectors.Vector) return String is
      Result : Unbounded_String;
   begin
      for I in Vec.First_Index .. Vec.Last_Index loop
         if I > Vec.First_Index then
            Result := Result & ", ";
         end if;
         Result := Result & Format_Spell_Line (Vec (I));
      end loop;
      return To_String (Result);
   end Join_Spells;

   -----------------------------------------------------------------
   --  Combat: Health/Endurance/Defense/TV line, then an Attacks
   --  bullet with one nested bullet per attack. Shared between the
   --  main entity and a Companion/Vehicle sub-entity that has its own
   --  combat: block (Karis's Arasuni, Yuu's Fenrir).
   -----------------------------------------------------------------

   function Format_Attack_Line (A : Entities.Attack) return String is
      Clause : constant String := Format_Attack_Clause (A);
      Line   : Unbounded_String :=
        To_Unbounded_String
          (Bold (To_String (A.Name) & ":") & " Roll " &
           Bold (Number_Img (A.Roll) & Override_Mark (A.Overrides (Entities.Roll)) & " dice") &
           " | " &
           Bold ("DX " & To_String (A.Dx) & Override_Mark (A.Overrides (Entities.Dx))) & " | " &
           Bold
             ("Endurance Cost: " & Trim_Img (A.Endurance) &
              Override_Mark (A.Overrides (Entities.Endurance))));
   begin
      if Clause /= "" then
         Line := Line & " " & Clause;
      end if;
      Line := Line & ".";
      if A.Has_Description then
         Line := Line & " " & Italic (To_String (A.Description));
      end if;
      return To_String (Line);
   end Format_Attack_Line;

   function Format_Combat_Summary_Line
     (C : Entities.Combat_Stats; NPC_Type : String := "") return String is
     ((if NPC_Type = "" then "" else Bold ("NPC Type:") & " " & NPC_Type & " | ") &
      Bold ("Health:") & " " & Trim_Img (C.Health) &
      Override_Mark (C.Overrides (Entities.Health)) & " | " &
      Bold ("Endurance:") & " " & Trim_Img (C.Endurance) &
      Override_Mark (C.Overrides (Entities.Endurance)) & " | " &
      Bold ("Defense:") & " " & Defense_Text (C) & " | " &
      Bold ("Threat Value (TV):") & " " &
      (if C.Has_Threat_Value
       then Trim_Img (C.Threat_Value) & Override_Mark (C.Overrides (Entities.Threat_Value))
       else "—"));

   procedure Print_Attack (A : Entities.Attack) is
      --  Terse indents this as a sub-bullet of the "- **Attacks:**"
      --  line above it; gemtext has no nested lists at all, so this
      --  is just Bullet's own top-level "* ", no indentation implied.
      Attack_Prefix : constant String :=
        (if Config.Format = Config.Gemtext then Bullet else "  - ");
   begin
      IO.Put_Line (Attack_Prefix & Format_Attack_Line (A));
   end Print_Attack;

   function NPC_Type_Text (E : Entities.Entity) return String is
     (if E.Has_NPC_Type then Entities.NPC_Kind_Name (E.NPC_Type) else "");

   procedure Print_Combat_And_Attacks
     (C : Entities.Combat_Stats; NPC_Type : String := "") is
   begin
      if not C.Has_Combat then
         return;
      end if;
      IO.Put_Line (Bullet & Format_Combat_Summary_Line (C, NPC_Type));
      IO.New_Line;

      if not C.Attacks.Is_Empty then
         IO.Put_Line (Bullet & Bold ("Attacks:"));
         IO.New_Line;
         for A of C.Attacks loop
            Print_Attack (A);
         end loop;
         IO.New_Line;
      end if;

      --  A paragraph, not a bullet: the text may run to several
      --  lines, which a reST bullet would need indented.
      if C.Has_Notes then
         IO.Put_Line (Bold ("Combat Notes:") & " " & To_String (C.Notes));
         IO.New_Line;
      end if;
   end Print_Combat_And_Attacks;

   -----------------------------------------------------------------
   --  Linked-content expansion: one section per top-level Ability
   --  that has Transformation-style nested Abilities/Weaknesses,
   --  Magic-style Spells, or a Companion/Vehicle sub-entity -- printed
   --  after the main entity's own Attacks, in Abilities list order.
   -----------------------------------------------------------------

   --  Unlike a top-level Entity.Is_Fragment (which always gets *some*
   --  identifying text -- its Background prose, or a bare bolded Name
   --  when there's no Background, Print_Fragment_Header's own doc
   --  comment), a Sub_Entity has no Background of its own to fall back
   --  on -- so this always leads with the Name itself, "**Name** --",
   --  the same "**Header** -- text" shape Print_Tail's own Notes
   --  already use elsewhere in the same document. Found missing
   --  entirely in an earlier version: without it, the flat Attributes
   --  line had nothing at all connecting it to which Companion/Vehicle
   --  it belonged to (the granting Ability's own line names it via
   --  `detail:`, but that's easy to lose track of by the time this
   --  line appears, especially once combat/Attacks separates the two).
   procedure Print_Sub_Entity_Fragment_Style (SE : Entities.Sub_Entity_Access) is
      Name : constant String := To_String (SE.Name);
   begin
      if SE.Abilities.Is_Empty and then SE.Weaknesses.Is_Empty then
         IO.Put_Line (Bold (Name) & ".");
         IO.New_Line;
      else
         declare
            Line : Unbounded_String :=
              To_Unbounded_String (Bold (Name) & " -- " & Bold ("Attributes:") & " ") &
              Join_Fragment_Sub_Items (SE.Abilities);
         begin
            if not SE.Abilities.Is_Empty and then not SE.Weaknesses.Is_Empty then
               Line := Line & "; ";
            end if;
            Line := Line & Join_Fragment_Sub_Items (SE.Weaknesses);
            IO.Put_Line (To_String (Line) & ".");
            IO.New_Line;
         end;
      end if;
      Print_Combat_And_Attacks (SE.Combat);
   end Print_Sub_Entity_Fragment_Style;

   procedure Print_Linked_Section (A : Entities.Ability) is
      Has_Transformation : constant Boolean :=
        not A.Sub_Abilities.Is_Empty or else not A.Sub_Weaknesses.Is_Empty;
      Has_Spells         : constant Boolean := not A.Spells.Is_Empty;
      Has_Sub_Entity      : constant Boolean := A.Sub_Entity /= null;
   begin
      if not (Has_Transformation or else Has_Spells or else Has_Sub_Entity) then
         return;
      end if;

      --  Fragment-style Companion/Vehicle: no separate section header
      --  (the granting Ability's own line already names it via
      --  `detail:`, same reasoning a top-level Fragment's own bare-
      --  name fallback exists for), just the compact Attributes/Combat
      --  shape -- see Print_Sub_Entity_Fragment_Style's own doc
      --  comment.
      if Has_Sub_Entity and then A.Sub_Entity.Is_Fragment then
         Print_Sub_Entity_Fragment_Style (A.Sub_Entity);
         return;
      end if;

      if Has_Sub_Entity then
         IO.Put_Line
           (Section_Header
              (To_String (A.Sub_Entity.Label) & ": " &
               Name_Detail (A.Sub_Entity.Name, False, Null_Unbounded_String)));
      else
         IO.Put_Line (Section_Header (Name_Detail (A.Name, A.Has_Detail, A.Detail)));
      end if;
      IO.New_Line;

      if Has_Transformation then
         declare
            Line : Unbounded_String := To_Unbounded_String ("Grants: ");
         begin
            Line := Line & Join_Sub_Items (A.Sub_Abilities);
            if not A.Sub_Abilities.Is_Empty and then not A.Sub_Weaknesses.Is_Empty then
               Line := Line & "; ";
            end if;
            Line := Line & Join_Sub_Items (A.Sub_Weaknesses);
            IO.Put_Line (End_With_Period (To_String (Line)));
            IO.New_Line;
         end;
      end if;

      if Has_Spells then
         IO.Put_Line (End_With_Period ("Spells: " & Join_Spells (A.Spells)));
         IO.New_Line;
      end if;

      if Has_Sub_Entity then
         if not A.Sub_Entity.Abilities.Is_Empty then
            IO.Put_Line
              (End_With_Period ("Abilities: " & Join_Sub_Items (A.Sub_Entity.Abilities)));
            IO.New_Line;
         end if;
         if not A.Sub_Entity.Weaknesses.Is_Empty then
            IO.Put_Line
              (End_With_Period ("Weaknesses: " & Join_Sub_Items (A.Sub_Entity.Weaknesses)));
            IO.New_Line;
         end if;
         Print_Combat_And_Attacks (A.Sub_Entity.Combat);
      end if;
   end Print_Linked_Section;

   -----------------------------------------------------------------
   --  Header/prose, Fragment header, tail.
   -----------------------------------------------------------------

   --  NPC Fragment (rulebook p. 142): the name has no separate title/
   --  header of its own -- it's expected to appear (bolded by the
   --  author, per rulebook convention) inside Background's own prose,
   --  same as the rulebook's "The **Shady Teacher** is new to the
   --  school..." -- so this only falls back to printing a bare bolded
   --  Name when there's no Background prose to carry it, rather than
   --  leaving the character unidentified.
   procedure Print_Fragment_Header (E : Entities.Entity) is
   begin
      if E.Has_Background then
         IO.Put_Line (To_String (E.Background));
      else
         IO.Put_Line (Bold (To_String (E.Name)));
      end if;
      IO.New_Line;
   end Print_Fragment_Header;

   --  Abilities then Weaknesses, each already alphabetized (per the
   --  sort audit), comma-joined within a list and semicolon-separated
   --  between the two lists -- the rulebook's own compact NPC
   --  Fragment shape, e.g. "Attributes: Art of Invisibility +2,
   --  Perceptive +2, Smart +3; Absent-Minded -1, Quirk -1 (...)".
   function Fragment_Attributes_Label (E : Entities.Entity) return String is
     (Bold (if E.Has_NPC_Type
            then "Attributes (" & Entities.NPC_Kind_Name (E.NPC_Type) & "):"
            else "Attributes:"));

   procedure Print_Fragment_Attributes (E : Entities.Entity) is
      Line : Unbounded_String;
   begin
      if E.Abilities.Is_Empty and then E.Weaknesses.Is_Empty then
         return;
      end if;
      Line := To_Unbounded_String (Fragment_Attributes_Label (E) & " ") &
        Join_Fragment_Abilities (E.Abilities);
      if not E.Abilities.Is_Empty and then not E.Weaknesses.Is_Empty then
         Line := Line & "; ";
      end if;
      Line := Line & Join_Fragment_Weaknesses (E.Weaknesses);
      IO.Put_Line (To_String (Line) & ".");
      IO.New_Line;
   end Print_Fragment_Attributes;

   --  After the other prose, as the Sample NPCs' pages have it (and
   --  after a Fragment's Attributes line, it having no other prose
   --  section), per the user.
   procedure Print_Character_Hooks (E : Entities.Entity) is
   begin
      if E.Has_Character_Hooks then
         IO.Put_Line (Section_Header ("Character Hooks"));
         IO.New_Line;
         IO.Put_Line (To_String (E.Character_Hooks));
         IO.New_Line;
      end if;
   end Print_Character_Hooks;

   --  Header/tagline/summary/background/personality -- byte-identical
   --  across Terse, Gemtext, and Html_In_Rst (only Html_In_Rst's
   --  Abilities/Weaknesses/Combat/Attacks/linked-content differ from
   --  Terse/Gemtext's; the prose scaffolding around them doesn't).
   procedure Print_Header_And_Prose (E : Entities.Entity; Entity_No : Positive) is
   begin
      declare
         Title : constant String := Entity_Title (E);
      begin
         if Config.Format = Config.Gemtext or else Config.Format = Config.Markdown then
            --  Gemtext's only heading syntax, and (per the user)
            --  Markdown's own choice too, for the same reason:
            --  -U/--subunderliner's "distinguish entities after the
            --  first" concept has no equivalent here (no underline
            --  character to swap, only a `#`-count depth) and doesn't
            --  apply -- always a flat `# Title` regardless of
            --  Entity_No.
            IO.Put_Line ("# " & Title);
         else
            declare
               Underline_Char : constant Character :=
                 (if Entity_No > 1 and then Config.Subunderliner /= ASCII.NUL
                  then Config.Subunderliner
                  else Config.Underliner);
            begin
               IO.Put_Line (Title);
               IO.Put_Line (String'(1 .. Title'Length => Underline_Char));
            end;
         end if;
         IO.New_Line;
      end;

      --  Only Html_In_Rst shows the portrait (PLAN.md §9 step 9): the
      --  path is the YAML file's, relative to it, so the HTML has to
      --  be made beside the YAML file for the image to be found.
      if Config.Format = Config.Html_In_Rst and then E.Has_Portrait then
         IO.Put_Line (".. image:: " & To_String (E.Portrait));
         IO.Put_Line ("   :alt: " & To_String (E.Name));
         IO.New_Line;
      end if;

      if E.Has_Tagline then
         IO.Put_Line (Italic ("""" & To_String (E.Tagline) & """"));
         IO.New_Line;
      end if;

      if E.Has_Summary then
         IO.Put_Line (Italic (To_String (E.Summary)));
         IO.New_Line;
      end if;

      if E.Has_Background then
         IO.Put_Line (Section_Header ("Background"));
         IO.New_Line;
         IO.Put_Line (To_String (E.Background));
         IO.New_Line;
      end if;

      if E.Has_Appearance then
         IO.Put_Line (Section_Header ("Appearance"));
         IO.New_Line;
         IO.Put_Line (To_String (E.Appearance));
         IO.New_Line;
      end if;

      if E.Has_Personality then
         IO.Put_Line (Section_Header ("Personality"));
         IO.New_Line;
         IO.Put_Line (To_String (E.Personality));
         IO.New_Line;
      end if;

      Print_Character_Hooks (E);
   end Print_Header_And_Prose;

   --  Notes/Fluff/Creation-Rules -- byte-identical across every
   --  format and every entity kind (Fragment included, PLAN.md/
   --  Ova_Fmt.Format_Common.ads's doc comment).
   procedure Print_Notes (E : Entities.Entity) is
   begin
      if not E.Notes.Is_Empty then
         IO.Put_Line (Section_Header ("Notes"));
         IO.New_Line;
         for N of E.Notes loop
            IO.Put_Line (Bold (To_String (N.Header)) & " -- " & To_String (N.Text));
            IO.New_Line;
         end loop;
      end if;

      if E.Has_Other_Notes then
         IO.Put_Line (Section_Header ("Other Notes"));
         IO.New_Line;
         IO.Put_Line (To_String (E.Other_Notes));
         IO.New_Line;
      end if;
   end Print_Notes;

   procedure Print_Options_If_Shown (E : Entities.Entity) is
   begin
      --  GM/author metadata (which character-creation limiting rules
      --  were used, rulebook p. 20-21), not part of the character's
      --  own write-up -- rendered only when asked for, per the user.
      if Config.Show_Options and then E.Has_Options then
         declare
            Line : constant String := Options_Text (E.Options);
         begin
            if Line /= "" then
               IO.Put_Line (Bold ("Creation Rules:") & " " & End_With_Period (Line));
               IO.New_Line;
            end if;
         end;
      end if;
   end Print_Options_If_Shown;

   procedure Print_Tail (E : Entities.Entity) is
   begin
      Print_Notes (E);

      if E.Has_Fluff then
         declare
            Line  : Unbounded_String;
            First : Boolean := True;

            --  Label is the capitalized field name ("Concept",
            --  "Favorite Food", ...) -- bolded here per-item, same as
            --  a Notes entry's header, rather than only bolding the
            --  "Fluff" section title and leaving each item's label
            --  plain.
            procedure Add (Label : String; Has : Boolean; Value : Unbounded_String) is
            begin
               if Has then
                  if not First then
                     Line := Line & ", ";
                  end if;
                  First := False;
                  Line := Line & Bold (Label & ":") & " " & Value;
               end if;
            end Add;
         begin
            IO.Put_Line (Section_Header ("Fluff"));
            IO.New_Line;
            Add ("Concept", E.Fluff.Has_Concept, E.Fluff.Concept);
            Add ("Birthday", E.Fluff.Has_Birthday, E.Fluff.Birthday);
            Add ("Age", E.Fluff.Has_Age, E.Fluff.Age);
            Add ("Gender", E.Fluff.Has_Gender, E.Fluff.Gender);
            Add ("Height", E.Fluff.Has_Height, E.Fluff.Height);
            Add ("Weight", E.Fluff.Has_Weight, E.Fluff.Weight);
            Add ("Hair", E.Fluff.Has_Hair, E.Fluff.Hair);
            Add ("Eyes", E.Fluff.Has_Eyes, E.Fluff.Eyes);
            Add ("Association", E.Fluff.Has_Association, E.Fluff.Association);
            Add ("Hobbies", E.Fluff.Has_Hobbies, E.Fluff.Hobbies);
            Add ("Favorite Food", E.Fluff.Has_Favorite_Food, E.Fluff.Favorite_Food);
            Add ("Allies", E.Fluff.Has_Allies, E.Fluff.Allies);
            Add ("Enemies", E.Fluff.Has_Enemies, E.Fluff.Enemies);
            Add ("Love Interests", E.Fluff.Has_Love_Interests, E.Fluff.Love_Interests);
            IO.Put_Line (End_With_Period (To_String (Line)));
            IO.New_Line;
         end;
      end if;

      Print_Options_If_Shown (E);
   end Print_Tail;

   procedure Process_Entity (E : Entities.Entity; Entity_No : Positive) is
   begin
      if E.Is_Fragment then
         --  Deliberately untouched by Config.Format, per the user: a
         --  Fragment's whole point is being flat/minimal, so it
         --  renders the same regardless of backend -- no raw HTML
         --  block, no tables.
         Print_Fragment_Header (E);
         Print_Fragment_Attributes (E);
         Print_Character_Hooks (E);
         Print_Combat_And_Attacks (E.Combat);
         for A of E.Abilities loop
            Print_Linked_Section (A);
         end loop;
      else
         Print_Header_And_Prose (E, Entity_No);

         if not E.Abilities.Is_Empty then
            IO.Put_Line
              (Bullet & Bold ("Abilities:") & " " & Join_Abilities (E.Abilities) & ".");
            IO.New_Line;
         end if;

         if not E.Weaknesses.Is_Empty then
            IO.Put_Line
              (Bullet & Bold ("Weaknesses:") & " " & Join_Weaknesses (E.Weaknesses) & ".");
            IO.New_Line;
         end if;

         Print_Combat_And_Attacks (E.Combat, NPC_Type_Text (E));

         for A of E.Abilities loop
            Print_Linked_Section (A);
         end loop;
      end if;

      Print_Tail (E);
   end Process_Entity;

end Ova_Fmt.Format_Common;
