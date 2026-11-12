package body Ova_Fmt.Sheet_Fonts is

   package SW renames Ova_Fmt.Sheet_Widths;

   function Name (F : Face) return String is
     (case F is
         when SW.Regular            => "NSR",
         when SW.Italic             => "NSI",
         when SW.Light_Italic       => "NSLI",
         when SW.Bold               => "NSB",
         when SW.Condensed_Semibold => "NSCSB");

   --  ASCII 32 .. 126 are the first 95 entries, Latin-1 160 .. 255 the
   --  next 96, then the extras.
   function Char_Width (Code : Natural; F : Face) return Natural is
   begin
      if Code in 32 .. 126 then
         return SW.Widths (F) (Code - 31);
      elsif Code in 160 .. 255 then
         return SW.Widths (F) (Code - 64);
      end if;
      for I in SW.Extras'Range loop
         if SW.Extras (I) = Code then
            return SW.Widths (F) (191 + I);
         end if;
      end loop;
      return 1000;
   end Char_Width;

   function Text_Width (S : String; F : Face) return Natural is
      W    : Natural := 0;
      I    : Positive := S'First;
      B    : Natural;
      Code : Natural;
      More : Natural;  --  continuation bytes still to come
   begin
      while I <= S'Last loop
         B := Character'Pos (S (I));
         if B < 16#80# then
            Code := B;
            More := 0;
         elsif B in 16#C2# .. 16#DF# then
            Code := B - 16#C0#;
            More := 1;
         elsif B in 16#E0# .. 16#EF# then
            Code := B - 16#E0#;
            More := 2;
         elsif B in 16#F0# .. 16#F4# then
            Code := B - 16#F0#;
            More := 3;
         else
            Code := Natural'Last;  --  not a lead byte
            More := 0;
         end if;
         I := I + 1;
         while More > 0 loop
            if I <= S'Last and then Character'Pos (S (I)) in 16#80# .. 16#BF# then
               Code := Code * 64 + Character'Pos (S (I)) - 16#80#;
               I := I + 1;
               More := More - 1;
            else
               --  Cut short: the bytes read count as one character.
               Code := Natural'Last;
               More := 0;
            end if;
         end loop;
         if Code < 32 then
            null;  --  control characters set nothing
         else
            W := Natural'Min (W + Char_Width (Code, F), Max_Text_Width);
         end if;
      end loop;
      return W;
   end Text_Width;

   function Upper (S : String) return String is
      R : String := S;
   begin
      for C of R loop
         if C in 'a' .. 'z' then
            C := Character'Val (Character'Pos (C) - 32);
         end if;
      end loop;
      return R;
   end Upper;

end Ova_Fmt.Sheet_Fonts;
