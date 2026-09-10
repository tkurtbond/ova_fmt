.\" hd-layout-experiment2.ms -- revised per the user: Companion/Vehicle
.\" sub-entities are no longer nested *inside* a table cell of the
.\" granting Ability's row. Instead they print as their own separate
.\" section after the main character's own content, structurally
.\" self-similar to the main character (own side-by-side Abilities/
.\" Weaknesses, own "Attacks & Combat Stats" box) -- matching what the
.\" rulebook's own Karis/Arasuni spread actually does (PLAN.md 2.3:
.\" Arasuni gets his own boxed "Attacks & Combat Stats (ARASUNI)",
.\" laid out alongside Karis's own, not folded into her Abilities
.\" table). This keeps every individual .TBL well under the ~28-row
.\" silent-overflow ceiling found in hd-layout-experiment.ms's first
.\" attempt: Transformation/Magic's short flat sub-lists still nest
.\" directly in the granting row's cell (they're not full sub-entities
.\" and stay small), only Companion/Vehicle move out.
.\"
.\" Second finding while rebuilding this: staying under the per-table
.\" row ceiling isn't sufficient by itself. A table also vanishes
.\" silently if it doesn't fit in whatever space is left on the
.\" *current* page -- it does NOT automatically flow onto a fresh page
.\" the way ordinary text does. Confirmed by removing the `.ne` lines
.\" below: under plain `groff -ms`, Arasuni's Combat table (page 2,
.\" right after his side-by-side Abilities/Weaknesses tables) vanished
.\" with no error; through the real Pandoc/pdfroff pipeline (different
.\" font metrics from plain -ms), Karis's OWN Combat box and the Other
.\" Statistics box vanished too, for the same reason. Fix: a plain
.\" troff `.ne <estimated height>` immediately before every top-level
.\" `.TBL` -- ordinary core-troff "need this much space or start a new
.\" page" bookkeeping, nothing hd-specific -- forces each table onto a
.\" fresh page whenever it wouldn't otherwise fit, instead of
.\" disappearing. Every `.ne` below is a rough hand estimate (rows
.\" times a per-row height guess plus header/caption); the real
.\" backend will need this computed per table from its actual row
.\" count, not eyeballed.
.mso hdtbl.tmac
.
.LP
.B "Karis (Hotheaded Space-Trekking Bounty Hunter)"
.br
.I "\(lqI'm every bit as tough as my father was, and I'll prove it by avenging his death!\(rq"
.LP
A bounty hunter avenging her father's death, aided by her GPL-issued
robotic partner Arasuni.
.LP
[Background / Personality prose omitted -- unchanged from Terse.]
.LP
.\" ---- Karis's own Abilities (left) / Weaknesses (right) ----
.ne 4.5i
.TBL cols=2 border=0 csp=4p cpd=0
.TR
.TD
.TBL cols=2 border=.5p bc=black csp=2p cpd=2p width='15% 85%'
.CPTN val=b Abilities
.TR
.TH Level
.TH Name
.TR
.TD hal=r +3
.TD Agile
.TR
.TD hal=r +3
.TD Attack (Boomerang)
.TR
.TD hal=r +1
.TD Combat Expert
.TR
.TD hal=r +2
.TD Companion (Arasuni) \(em see below
.TR
.TD hal=r +1
.TD Cute!
.TR
.TD hal=r +1
.TD Evasive
.TR
.TD hal=r +1
.TD Intuitive
.TR
.TD hal=r +1
.TD Perceptive
.TR
.TD hal=r +3
.TD Quick
.ETB
.TD
.TBL cols=2 border=.5p bc=black csp=2p cpd=2p width='15% 85%'
.CPTN val=b Weaknesses
.TR
.TH Level
.TH Name
.TR
.TD hal=r \-1
.TD Bizarre Appearance (Strange Ears)
.TR
.TD hal=r \-1
.TD Impulsive
.TR
.TD hal=r \-3
.TD Obsession (Kill Shadowman)
.TR
.TD hal=r \-2
.TD Quirk (Stranger in a Strange Land)
.TR
.TD hal=r \-2
.TD Sensitivity (Chest)
.TR
.TD hal=r \-1
.TD Short-Tempered
.TR
.TD hal=r \-1
.TD Soft Spot (Stuffed Animals)
.ETB
.ETB
.LP
.\" ---- Karis's own Attacks & Combat Stats box ----
.ne 5i
.TBL cols=4 border=.5p bc=black csp=2p cpd=2p width='25% 25% 25% 25%'
.CPTN val=b "Attacks & Combat Stats (KARIS)"
.TR
.TH Name
.TH Roll
.TH DX
.TH End
.TR
.TD \fBKinetic Boomerang\fP
.TD hal=c 6
.TD hal=c 4
.TD hal=c 0
.TR
.TD colspan=4 [Perks: Armor Piercing, Ranged; Flaws: Weapon]
.TR
.TD colspan=4 \fIKaris's signature weapon can be wielded versatilely, both as a blade and a boomerang.\fP
.TR
.TD \fBTrick Shot\fP
.TD hal=c 6
.TD hal=c 3
.TD hal=c 0
.TR
.TD colspan=4 [Perks: Disarming, Ranged; Flaws: Ineffective, Weapon]
.TR
.TD colspan=4 \fIWith finesse, Karis throws her weapon in a tight arc to disarm opponents.\fP
.TR
.TD \fBSweeping Strike\fP
.TD hal=c 6
.TD hal=c 3
.TD hal=c 0
.TR
.TD colspan=4 [Perks: Multiple Targets, Ranged; Flaws: Ineffective, Weapon]
.TR
.TD colspan=4 \fITake down multiple foes in a single throw!\fP
.TR
.TD \fBFlex-Steel Cable\fP
.TD hal=c 6
.TD hal=c 1
.TD hal=c 0
.TR
.TD colspan=4 [Perks: Paralyzing x2, Ranged; Flaws: Ineffective x3, Weapon]
.TR
.TD colspan=4 \fIHer weapon can release a super-strong cable to entangle foes, among other creative uses.\fP
.TR
.TH Defense
.TH Health
.TH Endurance
.TH TV
.TR
.TD hal=c \fB6\fP
.TD hal=c \fB40\fP
.TD hal=c \fB40\fP
.TD hal=c \fB16\fP
.ETB
.LP
.\" ---- Other Statistics box ----
.ne 4.5i
.TBL cols=2 border=.5p bc=black csp=2p cpd=2p width='25% 75%'
.CPTN val=b "Other Statistics"
.TR
.TD \fBConcept\fP
.TD Hotheaded Space-Trekking Bounty Hunter
.TR
.TD \fBBirthday\fP
.TD March 23
.TR
.TD \fBAge\fP
.TD 18
.TR
.TD \fBGender\fP
.TD Female
.TR
.TD \fBHeight\fP
.TD 5'1"
.TR
.TD \fBWeight\fP
.TD 108 lbs.
.TR
.TD \fBHair\fP
.TD Reddish-Pink
.TR
.TD \fBEyes\fP
.TD Green
.TR
.TD \fBAssociation\fP
.TD Galactic Peace Legion Contract
.TR
.TD \fBHobbies\fP
.TD Collecting Stuffed Animals
.TR
.TD \fBFave Food\fP
.TD Milkshakes
.TR
.TD \fBAllies\fP
.TD Arasuni
.TR
.TD \fBEnemies\fP
.TD Shadowman
.ETB
.LP
.\" ---- Companion sub-entity, printed after Karis's own content, ----
.\" ---- structurally self-similar to a top-level character ----
.B "Companion: Arasuni"
.LP
.ne 4i
.TBL cols=2 border=0 csp=4p cpd=0
.TR
.TD
.TBL cols=2 border=.5p bc=black csp=2p cpd=2p width='15% 85%'
.CPTN val=b "Arasuni \(em Abilities"
.TR
.TH Level
.TH Name
.TR
.TD hal=r +2
.TD Armored
.TR
.TD hal=r +1
.TD Attack
.TR
.TD hal=r +1
.TD Combat Expert
.TR
.TD hal=r +1
.TD Evasive
.TR
.TD hal=r +3
.TD Life Support
.TR
.TD hal=r +3
.TD Strong
.TR
.TD hal=r +2
.TD Tough
.TR
.TD hal=r +1
.TD Unique Ability (Computerized Brain)
.ETB
.TD
.TBL cols=2 border=.5p bc=black csp=2p cpd=2p width='15% 85%'
.CPTN val=b "Arasuni \(em Weaknesses"
.TR
.TH Level
.TH Name
.TR
.TD hal=r \-1
.TD Awkward Size (Large)
.TR
.TD hal=r \-2
.TD Bizarre Appearance
.TR
.TD hal=r \-2
.TD Emotionless
.TR
.TD hal=r \-1
.TD Quirk (Quoting Earth)
.TR
.TD hal=r \-3
.TD Servitude (Karis)
.TR
.TD hal=r \-1
.TD Slow
.TR
.TD hal=r \-2
.TD Vulnerability (Electricity)
.ETB
.ETB
.LP
.ne 3.5i
.TBL cols=4 border=.5p bc=black csp=2p cpd=2p width='25% 25% 25% 25%'
.CPTN val=b "Attacks & Combat Stats (ARASUNI)"
.TR
.TH Name
.TH Roll
.TH DX
.TH End
.TR
.TD \fBIron Knuckle\fP
.TD hal=c 3
.TD hal=c 5
.TD hal=c 0
.TR
.TD colspan=4 [Affinity: Mighty Robot]
.TR
.TD colspan=4 \fIArasuni's immense size and strength allow him to deal a crushing blow.\fP
.TR
.TD \fBStun Pulse Rifle\fP
.TD hal=c 2
.TD hal=c 2
.TD hal=c 0
.TR
.TD colspan=4 [Perks: Impairing, Ranged; Flaws: Inaccurate, Weapon]
.TR
.TD colspan=4 \fIWhile not the most powerful of weapons, it is useful for subduing stubborn foes.\fP
.TR
.TH Defense
.TH Health
.TH Endurance
.TH TV
.TR
.TD hal=c \fB2\fP
.TD hal=c \fB40\fP
.TD hal=c \fB20\fP
.TD hal=c \fB10\fP
.ETB
