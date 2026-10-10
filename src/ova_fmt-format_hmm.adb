with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Text_IO;
with Ova_Fmt.Config;
with Ova_Fmt.Format_Common;

package body Ova_Fmt.Format_Hmm is

   package Config renames Ova_Fmt.Config;
   package Common renames Ova_Fmt.Format_Common;
   package IO renames Ada.Text_IO;
   use type Entities.Sub_Entity_Access;

   function Indent (Depth : Natural) return String is
     (String'(1 .. Depth => ASCII.HT));

   function All_One_Line (S : String) return String renames Common.All_One_Line;
   --  An h-m-m node is exactly one physical line, so any internal
   --  newline in a prose field (from a "background: |" YAML literal
   --  block scalar, e.g. every test-data/sample-pcs/*.yaml character)
   --  has to be flattened to a space rather than printed literally --
   --  same besm2_fmt.Format_Hmm.All_One_Line reasoning/shape.

   -----------------------------------------------------------------
   --  Abilities/Weaknesses: a header node with one child node per
   --  item (default), or one node folding the label and the whole
   --  comma-joined list together (-c/--hmm-compact-lists, per the
   --  user). Two near-identical procedures rather than one generic
   --  one, since the main entity's Abilities/Weaknesses are
   --  Ability_Vectors/Weakness_Vectors (two distinct element types)
   --  while a Companion/Vehicle sub-entity's are both
   --  Sub_Item_Vectors -- matching Ova_Fmt.Entities' own distinction.
   -----------------------------------------------------------------

   procedure Print_Abilities_Weaknesses
     (Abilities    : Entities.Ability_Vectors.Vector;
      Weaknesses   : Entities.Weakness_Vectors.Vector;
      Header_Depth : Natural)
   is
   begin
      if not Abilities.Is_Empty then
         if Config.Hmm_Compact_Lists then
            IO.Put_Line
              (Indent (Header_Depth) &
               Common.End_With_Period
                 (Common.Bold ("Abilities:") & " " & Common.Join_Abilities (Abilities)));
         else
            IO.Put_Line (Indent (Header_Depth) & Common.Section_Header ("Abilities"));
            for A of Abilities loop
               IO.Put_Line (Indent (Header_Depth + 1) & Common.Format_Ability_Line (A));
            end loop;
         end if;
      end if;

      if not Weaknesses.Is_Empty then
         if Config.Hmm_Compact_Lists then
            IO.Put_Line
              (Indent (Header_Depth) &
               Common.End_With_Period
                 (Common.Bold ("Weaknesses:") & " " & Common.Join_Weaknesses (Weaknesses)));
         else
            IO.Put_Line (Indent (Header_Depth) & Common.Section_Header ("Weaknesses"));
            for W of Weaknesses loop
               IO.Put_Line (Indent (Header_Depth + 1) & Common.Format_Weakness_Line (W));
            end loop;
         end if;
      end if;
   end Print_Abilities_Weaknesses;

   procedure Print_Sub_Item_Section
     (Items : Entities.Sub_Item_Vectors.Vector; Label : String; Header_Depth : Natural)
   is
   begin
      if Items.Is_Empty then
         return;
      end if;
      if Config.Hmm_Compact_Lists then
         IO.Put_Line
           (Indent (Header_Depth) &
            Common.End_With_Period
              (Common.Bold (Label & ":") & " " & Common.Join_Sub_Items (Items)));
      else
         IO.Put_Line (Indent (Header_Depth) & Common.Section_Header (Label));
         for I of Items loop
            IO.Put_Line (Indent (Header_Depth + 1) & Common.Format_Sub_Item_Line (I));
         end loop;
      end if;
   end Print_Sub_Item_Section;

   -----------------------------------------------------------------
   --  Combat: a "Combat" header node, a single stats-summary child
   --  node, then (if any) an "Attacks" header node with one child
   --  node per attack. Header_Depth is where "Combat" itself lands --
   --  D2 for the main entity, one level deeper for a Companion/
   --  Vehicle's own combat: block (Print_Linked_Section below).
   -----------------------------------------------------------------

   procedure Print_Combat (C : Entities.Combat_Stats; Header_Depth : Natural) is
   begin
      if not C.Has_Combat then
         return;
      end if;
      IO.Put_Line (Indent (Header_Depth) & Common.Section_Header ("Combat"));
      IO.Put_Line (Indent (Header_Depth + 1) & Common.Format_Combat_Summary_Line (C));
      if not C.Attacks.Is_Empty then
         IO.Put_Line (Indent (Header_Depth + 1) & Common.Section_Header ("Attacks"));
         for A of C.Attacks loop
            IO.Put_Line (Indent (Header_Depth + 2) & Common.Format_Attack_Line (A));
         end loop;
      end if;
      if C.Has_Notes then
         IO.Put_Line
           (Indent (Header_Depth + 1) & Common.Bold ("Combat Notes:") & " " &
            All_One_Line (To_String (C.Notes)));
      end if;
   end Print_Combat;

   -----------------------------------------------------------------
   --  Linked-content expansion: one node per top-level Ability that
   --  has Transformation-style nested Abilities/Weaknesses, Magic-
   --  style Spells, or a Companion/Vehicle sub-entity -- a sibling of
   --  Abilities/Weaknesses/Combat at Header_Depth, in Abilities list
   --  order, same as Ova_Fmt.Format_Common.Print_Linked_Section. A
   --  Companion/Vehicle's own Abilities/Weaknesses/Combat nest one
   --  level deeper (Header_Depth + 1), recursively via
   --  Print_Sub_Item_Section/Print_Combat above -- h-m-m's own
   --  indentation makes this recursion free, unlike Terse's flat
   --  comma-joined "Abilities: ..." line for a sub-entity.
   -----------------------------------------------------------------

   --  Fragment-style Companion/Vehicle (`fragment: true`) -- no
   --  separate header node (the granting Ability's own line already
   --  names it via `detail:`), one compact "Attributes:" node at
   --  Header_Depth itself (not one level deeper -- there's no header
   --  node consuming that level here), then Combat/Attacks, same
   --  Header_Depth. Mirrors Ova_Fmt.Format_Common.
   --  Print_Sub_Entity_Fragment_Style's shape but with Header_Depth
   --  threaded through, which that shared version has no parameter
   --  for.
   --  Leads with "**Name** --", same fix/reasoning as Ova_Fmt.
   --  Format_Common.Print_Sub_Entity_Fragment_Style's own doc comment:
   --  a Sub_Entity has no Background of its own to fall back on for
   --  identification the way a top-level Fragment does.
   procedure Print_Sub_Entity_Fragment_Style
     (SE : Entities.Sub_Entity_Access; Header_Depth : Natural)
   is
      Name : constant String := To_String (SE.Name);
   begin
      if SE.Abilities.Is_Empty and then SE.Weaknesses.Is_Empty then
         IO.Put_Line (Indent (Header_Depth) & Common.Bold (Name) & ".");
      else
         declare
            Line : Unbounded_String :=
              To_Unbounded_String (Common.Bold (Name) & " -- " & Common.Bold ("Attributes:") & " ") &
              Common.Join_Fragment_Sub_Items (SE.Abilities);
         begin
            if not SE.Abilities.Is_Empty and then not SE.Weaknesses.Is_Empty then
               Line := Line & "; ";
            end if;
            Line := Line & Common.Join_Fragment_Sub_Items (SE.Weaknesses);
            IO.Put_Line (Indent (Header_Depth) & To_String (Line) & ".");
         end;
      end if;
      Print_Combat (SE.Combat, Header_Depth);
   end Print_Sub_Entity_Fragment_Style;

   procedure Print_Linked_Section (A : Entities.Ability; Header_Depth : Natural) is
      Has_Transformation : constant Boolean :=
        not A.Sub_Abilities.Is_Empty or else not A.Sub_Weaknesses.Is_Empty;
      Has_Spells         : constant Boolean := not A.Spells.Is_Empty;
      Has_Sub_Entity      : constant Boolean := A.Sub_Entity /= null;
   begin
      if not (Has_Transformation or else Has_Spells or else Has_Sub_Entity) then
         return;
      end if;

      if Has_Sub_Entity and then A.Sub_Entity.Is_Fragment then
         Print_Sub_Entity_Fragment_Style (A.Sub_Entity, Header_Depth);
         return;
      end if;

      if Has_Sub_Entity then
         IO.Put_Line
           (Indent (Header_Depth) &
            Common.Section_Header
              (To_String (A.Sub_Entity.Label) & ": " &
               Common.Name_Detail (A.Sub_Entity.Name, False, Null_Unbounded_String)));
      else
         IO.Put_Line
           (Indent (Header_Depth) &
            Common.Section_Header (Common.Name_Detail (A.Name, A.Has_Detail, A.Detail)));
      end if;

      if Has_Transformation then
         declare
            Line : Unbounded_String := To_Unbounded_String ("Grants: ");
         begin
            Line := Line & Common.Join_Sub_Items (A.Sub_Abilities);
            if not A.Sub_Abilities.Is_Empty and then not A.Sub_Weaknesses.Is_Empty then
               Line := Line & "; ";
            end if;
            Line := Line & Common.Join_Sub_Items (A.Sub_Weaknesses);
            IO.Put_Line (Indent (Header_Depth + 1) & Common.End_With_Period (To_String (Line)));
         end;
      end if;

      if Has_Spells then
         IO.Put_Line
           (Indent (Header_Depth + 1) &
            Common.End_With_Period ("Spells: " & Common.Join_Spells (A.Spells)));
      end if;

      if Has_Sub_Entity then
         Print_Sub_Item_Section (A.Sub_Entity.Abilities, "Abilities", Header_Depth + 1);
         Print_Sub_Item_Section (A.Sub_Entity.Weaknesses, "Weaknesses", Header_Depth + 1);
         Print_Combat (A.Sub_Entity.Combat, Header_Depth + 1);
      end if;
   end Print_Linked_Section;

   -----------------------------------------------------------------
   --  Notes/Fluff/Creation-Rules tail -- same fields/order as
   --  Ova_Fmt.Format_Common.Print_Tail, but every line needs its own
   --  Indent (Print_Tail has no depth parameter -- Terse/Gemtext don't
   --  track depth at all -- so it isn't reusable here).
   -----------------------------------------------------------------

   procedure Print_Tail (E : Entities.Entity; Header_Depth : Natural) is
   begin
      if not E.Notes.Is_Empty then
         IO.Put_Line (Indent (Header_Depth) & Common.Section_Header ("Notes"));
         for N of E.Notes loop
            IO.Put_Line
              (Indent (Header_Depth + 1) & Common.Bold (To_String (N.Header)) & " -- " &
               All_One_Line (To_String (N.Text)));
         end loop;
      end if;

      if E.Has_Other_Notes then
         IO.Put_Line (Indent (Header_Depth) & Common.Section_Header ("Other Notes"));
         IO.Put_Line (Indent (Header_Depth + 1) & All_One_Line (To_String (E.Other_Notes)));
      end if;

      if E.Has_Fluff then
         declare
            Line  : Unbounded_String;
            First : Boolean := True;

            procedure Add (Label : String; Has : Boolean; Value : Unbounded_String) is
            begin
               if Has then
                  if not First then
                     Line := Line & ", ";
                  end if;
                  First := False;
                  Line := Line & Common.Bold (Label & ":") & " " & Value;
               end if;
            end Add;
         begin
            IO.Put_Line (Indent (Header_Depth) & Common.Section_Header ("Fluff"));
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
            IO.Put_Line
              (Indent (Header_Depth + 1) &
               Common.End_With_Period (All_One_Line (To_String (Line))));
         end;
      end if;

      if Config.Show_Options and then E.Has_Options
        and then Common.Options_Text (E.Options) /= ""
      then
         IO.Put_Line
           (Indent (Header_Depth) & Common.Bold ("Creation Rules:") & " " &
            Common.End_With_Period (Common.Options_Text (E.Options)));
      end if;
   end Print_Tail;

   -----------------------------------------------------------------
   --  Process_Entity.
   -----------------------------------------------------------------

   procedure Process_Entity (E : Entities.Entity; Entity_No : Positive) is
      pragma Unreferenced (Entity_No);

      D1 : constant Natural := Config.Hmm_Depth + 1;  --  entity line
      D2 : constant Natural := Config.Hmm_Depth + 2;  --  section headers
      D3 : constant Natural := Config.Hmm_Depth + 3;  --  section prose/content
   begin
      if E.Is_Fragment then
         --  Deliberately untouched by Config.Format, matching every
         --  other backend, per the user: a Fragment's whole point is
         --  being flat/minimal -- one "Attributes:" node regardless of
         --  -c/--hmm-compact-lists, no separate Abilities/Weaknesses
         --  header nodes.
         if E.Has_Background then
            IO.Put_Line (Indent (D1) & All_One_Line (To_String (E.Background)));
         else
            IO.Put_Line (Indent (D1) & Common.Bold (To_String (E.Name)));
         end if;

         if not E.Abilities.Is_Empty or else not E.Weaknesses.Is_Empty then
            declare
               Line : Unbounded_String :=
                 To_Unbounded_String (Common.Bold ("Attributes:") & " ") &
                 Common.Join_Fragment_Abilities (E.Abilities);
            begin
               if not E.Abilities.Is_Empty and then not E.Weaknesses.Is_Empty then
                  Line := Line & "; ";
               end if;
               Line := Line & Common.Join_Fragment_Weaknesses (E.Weaknesses);
               IO.Put_Line (Indent (D2) & To_String (Line) & ".");
            end;
         end if;

         Print_Combat (E.Combat, D2);
         for A of E.Abilities loop
            Print_Linked_Section (A, D2);
         end loop;
      else
         IO.Put_Line (Indent (D1) & Common.Entity_Title (E));

         if E.Has_Tagline then
            IO.Put_Line
              (Indent (D2) &
               Common.Italic (""""  & All_One_Line (To_String (E.Tagline)) & """"));
         end if;

         if E.Has_Summary then
            IO.Put_Line (Indent (D2) & Common.Italic (All_One_Line (To_String (E.Summary))));
         end if;

         if E.Has_Background then
            IO.Put_Line (Indent (D2) & Common.Section_Header ("Background"));
            IO.Put_Line (Indent (D3) & All_One_Line (To_String (E.Background)));
         end if;

         if E.Has_Appearance then
            IO.Put_Line (Indent (D2) & Common.Section_Header ("Appearance"));
            IO.Put_Line (Indent (D3) & All_One_Line (To_String (E.Appearance)));
         end if;

         if E.Has_Personality then
            IO.Put_Line (Indent (D2) & Common.Section_Header ("Personality"));
            IO.Put_Line (Indent (D3) & All_One_Line (To_String (E.Personality)));
         end if;

         Print_Abilities_Weaknesses (E.Abilities, E.Weaknesses, D2);
         Print_Combat (E.Combat, D2);
         for A of E.Abilities loop
            Print_Linked_Section (A, D2);
         end loop;
      end if;

      Print_Tail (E, D2);
   end Process_Entity;

end Ova_Fmt.Format_Hmm;
