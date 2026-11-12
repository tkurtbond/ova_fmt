with Ada.Containers.Vectors;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Text_IO;
with Arg_Parser;
with Ova_Fmt.Config;
with Ova_Fmt.Format_Common;
with Ova_Fmt.Sheet_Fonts;
with Ova_Fmt.Sheet_Map;
with Ova_Fmt.Sheet_Widths;

package body Ova_Fmt.Format_Sheet is

   package IO renames Ada.Text_IO;
   package FC renames Ova_Fmt.Format_Common;
   package SF renames Ova_Fmt.Sheet_Fonts;
   package SM renames Ova_Fmt.Sheet_Map;
   package SW renames Ova_Fmt.Sheet_Widths;

   use type SM.Row_Kind;
   use type SF.Face;
   use type Arg_Parser.String_Reference;

   LF : constant Character := ASCII.LF;

   First_Entity : Boolean := True;
   Portraits    : Natural := 0;  --  numbers each portrait for ova_sheet.sh

   function Img (N : Integer) return String is
      S : constant String := Integer'Image (N);
   begin
      return (if N < 0 then S else S (S'First + 1 .. S'Last));
   end Img;

   ---------------------------------------------------------------------
   --  The sheet's geometry, in hundredths of a point (centipoints),
   --  from its form fields' rectangles: X and Y0 the lower left corner,
   --  Y0 from the bottom of the page, as PDF measures.
   ---------------------------------------------------------------------

   Page_Height : constant := 59528;

   type Rect is record
      X, Y0, W, H : Natural;
   end record;

   --  Y0 from the top, as troff measures.
   function Top (R : Rect) return Natural is (Page_Height - (R.Y0 + R.H));

   --  Text is kept this far inside a field on each side.
   Pad : constant := 200;

   --  The fields that hold blocks of text (Combat Notes and page 2's)
   --  run to the edges of their boxes, so their text is kept a further
   --  Block_Inset in from the sides.
   Block_Inset : constant := 400;

   function Inset (R : Rect) return Rect is
     ((R.X + Block_Inset, R.Y0, R.W - 2 * Block_Inset, R.H));

   --  The ruled lines of the Abilities and Weaknesses columns: row K's
   --  baseline from the top of the page.
   Row_Base : constant := 11670;
   Row_Step : constant := 1300;

   function Row_Baseline (K : Positive) return Natural is (Row_Base + Row_Step * (K - 1));

   Dice_Width : constant := 1810;
   Name_Width : constant := 15260;
   Ability_Dice_X  : constant := 3500;
   Ability_Name_X  : constant := 5720;
   Weakness_Dice_X : constant := 21610;
   Weakness_Name_X : constant := 23830;

   --  A Sub or Spell row is indented into the name column; any row's
   --  second and later lines hang further in.
   Sub_Indent : constant := 800;
   Hang       : constant := 600;

   Character_Name : constant Rect := (14650, 54130, 12980, 1790);
   Player_Name    : constant Rect := (28210, 54130, 12780, 1790);

   type Attack_Rects is array (1 .. SM.Attack_Slots) of Rect;

   Attack_Name : constant Attack_Rects :=
     ((14330, 20930, 13710, 1240), (14330, 16970, 13710, 1240),
      (14330, 13010, 13710, 1230), (14330, 9100, 13710, 1230));
   Attack_Clause : constant Attack_Rects :=
     ((14330, 18290, 13710, 2640), (14330, 14330, 13710, 2640),
      (14330, 10370, 13710, 2640), (14330, 6460, 13710, 2640));
   Roll_Box : constant Attack_Rects :=
     ((28270, 18250, 3260, 2690), (28270, 14280, 3260, 2880),
      (28270, 10380, 3260, 2760), (28270, 6480, 3260, 2760));
   Dx_Box : constant Attack_Rects :=
     ((31760, 18250, 2980, 2690), (31760, 14280, 2980, 2880),
      (31760, 10380, 2980, 2760), (31760, 6480, 2980, 2760));
   End_Box : constant Attack_Rects :=
     ((34970, 18250, 3310, 2690), (34970, 14280, 3310, 2880),
      (34970, 10380, 3310, 2760), (34970, 6480, 3310, 2760));

   --  The portrait, inside the box's rounded corners.
   Portrait_Box : constant Rect :=
     (24040 + Block_Inset, 27890 + Block_Inset, 16280 - 2 * Block_Inset, 28710 - 2 * Block_Inset);

   Combat_Notes : constant Rect := Inset ((2810, 4680, 11250, 15970));
   Defense_Box  : constant Rect := (14920, 2250, 4660, 2850);
   Health_Box   : constant Rect := (21080, 2250, 4660, 2850);
   Endurance_Box : constant Rect := (28030, 2250, 4660, 2850);
   TV_Box       : constant Rect := (34590, 2250, 3370, 2850);

   --  The fields of page 2, in the order sections are laid into them.
   type Prose_Field is (Background, Appearance, Personality, Other_Notes);

   function Prose_Name (P : Prose_Field) return String is
     (case P is
         when Background  => "Background",
         when Appearance  => "Appearance",
         when Personality => "Personality",
         when Other_Notes => "Other Notes");

   Prose_Rect : constant array (Prose_Field) of Rect :=
     (Background  => Inset ((3270, 26790, 20630, 28740)),
      Appearance  => Inset ((3170, 8990, 17230, 14540)),
      Personality => Inset ((21140, 8990, 17230, 14540)),
      Other_Notes => Inset ((3170, 2050, 35190, 3970)));

   ---------------------------------------------------------------------
   --  Looks: a face, a size in tenths of a point, and whether it is
   --  the sheet's dark red. The rulebook's emphasis, in Noto Sans (that
   --  PLAN.md, "Fonts and type styles"); small caps are faked with
   --  upper case a size down.
   ---------------------------------------------------------------------

   type Look is record
      Face : SF.Face;
      Size : Positive;
      Red  : Boolean := False;
   end record;

   Item_Look    : constant Look := (SW.Italic, 80, False);
   Item_Caps    : constant Look := (SW.Regular, 70, False);
   Sub_Look     : constant Look := (SW.Light_Italic, 65, False);
   Sub_Caps     : constant Look := (SW.Regular, 55, False);
   Dice_Look    : constant Look := (SW.Regular, 80, False);
   Notes_Look   : constant Look := (SW.Regular, 70, False);
   Prose_Look   : constant Look := (SW.Regular, 80, False);

   Notes_Leading  : constant := 850;
   Prose_Leading  : constant := 1000;
   Clause_Leading : constant := 800;
   Clause_Lines   : constant := 3;

   --  U+2026 in UTF-8.
   Ellipsis : constant String :=
     Character'Val (16#E2#) & Character'Val (16#80#) & Character'Val (16#A6#);

   --  The height of a capital, 0.714 em in Noto Sans, in centipoints.
   function Cap (Size : Positive) return Natural is (714 * Size / 100);

   --  "116.70": centipoints as points.
   function Pt (N : Natural) return String is
      Frac : constant String := Img (100 + N mod 100);
   begin
      return Img (N / 100) & "." & Frac (Frac'Last - 1 .. Frac'Last);
   end Pt;

   --  "8", "6.5": tenths of a point as points.
   function Size_Img (S : Positive) return String is
     (if S mod 10 = 0 then Img (S / 10) else Img (S / 10) & "." & Img (S mod 10));

   ---------------------------------------------------------------------
   --  Styled text: a string and each of its bytes' look.
   ---------------------------------------------------------------------

   package Look_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Look);

   type Styled is record
      Text  : Unbounded_String;
      Looks : Look_Vectors.Vector;
   end record;

   --  Text with each "--" an em dash, U+2014 in UTF-8, as the
   --  rulebook sets one; the YAML has only ASCII to type it with.
   --  Done where text comes in (Add, and the procedures that cut a
   --  text by its length, before they measure it), so that lines are
   --  broken with the dash's own width and cut on the dashed text.
   --  groff reads it through preconv (ova_sheet.sh's -k).
   function Dashes (Text : String) return String is
      Em     : constant String :=
        Character'Val (16#E2#) & Character'Val (16#80#) & Character'Val (16#94#);
      Result : Unbounded_String;
      I      : Natural := Text'First;
   begin
      while I <= Text'Last loop
         if Text (I) = '-' and then I < Text'Last and then Text (I + 1) = '-' then
            Append (Result, Em);
            I := I + 2;
         else
            Append (Result, Text (I));
            I := I + 1;
         end if;
      end loop;
      return To_String (Result);
   end Dashes;

   procedure Add (S : in out Styled; Text : String; L : Look) is
      T : constant String := Dashes (Text);
   begin
      Append (S.Text, T);
      for I in T'Range loop
         S.Looks.Append (L);
      end loop;
   end Add;

   function Plain (Text : String; L : Look) return Styled is
      S : Styled;
   begin
      Add (S, Text, L);
      return S;
   end Plain;

   --  Where Width stops counting: 20,000 points, far wider than any
   --  line, and small enough that Break's sum of two such widths is
   --  still a Natural.
   Max_Width : constant := 200_000_000;

   --  The width of S's bytes First .. Last, in ten-thousandths of a
   --  point, up to Max_Width: a run of one look at a time.
   function Width (S : Styled; First, Last : Natural) return Natural is
      T : constant String := To_String (S.Text);
      W : Natural := 0;
      I : Positive := First;
      J : Positive;
   begin
      while I <= Last loop
         J := I;
         while J < Last and then S.Looks (J + 1) = S.Looks (I) loop
            J := J + 1;
         end loop;
         W := Natural'Min
                (W + SF.Text_Width (T (I .. J), S.Looks (I).Face) * S.Looks (I).Size,
                 Max_Width);
         I := J + 1;
      end loop;
      return W;
   end Width;

   type Span is record
      First, Last : Positive;
   end record;

   package Span_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Span);

   --  S broken greedily at spaces into lines First_Width centipoints
   --  wide, then Rest_Width, each LF starting a new line, into at most
   --  Max_Lines lines (0: any number). Cut is the index of the last
   --  byte placed, Length (S.Text) if all of it is. A word wider than
   --  its line has a line of its own and overflows it.
   procedure Break (S : Styled; First_Width, Rest_Width : Natural;
                    Max_Lines : Natural; Lines : out Span_Vectors.Vector;
                    Cut : out Natural)
   is
      T     : constant String := To_String (S.Text);
      I     : Positive := 1;
      J     : Positive;
      Open  : Boolean := False;  --  a line has words
      Line  : Span := (1, 1);
      Cur   : Natural := 0;
      W     : Natural;

      function Limit return Natural is
        ((if Natural (Lines.Length) = 0 then First_Width else Rest_Width) * 100);

      procedure Close is
      begin
         if Open then
            Lines.Append (Line);
            Open := False;
         end if;
      end Close;
   begin
      Lines.Clear;
      Cut := 0;
      while I <= T'Last loop
         if T (I) = LF then
            Close;
            I := I + 1;
         elsif T (I) = ' ' then
            I := I + 1;
         else
            J := I;
            while J < T'Last and then T (J + 1) /= ' ' and then T (J + 1) /= LF loop
               J := J + 1;
            end loop;
            W := Width (S, I, J);
            if Open then
               declare
                  Space : constant Natural := Width (S, Line.Last + 1, I - 1);
               begin
                  if Cur + Space + W <= Limit then
                     Line.Last := J;
                     Cur := Cur + Space + W;
                  else
                     Close;
                  end if;
               end;
            end if;
            if not Open then
               if Max_Lines > 0 and then Natural (Lines.Length) = Max_Lines then
                  return;
               end if;
               Line := (I, J);
               Cur := W;
               Open := True;
            end if;
            Cut := J;
            I := J + 1;
         end if;
      end loop;
      Close;
      Cut := T'Last;
   end Break;

   --  Text as troff text: `\` as `\e`, a tab as a space.
   function Escape (Text : String) return String is
      Result : Unbounded_String;
   begin
      for C of Text loop
         case C is
            when '\' => Append (Result, "\e");
            when ASCII.HT => Append (Result, ' ');
            when others => Append (Result, C);
         end case;
      end loop;
      return To_String (Result);
   end Escape;

   --  S's bytes First .. Last as troff: each change of look an escape,
   --  `\` as `\e`. It starts with an escape, so it can't be read as a
   --  request.
   function Troff (S : Styled; First, Last : Positive) return String is
      T      : constant String := To_String (S.Text);
      Result : Unbounded_String;
      Red    : Boolean := False;
   begin
      for I in First .. Last loop
         if I = First or else S.Looks (I) /= S.Looks (I - 1) then
            declare
               L : constant Look := S.Looks (I);
            begin
               if L.Red /= Red then
                  Append (Result, (if L.Red then "\m[ovared]" else "\m[default]"));
                  Red := L.Red;
               end if;
               Append (Result, "\f[" & SF.Name (L.Face) & "]\s[" & Size_Img (L.Size) & "]");
            end;
         end if;
         Append (Result, Escape (T (I .. I)));
      end loop;
      if Red then
         Append (Result, "\m[default]");
      end if;
      return To_String (Result);
   end Troff;

   --  A line of S with its baseline Y from the top and its left at X.
   procedure Place (Y, X : Natural; S : Styled; L : Span) is
   begin
      IO.Put_Line (".L " & Pt (Y) & " " & Pt (X));
      IO.Put_Line (Troff (S, L.First, L.Last));
   end Place;

   --  Text in R's one line, centred or at its left, in F at Size,
   --  stepping down half a point at a time to Floor until it fits; if
   --  not even then, the words that fit. False if not all of it fit.
   function Put_Line_In (Line : String; F : SF.Face; Size, Floor : Positive;
                         R : Rect; Centred : Boolean; Red : Boolean := False)
     return Boolean
   is
      Text  : constant String := Dashes (Line);
      Inner : constant Natural := R.W - 2 * Pad;
      S     : Positive := Size;
   begin
      if Text = "" then
         return True;
      end if;
      while S > Floor and then SF.Text_Width (Text, F) * S > Inner * 100 loop
         S := Positive'Max (Floor, S - 5);
      end loop;
      declare
         St    : constant Styled := Plain (Text, (F, S, Red));
         Lines : Span_Vectors.Vector;
         Cut   : Natural;
      begin
         Break (St, Inner, Inner, 1, Lines, Cut);
         if Lines.Is_Empty then
            return False;
         end if;
         declare
            L : constant Span := Lines.First_Element;
            W : constant Natural := Width (St, L.First, L.Last);
            X : constant Natural :=
              (if Centred and then W <= R.W * 100 then R.X + (R.W * 100 - W) / 200
               else R.X + Pad);
         begin
            Place (Top (R) + (R.H + Cap (S)) / 2, X, St, L);
         end;
         return Cut = Text'Length;
      end;
   end Put_Line_In;

   procedure Put_Line_In (Text : String; F : SF.Face; Size, Floor : Positive;
                          R : Rect; Centred : Boolean)
   is
      All_Fit : constant Boolean := Put_Line_In (Text, F, Size, Floor, R, Centred);
   begin
      pragma Unreferenced (All_Fit);
   end Put_Line_In;

   --  The most lines of L at Leading that R holds, top-aligned.
   function Block_Lines (R : Rect; L : Look; Leading : Positive) return Positive is
     (Positive'Max (1, (R.H - 2 * Pad - Cap (L.Size)) / Leading + 1));

   --  Text split into what fits R at L and Leading and the rest, R
   --  taking at least one word.
   procedure Fit_Block (Block : String; L : Look; R : Rect; Leading : Positive;
                        Fitted, Rest : out Unbounded_String)
   is
      Text  : constant String := Dashes (Block);
      Lines : Span_Vectors.Vector;
      Cut   : Natural;
   begin
      Break (Plain (Text, L), R.W - 2 * Pad, R.W - 2 * Pad,
             Block_Lines (R, L, Leading), Lines, Cut);
      if Cut = 0 and then not Lines.Is_Empty then
         Cut := Lines.First_Element.Last;
      end if;
      Fitted := To_Unbounded_String (FC.Trim_Blanks (Text (Text'First .. Text'First + Cut - 1)));
      Rest := To_Unbounded_String (FC.Trim_Blanks (Text (Text'First + Cut .. Text'Last)));
   end Fit_Block;

   --  Text in R, top-aligned, a line at a time.
   procedure Put_Block (Block : String; L : Look; R : Rect; Leading : Positive) is
      Text  : constant String := Dashes (Block);
      St    : constant Styled := Plain (Text, L);
      Lines : Span_Vectors.Vector;
      Cut   : Natural;
      Y     : Natural := Top (R) + Pad + Cap (L.Size);
   begin
      Break (St, R.W - 2 * Pad, R.W - 2 * Pad, 0, Lines, Cut);
      for Line of Lines loop
         Place (Y, R.X + Pad, St, Line);
         Y := Y + Leading;
      end loop;
   end Put_Block;

   ---------------------------------------------------------------------
   --  Rows.
   ---------------------------------------------------------------------

   function Indent (R : SM.Row) return Natural is
     (if R.Kind = SM.Item then 0 else Sub_Indent);

   --  A row's text: an Item's name in italic, a Sub's level and name
   --  and a Spell in light italic, smaller; the bracket's perks, flaws
   --  and Endurance in faked small caps.
   function Row_Text (R : SM.Row) return Styled is
      Base : constant Look := (if R.Kind = SM.Item then Item_Look else Sub_Look);
      Caps : constant Look := (if R.Kind = SM.Item then Item_Caps else Sub_Caps);
      S    : Styled;
   begin
      if R.Kind = SM.Sub then
         Add (S, To_String (R.Level) & " ", Base);
      end if;
      Add (S, To_String (R.Plain), Base);
      if Length (R.Mods) > 0 then
         Add (S, " [", Base);
         Add (S, SF.Upper (To_String (R.Mods)), Caps);
         Add (S, "]", Base);
      end if;
      return S;
   end Row_Text;

   procedure Row_Break (R : SM.Row; Lines : out Span_Vectors.Vector) is
      First : constant Natural := Name_Width - 2 * Pad - Indent (R);
      Cut   : Natural;
   begin
      Break (Row_Text (R), First, First - Hang, 0, Lines, Cut);
   end Row_Break;

   --  Sheet_Map's measure: the ruled lines a row takes.
   function Row_Lines (R : SM.Row) return Positive is
      Lines : Span_Vectors.Vector;
   begin
      Row_Break (R, Lines);
      return Positive'Max (1, Natural (Lines.Length));
   end Row_Lines;

   --  An owner's parts of the continuation pages, gathered over its
   --  copies of page 1.
   --  What an owner's copies of page 1 send to the continuation pages:
   --  the Character Name and Player Name fields in full when cut (the
   --  first cut copy's), and the notes, attacks and combat notes that
   --  don't fit.
   type Owner_Parts is record
      Name, Player, Ability_Notes, Attacks, Combat_Notes : Unbounded_String;
   end record;

   --  Line added to Lines, LF-separated.
   procedure Add_Line (Lines : in out Unbounded_String; Line : String) is
   begin
      if Length (Lines) > 0 then
         Append (Lines, LF);
      end if;
      Append (Lines, Line);
   end Add_Line;

   procedure Put_Rows (Parts : in out Owner_Parts; Rows : SM.Row_Vectors.Vector;
                       Dice_X, Name_X : Natural) is
      K : Positive := 1;
   begin
      for R of Rows loop
         declare
            St    : constant Styled := Row_Text (R);
            Lines : Span_Vectors.Vector;
         begin
            Row_Break (R, Lines);
            if R.Kind = SM.Item and then Length (R.Level) > 0 then
               declare
                  Dice : constant Styled := Plain (To_String (R.Level), Dice_Look);
                  W    : constant Natural := Width (Dice, 1, Length (R.Level));
               begin
                  Place (Row_Baseline (K), Dice_X + (Dice_Width * 100 - W) / 200,
                         Dice, (1, Length (R.Level)));
               end;
            end if;
            for N in Lines.First_Index .. Lines.Last_Index loop
               Place (Row_Baseline (K + N - 1),
                      Name_X + Pad + Indent (R) + (if N > 1 then Hang else 0),
                      St, Lines (N));
            end loop;
            K := K + Positive'Max (1, Natural (Lines.Length));
            if R.Has_Note then
               Add_Line (Parts.Ability_Notes, FC.Reflow (R.Note));
            end if;
         end;
      end loop;
   end Put_Rows;

   ---------------------------------------------------------------------
   --  Attacks.
   ---------------------------------------------------------------------

   --  The clause in faked small caps, stepping down to 5.5 pt until it
   --  fits Clause_Lines lines; False if not even then, when as many
   --  words as fit are placed, ending in an ellipsis rather than the
   --  comma or semicolon after the last (the whole clause goes in the
   --  Attacks section).
   function Put_Clause (Clause : String; R : Rect) return Boolean is
      Inner : constant Natural := R.W - 2 * Pad;
      Text  : constant String := SF.Upper (Dashes (Clause));
      Size  : Positive := 65;
      Lines : Span_Vectors.Vector;
      Cut   : Natural;
      St    : Styled;
   begin
      loop
         St := Plain (Text, (SW.Regular, Size, False));
         Break (St, Inner, Inner, Clause_Lines, Lines, Cut);
         exit when Cut = Text'Length or else Size <= 55;
         Size := Size - 5;
      end loop;
      if Cut < Text'Length then
         declare
            K    : Natural := Cut;
            Done : Natural;
         begin
            loop
               while K > 0 and then Text (K) in ' ' | ',' | ';' | ':' loop
                  K := K - 1;
               end loop;
               St := Plain (Text (Text'First .. K) & Ellipsis, (SW.Regular, Size, False));
               Break (St, Inner, Inner, Clause_Lines, Lines, Done);
               exit when Done = Length (St.Text) or else K = 0;
               --  Drop the last word.
               while K > 0 and then Text (K) /= ' ' loop
                  K := K - 1;
               end loop;
            end loop;
         end;
      end if;
      declare
         N     : constant Natural := Natural (Lines.Length);
         Block : constant Natural := (N - 1) * Clause_Leading + Cap (Size);
         Y     : Natural := Top (R) + (R.H - Block) / 2 + Cap (Size);
      begin
         for Line of Lines loop
            Place (Y, R.X + Pad, St, Line);
            Y := Y + Clause_Leading;
         end loop;
      end;
      return Cut = Text'Length;
   end Put_Clause;

   procedure Put_Attacks (Parts : in out Owner_Parts;
                          Attacks : SM.Attack_Slot_Vectors.Vector) is
   begin
      for N in Attacks.First_Index .. Attacks.Last_Index loop
         declare
            A         : constant SM.Attack_Slot := Attacks (N);
            Clause    : constant String := To_String (A.Clause);
            Name_Fits : constant Boolean :=
              Put_Line_In (To_String (A.Name), SW.Bold, 80, 65,
                           Attack_Name (N), Centred => False, Red => True);
            Clipped   : constant Boolean :=
              Clause /= "" and then not Put_Clause (Clause, Attack_Clause (N));
            Entry_Text : Unbounded_String;
         begin
            Put_Line_In (To_String (A.Roll), SW.Condensed_Semibold, 160, 80,
                         Roll_Box (N), Centred => True);
            Put_Line_In (To_String (A.Dx), SW.Condensed_Semibold, 160, 80,
                         Dx_Box (N), Centred => True);
            Put_Line_In (To_String (A.Endurance), SW.Condensed_Semibold, 160, 80,
                         End_Box (N), Centred => True);
            if A.Has_Description or else Clipped or else not Name_Fits then
               Entry_Text := A.Name;
               if Clipped then
                  Append (Entry_Text, " (" & Clause & ")");
               end if;
               if A.Has_Description then
                  Append (Entry_Text, ": " & FC.Reflow (A.Description));
               end if;
               Add_Line (Parts.Attacks, To_String (Entry_Text));
            end if;
         end;
      end loop;
   end Put_Attacks;

   ---------------------------------------------------------------------
   --  Pages.
   ---------------------------------------------------------------------

   procedure Put_Page_1 (P : SM.Page_1; Parts : in out Owner_Parts) is
      Stat : constant SF.Face := SW.Condensed_Semibold;
   begin
      IO.Put_Line (".SP p1");
      if not Put_Line_In (To_String (P.Title), SW.Regular, 120, 80,
                          Character_Name, Centred => False)
        and then Length (Parts.Name) = 0
      then
         Parts.Name := P.Title;
      end if;
      if P.Has_Player
        and then not Put_Line_In (To_String (P.Player), SW.Regular, 120, 80,
                                  Player_Name, Centred => False)
        and then Length (Parts.Player) = 0
      then
         Parts.Player := P.Player;
      end if;
      Put_Rows (Parts, P.Abilities, Ability_Dice_X, Ability_Name_X);
      Put_Rows (Parts, P.Weaknesses, Weakness_Dice_X, Weakness_Name_X);
      Put_Attacks (Parts, P.Attacks);
      declare
         Notes : Unbounded_String;
      begin
         if Length (P.NPC_Type) > 0 then
            Notes := "NPC Type: " & P.NPC_Type;
         end if;
         if P.Has_Combat_Notes then
            Add_Line (Notes, FC.Reflow (P.Combat_Notes));
         end if;
         if Length (Notes) > 0 then
            declare
               Fitted : Unbounded_String;
            begin
               Fit_Block (To_String (Notes), Notes_Look, Combat_Notes, Notes_Leading,
                          Fitted, Parts.Combat_Notes);
               Put_Block (To_String (Fitted), Notes_Look, Combat_Notes, Notes_Leading);
            end;
         end if;
      end;
      if P.Has_Stats then
         Put_Line_In (To_String (P.Defense), Stat, 180, 80, Defense_Box, Centred => True);
         Put_Line_In (To_String (P.Health), Stat, 180, 80, Health_Box, Centred => True);
         Put_Line_In (To_String (P.Endurance), Stat, 180, 80, Endurance_Box, Centred => True);
         Put_Line_In (To_String (P.Threat_Value), Stat, 180, 80, TV_Box, Centred => True);
      end if;
   end Put_Page_1;

   --  A part of the continuation pages: a heading, then each line of
   --  Content a paragraph.
   type Section is record
      Label, Content : Unbounded_String;
   end record;

   package Section_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Section);

   procedure Add_Section (Sections : in out Section_Vectors.Vector;
                          Label : String; Content : String) is
   begin
      if Content /= "" then
         Sections.Append ((To_Unbounded_String (Label), To_Unbounded_String (Content)));
      end if;
   end Add_Section;

   procedure Add_Owner_Sections (Sections : in out Section_Vectors.Vector;
                                 Owner : String; Parts : Owner_Parts) is
   begin
      Add_Section (Sections, Owner & ": Name", To_String (Parts.Name));
      Add_Section (Sections, Owner & ": Player Name", To_String (Parts.Player));
      Add_Section (Sections, Owner & ": Ability Notes", To_String (Parts.Ability_Notes));
      Add_Section (Sections, Owner & ": Attacks", To_String (Parts.Attacks));
      Add_Section (Sections, Owner & ": Combat Notes (continued)",
                   To_String (Parts.Combat_Notes));
   end Add_Owner_Sections;

   --  Text as one filled troff line: `\&` first, so that it can't be
   --  read as a request.
   procedure Put_Text (Text : String) is
   begin
      IO.Put_Line ("\&" & Escape (Dashes (Text)));
   end Put_Text;

   procedure Put_Sections (Sections : Section_Vectors.Vector) is
   begin
      if Sections.Is_Empty then
         return;
      end if;
      IO.Put_Line (".CP");
      for S of Sections loop
         IO.Put_Line (".SH");
         Put_Text (To_String (S.Label));
         declare
            C    : constant String := To_String (S.Content);
            From : Positive := C'First;
            To   : Natural;
         begin
            while From <= C'Last loop
               To := From;
               while To <= C'Last and then C (To) /= LF loop
                  To := To + 1;
               end loop;
               if To > From then
                  IO.Put_Line (".PP");
                  Put_Text (C (From .. To - 1));
               end if;
               From := To + 1;
            end loop;
         end;
      end loop;
   end Put_Sections;

   ---------------------------------------------------------------------
   --  Output.
   ---------------------------------------------------------------------

   --  The page is the sheet's; every placed line sets its own face and
   --  size. L places a line's baseline Y points from the top and X
   --  from the left. SP starts a sheet page and reports it; CP starts
   --  a continuation page, with margins of half an inch and a footer
   --  trap; SH and PP are its headings and paragraphs.
   Preamble : constant array (Positive range <>) of access constant String :=
     (new String'(".\"" ova_fmt -S: the OVA character sheet's values, to be typeset"),
      new String'(".\"" with groff -k -Tpdf and laid over the blank sheet (ova_sheet.sh)."),
      new String'(".pl 595.276p"),
      new String'(".po 0"),
      new String'(".nh"),
      new String'(".ad l"),
      new String'(".defcolor ovared rgb 0.47 0.11 0.13"),
      new String'(".nr started 0"),
      new String'(".nr cont 0"),
      new String'(".de L"),
      new String'(".sp |\\$1p-1p"),
      new String'(".in \\$2p"),
      new String'(".."),
      new String'(".de HD"),
      new String'(".if \\n[cont] 'sp |36p"),
      new String'(".."),
      new String'(".wh 0 HD"),
      new String'(".de FT"),
      new String'("'bp"),
      new String'(".."),
      new String'(".de SP"),
      new String'(".ch FT"),
      new String'(".nr cont 0"),
      new String'(".if \\n[started] .bp"),
      new String'(".nr started 1"),
      new String'(".nf"),
      new String'(".vs 1p"),
      new String'(".tm ova-sheet-page \\n% \\$1"),
      new String'(".."),
      new String'(".de CP"),
      new String'(".nr cont 1"),
      new String'(".if \\n[started] .bp"),
      new String'(".nr started 1"),
      new String'(".wh -40p FT"),
      new String'(".fi"),
      new String'(".in 36p"),
      new String'(".ll 383.528p"),
      new String'(".vs 11p"),
      new String'(".."),
      new String'(".de PT"),
      new String'(".if d ova-portrait-\\$1 \\X'pdf: pdfpic \\*[ova-portrait-\\$1] -L \\$2p \\$3p'"),
      new String'(".."),
      new String'(".de SH"),
      new String'(".sp 8p"),
      new String'(".ne 4v"),
      new String'(".ft NSB"),
      new String'(".ps 10"),
      new String'(".."),
      new String'(".de PP"),
      new String'(".br"),
      new String'(".ft NSR"),
      new String'(".ps 9"),
      new String'(".sp 3p"),
      new String'(".."));

   --  The portrait: -P's, or else E's own, a relative path taken from
   --  the YAML file's directory. ova_sheet.sh finds the comment,
   --  converts the image to a PDF, and defines ova-portrait-N as its
   --  name for PT, which places it with its top left at the box's, as
   --  large as fits; without that, PT places nothing.
   procedure Put_Portrait (E : Entities.Entity) is
      Path : Unbounded_String;
      R    : Rect renames Portrait_Box;
   begin
      if Config.Portrait /= null then
         Path := To_Unbounded_String (Config.Portrait.all);
      elsif E.Has_Portrait and then Length (E.Portrait) > 0 then
         Path := E.Portrait;
         if Element (Path, 1) /= '/' and then Config.Source_Dir /= null then
            Path := Config.Source_Dir.all & Path;
         end if;
      end if;
      if Length (Path) = 0 or else Index (Path, (1 => LF)) > 0 then
         return;
      end if;
      Portraits := Portraits + 1;
      declare
         Size : constant String := Img (Portraits) & " " & Pt (R.W) & " " & Pt (R.H);
      begin
         IO.Put_Line (".\"" ova-sheet-portrait " & Size & " " & To_String (Path));
         IO.Put_Line (".L " & Pt (Top (R)) & " " & Pt (R.X));
         IO.Put_Line (".PT " & Size);
      end;
   end Put_Portrait;

   procedure Process_Entity (E : Entities.Entity) is
      Pages    : constant SM.Page_1_Vectors.Vector := SM.Fill (E, Row_Lines'Access);
      Name     : constant String := To_String (E.Name);
      Sections : Section_Vectors.Vector;
      Fitted   : array (Prose_Field) of Unbounded_String;
      Parts    : Owner_Parts;

      procedure Main_Prose (P : Prose_Field; Has : Boolean; Text : Unbounded_String) is
         Content : constant String := (if Has then FC.Reflow (Text) else "");
         Rest    : Unbounded_String;
      begin
         if Content /= "" then
            Fit_Block (Content, Prose_Look, Prose_Rect (P), Prose_Leading, Fitted (P), Rest);
            Add_Section (Sections, Name & ": " & Prose_Name (P) & " (continued)",
                         To_String (Rest));
         end if;
      end Main_Prose;
   begin
      if First_Entity then
         for Line of Preamble loop
            IO.Put_Line (Line.all);
         end loop;
         First_Entity := False;
      end if;

      Main_Prose (Background, E.Has_Background, E.Background);
      Main_Prose (Appearance, E.Has_Appearance, E.Appearance);
      Main_Prose (Personality, E.Has_Personality, E.Personality);
      Main_Prose (Other_Notes, E.Has_Other_Notes, E.Other_Notes);

      for I in Pages.First_Index .. Pages.Last_Index loop
         if I > Pages.First_Index and then not Pages (I).Continued then
            Add_Owner_Sections (Sections, To_String (Pages (I - 1).Owner), Parts);
            Parts := (others => Null_Unbounded_String);
         end if;
         Put_Page_1 (Pages (I), Parts);
      end loop;
      Add_Owner_Sections (Sections, To_String (Pages.Last_Element.Owner), Parts);

      for N of E.Notes loop
         Add_Section (Sections, Name & ": " & To_String (N.Header), FC.Reflow (N.Text));
      end loop;
      if E.Has_Character_Hooks then
         Add_Section (Sections, Name & ": Character Hooks", FC.Reflow (E.Character_Hooks));
      end if;

      IO.Put_Line (".SP p2");
      for P in Prose_Field loop
         Put_Block (To_String (Fitted (P)), Prose_Look, Prose_Rect (P), Prose_Leading);
      end loop;
      Put_Portrait (E);

      Put_Sections (Sections);
   end Process_Entity;

end Ova_Fmt.Format_Sheet;
