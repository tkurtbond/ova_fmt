with PDF_Out;      use PDF_Out;
with Fukiko_Style; use Fukiko_Style;

--  Phase 1 of the Fukiko-page experiment (see PLAN.md): the graphical
--  skeleton of rulebook pp. 36-37 (PDF pp. 38-39) -- shapes, fills, and
--  rules only, with no text at all. Labels come in phase 2, lorem-ipsum
--  prose in phase 3.

procedure Ova_Pdf is

   Pdf : PDF_Out_File;

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

      --  Dotted rule below the banner.
      Dotted_HRule (Pdf, 24.0, 384.0, 85.0);

      --  Left column: "Background" heading rule (narrow column, leaving
      --  room at its right for where the character art used to be).
      Solid_HRule (Pdf, 43.0, 197.0, 100.0);

      --  Right column, below where the art ends: "Personality" and
      --  "Lovely Savior Myu Myu" heading rules.
      Solid_HRule (Pdf, 214.0, 389.0, 393.0);
      Solid_HRule (Pdf, 214.0, 389.0, 502.0);

      --  Bottom dotted rule (mirrors the one under the banner).
      Dotted_HRule (Pdf, 24.0, 384.0, 566.0);
   end Draw_Page_36_Graphics;

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
      Stat_Row_Y     : constant := 415.0;  --  Divider above DEFENSE/../TV
      Row_Ys : constant array (1 .. 4) of Real := (259.0, 304.0, 348.0, 394.0);
      Col_Xs : constant array (1 .. 3) of Real := (288.0, 319.0, 350.0);
      Stat_Col_Xs : constant array (1 .. 3) of Real := (222.0, 271.0, 331.0);
   begin
      --  Top dotted rule (mirrors the one that would sit under the page
      --  header, and the one on page 36).
      Pdf.Stroking_Color (Maroon);
      Dotted_HRule (Pdf, 17.0, 384.0, 31.0);

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

begin
   Pdf.Create ("Fukiko-experiment.pdf");
   Pdf.Page_Setup (Page_Rect);
   Pdf.Margins ((0.0, 0.0, 0.0, 0.0));

   Draw_Page_36_Graphics;
   Pdf.New_Page;
   Draw_Page_37_Graphics;

   Pdf.Close;
end Ova_Pdf;
