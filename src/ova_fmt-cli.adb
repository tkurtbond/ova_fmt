package body Ova_Fmt.Cli is

   package Config renames Ova_Fmt.Config;

   function Do_Help return Boolean is
   begin
      Arg_Parser.Usage (The_Parser);
      raise Help_Requested;
      return False;
   end Do_Help;

   function Do_Gemtext return Boolean is
   begin
      Config.Format := Config.Gemtext;
      return True;
   end Do_Gemtext;

   function Do_Markdown return Boolean is
   begin
      Config.Format := Config.Markdown;
      return True;
   end Do_Markdown;

   function Do_Html return Boolean is
   begin
      Config.Format := Config.Html_In_Rst;
      return True;
   end Do_Html;

   function Do_Groff return Boolean is
   begin
      Config.Format := Config.Groff_In_Rst;
      return True;
   end Do_Groff;

   function Do_Hmm return Boolean is
   begin
      Config.Format := Config.Hmm;
      return True;
   end Do_Hmm;

   function Do_Subunderliner (Arg : String) return Boolean is
   begin
      if Arg'Length /= 1 then
         raise Arg_Parser.Invalid_Option_Argument with
           "-U/--subunderliner takes exactly one character, got """ &
           Arg & '"';
      end if;
      Config.Subunderliner := Arg (Arg'First);
      return True;
   end Do_Subunderliner;

   function Do_Underliner (Arg : String) return Boolean is
   begin
      if Arg'Length /= 1 then
         raise Arg_Parser.Invalid_Option_Argument with
           "-u/--underliner takes exactly one character, got """ &
           Arg & '"';
      end if;
      Config.Underliner := Arg (Arg'First);
      return True;
   end Do_Underliner;

   function Do_Argument (Start_With : Positive; Arg : String) return Boolean is
      pragma Unreferenced (Start_With);
   begin
      Filenames.Append (Ada.Strings.Unbounded.To_Unbounded_String (Arg));
      return True;
   end Do_Argument;

   procedure Parse is
   begin
      Arg_Parser.Parse_Arguments (The_Parser);
   end Parse;

end Ova_Fmt.Cli;
