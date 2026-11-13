with Ada.Text_IO;

package body Ova_Fmt.Sheet_Draw is

   --  Coordinates in points, x from the left and y from the top, as L
   --  takes them; the blank sheet's from the bottom are 595.276 - y.
   --
   --  AT Y X places the next output line's baseline, in any units.
   --  RF X Y W H R COLOUR fills a rectangle, top left (X, Y), with
   --  corners rounded by R: two crossed rectangles and a circle in each
   --  corner. A stroked frame is one filled rectangle on another.  HR
   --  and VR are the Combat Stats grid's 0.5 pt rules, across and down;
   --  each polygon and rule ends where it began, so that the line's
   --  vertical position doesn't move.  The dots string is one of the
   --  dotted rules on the Abilities and Weaknesses boxes: 1 pt dots
   --  2.003 pt apart.  TX X Y FACE HEIGHT WIDTH COLOUR TEXT sets a
   --  label with its baseline at Y, HEIGHT points high and scaled
   --  across (\s, with \H keeping the height) to WIDTH points, the
   --  label's width on the sheet, whose faces are narrower than Noto's.
   --  Sizes are in u, a thousandth of a point under -Tpdf: \s'Nz' would
   --  be N points.
   --
   --  Continuation pages harmonize with the sheet's: FR-cp is a grey
   --  ground and a white panel framed in red under a red "Continued"
   --  title bar, as the Combat Stats box is, and SH's headings are red
   --  as page 2's are. HD, the top-of-page trap, draws it on every
   --  continuation page, those groff breaks to as well, in its own
   --  environment, so that the text's fill, indent, font and colour
   --  are left alone. FT does nothing while a page is drawn: the
   --  drawing passes the footer trap, which would break the page.
   --  Inside .de, \\n is read when the macro runs, \n when it is
   --  defined.
   Macros : constant array (Positive range <>) of access constant String :=
     (new String'(".\"" ova-sheet-redrawn"),
      new String'(".\"" -R: the sheet's frames and labels drawn here, not taken from the"),
      new String'(".\"" blank sheet; FR-p1 and FR-p2 draw a page's, under its text."),
      new String'(".defcolor ovasheetgrey cmyk 0.065 0.1 0.072 0"),
      new String'(".defcolor ovasheetred rgb 0.451 0.114 0.126"),
      new String'(".de AT"),
      new String'(".sp |\\$1-1p"),
      new String'(".in \\$2"),
      new String'(".."),
      new String'(".de RF"),
      new String'(".nr rf-x \\$1p"),
      new String'(".nr rf-y \\$2p"),
      new String'(".nr rf-w \\$3p"),
      new String'(".nr rf-h \\$4p"),
      new String'(".nr rf-r \\$5p"),
      new String'(".nr rf-d 2*\\n[rf-r]"),
      new String'(".AT \\n[rf-y]u+\\n[rf-r]u \\n[rf-x]u"),
      new String'("\M[\\$6]\D'P \\n[rf-w]u 0 0 \\n[rf-h]u-\\n[rf-d]u -\\n[rf-w]u 0 0 \\n[rf-d]u-\\n[rf-h]u'\M[]"),
      new String'(".AT \\n[rf-y]u \\n[rf-x]u+\\n[rf-r]u"),
      new String'("\M[\\$6]\D'P \\n[rf-w]u-\\n[rf-d]u 0 0 \\n[rf-h]u \\n[rf-d]u-\\n[rf-w]u 0 0 -\\n[rf-h]u'\M[]"),
      new String'(".if \\n[rf-r] \{\"),
      new String'(".AT \\n[rf-y]u+\\n[rf-r]u \\n[rf-x]u"),
      new String'("\M[\\$6]\D'C \\n[rf-d]u'\h'\\n[rf-w]u-\\n[rf-d]u-\\n[rf-d]u'\D'C \\n[rf-d]u'\M[]"),
      new String'(".AT \\n[rf-y]u+\\n[rf-h]u-\\n[rf-r]u \\n[rf-x]u"),
      new String'("\M[\\$6]\D'C \\n[rf-d]u'\h'\\n[rf-w]u-\\n[rf-d]u-\\n[rf-d]u'\D'C \\n[rf-d]u'\M[]"),
      new String'(".\}"),
      new String'(".."),
      new String'(".de HR"),
      new String'(".AT \\$2p \\$1p"),
      new String'("\m[ovasheetred]\D't 0.5p'\D'l \\$3p 0'\m[]"),
      new String'(".."),
      new String'(".de VR"),
      new String'(".AT \\$2p \\$1p"),
      new String'("\m[ovasheetred]\D't 0.5p'\D'l 0 \\$3p'\v'-\\$3p'\m[]"),
      new String'(".."),
      new String'(".ds dots"),
      new String'(".nr dots 0 1"),
      new String'(".while \n+[dots]<=177 .as dots \M[ovasheetgrey]\D'C 1p'\M[]\h'1.003p'"),
      new String'(".de TX"),
      new String'(".AT \\$2p \\$1p"),
      new String'(".ds tx-f \\$3"),
      new String'(".nr tx-h \\$4p"),
      new String'(".nr tx-t \\$5p"),
      new String'(".ds tx-c \\$6"),
      new String'(".shift 6"),
      new String'(".nr tx-w \w'\f[\\*[tx-f]]\s'\\n[tx-h]u'\\$*'"),
      new String'(".nr tx-s \\n[tx-h]/10*\\n[tx-t]/(\\n[tx-w]/10)"),
      new String'("\f[\\*[tx-f]]\s'\\n[tx-s]u'\H'\\n[tx-h]u'\m[\\*[tx-c]]\\$*\m[]\H'0'\s[0]\f[]"),
      new String'(".."),
      new String'(".de FR-p1"),
      new String'(".RF 23.75 364.846 412.75 201.87 8 ovasheetgrey"),
      new String'(".RF -8.64 85.866 404.64 250.75 8 ovasheetgrey"),
      new String'(".RF 100.47 31.306 336 34.7 12.3 ovasheetred"),
      new String'(".RF 146.47 36 129.778 18 5.76 white"),
      new String'(".RF 282.334 36 127.666 18 5.76 white"),
      new String'(".RF 34.47 103.996 18 228.44 5.76 white"),
      new String'(".RF 56.47 103.996 153.29 228.44 5.76 white"),
      new String'(".RF 216.47 103.996 18 228.44 5.76 white"),
      new String'(".RF 238.47 103.996 153.29 228.44 5.76 white"),
      new String'(".nr dots 0"),
      new String'(".while \\n[dots]<17 \{\"),
      new String'(".AT 119.116p+(\\n[dots]u*13p) 36.6p"),
      new String'("\\*[dots]"),
      new String'(".nr dots +1"),
      new String'(".\}"),
      new String'(".RF 27.75 388.366 120.72 174.35 8 white"),
      new String'(".RF 140.86 358.996 247.22 220.37 15 ovasheetred"),
      new String'(".RF 142.86 360.996 243.22 216.37 13 white"),
      new String'(".RF 140.86 345.996 247.22 27.62 12 ovasheetred"),
      new String'(".RF 140.86 363.996 247.22 9.62 0 ovasheetred"),
      new String'(".HR 145.47 412.996 238.03"),
      new String'(".HR 145.47 452.746 238.03"),
      new String'(".HR 145.47 491.746 238.03"),
      new String'(".HR 145.47 530.746 238.03"),
      new String'(".VR 281.47 376.366 154.38"),
      new String'(".VR 316.47 376.366 154.38"),
      new String'(".VR 348.47 376.366 154.38"),
      new String'(".TX 147.37 61.496 NSXCB 8 36.9 white CHARACTER NAME"),
      new String'(".TX 282.3 61.496 NSXCB 8 30.57 white PLAYER NAME"),
      new String'(".TX 37.35 99.416 NSXCB 14 32.63 black ABILITIES"),
      new String'(".TX 219.02 99.416 NSXCB 14 46.79 black WEAKNESSES"),
      new String'(".TX 34.02 381.416 NSXCB 14 54.36 black COMBAT NOTES"),
      new String'(".TX 33.02 559.066 NSXCB 12 95.17 ovasheetgrey DAMAGE, COMPLICATIONS, ETC."),
      new String'(".TX 146.47 369.646 NSXCB 24 94.25 white Combat Stats"),
      new String'(".TX 284.33 385.496 NSR 11 28.14 ovasheetred ROLL"),
      new String'(".TX 324.33 385.496 NSR 11 15.16 ovasheetred DX"),
      new String'(".TX 354.33 385.496 NSR 11 23.23 ovasheetred END"),
      new String'(".TX 284.33 423.496 NSR 11 28.14 ovasheetred ROLL"),
      new String'(".TX 324.33 423.496 NSR 11 15.16 ovasheetred DX"),
      new String'(".TX 354.33 423.496 NSR 11 23.23 ovasheetred END"),
      new String'(".TX 284.33 463.496 NSR 11 28.14 ovasheetred ROLL"),
      new String'(".TX 324.33 463.496 NSR 11 15.16 ovasheetred DX"),
      new String'(".TX 354.33 463.496 NSR 11 23.23 ovasheetred END"),
      new String'(".TX 284.33 502.496 NSR 11 28.14 ovasheetred ROLL"),
      new String'(".TX 324.33 502.496 NSR 11 15.16 ovasheetred DX"),
      new String'(".TX 354.33 502.496 NSR 11 23.23 ovasheetred END"),
      new String'(".TX 148.47 541.496 NSR 11 48.01 ovasheetred DEFENSE"),
      new String'(".TX 211.47 541.496 NSR 11 43.05 ovasheetred HEALTH"),
      new String'(".TX 271.48 541.496 NSR 11 68.31 ovasheetred ENDURANCE"),
      new String'(".TX 356.47 541.496 NSR 11 13.61 ovasheetred TV"),
      new String'(".."),
      new String'(".de FR-p2"),
      new String'(".RF 0 0 419.528 595.276 0 ovasheetgrey"),
      new String'(".RF 32.78 19.346 238.22 307.93 8 white"),
      new String'(".RF 31.78 340.066 172 165.3 8 white"),
      new String'(".RF 211.36 340.066 172 165.3 8 white"),
      new String'(".RF 31.78 516.116 351.58 58.5 8 white"),
      new String'(".RF 238.78 0 166.22 36.006 0 ovasheetred"),
      new String'(".RF 238.78 17.996 166.22 310.62 14 ovasheetred"),
      new String'(".RF 240.78 19.996 162.22 306.62 12 white"),
      new String'(".TX 36.4 36.996 NSXCB 16 58.88 ovasheetred Background"),
      new String'(".TX 36 356.996 NSXCB 16 58.51 ovasheetred Appearance"),
      new String'(".TX 219.76 356.996 NSXCB 16 58 ovasheetred Personality"),
      new String'(".TX 36 534 NSXCB 16 60.59 ovasheetred Other Notes"),
      new String'(".TX 285.02 14.996 NSXCB 12 73.74 ovasheetgrey CHARACTER PORTRAIT"),
      new String'(".."),
      new String'(".\"" -R: continuation pages drawn to match the sheet's; HD draws each one."),
      new String'(".de FR-cp"),
      new String'(".RF 0 0 419.528 595.276 0 ovasheetgrey"),
      new String'(".RF 31.78 37 351.58 540 15 ovasheetred"),
      new String'(".RF 33.78 39 347.58 536 13 white"),
      new String'(".RF 31.78 24 351.58 27.62 12 ovasheetred"),
      new String'(".RF 31.78 42 351.58 9.62 0 ovasheetred"),
      new String'(".TX 37.39 47.65 NSXCB 24 73.83 white Continued"),
      new String'(".."),
      new String'(".nr drawing 0"),
      new String'(".de FT"),
      new String'(".if !\\n[drawing] 'bp"),
      new String'(".."),
      new String'(".de HD"),
      new String'(".if \\n[cont] \{\"),
      new String'(".nr drawing 1"),
      new String'(".ev ova-draw"),
      new String'(".nf"),
      new String'(".vs 1p"),
      new String'(".FR-cp"),
      new String'(".ev"),
      new String'(".nr drawing 0"),
      new String'("'sp |64p"),
      new String'(".\}"),
      new String'(".."),
      new String'(".am CP"),
      new String'(".in 44p"),
      new String'(".ll 371p"),
      new String'(".."),
      new String'(".am SH"),
      new String'(".ft NSCSB"),
      new String'(".ps 12"),
      new String'(".gcolor ovasheetred"),
      new String'(".."),
      new String'(".am PP"),
      new String'(".gcolor default"),
      new String'(".."));


   --  -C's page 1, in the same terms: the sheet's header, a column of
   --  lines for the Abilities and Weaknesses (no Dice boxes and no dots,
   --  as in the rulebook), and an Attacks & Combat Stats box built as
   --  the sheet's Combat Stats box is, with five attack slots 39.5 pt
   --  apart, a Combat Notes space and the four stats along its bottom.
   --  New labels are scaled as the sheet's own are, by their measured
   --  width in Noto Sans times its ratio for the sheet's labels. CR is
   --  the faint rule between the Abilities and the Weaknesses.
   One_Column_Macros : constant array (Positive range <>) of access constant String :=
     (new String'(".\"" -C: page 1 as one column beside an Attacks & Combat Stats box."),
      new String'(".defcolor ovasheetrule gray 0.75"),
      new String'(".de CR"),
      new String'(".RF 40.47 \\$1 124 0.6 0 ovasheetrule"),
      new String'(".."),
      new String'(".de FR-p1c"),
      new String'(".RF -8.64 85.866 404.64 490 8 ovasheetgrey"),
      new String'(".RF 100.47 31.306 336 34.7 12.3 ovasheetred"),
      new String'(".RF 146.47 36 129.778 18 5.76 white"),
      new String'(".RF 282.334 36 127.666 18 5.76 white"),
      new String'(".RF 34.47 103.996 136 462 5.76 white"),
      new String'(".RF 176.47 116.996 215.29 449 15 ovasheetred"),
      new String'(".RF 178.47 118.996 211.29 445 13 white"),
      new String'(".RF 176.47 103.996 215.29 27.62 12 ovasheetred"),
      new String'(".RF 176.47 121.996 215.29 9.62 0 ovasheetred"),
      new String'(".HR 181.08 170.996 206.1"),
      new String'(".HR 181.08 210.496 206.1"),
      new String'(".HR 181.08 249.996 206.1"),
      new String'(".HR 181.08 289.496 206.1"),
      new String'(".HR 181.08 328.996 206.1"),
      new String'(".HR 181.08 517.376 206.1"),
      new String'(".VR 285.15 134.366 194.63"),
      new String'(".VR 320.15 134.366 194.63"),
      new String'(".VR 352.15 134.366 194.63"),
      new String'(".TX 147.37 61.496 NSXCB 8 36.9 white CHARACTER NAME"),
      new String'(".TX 282.3 61.496 NSXCB 8 30.57 white PLAYER NAME"),
      new String'(".TX 37.35 99.416 NSXCB 14 87.31 black ABILITIES & WEAKNESSES"),
      new String'(".TX 182.08 124.95 NSXCB 20 137.2 white Attacks & Combat Stats"),
      new String'(".TX 288.01 143.516 NSR 11 28.14 ovasheetred ROLL"),
      new String'(".TX 328.01 143.516 NSR 11 15.16 ovasheetred DX"),
      new String'(".TX 358.01 143.516 NSR 11 23.23 ovasheetred END"),
      new String'(".TX 288.01 183.016 NSR 11 28.14 ovasheetred ROLL"),
      new String'(".TX 328.01 183.016 NSR 11 15.16 ovasheetred DX"),
      new String'(".TX 358.01 183.016 NSR 11 23.23 ovasheetred END"),
      new String'(".TX 288.01 222.516 NSR 11 28.14 ovasheetred ROLL"),
      new String'(".TX 328.01 222.516 NSR 11 15.16 ovasheetred DX"),
      new String'(".TX 358.01 222.516 NSR 11 23.23 ovasheetred END"),
      new String'(".TX 288.01 262.016 NSR 11 28.14 ovasheetred ROLL"),
      new String'(".TX 328.01 262.016 NSR 11 15.16 ovasheetred DX"),
      new String'(".TX 358.01 262.016 NSR 11 23.23 ovasheetred END"),
      new String'(".TX 288.01 301.516 NSR 11 28.14 ovasheetred ROLL"),
      new String'(".TX 328.01 301.516 NSR 11 15.16 ovasheetred DX"),
      new String'(".TX 358.01 301.516 NSR 11 23.23 ovasheetred END"),
      new String'(".TX 184.47 341.496 NSR 11 85.63 ovasheetred COMBAT NOTES"),
      new String'(".TX 182.47 528.126 NSR 11 48.01 ovasheetred DEFENSE"),
      new String'(".TX 236 528.126 NSR 11 43.05 ovasheetred HEALTH"),
      new String'(".TX 285.85 528.126 NSR 11 68.31 ovasheetred ENDURANCE"),
      new String'(".TX 366.2 528.126 NSR 11 13.61 ovasheetred TV"),
      new String'(".."));

   procedure Put_Preamble (One_Column : Boolean) is
   begin
      for Line of Macros loop
         Ada.Text_IO.Put_Line (Line.all);
      end loop;
      if One_Column then
         for Line of One_Column_Macros loop
            Ada.Text_IO.Put_Line (Line.all);
         end loop;
      end if;
   end Put_Preamble;

end Ova_Fmt.Sheet_Draw;
