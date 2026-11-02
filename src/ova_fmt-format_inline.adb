with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Text_IO;
with Ova_Fmt.Format_Common;

package body Ova_Fmt.Format_Inline is

   package IO renames Ada.Text_IO;
   package FC renames Ova_Fmt.Format_Common;
   use type Entities.Sub_Entity_Access;

   Width : constant := 70;

   --  Appends S to P, after a blank unless P is empty.
   procedure Add (P : in out Unbounded_String; S : String) is
   begin
      if Length (P) > 0 then
         Append (P, ' ');
      end if;
      Append (P, S);
   end Add;

   --  S ended with a period, unless it ends a sentence already: with
   --  ".", "!" or "?", perhaps then a closing quote or parenthesis.
   --  Format_Common.End_With_Period only looks for the ".".
   function Sentence (S : String) return String is
      I : Integer := S'Last;
   begin
      while I >= S'First and then (S (I) = '"' or else S (I) = ''' or else S (I) = ')') loop
         I := I - 1;
      end loop;
      if I >= S'First and then (S (I) = '.' or else S (I) = '!' or else S (I) = '?') then
         return S;
      end if;
      return S & ".";
   end Sentence;

   --  Appends the prose S, on one line, as a sentence.
   procedure Add_Prose (P : in out Unbounded_String; S : Unbounded_String) is
   begin
      Add (P, Sentence (FC.All_One_Line (To_String (S))));
   end Add_Prose;

   -----------------------------------------------------------------
   --  Filling.
   -----------------------------------------------------------------

   --  Whether the word S (From .. To), at the start of a line, would
   --  make it something other than a paragraph's text: a heading, a
   --  block quote, a list item (a lone "-", "+" or "*", or digits and
   --  a "." or ")"), a thematic break or a setext underline (nothing
   --  but "-", "=", "*" or "_").
   function Opens_Block (S : String; From, To : Positive) return Boolean is
      I : Natural := From;
   begin
      if S (From) = '#' or else S (From) = '>' or else (S (From) = '+' and then To = From) then
         return True;
      end if;
      while I <= To and then (S (I) = '-' or else S (I) = '=' or else S (I) = '*' or else S (I) = '_') loop
         I := I + 1;
      end loop;
      if I > To then
         return True;
      end if;
      I := From;
      while I <= To and then S (I) in '0' .. '9' loop
         I := I + 1;
      end loop;
      return I > From and then I = To and then (S (I) = '.' or else S (I) = ')');
   end Opens_Block;

   --  Scans the word that starts at or after I in S, setting From and
   --  To to its bounds, I to just after it, and W to its width. A
   --  character is a byte that isn't a UTF-8 continuation byte (16#80#
   --  to 16#BF#), so U+2212 is one column. From > S'Last if there is
   --  no word left.
   procedure Word (S : String; I : in out Positive; From, To, W : out Natural) is
   begin
      while I <= S'Last and then S (I) = ' ' loop
         I := I + 1;
      end loop;
      From := I;
      W := 0;
      while I <= S'Last and then S (I) /= ' ' loop
         if Character'Pos (S (I)) not in 16#80# .. 16#BF# then
            W := W + 1;
         end if;
         I := I + 1;
      end loop;
      To := I - 1;
   end Word;

   --  Writes P filled to Width columns, then an empty line. Words are
   --  split at blanks, and a run of blanks is one. A word that would
   --  open a Markdown block at the start of a line stays on the line of
   --  the word before it, so the break comes before that one instead.
   --  A word, or words kept together, longer than Width has a line of
   --  its own.
   procedure Paragraph (P : Unbounded_String) is
      S : constant String := To_String (P);
      I, K : Positive := S'First;
      From, To, W, Next, Next_To, W2 : Natural;
      Col : Natural := 0;
   begin
      Word (S, I, From, To, W);
      while From <= S'Last loop
         --  Take in the words that can't start a line.
         K := I;
         Word (S, K, Next, Next_To, W2);
         while Next <= S'Last and then Opens_Block (S, Next, Next_To) loop
            W := W + 1 + W2;
            To := Next_To;
            I := K;
            Word (S, K, Next, Next_To, W2);
         end loop;
         if Col > 0 then
            if Col + 1 + W > Width then
               IO.New_Line;
               Col := 0;
            else
               IO.Put (' ');
               Col := Col + 1;
            end if;
         end if;
         --  Write S (From .. To) with each run of blanks as one.
         for J in From .. To loop
            if S (J) /= ' ' or else S (J - 1) /= ' ' then
               IO.Put (S (J));
            end if;
         end loop;
         Col := Col + W;
         Word (S, I, From, To, W);
      end loop;
      IO.New_Line;
      IO.New_Line;
   end Paragraph;

   -----------------------------------------------------------------
   --  Parts.
   -----------------------------------------------------------------

   --  "*abilities; weaknesses.*", "" if there are neither. Each is
   --  "Name Level (detail)", the NPC Fragment order, as in a cast list:
   --  "Attack +2 (Blaster rifle)".
   function Traits (Abilities, Weaknesses : String) return String is
   begin
      if Abilities = "" and then Weaknesses = "" then
         return "";
      end if;
      return FC.Italic
        (Abilities & (if Abilities /= "" and then Weaknesses /= "" then "; " else "") &
         Weaknesses & ".");
   end Traits;

   --  Appends Text to Parts, after "; " if Parts isn't empty.
   procedure Add_Part (Parts : in out Unbounded_String; Text : String) is
   begin
      if Length (Parts) > 0 then
         Append (Parts, "; ");
      end if;
      Append (Parts, Text);
   end Add_Part;

   --  The perks or flaws of Vec, comma-joined.
   function Perks_Flaws (Vec : Entities.Perk_Flaw_Vectors.Vector) return String is
      Result : Unbounded_String;
   begin
      for I in Vec.First_Index .. Vec.Last_Index loop
         if I > Vec.First_Index then
            Append (Result, ", ");
         end if;
         Append (Result, FC.Format_Perk_Flaw (Vec (I)));
      end loop;
      return To_String (Result);
   end Perks_Flaws;

   --  "Name (Affinity: a; perks; flaws): Roll N, DX d, End c.", then
   --  its description, with only the parenthesized parts there are.
   function Attack (A : Entities.Attack) return String is
      Parts  : Unbounded_String;
      Result : Unbounded_String := A.Name;
   begin
      if A.Has_Affinity then
         Add_Part (Parts, "Affinity: " & To_String (A.Affinity));
      end if;
      if not A.Perks.Is_Empty then
         Add_Part (Parts, Perks_Flaws (A.Perks));
      end if;
      if not A.Flaws.Is_Empty then
         Add_Part (Parts, Perks_Flaws (A.Flaws));
      end if;
      if Length (Parts) > 0 then
         Append (Result, " (" & Parts & ")");
      end if;
      Append (Result, ": Roll " & FC.Number_Img (A.Roll) &
                FC.Override_Mark (A.Overrides (Entities.Roll)) &
                ", DX " & To_String (A.Dx) & FC.Override_Mark (A.Overrides (Entities.Dx)) &
                ", End " & FC.Trim_Img (A.Endurance) &
                FC.Override_Mark (A.Overrides (Entities.Endurance)) & ".");
      if A.Has_Description then
         Add_Prose (Result, A.Description);
      end if;
      return To_String (Result);
   end Attack;

   --  N as a word, up to twelve, as prose has it; past that its digits.
   function Count_Text (N : Positive) return String is
     (case N is
         when 1 => "one", when 2 => "two", when 3 => "three", when 4 => "four",
         when 5 => "five", when 6 => "six", when 7 => "seven", when 8 => "eight",
         when 9 => "nine", when 10 => "ten", when 11 => "eleven", when 12 => "twelve",
         when others => FC.Trim_Img (N));

   --  E's NPC type's plural, as a count of them has it: "Secondaries",
   --  "Bosses".
   function NPC_Type_Plural (E : Entities.Entity) return String is
     (case E.NPC_Type is
         when Entities.Secondary => "Secondaries",
         when Entities.Boss      => "Bosses",
         when others             => FC.NPC_Type_Text (E) & "s");

   --  C's attacks, then "Defense D. Health H, Endurance E. TV T.", then
   --  its notes, appended to P; nothing if there is no combat. Each of
   --  a group makes it "TV T each."
   procedure Add_Combat
     (P : in out Unbounded_String; C : Entities.Combat_Stats; Group : Boolean := False) is
   begin
      if not C.Has_Combat then
         return;
      end if;
      for A of C.Attacks loop
         Add (P, Attack (A));
      end loop;
      Add (P, "Defense " & FC.Defense_Text (C) &
             ". Health " & FC.Trim_Img (C.Health) &
             FC.Override_Mark (C.Overrides (Entities.Health)) &
             ", Endurance " & FC.Trim_Img (C.Endurance) &
             FC.Override_Mark (C.Overrides (Entities.Endurance)) & "." &
             (if C.Has_Threat_Value
              then " TV " & FC.Trim_Img (C.Threat_Value) &
                FC.Override_Mark (C.Overrides (Entities.Threat_Value)) &
                (if Group then " each." else ".")
              else ""));
      if C.Has_Notes then
         Add_Prose (P, C.Notes);
      end if;
   end Add_Combat;

   --  A paragraph for an Ability's linked content, led by its title in
   --  bold: "**Companion: Name.**", or the Ability's name and detail.
   procedure Linked (A : Entities.Ability) is
      SE : constant Entities.Sub_Entity_Access := A.Sub_Entity;
      P  : Unbounded_String;
   begin
      if A.Sub_Abilities.Is_Empty and then A.Sub_Weaknesses.Is_Empty and then
        A.Spells.Is_Empty and then SE = null
      then
         return;
      end if;
      if SE /= null then
         P := To_Unbounded_String (FC.Bold (To_String (SE.Label & ": " & SE.Name) & "."));
      else
         P := To_Unbounded_String (FC.Bold (FC.Name_Detail (A.Name, A.Has_Detail, A.Detail) & "."));
      end if;
      if not A.Sub_Abilities.Is_Empty or else not A.Sub_Weaknesses.Is_Empty then
         declare
            Abilities  : constant String := FC.Join_Fragment_Sub_Items (A.Sub_Abilities);
            Weaknesses : constant String := FC.Join_Fragment_Sub_Items (A.Sub_Weaknesses);
         begin
            Add (P, Sentence
                   ("Grants: " & Abilities &
                    (if Abilities /= "" and then Weaknesses /= "" then "; " else "") &
                    Weaknesses));
         end;
      end if;
      if not A.Spells.Is_Empty then
         Add (P, Sentence ("Spells: " & FC.Join_Spells (A.Spells)));
      end if;
      if SE /= null then
         declare
            T : constant String :=
              Traits (FC.Join_Fragment_Sub_Items (SE.Abilities),
                      FC.Join_Fragment_Sub_Items (SE.Weaknesses));
         begin
            if T /= "" then
               Add (P, T);
            end if;
         end;
         Add_Combat (P, SE.Combat);
      end if;
      Paragraph (P);
   end Linked;

   --  The entity's paragraph, led by "**Name** (Secondary)." or, with
   --  no NPC type, "**Name.**", then its linked content's. With a count
   --  over 1 the lead is "**Name** (three Secondaries)." or, with no
   --  NPC type, "**Name** (three).", and a Fragment's "Secondary NPCs
   --  (three)."
   procedure Process_Entity (E : Entities.Entity; Entity_No : Positive) is
      pragma Unreferenced (Entity_No);
      Group : constant Boolean := E.Count > 1;
      P     : Unbounded_String;
   begin
      if E.Is_Fragment and then E.Has_Background then
         Add_Prose (P, E.Background);
         if E.Has_NPC_Type and then Group then
            Add (P, FC.NPC_Type_Text (E) & " NPCs (" & Count_Text (E.Count) & ").");
         elsif E.Has_NPC_Type then
            Add (P, FC.NPC_Type_Text (E) & " NPC.");
         elsif Group then
            Add (P, "(" & Count_Text (E.Count) & ").");
         end if;
      else
         if Group then
            P := To_Unbounded_String
              (FC.Bold (To_String (E.Name)) & " (" & Count_Text (E.Count) &
               (if E.Has_NPC_Type then " " & NPC_Type_Plural (E) else "") & ").");
         elsif E.Has_NPC_Type then
            P := To_Unbounded_String
              (FC.Bold (To_String (E.Name)) & " (" & FC.NPC_Type_Text (E) & ").");
         else
            P := To_Unbounded_String (FC.Bold (To_String (E.Name) & "."));
         end if;
         if E.Has_Summary then
            Add_Prose (P, E.Summary);
         end if;
         if E.Has_Background then
            Add_Prose (P, E.Background);
         end if;
         if E.Has_Appearance then
            Add_Prose (P, E.Appearance);
         end if;
         if E.Has_Personality then
            Add_Prose (P, E.Personality);
         end if;
      end if;
      declare
         T : constant String :=
           Traits (FC.Join_Fragment_Abilities (E.Abilities),
                   FC.Join_Fragment_Weaknesses (E.Weaknesses));
      begin
         if T /= "" then
            Add (P, T);
         end if;
      end;
      Add_Combat (P, E.Combat, Group);
      Paragraph (P);
      for A of E.Abilities loop
         Linked (A);
      end loop;
   end Process_Entity;

end Ova_Fmt.Format_Inline;
