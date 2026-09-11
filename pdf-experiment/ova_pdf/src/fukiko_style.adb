package body Fukiko_Style is

   function Top_XY (X, Y : Real) return Point is
     ((x => X, y => Page_Height - Y));

   function Top_Rect (X, Y, W, H : Real) return Rectangle is
     ((x_min => X, y_min => Page_Height - Y - H, width => W, height => H));

   function All_Corners (R : Real) return Corner_Radii is
     ((Top_Left | Top_Right | Bottom_Right | Bottom_Left => R));

   procedure Rounded_Rect
     (Pdf       : in out PDF_Out_Stream'Class;
      What      :        Rectangle;
      Radii     :        Corner_Radii;
      Rendering :        Path_Rendering_Mode)
   is
      X : Real renames What.x_min;
      Y : Real renames What.y_min;
      W : Real renames What.width;
      H : Real renames What.height;
      TL : Real renames Radii.Top_Left;
      TR : Real renames Radii.Top_Right;
      BR : Real renames Radii.Bottom_Right;
      BL : Real renames Radii.Bottom_Left;
   begin
      --  Start just after the bottom-left corner, then walk the four
      --  edges counterclockwise, cutting each rounded corner with a
      --  quarter-circle Arc (or leaving it square when its radius is 0).
      if BL > 0.0 then
         Move (Pdf, (X + BL, Y));
      else
         Move (Pdf, (X, Y));
      end if;

      if BR > 0.0 then
         Line (Pdf, (X + W - BR, Y));
         Arc (Pdf, (X + W - BR, Y + BR), BR, -90.0, 0.0, True);
      else
         Line (Pdf, (X + W, Y));
      end if;

      if TR > 0.0 then
         Line (Pdf, (X + W, Y + H - TR));
         Arc (Pdf, (X + W - TR, Y + H - TR), TR, 0.0, 90.0, True);
      else
         Line (Pdf, (X + W, Y + H));
      end if;

      if TL > 0.0 then
         Line (Pdf, (X + TL, Y + H));
         Arc (Pdf, (X + TL, Y + H - TL), TL, 90.0, 180.0, True);
      else
         Line (Pdf, (X, Y + H));
      end if;

      if BL > 0.0 then
         Line (Pdf, (X, Y + BL));
         Arc (Pdf, (X + BL, Y + BL), BL, 180.0, 270.0, True);
      else
         Line (Pdf, (X, Y));
      end if;

      Finish_Path
        (Pdf, close_path => True, rendering => Rendering,
         rule => nonzero_winding_number);
   end Rounded_Rect;

   procedure Solid_HRule
     (Pdf                : in out PDF_Out_Stream'Class;
      X1, X2, Y_From_Top :        Real;
      Width              :        Real := 0.75)
   is
   begin
      Pdf.Line_Width (Width);
      Pdf.Single_Line (Top_XY (X1, Y_From_Top), Top_XY (X2, Y_From_Top));
   end Solid_HRule;

   procedure Dotted_HRule
     (Pdf                : in out PDF_Out_Stream'Class;
      X1, X2, Y_From_Top :        Real;
      Gap                :        Real := 4.0;
      Dot_Diameter       :        Real := 1.8)
   is
   begin
      Pdf.Line_Width (Dot_Diameter);
      Pdf.Insert_Graphics_PDF_Code ("1 J");  --  Round line cap.
      Pdf.Insert_Graphics_PDF_Code ("[0 " & Img (Gap) & "] 0 d");
      Pdf.Single_Line (Top_XY (X1, Y_From_Top), Top_XY (X2, Y_From_Top));
      Pdf.Insert_Graphics_PDF_Code ("[] 0 d");  --  Restore a solid stroke.
      Pdf.Insert_Graphics_PDF_Code ("0 J");     --  Restore a butt cap.
   end Dotted_HRule;

   procedure Text
     (Pdf   : in out PDF_Out_Stream'Class;
      X, Y  :        Real;
      Font  :        Standard_Font_Type;
      Size  :        Real;
      Col   :        Color_Type;
      S     :        String)
   is
   begin
      Pdf.Font (Font);
      Pdf.Font_Size (Size);
      Pdf.Color (Col);
      Pdf.Put_XY (Top_XY (X, Y), S);
   end Text;

   procedure Solid_VRule
     (Pdf                          : in out PDF_Out_Stream'Class;
      X, Y1_From_Top, Y2_From_Top :        Real;
      Width                        :        Real := 0.5)
   is
   begin
      Pdf.Line_Width (Width);
      Pdf.Single_Line (Top_XY (X, Y1_From_Top), Top_XY (X, Y2_From_Top));
   end Solid_VRule;

end Fukiko_Style;
