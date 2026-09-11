with PDF_Out;      use PDF_Out;
with Fukiko_Style; use Fukiko_Style;

--  Phase 1 of the Fukiko-page experiment (see PLAN.md): the graphical
--  skeleton of rulebook pp. 36-37 (PDF pp. 38-39) -- shapes, fills, and
--  rules only, with no text at all. Labels come in phase 2, lorem-ipsum
--  prose in phase 3.

procedure Ova_Pdf is

   Pdf : PDF_Out_File;

   --  Attacks & Combat Stats geometry, shared between the labels
   --  (name/tag/ROLL-DX-END) and text (lorem-ipsum description) passes.
   Attack_X   : constant := 180.0;
   Roll_Col_L : constant := 288.0;
   Dx_Col_L   : constant := 319.0;
   End_Col_L  : constant := 350.0;
   Box_Right  : constant := 380.0;
   Name_Col_W : constant := Roll_Col_L - Attack_X - 6.0;
   Row_Tops   : constant array (1 .. 4) of Real :=
     (216.0, 259.0, 304.0, 348.0);

   --  Y position just below each row's (possibly word-wrapped) tag line,
   --  filled in by Draw_Page_37_Labels and read back by Draw_Page_37_Text
   --  so each lorem-ipsum description starts right after the actual tag
   --  text instead of a guessed fixed offset.
   Tag_End_Y : array (1 .. 4) of Real := (others => 0.0);

   ------------------------------------------------------------------
   --  Page 36 (left page): name banner + section-heading rules.    --
   ------------------------------------------------------------------

   procedure Draw_Page_36_Graphics is
      Banner_Radius : constant := 10.0;
   begin
      --  Name banner (wide bar) and its brighter left-end "tab".
      Pdf.Color (Maroon);
      Rounded_Rect
        (Pdf, Top_Rect (24.0, 40.0, 317.0, 43.0),
         All_Corners (Banner_Radius), fill);
      Pdf.Color (Bright_Maroon);
      Rounded_Rect
        (Pdf, Top_Rect (24.0, 40.0, 120.0, 43.0),
         All_Corners (Banner_Radius), fill);

      Pdf.Stroking_Color (Maroon);

      --  Left column: "Background" heading rule (narrow column, leaving
      --  room at its right for where the character art used to be).
      Solid_HRule (Pdf, 43.0, 197.0, 102.0);

      --  Right column, below where the art ends: "Personality" and
      --  "Lovely Savior Myu Myu" heading rules.
      Solid_HRule (Pdf, 214.0, 389.0, 393.0);
      Solid_HRule (Pdf, 214.0, 389.0, 502.0);
   end Draw_Page_36_Graphics;

   --------------------------------------------------------------
   --  Page 36 labels: name, tagline, and the three section     --
   --  headings (no body prose yet -- that is phase 3).         --
   --------------------------------------------------------------

   procedure Draw_Page_36_Labels is
   begin
      Text (Pdf, 34.0, 73.0, Helvetica_Bold, 30.0, White, "Fukiko");

      Text (Pdf, 43.0, 97.0, Helvetica_Bold, 13.0, Maroon, "Background");
      Text (Pdf, 214.0, 390.0, Helvetica_Bold, 13.0, Maroon, "Personality");
      Text
        (Pdf, 214.0, 499.0, Helvetica_Bold, 11.0, Maroon,
         "Lovely Savior Myu Myu");
   end Draw_Page_36_Labels;

   ------------------------------------------------------------------
   --  Page 36 prose: the tagline (a short flavor quote in the      --
   --  original) and the Background/Personality/Lovely Savior Myu   --
   --  Myu body paragraphs -- lorem ipsum throughout, per PLAN.md's  --
   --  copyright-conscious scope (only game-mechanical data is      --
   --  transcribed faithfully; narrative prose is not).             --
   ------------------------------------------------------------------

   procedure Draw_Page_36_Text is
      Lorem_1 : constant String :=
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit, " &
        "sed do eiusmod tempor incididunt ut labore et dolore magna " &
        "aliqua. Ut enim ad minim veniam, quis nostrud exercitation " &
        "ullamco laboris nisi ut aliquip ex ea commodo consequat.";
      Lorem_2 : constant String :=
        "Duis aute irure dolor in reprehenderit in voluptate velit " &
        "esse cillum dolore eu fugiat nulla pariatur. Excepteur sint " &
        "occaecat cupidatat non proident, sunt in culpa qui officia " &
        "deserunt mollit anim id est laborum.";
      Lorem_3 : constant String :=
        "Sed ut perspiciatis unde omnis iste natus error sit " &
        "voluptatem accusantium doloremque laudantium, totam rem " &
        "aperiam, eaque ipsa quae ab illo inventore veritatis.";
      Lorem_4 : constant String :=
        "Nemo enim ipsam voluptatem quia voluptas sit aspernatur " &
        "aut odit aut fugit, sed quia consequuntur magni dolores " &
        "eos qui ratione voluptatem sequi nesciunt.";
      Lorem_5 : constant String :=
        "Neque porro quisquam est, qui dolorem ipsum quia dolor " &
        "sit amet, consectetur adipisci velit.";
   begin
      Text
        (Pdf, 160.0, 57.0, Helvetica_Bold, 7.5, White,
         "LOREM IPSUM DOLOR SIT AMET CONSECTETUR");
      Text
        (Pdf, 160.0, 67.0, Helvetica_Bold, 7.5, White,
         "ADIPISCING ELIT SED DO EIUSMOD TEMPOR!");

      declare
         Y : constant Real :=
           Paragraph
             (Pdf, 43.0, 114.0, 154.0, Times_Roman, 9.0, 11.5, Ink, Lorem_1);
         Ignore : constant Real :=
           Paragraph
             (Pdf, 43.0, Y + 5.0, 154.0, Times_Roman, 9.0, 11.5, Ink, Lorem_2);
         pragma Unreferenced (Ignore);
      begin
         null;
      end;

      declare
         Ignore : constant Real :=
           Paragraph
             (Pdf, 214.0, 403.0, 175.0, Times_Roman, 9.0, 11.5, Ink, Lorem_3);
         pragma Unreferenced (Ignore);
      begin
         null;
      end;

      declare
         Y : constant Real :=
           Paragraph
             (Pdf, 214.0, 512.0, 175.0, Times_Roman, 9.0, 11.5, Ink, Lorem_4);
         Ignore : constant Real :=
           Paragraph
             (Pdf, 214.0, Y + 5.0, 175.0, Times_Roman, 9.0, 11.5, Ink,
              Lorem_5);
         pragma Unreferenced (Ignore);
      begin
         null;
      end;
   end Draw_Page_36_Text;

   ------------------------------------------------------------------
   --  Page 37 (right page): Abilities/Weaknesses panel and the      --
   --  Attacks & Combat Stats box.                                   --
   ------------------------------------------------------------------

   procedure Draw_Page_37_Graphics is
      Panel_Radius   : constant := 10.0;
      Box_Radius     : constant := 10.0;
      Attacks_X      : constant := 170.0;
      Attacks_W      : constant := 210.0;
      Attacks_Top    : constant := 190.0;
      Header_H       : constant := 26.0;
      Attacks_H      : constant := 266.0;
      Stat_Row_Y     : constant := 394.0;  --  Divider above DEFENSE/../TV
      Row_Ys : constant array (1 .. 3) of Real := (259.0, 304.0, 348.0);
      Col_Xs : constant array (1 .. 3) of Real := (288.0, 319.0, 350.0);
      Stat_Col_Xs : constant array (1 .. 3) of Real := (222.0, 271.0, 331.0);
   begin
      Pdf.Stroking_Color (Maroon);

      --  Abilities/Weaknesses panel.
      Pdf.Color (Panel_Bg);
      Rounded_Rect
        (Pdf, Top_Rect (42.0, 42.0, 342.0, 152.0),
         All_Corners (Panel_Radius), fill);

      Pdf.Stroking_Color (Maroon);
      Solid_HRule (Pdf, 42.0, 202.0, 59.0);   --  "ABILITIES" heading rule
      Solid_HRule (Pdf, 221.0, 384.0, 59.0);  --  "WEAKNESSES" heading rule
      Solid_VRule (Pdf, 206.0, 46.0, 190.0);  --  column divider

      --  Attacks & Combat Stats box: white body with a thin maroon
      --  border, topped by a solid maroon header bar (rounded only at
      --  the top, since it sits flush on the body below it).
      Pdf.Color (White);
      Rounded_Rect
        (Pdf, Top_Rect (Attacks_X, Attacks_Top, Attacks_W, Attacks_H),
         All_Corners (Box_Radius), fill);

      Pdf.Stroking_Color (Maroon);
      Pdf.Line_Width (0.75);
      Rounded_Rect
        (Pdf, Top_Rect (Attacks_X, Attacks_Top, Attacks_W, Attacks_H),
         All_Corners (Box_Radius), stroke);

      Pdf.Color (Maroon);
      Rounded_Rect
        (Pdf, Top_Rect (Attacks_X, Attacks_Top, Attacks_W, Header_H),
         (Top_Left => Box_Radius, Top_Right => Box_Radius, others => 0.0),
         fill);

      --  Row dividers between the four attacks, and the heavier divider
      --  above the closing DEFENSE/HEALTH/ENDURANCE/TV stat row.
      Pdf.Stroking_Color (Maroon);
      for Y of Row_Ys loop
         Solid_HRule (Pdf, Attacks_X, Attacks_X + Attacks_W, Y);
      end loop;
      Solid_HRule (Pdf, Attacks_X, Attacks_X + Attacks_W, Stat_Row_Y, 1.0);

      --  Vertical dividers separating the description column from the
      --  ROLL / DX / END sub-columns, running the height of all 4 rows.
      for X of Col_Xs loop
         Solid_VRule (Pdf, X, Attacks_Top + Header_H, Stat_Row_Y);
      end loop;

      --  Vertical dividers within the closing stat row, and the
      --  inverted (maroon-filled) TV cell in its bottom-right corner.
      for X of Stat_Col_Xs loop
         Solid_VRule (Pdf, X, Stat_Row_Y, Attacks_Top + Attacks_H);
      end loop;

      Pdf.Color (Maroon);
      Rounded_Rect
        (Pdf,
         Top_Rect
           (Stat_Col_Xs (3), Stat_Row_Y,
            Attacks_X + Attacks_W - Stat_Col_Xs (3),
            Attacks_Top + Attacks_H - Stat_Row_Y),
         (Bottom_Right => Box_Radius, others => 0.0), fill);
   end Draw_Page_37_Graphics;

   ------------------------------------------------------------------
   --  Page 37 labels: headings, ability/weakness names & values,   --
   --  Other Statistics fields, and the Attacks & Combat Stats      --
   --  table's names/tags/numbers (attack *descriptions* are prose  --
   --  and come in phase 3).                                        --
   ------------------------------------------------------------------

   procedure Draw_Page_37_Labels is

      Val_Font   : constant Standard_Font_Type := Helvetica_Bold;
      Trait_Font : constant Standard_Font_Type := Times_Italic;
      List_Size  : constant := 8.5;
      Line_H     : constant := 9.6;

      --  One Abilities/Weaknesses line: a bold value in the gutter and
      --  an italic trait name/description to its right.
      procedure Ability_Line
        (X_Val, X_Trait, Y : Real;
         Value, Trait      : String;
         Size               : Real := List_Size)
      is
      begin
         Text (Pdf, X_Val, Y, Val_Font, Size, Maroon, Value);
         Text (Pdf, X_Trait, Y, Trait_Font, Size, Ink, Trait);
      end Ability_Line;

      Y : Real;

      --  Other Statistics: a small-caps-style bold label followed by a
      --  plain value on the same line, the value positioned right after
      --  the label's actual rendered width (via Bounding_Box).
      procedure Field (Label, Value : String; Y : Real) is
         X : constant := 42.0;
      begin
         Text (Pdf, X, Y, Helvetica_Bold, 7.5, Ink, Label & ' ');
         Text
           (Pdf, X + Pdf.Bounding_Box (Label & ' ').width, Y,
            Times_Roman, 7.5, Ink, Value);
      end Field;

      --  Same as Field, but word-wraps a value too long to fit before
      --  the Attacks & Combat Stats box (e.g. ENEMIES), continuing at
      --  the same indent as the value's first line.
      procedure Field_Wrap (Label, Value : String; Y : Real) is
         X     : constant := 42.0;
         Val_X : Real;
      begin
         Text (Pdf, X, Y, Helvetica_Bold, 7.5, Ink, Label & ' ');
         Val_X := X + Pdf.Bounding_Box (Label & ' ').width;
         declare
            Next_Y : constant Real :=
              Paragraph
                (Pdf, Val_X, Y, Attack_X - 8.0 - Val_X, Times_Roman, 7.5,
                 9.0, Ink, Value);
            pragma Unreferenced (Next_Y);
         begin
            null;
         end;
      end Field_Wrap;

      --  Each attack row's name, word-wrapped tag line (its perks/flaws
      --  and affinities), and centered ROLL / DX / END caption+number.
      procedure Attack_Row
        (Idx : Positive; Name, Tag : String; Roll, Dx, End_V : String)
      is
         Top : constant Real := Row_Tops (Idx);
      begin
         Text (Pdf, Attack_X, Top + 11.0, Helvetica_Bold, 8.0, Maroon, Name);
         Tag_End_Y (Idx) :=
           Paragraph
             (Pdf, Attack_X, Top + 19.5, Name_Col_W, Helvetica_Bold, 5.5,
              6.2, Ink, Tag);

         Centered_Text
           (Pdf, Roll_Col_L, Dx_Col_L - Roll_Col_L, Top + 11.0,
            Helvetica_Bold, 7.5, Maroon, "ROLL");
         Centered_Text
           (Pdf, Dx_Col_L, End_Col_L - Dx_Col_L, Top + 11.0,
            Helvetica_Bold, 7.5, Maroon, "DX");
         Centered_Text
           (Pdf, End_Col_L, Box_Right - End_Col_L, Top + 11.0,
            Helvetica_Bold, 7.5, Maroon, "END");

         Centered_Text
           (Pdf, Roll_Col_L, Dx_Col_L - Roll_Col_L, Top + 36.0,
            Helvetica_Bold, 20.0, Ink, Roll);
         Centered_Text
           (Pdf, Dx_Col_L, End_Col_L - Dx_Col_L, Top + 36.0,
            Helvetica_Bold, 20.0, Ink, Dx);
         Centered_Text
           (Pdf, End_Col_L, Box_Right - End_Col_L, Top + 36.0,
            Helvetica_Bold, 20.0, Ink, End_V);
      end Attack_Row;

   begin
      Text (Pdf, 42.0, 56.0, Helvetica_Bold, 13.0, Maroon, "ABILITIES");
      Text (Pdf, 221.0, 56.0, Helvetica_Bold, 13.0, Maroon, "WEAKNESSES");

      --  Abilities column.
      Y := 68.0;
      Ability_Line (50.0, 68.0, Y, "+2", "Companion (Azyrus)");
      Y := Y + Line_H;
      Ability_Line (50.0, 68.0, Y, "+2", "Cute!"); Y := Y + Line_H;
      Ability_Line (50.0, 68.0, Y, "+1", "Iron-Willed"); Y := Y + Line_H;
      Ability_Line (50.0, 68.0, Y, "+2", "Knowledge (Shoujo Manga)");
      Y := Y + Line_H;
      Ability_Line (50.0, 68.0, Y, "+2", "Quick"); Y := Y + Line_H;
      Ability_Line (50.0, 68.0, Y, "+2", "Shape-Shifter"); Y := Y + Line_H;
      Ability_Line (50.0, 68.0, Y, "+4", "Transformation"); Y := Y + Line_H;
      Ability_Line (68.0, 84.0, Y, "+2", "Attack", 7.5); Y := Y + 8.5;
      Ability_Line
        (68.0, 84.0, Y, "+3", "Barrier (Area Effect; Elaborate", 7.5);
      Y := Y + 8.5;
      Text (Pdf, 92.0, Y, Trait_Font, 7.5, Ink, "Gestures; 5 End)");
      Y := Y + 8.5;
      Ability_Line (68.0, 84.0, Y, "+2", "Combat Expert", 7.5); Y := Y + 8.5;
      Ability_Line (68.0, 84.0, Y, "+2", "Healer", 7.5); Y := Y + 8.5;
      Ability_Line
        (68.0, 84.0, Y, "-1", "Bizarre Appearance (Cat Features)", 7.5);

      --  Weaknesses column.
      Y := 68.0;
      Ability_Line (229.0, 247.0, Y, "-2", "Ageism"); Y := Y + Line_H;
      Ability_Line (229.0, 247.0, Y, "-2", "Crybaby"); Y := Y + Line_H;
      Ability_Line (229.0, 247.0, Y, "-1", "Easily Distracted");
      Y := Y + Line_H;
      Ability_Line (229.0, 247.0, Y, "-2", "Focus (Powers Require Neko");
      Y := Y + Line_H;
      Text
        (Pdf, 255.0, Y, Trait_Font, List_Size, Ink, "Transformation Locket)");
      Y := Y + Line_H;
      Ability_Line (229.0, 247.0, Y, "-1", "Frail"); Y := Y + Line_H;
      Ability_Line (229.0, 247.0, Y, "-1", "Naive");

      --  Other Statistics.
      Text
        (Pdf, 42.0, 203.0, Helvetica_Bold, 10.0, Maroon, "OTHER STATISTICS");
      Y := 216.0;
      Field ("CONCEPT:", "Magical Meow Meow Girl", Y); Y := Y + 11.0;
      Field ("BIRTHDAY:", "July 26", Y); Y := Y + 11.0;
      Field ("AGE:", "12", Y); Y := Y + 11.0;
      Field ("GENDER:", "Female", Y); Y := Y + 11.0;
      Field ("HEIGHT:", "4'10""", Y); Y := Y + 11.0;
      Field ("WEIGHT:", "85 lbs.", Y); Y := Y + 11.0;
      Field ("HAIR:", "Blonde", Y); Y := Y + 11.0;
      Field ("EYES:", "Blue", Y); Y := Y + 11.0;
      Field ("ASSOCIATION:", "Middle School", Y); Y := Y + 11.0;
      Field ("HOBBIES:", "Shoujo Manga", Y); Y := Y + 11.0;
      Field ("FAVE FOOD:", "Chocolate", Y); Y := Y + 11.0;
      Field ("ALLIES:", "Azyrus", Y); Y := Y + 11.0;
      Field_Wrap ("ENEMIES:", "Sinister Folk and Their Minions", Y);

      --  Attacks & Combat Stats.
      Text
        (Pdf, Attack_X, 211.0, Helvetica_Bold, 15.0, White,
         "Attacks & Combat Stats");

      Attack_Row
        (1, "Neko Neko Catnip Cantrip",
         "RANGED, AFFINITY: LOVE", "4", "3", "0");
      Attack_Row
        (2, "Neko Neko Heart Burst",
         "EFFECTIVE X2, RANGED, AFFINITY: LOVE", "4", "5", "10");
      Attack_Row
        (3, "Neko Neko Wave",
         "AREA EFFECT X2, STUNNING, AFFINITY: LOVE; NO DAMAGE",
         "4", "0", "10");
      Attack_Row
        (4, "Neko Neko Yarn Entangle",
         "PARALYZING, AFFINITY: LOVE", "4", "3", "10");

      --  Closing DEFENSE / HEALTH / ENDURANCE / TV stat row.
      Text (Pdf, 178.0, 406.0, Helvetica_Bold, 8.5, Maroon, "DEFENSE");
      Text (Pdf, 230.0, 406.0, Helvetica_Bold, 8.5, Maroon, "HEALTH");
      Text (Pdf, 274.0, 406.0, Helvetica_Bold, 8.0, Maroon, "ENDURANCE");
      Text (Pdf, 347.0, 406.0, Helvetica_Bold, 8.5, White, "TV");

      Text (Pdf, 178.0, 432.0, Helvetica_Bold, 20.0, Ink, "4/5");
      Text (Pdf, 238.0, 432.0, Helvetica_Bold, 20.0, Ink, "30");
      Text (Pdf, 288.0, 432.0, Helvetica_Bold, 20.0, Ink, "40");
      Text (Pdf, 347.0, 432.0, Helvetica_Bold, 20.0, White, "12");
   end Draw_Page_37_Labels;

   ------------------------------------------------------------------
   --  Page 37 prose: the four attack descriptions, the paragraph   --
   --  continuing from page 36's "Lovely Savior Myu Myu" section,   --
   --  and the "Azyrus" heading + paragraph (its "Attributes:" line --
   --  is game-mechanical data, so it is transcribed as a label).   --
   ------------------------------------------------------------------

   procedure Draw_Page_37_Text is
      Desc_1 : constant String :=
        "Lorem ipsum dolor sit amet consectetur adipiscing elit sed " &
        "do eiusmod tempor incididunt ut labore.";
      Desc_2 : constant String :=
        "Ut enim ad minim veniam quis nostrud exercitation ullamco " &
        "laboris nisi ut aliquip ex ea commodo.";
      Desc_3 : constant String := "Duis aute irure dolor in reprehenderit.";
      Desc_4 : constant String :=
        "In voluptate velit esse cillum dolore eu fugiat nulla " &
        "pariatur excepteur sint occaecat.";
      Continuation : constant String :=
        "Cupidatat non proident, sunt in culpa qui officia deserunt " &
        "mollit anim id est laborum. Sed ut perspiciatis unde omnis " &
        "iste natus error sit voluptatem accusantium doloremque " &
        "laudantium, totam rem aperiam.";
      Azyrus_Para : constant String :=
        "Eaque ipsa quae ab illo inventore veritatis et quasi " &
        "architecto beatae vitae dicta sunt explicabo. Nemo enim " &
        "ipsam voluptatem quia voluptas sit aspernatur aut odit.";
      Ignore : Real;
      pragma Unreferenced (Ignore);
   begin
      Ignore :=
        Paragraph
          (Pdf, Attack_X, Tag_End_Y (1) + 1.5, Name_Col_W,
           Times_Italic, 6.0, 6.2, Ink, Desc_1);
      Ignore :=
        Paragraph
          (Pdf, Attack_X, Tag_End_Y (2) + 1.5, Name_Col_W,
           Times_Italic, 6.0, 6.2, Ink, Desc_2);
      Ignore :=
        Paragraph
          (Pdf, Attack_X, Tag_End_Y (3) + 1.5, Name_Col_W,
           Times_Italic, 6.0, 6.2, Ink, Desc_3);
      Ignore :=
        Paragraph
          (Pdf, Attack_X, Tag_End_Y (4) + 1.5, Name_Col_W,
           Times_Italic, 6.0, 6.2, Ink, Desc_4);

      Ignore :=
        Paragraph
          (Pdf, 43.0, 470.0, 154.0, Times_Roman, 9.0, 11.5, Ink, Continuation);

      Text (Pdf, 214.0, 470.0, Helvetica_Bold, 12.0, Maroon, "Azyrus");
      Ignore :=
        Paragraph
          (Pdf, 214.0, 484.0, 175.0, Times_Roman, 9.0, 11.5, Ink, Azyrus_Para);

      Text (Pdf, 214.0, 550.0, Helvetica_Bold, 8.0, Ink, "Attributes:");
      Ignore :=
        Paragraph
          (Pdf, 214.0, 560.0, 175.0, Times_Roman, 8.0, 9.5, Ink,
           "Flight +2, Quick +1, Smart +2; Awkward Size (Small) -1, " &
           "Frail -1, Short-Tempered -1");
   end Draw_Page_37_Text;

begin
   Pdf.Create ("Fukiko-experiment.pdf");
   Pdf.Page_Setup (Page_Rect);
   Pdf.Margins ((0.0, 0.0, 0.0, 0.0));

   Draw_Page_36_Graphics;
   Draw_Page_36_Labels;
   Draw_Page_36_Text;
   Pdf.New_Page;
   Draw_Page_37_Graphics;
   Draw_Page_37_Labels;
   Draw_Page_37_Text;

   Pdf.Close;
end Ova_Pdf;
