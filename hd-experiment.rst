.. Pipeline check for hd-experiment.ms: confirms the exact hdtbl
   markup in that file survives being embedded in a ``.. raw:: ms``
   block and run through the same ``pandoc -r rst -w ms
   --template=tkb -o build/%.ms.pdf`` command GNUmakefile's real
   ``.ms.pdf`` rule uses, i.e. the same shape the groff-in-reST backend
   (PLAN.md section 9 step 6) will need to produce from
   Ova_Fmt.Format_Groff (or wherever it lands). See hd-experiment.ms
   for the findings this confirmed.

Nested Table Pipeline Test
===========================

Text before the table.

.. raw:: ms

   .mso hdtbl.tmac
   .TBL cols=2 border=.5p bc=black csp=2p cpd=2p width='10% 90%'
   .CPTN val=b Abilities
   .TR
   .TH Level
   .TH Name
   .TR
   .TD hal=r +2
   .TD Companion (Azyrus)
   .TR
   .TD hal=r +4
   .TD
   Transformation
   .TBL cols=2 border=.5p bc=black csp=2p cpd=2p width='10% 90%'
   .TR
   .TD hal=r +2
   .TD Attack
   .TR
   .TD hal=r \-1
   .TD Bizarre Appearance (Cat Features)
   .ETB
   .TR
   .TD hal=r +15
   .TD \fBTotal Ability Levels\fP
   .ETB

Text after the table.
