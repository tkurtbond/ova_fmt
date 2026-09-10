with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Text_IO;
with Ova_Fmt.Config;

package body Ova_Fmt.Format_Terse is

   package Config renames Ova_Fmt.Config;
   package IO renames Ada.Text_IO;
   use type Entities.Sub_Entity_Access;
   use type Config.Output_Format;

   --  Terse (reST) always wants its own emphasis markup; Gemtext's
   --  spec has none at all, so these only wrap when
   --  Config.Gemtext_Emphasis opts in (Config.Gemtext_Emphasis's own
   --  doc comment).
   function Bold (S : String) return String is
     (if Config.Format = Config.Gemtext and then not Config.Gemtext_Emphasis
      then S
      else "**" & S & "**");

   function Italic (S : String) return String is
     (if Config.Format = Config.Gemtext and then not Config.Gemtext_Emphasis
      then S
      else "*" & S & "*");

   --  A structural section label ("Notes", "Fluff", "Companion: X",
   --  ...) -- a real gemtext `##` heading in Gemtext output (headings
   --  are a distinct, always-available line type, not inline
   --  emphasis, so this doesn't gate on Gemtext_Emphasis the way
   --  Bold/Italic do), a bolded line in Terse as before.
   function Section_Header (S : String) return String is
     (if Config.Format = Config.Gemtext then "## " & S else Bold (S));

   --  The list-item prefix Terse's reST bullets and Gemtext's own list
   --  syntax each need -- "- " does nothing special in gemtext (its
   --  spec: "Using - instead of * like in Markdown will not do
   --  anything"), and gemtext lists don't nest, so this is also used
   --  for what Terse renders as an indented sub-bullet (Print_Attack).
   function Bullet return String is
     (if Config.Format = Config.Gemtext then "* " else "- ");

   function Trim_Img (N : Integer) return String is
     (Ada.Strings.Fixed.Trim (Integer'Image (N), Ada.Strings.Left));
   --  Plain non-negative magnitude: "3", "0". Only for values that
   --  can never actually be negative (Health/Endurance/Threat Value,
   --  a Perk/Flaw's `counts-as` repeat count) -- use Number_Img
   --  below for anything that can.

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
   --  A magnitude that might legitimately be negative (an attack's
   --  `roll`, a Perk/Flaw's chosen `cost`) -- unlike Trim_Img, this
   --  goes through Minus_Glyph instead of relying on Integer'Image's
   --  own always-ASCII "-".

   function Signed_Img (N : Integer) return String is
     (if N >= 0 then "+" & Trim_Img (N) else Number_Img (N));
   --  Ability/Weakness Levels always show an explicit sign, matching
   --  every source (rulebook sheet and the Karis mockup alike).

   function End_With_Period (S : String) return String is
     (if S'Length > 0 and then S (S'Last) = '.' then S else S & ".");
   --  Avoids a doubled "..": free-form author text (a `fluff:` value
   --  in particular -- "enemies: Malicron Corp.") can legitimately
   --  already end with a period.

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

   --  Perks/Flaws suffix for an Ability/Sub_Item that carries its own
   --  (e.g. Ai's top-level Barrier, Fukiko's Transformation-nested
   --  Barrier) -- "[Perks: ...; Flaws: ...]", empty string if neither
   --  is present.
   function Format_Modifiers_Bracket
     (Perks, Flaws : Entities.Perk_Flaw_Vectors.Vector) return String
   is
      Parts : Unbounded_String;
   begin
      if not Perks.Is_Empty then
         Parts := Parts & "Perks: " & Format_Perk_Flaw_List (Perks);
      end if;
      if not Flaws.Is_Empty then
         if Length (Parts) > 0 then
            Parts := Parts & "; ";
         end if;
         Parts := Parts & "Flaws: " & Format_Perk_Flaw_List (Flaws);
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
          (Name_Detail (A.Name, A.Has_Detail, A.Detail) & " " & Signed_Img (A.Level));
   begin
      Result := Result & Format_Modifiers_Bracket (A.Perks, A.Flaws);
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
        To_Unbounded_String (To_String (A.Name) & " " & Signed_Img (A.Level));
   begin
      if A.Has_Detail then
         Result := Result & " (" & A.Detail & ")";
      end if;
      Result := Result & Format_Modifiers_Bracket (A.Perks, A.Flaws);
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
          (Name_Detail (S.Name, S.Has_Detail, S.Detail) & " " & Signed_Img (S.Level));
   begin
      Result := Result & Format_Modifiers_Bracket (S.Perks, S.Flaws);
      if S.Has_Note then
         Result := Result & " (" & S.Note & ")";
      end if;
      return To_String (Result);
   end Format_Sub_Item_Line;

   function Format_Spell_Line (S : Entities.Spell) return String is
     (To_String (S.Name) & " (" & To_String (S.Ability) & " " &
      Signed_Img (S.Level) & "; " & To_String (S.Endurance) & " Endurance)");

   -----------------------------------------------------------------
   --  Combat: Health/Endurance/Defense/TV line, then an Attacks
   --  bullet with one nested bullet per attack. Shared between the
   --  main entity and a Companion/Vehicle sub-entity that has its own
   --  combat: block (Karis's Arasuni, Yuu's Fenrir).
   -----------------------------------------------------------------

   procedure Print_Attack (A : Entities.Attack) is
      Clause : constant String := Format_Attack_Clause (A);
      --  Terse indents this as a sub-bullet of the "- **Attacks:**"
      --  line above it; gemtext has no nested lists at all, so this
      --  is just Bullet's own top-level "* ", no indentation implied.
      Attack_Prefix : constant String :=
        (if Config.Format = Config.Gemtext then Bullet else "  - ");
      Line   : Unbounded_String :=
        To_Unbounded_String
          (Attack_Prefix & Bold (To_String (A.Name) & ":") & " Roll " &
           Bold (Number_Img (A.Roll) & " dice") & " | " &
           Bold ("DX " & To_String (A.Dx)) & " | " &
           Bold ("Endurance Cost: " & Trim_Img (A.Endurance)));
   begin
      if Clause /= "" then
         Line := Line & " " & Clause;
      end if;
      Line := Line & ".";
      if A.Has_Description then
         Line := Line & " " & Italic (To_String (A.Description));
      end if;
      IO.Put_Line (To_String (Line));
   end Print_Attack;

   procedure Print_Combat_And_Attacks (C : Entities.Combat_Stats) is
   begin
      if not C.Has_Combat then
         return;
      end if;
      IO.Put_Line
        (Bullet & Bold ("Health:") & " " & Trim_Img (C.Health) & " | " &
         Bold ("Endurance:") & " " & Trim_Img (C.Endurance) & " | " &
         Bold ("Defense:") & " " & To_String (C.Defense) & " | " &
         Bold ("Threat Value (TV):") & " " &
         (if C.Has_Threat_Value then Trim_Img (C.Threat_Value) else "—"));
      IO.New_Line;

      if not C.Attacks.Is_Empty then
         IO.Put_Line (Bullet & Bold ("Attacks:"));
         IO.New_Line;
         for A of C.Attacks loop
            Print_Attack (A);
         end loop;
         IO.New_Line;
      end if;
   end Print_Combat_And_Attacks;

   -----------------------------------------------------------------
   --  Linked-content expansion: one section per top-level Ability
   --  that has Transformation-style nested Abilities/Weaknesses,
   --  Magic-style Spells, or a Companion/Vehicle sub-entity -- printed
   --  after the main entity's own Attacks, in Abilities list order.
   --  First-pass design (PLAN.md/this package's header comment), not
   --  yet user-reviewed.
   -----------------------------------------------------------------

   procedure Print_Linked_Section (A : Entities.Ability) is
      Has_Transformation : constant Boolean :=
        not A.Sub_Abilities.Is_Empty or else not A.Sub_Weaknesses.Is_Empty;
      Has_Spells         : constant Boolean := not A.Spells.Is_Empty;
      Has_Sub_Entity      : constant Boolean := A.Sub_Entity /= null;
   begin
      if not (Has_Transformation or else Has_Spells or else Has_Sub_Entity) then
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
            for I in A.Sub_Abilities.First_Index .. A.Sub_Abilities.Last_Index loop
               if I > A.Sub_Abilities.First_Index then
                  Line := Line & ", ";
               end if;
               Line := Line & Format_Sub_Item_Line (A.Sub_Abilities (I));
            end loop;
            if not A.Sub_Weaknesses.Is_Empty then
               if not A.Sub_Abilities.Is_Empty then
                  Line := Line & "; ";
               end if;
               for I in A.Sub_Weaknesses.First_Index .. A.Sub_Weaknesses.Last_Index loop
                  if I > A.Sub_Weaknesses.First_Index then
                     Line := Line & ", ";
                  end if;
                  Line := Line & Format_Sub_Item_Line (A.Sub_Weaknesses (I));
               end loop;
            end if;
            IO.Put_Line (End_With_Period (To_String (Line)));
            IO.New_Line;
         end;
      end if;

      if Has_Spells then
         declare
            Line : Unbounded_String := To_Unbounded_String ("Spells: ");
         begin
            for I in A.Spells.First_Index .. A.Spells.Last_Index loop
               if I > A.Spells.First_Index then
                  Line := Line & ", ";
               end if;
               Line := Line & Format_Spell_Line (A.Spells (I));
            end loop;
            IO.Put_Line (End_With_Period (To_String (Line)));
            IO.New_Line;
         end;
      end if;

      if Has_Sub_Entity then
         if not A.Sub_Entity.Abilities.Is_Empty then
            declare
               Line : Unbounded_String := To_Unbounded_String ("Abilities: ");
            begin
               for I in A.Sub_Entity.Abilities.First_Index .. A.Sub_Entity.Abilities.Last_Index loop
                  if I > A.Sub_Entity.Abilities.First_Index then
                     Line := Line & ", ";
                  end if;
                  Line := Line & Format_Sub_Item_Line (A.Sub_Entity.Abilities (I));
               end loop;
               IO.Put_Line (End_With_Period (To_String (Line)));
               IO.New_Line;
            end;
         end if;
         if not A.Sub_Entity.Weaknesses.Is_Empty then
            declare
               Line : Unbounded_String := To_Unbounded_String ("Weaknesses: ");
            begin
               for I in A.Sub_Entity.Weaknesses.First_Index .. A.Sub_Entity.Weaknesses.Last_Index loop
                  if I > A.Sub_Entity.Weaknesses.First_Index then
                     Line := Line & ", ";
                  end if;
                  Line := Line & Format_Sub_Item_Line (A.Sub_Entity.Weaknesses (I));
               end loop;
               IO.Put_Line (End_With_Period (To_String (Line)));
               IO.New_Line;
            end;
         end if;
         Print_Combat_And_Attacks (A.Sub_Entity.Combat);
      end if;
   end Print_Linked_Section;

   -----------------------------------------------------------------
   --  Process_Entity.
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
   procedure Print_Fragment_Attributes (E : Entities.Entity) is
   begin
      if E.Abilities.Is_Empty and then E.Weaknesses.Is_Empty then
         return;
      end if;
      IO.Put (Bold ("Attributes:") & " ");
      for I in E.Abilities.First_Index .. E.Abilities.Last_Index loop
         if I > E.Abilities.First_Index then
            IO.Put (", ");
         end if;
         IO.Put (Format_Fragment_Ability_Line (E.Abilities (I)));
      end loop;
      if not E.Abilities.Is_Empty and then not E.Weaknesses.Is_Empty then
         IO.Put ("; ");
      end if;
      for I in E.Weaknesses.First_Index .. E.Weaknesses.Last_Index loop
         if I > E.Weaknesses.First_Index then
            IO.Put (", ");
         end if;
         IO.Put (Format_Fragment_Weakness_Line (E.Weaknesses (I)));
      end loop;
      IO.Put_Line (".");
      IO.New_Line;
   end Print_Fragment_Attributes;

   procedure Process_Entity (E : Entities.Entity; Entity_No : Positive) is
   begin
      if E.Is_Fragment then
         Print_Fragment_Header (E);
         Print_Fragment_Attributes (E);
      else
         declare
            Title : constant String :=
              Name_Detail
                (E.Name,
                 E.Has_Fluff and then E.Fluff.Has_Concept,
                 (if E.Has_Fluff then E.Fluff.Concept else Null_Unbounded_String));
         begin
            if Config.Format = Config.Gemtext then
               --  Gemtext's only heading syntax; -U/--subunderliner's
               --  "distinguish entities after the first" concept has
               --  no equivalent here (no underline character to swap)
               --  and doesn't apply.
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

         if E.Has_Personality then
            IO.Put_Line (Section_Header ("Personality"));
            IO.New_Line;
            IO.Put_Line (To_String (E.Personality));
            IO.New_Line;
         end if;

         if not E.Abilities.Is_Empty then
            IO.Put (Bullet & Bold ("Abilities:") & " ");
            for I in E.Abilities.First_Index .. E.Abilities.Last_Index loop
               if I > E.Abilities.First_Index then
                  IO.Put (", ");
               end if;
               IO.Put (Format_Ability_Line (E.Abilities (I)));
            end loop;
            IO.Put_Line (".");
            IO.New_Line;
         end if;

         if not E.Weaknesses.Is_Empty then
            IO.Put (Bullet & Bold ("Weaknesses:") & " ");
            for I in E.Weaknesses.First_Index .. E.Weaknesses.Last_Index loop
               if I > E.Weaknesses.First_Index then
                  IO.Put (", ");
               end if;
               IO.Put (Format_Weakness_Line (E.Weaknesses (I)));
            end loop;
            IO.Put_Line (".");
            IO.New_Line;
         end if;
      end if;

      Print_Combat_And_Attacks (E.Combat);

      for A of E.Abilities loop
         Print_Linked_Section (A);
      end loop;

      if not E.Notes.Is_Empty then
         IO.Put_Line (Section_Header ("Notes"));
         IO.New_Line;
         for N of E.Notes loop
            IO.Put_Line (Bold (To_String (N.Header)) & " -- " & To_String (N.Text));
            IO.New_Line;
         end loop;
      end if;

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

      --  GM/author metadata (which character-creation limiting rules
      --  were used, rulebook p. 20-21), not part of the character's
      --  own write-up -- rendered only when asked for, per the user.
      if Config.Show_Options and then E.Has_Options then
         declare
            O     : Entities.Options_Block renames E.Options;
            Line  : Unbounded_String;
            First : Boolean := True;

            procedure Add (Item : String) is
            begin
               if not First then
                  Line := Line & ", ";
               end if;
               First := False;
               Line := Line & Item;
            end Add;
         begin
            if O.Has_Base_Zero then
               Add ("Base Zero (±" & Trim_Img (O.Base_Zero) & ")");
            end if;
            if O.Has_Power_Ceiling then
               Add ("Power Ceiling (" & Trim_Img (O.Power_Ceiling) & ")");
            end if;
            if O.Scaled_Cost then
               Add ("Scaled Cost");
            end if;
            if O.Combined_Effectiveness then
               Add ("Combined Effectiveness");
            end if;
            if not First then
               IO.Put_Line
                 (Bold ("Creation Rules:") & " " &
                  End_With_Period (To_String (Line)));
               IO.New_Line;
            end if;
         end;
      end if;
   end Process_Entity;

end Ova_Fmt.Format_Terse;
