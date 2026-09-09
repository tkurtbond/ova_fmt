# ova_fmt: porting `ova-rst.scm` (and finishing the design) to Ada

**Status:** planning / not started. This repo
(`~/Repos/RPG/Tools/ova_fmt`) currently contains only `.git` (no
commits yet). This file exists so a future session has everything
needed to pick the work up without re-gathering context.

## 1. Relationship to `besm2_fmt`

This is the second port in the same family as
[`besm2_fmt`](https://github.com/tkurtbond/besm2_fmt)
(`~/Repos/RPG/Tools/besm2_fmt`, `PLAN.md` there), which converts a
YAML BESM 2nd Edition character into reST/terse/h-m-m/raw-ms output
and is **complete** (all four backends, byte-for-byte verified
against the original Chicken Scheme `besm2-rst.scm`). `besm2_fmt` is
the model to follow for tooling, package layout, and lessons already
learned — but **unlike `besm2_fmt`, this is not a straightforward
port of a working, finished Scheme program.** The OVA source and its
test data are both unfinished, and the OVA domain model has real
structural differences from BESM's that need actual design work, not
just translation. See §4 and §5.

## 2. Source materials

All of the following are copyrighted works (Dyskami Publishing's
*OVA: The Anime Role-Playing Game* and its ancillary products); the
user has the normal personal-use rights to their own purchased/created
copies, not redistribution rights. Treat text extracted from them as
private local reference material — don't paste large verbatim excerpts
into files that get committed to `ova_fmt`'s git repo (which may end
up with a public remote, as `besm2_fmt` did at
`github.com/tkurtbond/besm2_fmt`).

Location: `~/Reference/RPG/OVA/`

- `OVA_The_Anime_Role-Playing_Game.pdf` — the full rulebook (170 pages).
- `ova-rulebook.txt`, `ova-rulebook-not-layout.txt` — text extractions
  of the rulebook (`ova-rulebook.txt` preserves the original two-column
  page layout with page numbers/running headers, so it's slower to
  read start-to-end but its line numbers correspond to physical pages;
  `-not-layout` reflows to single-column and is easier to `grep`). Both
  have now been read/searched for the sections relevant to this plan
  (see §2.2 for what that turned up). Table of contents (from
  `ova-rulebook.txt`'s first page), useful for further navigation by
  either file's page markers: Introduction (9), Creating a Character
  (17), Sample Characters (23), Abilities & Weaknesses (49), Taking
  Action (93), Combat, Health, & Endurance (103), Growth & Experience
  (115), Game Master's Section (119), Sample NPCs (133), Appendix:
  Telling Anime Stories (148), Index (158), Character sheet (164).
  Useful section anchors found so far (line numbers in
  `ova-rulebook-not-layout.txt` unless noted):
  - Character creation "fluff" fields: ~line 700.
  - Limiting-the-character rules (Scaled Cost, Base Zero, Combined
    Effectiveness, Power Ceiling): ~line 735–805, and again with fuller
    treatment at "Base Zero" (11141), "Combined Effectiveness" (11190),
    "Power Ceiling" (11652), "Scaled Cost" (11745).
  - Sample Characters chapter starts ~line 857 (Raine first; see §2.2
    for the full chapter's significance for this project).
  - Magic, Arcane / Magic, Witchcraft rules: `ova-rulebook.txt` lines
    ~2461–2530 (Spell Endurance Cost table, spell-casting DN formula,
    the "a spell mimics another Ability's Level" mechanic — see §2.2).
  - Transformation: `ova-rulebook.txt` lines ~2786–2810. Vehicle
    (Mecha) and Companion (via `abilities.md`): `ova-rulebook.txt`
    lines ~2820–2832 for Vehicle — see §2.2 for the separate-Health/
    Endurance and non-cumulative-Abilities wrinkle.
  - Threat Value (GM-facing balancing number, `combat.tv`'s
    derivation): `ova-rulebook.txt` lines ~5684–5736.
- `OVA-Blank-Character-Sheet-Form-Fillable.pdf` — the official blank
  character sheet. Confirms the canonical field set (see §5).
- `OVAPlayerBook-Auren-2015-01-29.pdf`,
  `OVAPlayerBook-Miho-2015-01-29.pdf`,
  `OVAPlayerBook-Raine-2015-01-29.pdf` — 14-page pregenerated-character
  booklets (one of the sample characters each). The character-sheet
  spread (physical pages 4–5 of each PDF — labeled "2"/"3" in-page,
  offset by front/back cover pages) has been read for all three and is
  now the best available reference for what a *finished, laid-out*
  character write-up looks like — see §2.1. Good candidates for
  additional golden/test fixtures once the YAML schema is settled,
  since they're full worked characters with combat suites, background,
  etc. (Auren already has a partial test-data file, see §6.)
- `ova-ref.pdf` (16KB, 2 pages) — a reference sheet the user made
  themselves (not a Dyskami product, so no third-party copyright
  concern on this one specifically). Already read in full. Contents:
  Abilities index with page numbers and a `(A)`/`(D)`/`(DX)`/`(I)`
  legend for which roll type each Ability affects; Weaknesses index;
  Perks and Flaws tables with Endurance cost and page numbers (Perks
  positive-Endurance-cost, Flaws negative, some marked `/M` = "can be
  taken multiple times" or `/n` = "can be taken n times"); Affinities
  page pointer; core mechanics summary (Taking Action, Difficulty
  Numbers, Initiative, Attack/Defend, Damage, Combat Complications,
  Drama Dice, Damaging Other Things, Other Combat Actions, Spell
  Endurance Cost table, Spell Casting Roll formula, NPC tiers). This is
  the best single condensed source for the game's numeric rules and is
  worth re-reading closely once designing the "derived stats" /
  validation side of the tool (if any — see open questions).
- `abilities.md` (98 lines), `weaknesses.md` (220 lines) — apparently
  hand-transcribed (or extracted) full-text Markdown of every Ability's
  and Weakness's rules description, keyed by **bold name** headers.
  Useful as a name/canonical-spelling reference and for any
  "look up this ability's description" feature, but not yet cross
  checked against the ref sheet's page-number index for completeness.
- `~/Reference/Document-Tools/lout/` — Basser Lout documentation, not
  OVA-specific: `design.pdf` (design rationale), `expert.pdf`
  (advanced/extension-level reference), `slides.pdf` (overview slide
  deck), `user.pdf` (the main user guide). Not yet read; earmarked for
  step 5 of §9's build order (the direct-to-Lout backend) —
  `user.pdf` is the likely primary reference for `@Doc`/`@Tbl` usage,
  `expert.pdf` for anything `Fukiko-experiment.lout` (§3) does that
  needs deeper explanation than the user guide covers.
- `OVA-Combat.odt`/`.pdf`, `OVA-ConversionGuide.pdf`,
  `OVA-Character-Sheet.ods`/`.pdf`,
  `OVA-Charsheet-Template-Google-Sheets.pdf`,
  `OVA-CharacterRecord-A4.pdf`/`-Letter.pdf`, `OVA-CharacterSheet.zip`,
  `ovasheet-new.pdf` — present in the directory but not yet reviewed;
  likely more character-sheet variants and a combat-rules cheat sheet.
  Check these before assuming the blank fillable sheet (§5) is the only
  layout reference.

### 2.1. Player-book character-sheet layout (read in full)

Physical pages 4–5 of each of the three player-book PDFs (Auren,
Miho, Raine) show a name/tagline header, two-column
Background/Personality prose (page 4), then a full character-sheet
spread (page 5): Abilities/Weaknesses two-column list, an "OTHER
STATISTICS" fluff block, and an "Attacks & Combat Stats" box. This is
real, professionally laid-out output for the exact data shape
`ova_fmt` needs to produce, so it's worth documenting precisely —
paraphrased/structural notes below, not verbatim prose (per §2's
copyright note):

- **Header**: character name (large), then a short italicized
  first-person tagline/catchphrase next to it (matches
  `Fukiko.yaml`'s `tagline`-shaped field, though the current test data
  doesn't actually have a `tagline` key — worth adding to the schema).
- **Background / Personality**: prose sections with bold section
  headers, laid out in two newspaper columns across the page. Maps
  directly onto `background`/`personality` in the existing test-data
  shape.
- **Abilities / Weaknesses** (two side-by-side columns, one heading
  each): each entry is a signed Level number in a narrow left column,
  then the Ability/Weakness name in italics, with a parenthetical
  detail where relevant (`Attack (Sword & Sorcery)`,
  `Code of Conduct (Protecting Women... Begrudgingly)`). **Nested
  items render two different ways depending on the parent ability**,
  a real finding not obvious from the test data alone:
  - Miho's `Transformation` ability (+1) has its own sub-abilities
    indented beneath it, and **each sub-item keeps its own leading
    signed Level** (`+2 Combat Expert`, `+2 Endurance Reserve`, `−3
    Unique Weakness (Loss of Control)` — note a Weakness nested inside
    an Ability's sub-list, not segregated into a separate
    sub-weaknesses column). This matches `Fukiko.yaml`'s
    `Transformation.abilities`/`.weaknesses` shape (each sub-item has
    its own `name`/`level`).
  - Auren's `Magic, Arcane` ability (+3) has its spells indented
    beneath it too, but **spells render with no separate leading
    Level at all** — just the spell name followed by a parenthetical
    summary folding in its Perks and Endurance cost as plain text
    (`Mana Shield (Barrier +2; 10+ Endurance)`, `Hasten (Quick +3; 20
    Endurance)`). This is a genuinely different rendering rule from
    Transformation's sub-abilities, not just a formatting accident —
    worth confirming against the rulebook's Magic section (p. 57–58)
    whether spells even *have* a Level of their own the way
    Transformation's sub-abilities do, or whether "Ability Level"
    there is more like a Perk grade. **Design consequence:** the Ada
    domain model likely needs to distinguish at least two kinds of
    "linked ability" content (Transformation/Companion/Vehicle-style
    sub-abilities-with-levels vs. Magic-style spells-with-perks-and-
    no-own-level), not treat all nesting uniformly — matches
    `Auren.yaml`'s existing `spell:`/`perks:` shape already looking
    different from `Fukiko.yaml`'s `Transformation.abilities` shape
    (§6), so this may not have been an accident/typo after all, but
    early recognition of this exact distinction.
- **"OTHER STATISTICS"** (the rendered fluff block): a bold-label
  colon-value list, one per line — `CONCEPT`, `BIRTHDAY`, `AGE` (Miho's
  shows a narrative aside: `1 (Appears 18)`, Auren's similarly `44
  (Appears 16)` — the character sheet's `age` field can carry
  prose, not just a bare number), `GENDER`, `HEIGHT`, `WEIGHT`,
  `HAIR`, `EYES` is *omitted* in all three samples (present in the
  rulebook's suggested field list and `fluff.yaml-partial`, but every
  finished sample here skips it), `ASSOCIATION`, `HOBBIES`, `FAVE
  FOOD` (label abbreviated from "Favorite Food" — cross-check against
  `Fukiko.yaml`'s `favorite-food` key, which spells it out fully;
  likely just a display-label abbreviation, not a schema difference),
  `ALLIES` (Auren/Raine: `None`), `ENEMIES`. **None of the three shows
  a Love Interest(s) line** even though it's in the rulebook's
  suggested fields and `fluff.yaml-partial` — apparently an
  omit-if-blank field, consistent with `ALLIES: None` showing rather
  than being omitted (i.e., the field is shown with an explicit "None"
  when applicable/known, but dropped entirely rather than shown blank
  when simply not used for that character — a distinction the schema
  and formatter should probably support: an explicit "None" value vs.
  an absent key are different things to render differently).
- **"Attacks & Combat Stats"** box: each attack is its own row/block,
  in this shape — bold attack **name**; a line of perks/flaws in
  small caps, **comma-separated Perks first, then a semicolon, then
  comma-separated Flaws** (e.g. `AREA EFFECT, ARMOR PIERCING,
  OVERWHELMING, RANGED, AFFINITY: ICE; FEATHER BLOW, INEFFECTIVE` —
  Perks before the `;`, Flaws after), with **`AFFINITY: <name>`
  embedded directly in the Perks list** rather than shown as its own
  field, and a repeatable perk/flaw's count rendered as a suffix on
  the name (`EFFECTIVE X2`, `INACCURATE X3`, `ACCURATE X2`) rather
  than as a separate number — confirms `ova-ref.pdf`'s `/M`
  ("multiple") perks/flaws use this `Name X<n>` convention in finished
  prose, not `Name (n)` or `Name: n`; then three large numbers under
  `ROLL` / `DX` / `END` headers; then one italicized sentence of
  flavor description. `Weapon` itself shows up as a **Flaw** tag on
  melee attacks (Raine's `Kaze Satsujinsha`: `ARMOR PIERCING; WEAPON`)
  — matches `ova-ref.pdf`'s Flaws table (`Weapon −5`) rather than
  being a separate attack property. After all attacks, one final
  summary row: `DEFENSE` / `HEALTH` / `ENDURANCE` / `TV`, each as one
  large number — all three player-book samples show a single plain
  Defense integer (Auren 4, Miho 5, Raine 5), unlike `Fukiko.yaml`'s
  paired `defense: "4/5"`; §2.2 (reading the primary rulebook, which
  includes all 12 sample characters rather than just these 3) confirms
  the pairing is real and not unique to Fukiko, just apparently
  optional per-character — see §2.2 and the open questions for what's
  now confirmed vs. still unexplained about it. Attacks render in
  table order *before* the Defense/Health/
  Endurance/TV summary — i.e. opposite of the field order
  `Fukiko.yaml`'s `combat:` mapping currently uses
  (`defense`/`health`/`endurance`/`threat-value` first, `attacks:`
  last); purely a presentation-order choice for a formatter to make,
  not something the YAML's own field order needs to match.
- **No worked example of Companion or Vehicle (Mecha) nesting** was
  seen in these three (none of Auren/Miho/Raine's sample sheets uses
  those two linked-ability types) — Transformation and Magic are the
  only two nesting shapes confirmed from primary sources so far.

### 2.2. Rulebook findings: the Sample Characters chapter, and three resolved modeling questions

Reading `ova-rulebook.txt` directly (rather than only the player books
and `ova-ref.pdf`) turned up one major resource and resolved several
of §2.1's/earlier open questions:

- **The rulebook's own "Sample Characters" chapter (p. 23–48) contains
  all twelve pregenerated characters' full write-ups**, in the exact
  same layout style documented in §2.1 (name/tagline header,
  Background/Personality prose, Abilities/Weaknesses columns, Other
  Statistics, Attacks & Combat Stats box) — the three player books
  (Auren, Miho, Raine) are just standalone excerpts of three of these
  twelve. **This is a substantially better golden-data source than
  either the player books or the hand-authored `test-data/*.yaml`
  files**: it's the original, primary presentation (confirmed
  byte-identical in content to what the Auren player book excerpts,
  so the player books are a reliable secondary check, not an
  independent source), and it covers 12 characters' worth of variety
  in one place — different combinations of nesting (or none),
  attack-suite sizes, fluff completeness, etc. — rather than 3. Found
  by locating each character's `Background` heading
  (`ova-rulebook.txt` lines 655, 772, 877, 1016, 1139, 1252, 1365,
  1478 [Fukiko], 1600 [Auren], 1693, 1822, 1922); Fukiko's full spread
  is at lines 1415–1471, Auren's at 1528–1554+. **Recommend
  transcribing test/golden fixtures from this chapter directly**
  (respecting §2's copyright note — transcribe the structured
  game-mechanical data, i.e. the actual YAML-shaped facts, not the
  prose Background/Personality paragraphs verbatim beyond what's
  needed for a realistic fixture) rather than relying solely on the
  incomplete/inconsistent `test-data/*.yaml` files (§6) or the 3
  player-book excerpts.
- **Resolved: why Magic's nested "spells" don't show their own
  Level** (§2.1's open question). The Magic, Arcane rules text
  (`ova-rulebook.txt` ~2461–2530) spells this out directly: a "spell"
  isn't a distinct thing with its own Level at all — casting one means
  *mimicking another Ability's effect*, at some Level of that mimicked
  Ability, by spending Endurance looked up from a two-axis "Spell
  Endurance Cost" table (mimicked Ability's Level across, caster's own
  Arcane-Magic-or-Witchcraft Level down; e.g. Level-2 Ability × Level-3
  caster = 10 Endurance). So Auren's `Mana Shield (Barrier +2; 10+
  Endurance)` reads as: a spell named "Mana Shield," which mimics the
  Barrier Ability at Level 2, costing 10+ Endurance to cast. **The
  Level shown belongs to the mimicked Ability field, not to an
  independent "spell level."** This means `Auren.yaml`'s existing
  `spell:`/`perks:` shape (§6) was closer to correct than
  `Fukiko.yaml`'s uniform `abilities:`/`level:` nesting suggests — a
  Magic-linked "spell" item's schema needs fields for (at least) the
  spell's own flavor name, the mimicked Ability's name + Level, and
  the Endurance cost, which is a genuinely different shape from a
  Transformation-linked sub-ability's plain `{name, level}}`.
- **New finding: Vehicle (Mecha) doesn't just nest — it can need a
  wholly separate combat sub-block.** `ova-rulebook.txt` ~2820–2832
  (Vehicle) states its granted Abilities/Weaknesses are **not
  necessarily cumulative** with the pilot's own (unlike Transformation
  and Companion, which explicitly are/imply are), and, more
  structurally significant: **"Health and Endurance are no longer
  linked"** — a Vehicle has its own separate Health and Endurance
  totals, damaged/depleted independently of the pilot's. This means a
  Vehicle-type linked ability may need to carry its own nested
  `combat`-shaped sub-block (at least health/endurance, possibly its
  own Defense/attacks too, if built "with specific attributes much as
  you would a character" per that same passage), not just a nested
  abilities/weaknesses list the way Transformation/Magic do. No
  worked Vehicle example was found in any of the 12 sample characters
  or 3 player books to confirm the exact YAML shape this implies —
  still an open item, but now a sharper one (§ open questions).
- **Resolved: `combat.defense: "4/5"` is real, and the split is the
  Barrier Ability's alternate Defense Roll, not a main-form/
  transformed-form split.** The rulebook's own printed Fukiko sheet
  (`ova-rulebook.txt` line 1461: `4/5 30   40 12` under `defense /
  health / endurance / tv`) matches `Fukiko.yaml`'s `defense: 4/5`/
  `health: 30`/`endurance: 40`/`threat-value: 12` exactly — an
  accurate transcription from the source, not test-data corruption.
  The user's first hypothesis was that the pair represents Defense in
  a character's normal form vs. their Transformation-driven form; the
  rulebook's Barrier Ability entry (`ova-rulebook.txt` ~2129–2152)
  gives the actual mechanism instead: *"Instead of making a normal
  Defense Roll in combat, you may roll your Barrier dice"* — i.e. any
  character with Barrier has **two independent Defense options**
  available simultaneously (their normal Defense Roll, or their
  Barrier dice as an alternative), and a paired Defense on a sample
  sheet is presenting both at once. Confirmed against a second,
  cleanly separating example: **Ai** (`ova-rulebook.txt` line
  ~1654, another of the 12 sample characters) has `+3 Barrier (no
  gesture; 5 end)` as a **plain top-level Ability with no
  Transformation at all**, and her Defense is *also* printed paired
  (`4/5`, `ova-rulebook.txt` line ~1691) — so the pairing tracks
  "has Barrier," not "has a transformed alternate form." Fukiko's
  case happens to acquire Barrier *through* Transformation (so her
  two numbers are only both meaningful while transformed), which is
  presumably what suggested the main-form/transformed-form reading,
  but Ai's case shows that's a coincidence of how she got Barrier, not
  the general rule.

  **Decided (user, following this finding):** still render Defense
  as printed on the source sheet — `4/5` etc. — verbatim; don't try to
  relabel it as two separate named fields or derive it purely from
  "has Barrier" at render time (a character sheet's Defense field
  stays a simple int-or-slash-pair value in the schema, closer to
  `Fukiko.yaml`'s existing `defense: "4/5"` than to the
  Consequence-for-the-schema idea floated in the first draft of this
  finding). Instead, **the Barrier Ability's own list entry should
  carry a short explanatory note** when it grants an alternate
  Defense Roll — e.g. rendering Fukiko's Transformation-nested
  `Barrier +3` as `Barrier +3 (area effect; elaborate gestures; 5
  end; alternate Defense Roll)` or similar terse parenthetical, so a
  reader can connect the sheet's paired Defense number back to the
  Ability that produces it without the formatter having to compute
  or explain the relationship structurally. Exact wording/placement
  of the note (baked into `Text_Layout`'s Barrier-specific rendering
  vs. a `note`/`detail` field on the ability data itself) is still to
  be designed once `Ova_Fmt.Entities`/format backends are underway —
  but the direction is: keep Defense simple and literal, put the
  explanation on Barrier instead.

### 2.3. Karis/Arasuni: a full nested-Companion example, and the terse-format target

**Karis** (`ova-rulebook.txt` lines 874–1012, another of the twelve
sample characters, p. 28–29) settles the "how does a Companion
write-up actually appear" question left open in §9's original step 1
— and the user separately supplied a concrete terse-format mockup for
this same character, so both are captured together here.

- **Companion can get a full nested character sub-block, not just a
  prose summary.** Unlike Fukiko's Azyrus (§2.1 — a one-line
  `Attributes: Flight +2, Quick +1, Smart +2; ...` prose summary with
  no combat stats of its own), Karis's Companion **Arasuni gets his
  own complete second Abilities/Weaknesses column pair, his own
  "Attacks & Combat Stats" box, and his own Defense/Health/Endurance/
  TV row**, laid out right alongside Karis's own on the same spread
  (explicitly headed "Attacks & Combat Stats (KARIS)" and "Attacks &
  Combat Stats (ARASUNI)" in the source). Arasuni: Abilities `+2
  Armored, +1 Attack, +1 Combat Expert, +1 Evasive, +3 Life Support,
  +3 Strong, +2 Tough, +1 Unique Ability (Computerized Brain)`;
  Weaknesses `−1 Awkward Size (Large), −2 Bizarre Appearance, −2
  Emotionless, −1 Quirk (Quoting Earth), −3 Servitude (Karis), −1
  Slow, −2 Vulnerability (Electricity)`; two attacks (`Iron Knuckle`,
  `Stun Pulse Rifle`); `defense 2, health 40, endurance 20, tv 10`.
  Note Arasuni's own `Servitude (Karis)` Weakness — the two entities
  cross-reference each other by name. **Consequence:** a Companion
  (and by extension, per §2.2, presumably Vehicle too) needs to
  support being represented as a **complete embedded sub-entity**
  (its own abilities/weaknesses/combat, i.e. structurally
  self-similar to a top-level entity) when it has real
  game-mechanical presence — not *only* the simpler prose-summary
  shape `Fukiko.yaml`'s `notes[]` currently models. Both shapes are
  now confirmed real (Azyrus is prose-only; Arasuni is a full
  sub-entity), so the schema likely needs to support both, probably
  as the author's choice depending on how mechanically detailed a
  given companion needs to be.
- **The user's terse-format mockup for Karis** (given directly, as "one
  example of how Karis might appear in terse form"):

  ```markdown
  # Karis (Hotheaded Space-Trekking Bounty Hunter)

  *The daughter of a legendary GPL hunter, tracking the criminal who killed her father.*

  * **Abilities:** Agile +3, Attack (Boomerang) +3, Combat Expert +1, Companion (Arasuni) +2, Cute! +1, Evasive +1, Intuitive +1, Perceptive +1, Quick +3.
  * **Weaknesses:** Bizarre Appearance (Strange Alien Ears) −1, Impulsive −1, Obsession (Capture Vandal Drake) −3, Quirk (Stranger in a Strange Land) −2, Sensitivity (Chest Size) −2, Short-Tempered −1, Soft Spot (Stuffed Animals) −1.
  * **Health:** 40 | **Endurance:** 40 | **Defense:** 6 | **Threat Value (TV):** 14   (-5)
  * **Attacks:**
    - **Kinetic Boomerang:** Roll **6 dice** | **DX 4** | **Endurance Cost: 0** (Perks: Armor Piercing, Ranged; Flaws: Weapon).
    - **Trick Shot:** Roll **6 dice** | **DX 3** | **Endurance Cost: 0** (Perks: Disarming, Ranged; Flaws: Ineffective, Weapon). *Used to disarm opponents.*
    - **Sweeping Strike:** Roll **6 dice** | **DX 3** | **Endurance Cost: 0** (Perks: Multiple Targets, Ranged; Flaws: Ineffective, Weapon). *Strikes up to 3 close enemies.*
    - **Flex-Steel Cable:** Roll **6 dice** | **DX 1** | **Endurance Cost: 0** (Perks: Paralyzing x2, Ranged; Flaws: Ineffective x3, Weapon). *Entangles and restrains.*
  ```

  This is the terse backend's design target (§9 step 2), so it's
  worth extracting its conventions precisely:
  - **Markdown, not reST** — `#` ATX heading, `*text*`/`**text**`
    for italic/bold, `*`/`-` bullet lists. This is a real divergence
    from `besm2_fmt`/`ova-rst.scm`'s reST-flavored terse output
    (underline-style headers, but the same `**`/`*` inline markup) —
    worth confirming explicitly whether `ova_fmt`'s terse output
    should target Markdown as its "native" text format going forward
    (feeding a possibly-different downstream pipeline than
    reST→Pandoc) rather than reST, since that changes the header/
    list syntax `Ova_Fmt.Format_Terse` needs to emit and possibly
    which downstream tool consumes it.
  - Header line: `# Name (concept)` — the parenthetical is the
    `fluff.concept` field, not a `tagline` quote (contrast the player
    books' quoted-catchphrase tagline under the name, §2.1) — followed
    by one italicized sentence that reads like a condensed one-line
    background summary (not the rulebook's actual Background prose,
    and not a first-person quote either). Whether this sentence is
    author-supplied (a new schema field, distinct from `background`)
    or auto-derived (first sentence of `background`? a synthesized
    summary?) is open — flag before implementing.
  - Abilities/Weaknesses: one comma-separated sentence each, `Name
    (detail) Level` order (detail immediately after name, level last
    — differs from the character-sheet convention of `Level Name
    (detail)`, §2.1/§2.2), ended with a period.
  - Combat summary: one line, `**Health:** N | **Endurance:** N |
    **Defense:** N | **Threat Value (TV):** N` pipe-separated, plus a
    trailing parenthetical number whose meaning isn't yet clear (see
    below).
  - Attacks: nested bullet list, one per attack: `**Name:** Roll **N
    dice** | **DX N** | **Endurance Cost: N** (Perks: ...; Flaws:
    ...).` followed by an optional italicized flavor sentence. Note
    **Perks/Flaws are explicitly labeled** here (`Perks: ...; Flaws:
    ...`) — clearer than the character sheet's unlabeled `PERKS...;
    FLAWS...` convention (§2.1) and worth carrying into the design
    since it removes the reader's need to already know the
    Perks-before-semicolon/Flaws-after convention. "Roll **N dice**"
    spells out "dice" explicitly rather than the sheet's bare number
    — matches the confirmed mechanic (§2.2/§2.3: `Roll` is a dice
    *count*, not a flat bonus — `2` base dice `+` applicable Ability
    Levels, e.g. Kinetic Boomerang's Roll 6 = 2 base + Attack 3 +
    Combat Expert 1).
  - **Numbers checked against the rulebook's actual Karis** (lines
    928–937, 969–975 above) **mostly match exactly** — same
    Abilities/Levels, same Weakness names/Levels (a couple of detail
    wordings differ slightly: `Strange Ears` → `Strange Alien Ears`,
    `Chest` → `Chest Size`), same attack Roll/DX/End numbers and
    Perks/Flaws — **but two things don't match the primary source and
    are worth a quick confirm before treating this mockup as
    literal**: (1) the Obsession target is `Capture Vandal Drake`
    here vs. the book's `Kill Shadowman` — a different name entirely,
    not just a rewording (possibly a deliberate substitution to avoid
    naming the copyrighted villain directly in a file that might get
    committed, given §2's copyright note — worth asking rather than
    assuming); (2) Threat Value is `14   (-5)` here vs. the book's
    plain `16` — the trailing `(-5)` isn't explained by anything
    found in the rulebook so far (Threat Value's own rules, §2.2, say
    nothing about a parenthetical adjustment shown alongside it) and
    doesn't obviously reconcile arithmetically either. Flagged as an
    open question rather than resolved.

## 3. Existing (unfinished) OVA tooling

Location: `~/current/RPG/Tools/OVA/` (Chicken Scheme, same toolchain
family as `besm2-rst.scm`: `args`, `bindings`, `(schemepunk show)`,
`loop`, `matchable`, SRFI 1/152, the `yaml` egg over `libyaml`).

- `ova-rst.scm` (204 lines) — the stub. `README.rst` states outright:
  *"Right now nothing in this repository works. I'm still hashing over
  ideas for how to represent OVA characters in YAML... The current
  `ova-rst.scm` is merely a skeleton."* Structurally it already has the
  CLI/dispatch skeleton (`process-file`/`process-filename`/`main`,
  `+command-line-options+` for `-h`, `-m`/raw-ms, `-o`/output,
  `-t`/terse, `-U`/`-u` underline chars) mirroring `besm2-rst.scm`'s
  shape, but the actual per-entity formatters are stubs:
  - `process-entity` — returns `#f` immediately, no output at all.
  - `process-entity-raw-ms` — same, returns `#f` immediately.
  - `process-entity-terse` — the only one with real logic. It computes
    `abilities-total`/`weaknesses-total`/`attributes-total` (flat sum of
    each list's `level` field) and renders `**Attributes:**` /
    `*Abilities:*` / `*Weaknesses:*` lines. Its own header comment block
    sketches the intended terse output shape modeled on Azyrus (OVA
    p. 37, a companion character write-up) — see the comment at
    `ova-rst.scm:73-91` for the target prose format. **This does not
    handle nested/linked abilities at all** (e.g. Transformation's own
    sub-abilities/sub-weaknesses in `Fukiko.yaml`) — it just does
    `(must-exist "level" ability)` on every top-level item.
  - No h-m-m backend exists for OVA (unlike besm2-rst.scm's four
    backends) — not yet decided whether one is wanted.
- `GNUmakefile` — mirrors `besm2_fmt`'s predecessor pattern: builds
  `build/ova-rst` via `csc`, generates `.gen.rst`/`-terse.gen.rst`/
  `-ms.gen.rst` per test-data file, then `pandoc`-based downstream
  targets (`.ms`/`.ms.pdf` via a custom `tkb` template with
  `-V twocolumns`, `.stmt.ms`/`.stmt.ms.pdf` via a `statement`
  template, `.native`, `.html`), plus `yamllint -f parsable` targets
  and a `lout`-based experiment (`Fukiko-experiment.lout` →
  `build/Fukiko-experiment.lout.pdf`, via `lout`+`ps2pdf`) that appears
  to be a parallel, non-Scheme typesetting experiment for the same
  Fukiko data — worth looking at once layout for nested attributes
  needs solving (§4), since it may contain earlier attempts at exactly
  that problem. `RPBHENTITIES` (`FV2021-Coleopteran enyon-boase
  pawl-cardynham nessa-kitto`) is leftover from `besm2-rst`'s makefile
  and doesn't correspond to any OVA test-data file — dead/copy-paste
  cruft, not a hint about OVA content.
- `columns.scm` (208 lines) — a **scratch/experiment file, not part of
  the program**, but it records a real, already-discovered design
  problem (see its own header comment, kept verbatim since it's the
  clearest statement of the issue):

  > I think this has proved that monadic formatting can't generate the
  > correct HTML tables... Specifically, for HTML, its columns divide
  > things into characters and lines, but recursive OVA things like
  > Magic (Arcane and Witchcraft), Transformation, and so forth need
  > cells that can contain tables. What I got, rather than one `<tr>`
  > that contains a table, is one `<tr>` for each line in the subtable.
  > ... For text output, it has no way to handle subtables, and if you
  > try to wrap things, the costs get out of sync with the
  > descriptions, since the wrapping adds extra lines to the
  > descriptions.

  **Correction (from the user, since this was initially
  misread):** HTML tables themselves handle nesting fine — a `<td>`
  can contain a whole `<table>` with no problem. The failure
  `columns.scm` actually demonstrates is that `(schemepunk show)`'s
  monadic column combinators (`columnar`/`tabular`/`wrapped`) have no
  way to *build* a nested table — they only know how to lay out flat
  rows of already-linearized text, so a sub-table gets flattened to
  one row per line instead of staying a nested element. The problem is
  in the formatting library used, not in HTML as a target. This
  matters for the design: it means **hand-emitting real nested
  `<table>` markup directly (not through any row/column layout
  abstraction) is a fully workable answer for HTML** — see §8 for the
  resulting output-format-by-output-format strategy, which settles
  this rather than leaving it as an open modeling question.

  For plain fixed-width text output (terse, reST's own table syntax),
  the underlying problem is real regardless of library: a monospace
  grid genuinely cannot represent a nested table without breaking
  either row alignment or the sub-table's own structure. §8 avoids
  the problem there too, by not using tabular layout for OVA's default
  text output at all.
- `x.scm` (71 lines) — scratch REPL exploration of what the `yaml` egg
  produces for `Fukiko.yaml` and for a couple of hand-written
  multi-document YAML strings (`yaml<-` vs `yaml-load`, `-1` for "all
  documents"). Confirms `yaml-load` on a single-document file gives a
  list of alists as expected; the multi-document exploration is
  relevant background for the same "does the loader silently collapse
  multiple documents" question `besm2_fmt`'s `PLAN.md` §"Open
  questions" already answered for BESM (yes, Chicken's `yaml-load`
  keeps only the last document — `alibfyaml`'s `Document_Stream`
  fixes this properly in Ada). No OVA-specific finding beyond
  confirming the same loader is in play.
- `interactive.scm` (10 lines) — trivial REPL scratch (loads
  `Fukiko.yaml`, one `wrapped` call). Nothing to carry forward.
- `Fukiko-experiment.lout`/`.lout.ld` — a Basser Lout typesetting
  source, not Scheme; the makefile builds it straight to PDF
  (`lout -a ... | ps2pdf`), independent of `ova-rst.scm`. **Read in
  full — it is exactly the worked nested-table example the design
  needs.** It hand-codes a curved-box character sheet fragment for
  Fukiko using Lout's `@Tbl` (the `tbl` package), two side-by-side
  top-level tables (Abilities, Weaknesses, each `aformat`/`bformat`
  two-column: level-with-trailing-caret `A` | name/description `B`),
  and — the important part — the Transformation row's `B` cell
  contains a **complete second `@Tbl { ... }` block** for its four
  sub-abilities (Attack, Barrier, Combat Expert, Healer) plus the
  linked Bizarre Appearance sub-weakness, using `{@Sym minus}` for a
  real minus sign glyph rather than ASCII hyphen. This is a genuine,
  already-functioning proof that Lout's table model nests cleanly
  (unlike groff `tbl`, §8), and is the reference to build
  `ova_fmt`'s eventual Lout emitter's Abilities/Weaknesses table
  against, rather than reinventing the markup shape from scratch.

## 4. Domain model differences from BESM (why this isn't a 1:1 port)

Reading `Fukiko.yaml`/`Auren.yaml`/`Acacia.yaml`/`template.yaml`
against the rulebook and `ova-ref.pdf` surfaces these structural
differences from `besm2_fmt`'s BESM model:

- **Two top-level lists, not three.** OVA has just Abilities and
  Weaknesses (both just "Attributes" with a signed Level — Abilities
  positive, Weaknesses negative, per `ova-ref.pdf`'s "Taking Action is
  Two Dice + Abilities & Bonuses − Weaknesses & Penalties"). No
  separate Stats list, no separate Skills list, no BESM-style
  points/CP bookkeeping — OVA "spends" Levels directly (Base
  Zero/Power Ceiling/Scaled Cost, §2's rulebook pointers), not an
  abstract point-buy currency the way BESM's `points` field is.
- **Nesting.** Abilities like Transformation, Magic (Arcane/
  Witchcraft), Companion, and Vehicle (Mecha) contain their own
  sub-abilities and sub-weaknesses (see `Fukiko.yaml`'s
  `Transformation.abilities`/`.weaknesses`, `Auren.yaml`'s `Magic,
  Arcane.spells`). This is the load-bearing design problem — see §3's
  `columns.scm` discussion. Not present in BESM's model at all
  (BESM's enhancements/limiters are flat string/tuple modifiers, never
  a recursive attribute list).
- **Perks and Flaws customize *any* Ability, not just attacks —
  corrected from an earlier draft of this plan.** The rulebook is
  explicit (`ova-rulebook-not-layout.txt` ~5792–5824): *"Ability Perks
  and Flaws ... provide additional ways to customize your Abilities
  and are listed as a subset of them. It's sort of like applying
  Abilities and Weaknesses to the Ability itself... For any Ability
  you feel can be further individualized through Perks and Flaws,
  simply go through the list and assign those that fit your mental
  image. Some Abilities mention the use of Perks and Flaws right in
  their text, but they can be applied to others as well."* So this is
  a **general Ability-modifier mechanic** — structurally exactly like
  BESM's enhancements/limiters (a name plus a signed Endurance-cost
  effect, `besm2_fmt`'s `format-customizers` dispatch shape is a
  reasonable starting point), attachable to any Ability whatsoever:
  a plain top-level Ability (Ai's `Barrier (no gesture; 5 end)`, §2.2,
  is a top-level Ability with a Flaw on it, not an attack), a
  Transformation/Magic-linked sub-ability (`Fukiko.yaml`'s Barrier
  sub-ability), *or* an Attack-Ability-based attack entry in
  `combat.attacks[]`. Attacks just happen to be where Perks/Flaws are
  most visible and most often used, since — per the same passage —
  *"Perks and Flaws that specifically mention attacks are usually best
  used with the Attack Ability"* (a usage tendency, not a structural
  restriction). **Design consequence:** `perks`/`flaws` shouldn't be
  modeled as an attack-specific or nesting-specific field; it belongs
  on whatever the common "Ability item" record type ends up being
  (top-level Ability, linked sub-ability, and Attack-typed combat
  entries should all share the same Perks/Flaws representation),
  parallel to how `besm2_fmt.Entities`' attribute record carries
  `Enhancements`/`Limiters` uniformly rather than per attribute kind.
- **Combat block is its own structured section**, matching the
  official character sheet's "Combat Stats" box exactly (§5): Defense,
  Health, Endurance, Threat Value (`tv`), and up to several named
  Attacks each with Roll, DX (Damage Multiplier), Endurance cost, plus
  Perks/Flaws/Affinity/Description. BESM has no equivalent — BESM
  folds combat-relevant numbers into its generic Derived Values list.
- **A `fluff` block** (concept, birthday, age, gender, height, weight,
  hair, eyes, association, hobbies, favorite-food, allies, enemies,
  love-interests) — matches the rulebook's suggested fluff fields
  (§2, ~line 700) and `fluff.yaml-partial`'s outline exactly. No BESM
  equivalent (BESM has no fluff section at all).
- **An `options` block** (`base-zero`, `power-ceiling`, `scaled-cost`,
  `combined-effectiveness`, `max-abilities-level`) recording which
  character-creation limiting rule(s) were used and their parameters —
  metadata about how the character was built, not data to be rendered
  as part of the character write-up necessarily (open question: does
  any output format display this at all, or is it purely informational
  for whoever maintains the YAML?).
- **Background/Appearance/Personality/Notes** — `Fukiko.yaml` has
  these as prose blocks plus a `notes` list of `{header, text,
  attributes}` entries (the `attributes` sub-field holds pre-rendered
  prose like `"Flight +2, Quick +1, Smart +2..."` for an NPC companion
  described within a note, not a structured list — see Azyrus in
  `Fukiko.yaml`'s `notes`). Roughly parallels BESM's
  `description`/`tagline`, but richer.

## 5. Canonical field set (from the official character sheet)

`OVA-Blank-Character-Sheet-Form-Fillable.pdf` (2 pages) confirms the
fields any output format should be able to round-trip:

- Header: Character Name, Player Name.
- Abilities (name + level list), Weaknesses (name + level list) —
  side by side.
- Combat Stats: up to 4 named attack rows (Roll / DX / END columns
  each), then a Defense / Health / Endurance / TV row.
- Combat Notes / "Damage, Complications, Etc." (free text).
- Page 2: Background, Appearance, Personality, Other Notes (free
  text), Character Portrait (image — out of scope for a text
  formatter).

This matches `Fukiko.yaml`'s shape closely and is a good sanity check
for whatever YAML schema gets settled on (§6): every one of these
fields should map onto something in the schema, and nothing essential
should be sheet-only/YAML-only without a reason.

## 6. Test data assessment — the schema is not settled

`~/current/RPG/Tools/OVA/test-data/` (5 files) does **not** use one
consistent schema. This is the other major open item before any real
port work, since `besm2_fmt`'s port strategy (§7 there: diff Ada
output byte-for-byte against real Scheme-generated golden output)
depends on having working, schema-valid input and a working reference
implementation — neither exists yet for OVA.

- `Fukiko.yaml` (177 lines, the most complete) — top-level YAML
  **mapping** (not a sequence like BESM's/Auren's files): `name`,
  `abilities`/`weaknesses` (each a list of `{name, level, [detail(s)],
  [abilities], [weaknesses], [perks], [flaws]}` — nested recursively
  for Transformation), `combat` (`defense` as a slashed
  string `"4/5"` — confirmed accurate against the primary rulebook's
  own printed Fukiko sheet, §2.2, not a transcription error — `health`,
  `endurance`,
  `threat-value`, `attacks[]` with `name`/`perks`/`flaws`/`affinity`
  (note: misspelled `afinity` on the first attack, `affinity`
  correctly on the rest — a typo to notice, not a schema variant)/
  `description`/`roll`/`dx`/`endurance`), `background`, `appearance`
  (empty), `personality`, `notes[]` (`header`/`text`/optional
  `attributes` prose), `fluff` (mapping of the §4 fields). Uses
  `details`/`detail` inconsistently (`detail:` singular on the
  Knowledge ability, `details:` plural on Bizarre Appearance/Focus) —
  another thing to normalize when settling the schema, not necessarily
  a meaningful distinction.
- `Auren.yaml` (98 lines) — top-level YAML **sequence** of one entity
  (`- name: Auren`, matching BESM's file shape), with an `options`
  block (§4) not present in `Fukiko.yaml` at all. Abilities/weaknesses
  use a **different item shape**: each list item's own key names the
  attribute (`ability: Combat Expert` / `weakness: Ageism`) instead of
  a fixed `name:` key, and several entries misspell the key itself
  (`abilty:` ×3, `abiltiy:` ×1) — these items likely fail to parse as
  intended under either schema as a result (a YAML mapping key typo
  like `abilty` just becomes a differently-named field, silently, not
  a YAML syntax error) and would need cleanup regardless of which
  schema direction is chosen. `label:` appears where `Fukiko.yaml`
  uses `detail:`/`details:` (also once misspelled `lebel:`). Nested
  `spells:` under `Magic, Arcane` uses `spell:`/`perks: - perk: ...`
  (again keying by value-as-key rather than a fixed `name:`), with one
  outlier (`Breath`'s perk uses `name: Life Support` instead of
  `perk:`) — so even within this one file the "key names the thing"
  convention isn't applied consistently. `combat.attacks:` is present
  but empty (no attacks filled in), and `background`/`appearance`/
  `personality`/`notes` are all empty.
- `Acacia.yaml` (12 lines) — top-level sequence, one entity, every
  field present as a key with no value (`abilities:`, `weaknesses:`,
  `combat:`, `background:`, `appearance:`, `personality:`, `notes:`).
  Effectively just a "here are the top-level section names" skeleton;
  no schema information beyond that.
- `template.yaml` (36 lines) — **not valid YAML as written**: it mixes
  a sequence item's mapping with stray `- perks:`/`- flaws:`/
  `- affinity:` list markers at the wrong indentation inside a
  mapping value, and uses placeholder tokens (`Ability X`, `Perk Y`,
  `level: N`, `cost: M`) rather than real data. Read as an aspirational
  sketch of intended structure (options block fully commented with
  rulebook page references, a perk/flaw shape with `name`/`level`/
  `cost`/`description`), not as a working fixture. Its `cost:` field
  (with a `# Total` comment) hints at wanting per-perk/flaw Endurance
  cost tracked explicitly, matching `ova-ref.pdf`'s Perk/Flaw End
  columns.
- `fluff.yaml-partial` (18 lines, note the `.yaml-partial` extension —
  deliberately not a complete/loadable file) — just the `fluff:`
  mapping with every OVA-rulebook-suggested field present as a
  commented-out-description placeholder. A clean reference for the
  fluff field list and field order, nothing more.

**Bottom line:** before any Ada work starts, the YAML schema needs to
be decided and `Fukiko.yaml`/`Auren.yaml`/`Acacia.yaml` brought into
conformance with it (fixing the `abilty`/`abiltiy`/`lebel` typos along
the way), the same way `besm2_fmt`'s port could lean on already-valid,
already-consistent `besm-tools` test-data. Recommend picking
`Fukiko.yaml`'s style (fixed `name:`/`level:` keys, nesting via
`abilities:`/`weaknesses:` under a parent item) as the base, since it's
both the most complete example and the one the stub's own
`process-entity-terse` already assumes (`must-exist "level" ability}`
expects a fixed key name, not `Auren.yaml`'s "key names the thing"
convention).

## 7. Output-format strategy for nested tables (settled by the user)

This resolves what was previously the top open question (§3/§4's
nested-table problem) with a concrete per-format plan, given directly
by the user rather than left for later design:

- **reST's own table syntax (grid or simple) is not usable for OVA at
  all.** Unlike BESM, where a flat attributes/defects/skills list maps
  fine onto one reST table per section, OVA's nested
  abilities-within-abilities has no representation in reST tables —
  reST doesn't support nested tables, and `besm2_fmt`'s grid-table
  backend (`process-entity`'s STAT/ATTRIBUTE/DEFECT/SKILL tables) is
  therefore **not** a shape to reuse for OVA's default output.
- **Default/primary text output should look like BESM's *terse*
  format instead** — paragraphs of prose (`**Attributes:**` etc.,
  matching `ova-rst.scm`'s existing `process-entity-terse` sketch,
  §3), not a tabular grid. This is the one format where nesting is
  natural: a nested ability's sub-abilities/sub-weaknesses just read
  as a parenthetical or nested clause within the parent's sentence,
  the same way `columns.scm`'s Azyrus example in `ova-rst.scm`'s
  header comment already reads Companion/Attributes/Weaknesses as
  flowing text. This sidesteps the nested-table problem entirely
  rather than solving it — there's no grid to keep aligned.
- **HTML output**: generate a raw HTML block embedded in the generated
  reST (`.. raw:: html`), the same technique `besm2-rst.scm`/
  `besm2_fmt` use for groff `tbl` via `.. raw:: ms` (`process-entity-
  raw-ms`/`Format_Raw_Ms`) — i.e. `ova_fmt` hand-emits literal
  `<table>`/`<tr>`/`<td>` markup itself (nesting a full `<table>`
  inside a `<td>` where an ability has sub-abilities), rather than
  trying to express the table through reST syntax and letting Pandoc
  render it. This is exactly what `columns.scm`'s correction (§3)
  establishes as workable: HTML nests tables fine, so hand-written
  markup is the right level to emit at, bypassing both reST's
  limitation and `(schemepunk show)`'s inability to build nested
  layouts.
- **groff/troff output**: `besm2_fmt`'s raw-ms backend uses classic
  `tbl` macros (`.TS`/`.TE`, `T{...T}` text blocks) — confirmed **not
  suitable for OVA**, since `tbl` has no construct for a table nested
  inside a cell (column/row spanning could maybe fake something
  visually, but isn't real nesting and wasn't pursued). Instead use
  groff's **`hd` table macros**, which do support nested tables (and
  color) — the same `.. raw:: ms` raw-block technique as
  `besm2_fmt`'s `tbl` approach, just with `hd` macro calls instead of
  `.TS`/`tbl` syntax, still processed through Pandoc's `ms` writer
  like the rest of the raw-ms pipeline. **Caveat, and worth flagging
  early:** `hd` is reportedly not well supported in the groff version
  the user expects to be current (~1.24) but *is* supported in groff
  1.23, which is the version actually installed/in use here — check
  the installed groff version before committing to this path, and
  re-verify `hd`'s nested-table support against whatever version is
  actually available when this gets built, since relying on it and
  then hitting a groff upgrade that dropped/changed `hd` support would
  be a real regression risk.
- **Lout/PDF output**: Pandoc has **no Lout backend**, so unlike the
  reST→(HTML|ms) pipeline, this output can't go through Pandoc at
  all — `ova_fmt` would need to emit complete, directly-renderable
  Lout source itself (`lout -a ... | ps2pdf`, matching the existing
  `GNUmakefile`'s `build/%.lout.pdf` pattern), the same role
  `Fukiko-experiment.lout` already plays as a hand-written example
  (§3) — i.e. this becomes a fifth, structurally different output
  mode, not just another `.. raw::` block inside reST. Lout's `@Tbl`
  package genuinely nests (proven by `Fukiko-experiment.lout`), so
  this is the one path with a working existing proof of concept
  already in the repo.

Net effect on `Ova_Fmt.Text_Layout`/format-backend design: the
fixed-width pad/wrap/columnar-row machinery `besm2_fmt` built
(§8-old/now-§9's "reuse directly" bullet) is useful for the
**terse-prose** format's word-wrapping, but the *tabular row/column
renderer* part of `besm2_fmt.Text_Layout` (`Put_Row`/`Separator_Line`,
the reST grid-table specific piece) has **no OVA consumer at all** —
OVA's tables live only inside raw HTML/`hd`/Lout blocks, each with
its own native table model, not through a shared Ada-side grid
renderer.

## 8. Proposed approach, following `besm2_fmt`'s playbook

Not yet decided/committed — for discussion before starting real work:

- **Toolchain:** same as `besm2_fmt` — Ada 2012, `alibfyaml`
  (`~/Repos/Ada/alibfyaml` / installed under
  `/usr/local/sw/versions/ada/`, resolved via `GPR_PROJECT_PATH`) for
  YAML, `arg_parser` for CLI parsing, same `Executable`-renaming
  `.gpr` trick if the root package ends up needing to be named
  `Ova_Fmt` (check whether that specific collision even applies here —
  `besm2_fmt`'s workaround was needed because `BESM2_Fmt` had to be
  both a procedure name and a parent package name; confirm the same
  shape before copying the workaround unnecessarily).
- **Package layout**, mirrored from `besm2_fmt/src/`:
  `ova_fmt.ads` (root anchor), `ova_fmt-config.ads`,
  `ova_fmt-text_layout.ads/.adb` (start from `besm2_fmt`'s, but budget
  real design time for the nested-table problem, §3/§4 — this is
  **not** a drop-in reuse), `ova_fmt-entities.ads/.adb` (parse each
  YAML entity into typed Ability/Weakness/Attack/Combat/Fluff records
  once, matching `besm2_fmt`'s "parse once, four backends consume it"
  rationale), one package per output format, `ova_fmt-cli.ads/.adb`,
  `ova_fmt_main.adb`.
- **Reuse `besm2_fmt`'s already-learned lessons directly**, since
  they're about YAML/Ada mechanics, not BESM-specific: libfyaml core
  hands back scalar text needing explicit `Integer_Value`/etc.
  conversion (already solved generically in `alibfyaml`'s
  `Libfyaml.Nodes` — no OVA-specific work needed there);
  `Display_Length`/UTF-8-aware width counting for any fixed-width
  column layout; `Word_Wrap` needing to treat embedded YAML
  literal-block newlines as word breaks, not literal content;
  `Document_Stream` for correct multi-document handling (OVA files so
  far are single-document, but no reason to special-case that).
- **Output formats**, per §7's settled per-format strategy: terse-prose
  as the default/primary text format (no BESM-style reST grid-table
  default at all — reST tables are off the table, so to speak, for
  OVA); an HTML backend that emits raw `.. raw:: html` blocks with
  hand-written (potentially nested) `<table>` markup; a raw-ms backend
  using groff `hd` macros instead of `tbl` (version caveat noted in
  §7); and a Lout backend that's a genuinely separate, non-Pandoc
  output mode producing directly-renderable Lout source. Not yet
  decided whether an h-m-m outline backend (no OVA attempt exists at
  all) is also wanted. No golden reference output exists for *any* OVA
  format yet (unlike BESM, where `besm-tools`' compiled binary and
  `GNUmakefile` targets served as the oracle) — acceptance testing
  will have to be built up from scratch (hand-verify the terse format
  against the rulebook's own Fukiko/Azyrus write-up on p. 36–37, and
  the Lout backend against `Fukiko-experiment.lout` specifically,
  since that's now a confirmed real worked example, §3) rather than
  diffed against a pre-existing working program.
- **Test data and build order**: see §9 — now a decided sequence
  rather than an open item.
- **Shared library question**: `besm2_fmt`'s `PLAN.md` already flags
  "factor `Text_Layout`/customizer logic into a shared library" as an
  open question for a hypothetical `besm4_fmt`. Worth reconsidering
  once OVA's `Text_Layout` needs diverge from BESM's (§3/§4) — may turn
  out OVA's nested-table requirement means less is actually shareable
  than the BESM4 case would have had, or it may clarify what the truly
  generic core (`Pad`, plain `Word_Wrap`, `Bold`/`Italics`/emphasis
  gating) versus per-game layout logic split should be.

## 9. Build order (decided)

Given directly by the user, superseding §8's "not yet decided" framing
for test data and output-format sequencing:

1. **YAML test data for all twelve sample characters** (§2.2), not
   just the existing `Fukiko.yaml`/`Auren.yaml`/`Acacia.yaml`/
   `template.yaml`. Base the schema on `Fukiko.yaml`'s existing
   structure wherever it already fits (§6's recommendation — fixed
   `name:`/`level:` keys, nesting via `abilities:`/`weaknesses:` under
   a parent item), but it needs to generalize to cover what the other
   eleven write-ups actually contain, not just Fukiko's shape:
   - `background`, `personality` — already present in `Fukiko.yaml`.
   - **NPC companion callouts — now confirmed to need two different
     shapes, not one** (§2.3): a simple prose-only companion (Fukiko's
     Azyrus: one `Attributes: Flight +2, Quick +1, Smart +2; ...`
     summary line, still fine as `notes[]`) *and* a fully-detailed
     companion with its own Abilities/Weaknesses/Attacks/Combat-stats
     sub-block (Karis's Arasuni, §2.3) — structurally a nested
     sub-entity, not a note. Schema needs to support both; probably
     the character's own choice depending on how mechanically
     detailed the companion needs to be for play.
   - **Transformation-description callouts**: Fukiko's sheet has a
     separate named box ("Lovely Savior Myu Myu") describing the
     transformation itself — trigger phrase, visual/narrative
     description — distinct from the Transformation Ability's own
     numeric list entry. Also currently folded into `notes[]`; check
     the other Transformation-using sample characters for the same
     convention.
   - Any further headed callout types turned up while transcribing the
     remaining eight characters not yet read closely (only Fukiko,
     Auren, Ai, and one other paired-Defense character have had their
     full spreads read so far, §2.2/§2.1).
   Deliberately use this pass to get schema coverage for every
   nesting/modifier shape already identified from primary sources:
   Ai's plain-Ability Perk/Flaw (§ Perks/Flaws correction above), a
   Magic-using character's spell-mimics-another-Ability shape (§2.2),
   and whichever sample characters (if any) use Companion or Vehicle,
   still unconfirmed as worked examples (§ open questions).
2. **Terse backend first.** Mirrors `besm2_fmt`'s own build order
   (its `PLAN.md` §8: terse validates CLI + data access + domain
   formatting before touching harder layout code) — and per §7, terse
   is the one OVA format that needs no table-layout code at all, so
   it's both the natural first target and the one with a ready-made
   reference to hand-verify against (the rulebook's own printed
   write-ups from step 1, not a pre-existing working binary the way
   BESM had — §8's note on acceptance-testing from scratch still
   applies).
3. **HTML backend**: raw `.. raw:: html` blocks containing
   hand-written, potentially-nested `<table>` markup (§7), through the
   same reST→Pandoc pipeline `besm2_fmt`'s raw-ms backend already
   demonstrates the shape of (reST→Pandoc→`ms` there; reST→Pandoc→HTML
   here).
4. **`hd`-table raw-ms backend**: groff `hd` macros, not `tbl` (§7),
   in a `.. raw:: ms` block, through Pandoc's `ms` writer. Sequenced
   after HTML deliberately — `hd`'s actual nested-table support still
   needs hands-on confirmation against the installed groff version
   (§ open questions), and having a working HTML nested-table
   reference in hand first gives something concrete to compare `hd`'s
   real rendered output against while sorting that out.
5. **Direct-to-Lout backend last.** No Pandoc involvement (§7) — a
   structurally separate output mode from the other three, modeled on
   the existing `Fukiko-experiment.lout` worked example (§3), using
   `~/Reference/Document-Tools/lout/`'s `user.pdf`/`expert.pdf` (§2)
   as needed for anything beyond what that one example already shows.

## Open questions

- **Terse output format: Markdown or reST?** (§2.3) The user's Karis
  mockup is Markdown (`#` headings, `*`/`**` inline markup, `*`/`-`
  bullets), not reST like `besm2_fmt`/`ova-rst.scm`'s terse backends.
  Confirm which is the actual target before implementing
  `Ova_Fmt.Format_Terse` — affects heading syntax and whether/how this
  feeds a reST→Pandoc pipeline the way the other backends do (§7/§9),
  or something else entirely.
- **Karis mockup's header tagline sentence**: is the italicized
  one-line summary under the name/concept (§2.3, "The daughter of a
  legendary GPL hunter...") a new schema field, or derived/synthesized
  from `background` somehow? Needs to be a real field with a real
  source before `Format_Terse` can render it for characters generally
  (not just hand-written for one mockup).
- **Karis mockup's two divergences from the primary rulebook text**
  (§2.3): the Obsession target name (`Capture Vandal Drake` in the
  mockup vs. `Kill Shadowman` in `ova-rulebook.txt`) and Threat Value
  (`14 (-5)` in the mockup vs. plain `16` in the book) — confirm
  whether these are deliberate (e.g. avoiding naming the copyrighted
  villain directly) or just illustrative approximation, and what the
  trailing `(-5)` after TV is meant to represent, before treating the
  mockup as a literal byte-for-byte rendering target.
- ~~**Nested-table rendering**~~ Resolved (§7): terse-prose for the
  default text format (sidesteps the problem), hand-written nested
  `<table>` markup in raw HTML blocks, groff `hd` macros (not `tbl`)
  in raw-ms blocks, and a genuinely separate directly-rendered Lout
  backend (no Pandoc involvement) modeled on `Fukiko-experiment.lout`.
- **YAML schema**: `name:`/`level:`-keyed items (`Fukiko.yaml`-style)
  vs. "key names the attribute" (`Auren.yaml`-style) — recommend the
  former (§6) but not yet decided/committed with the user.
- **`options` block**: character-creation-limit metadata — rendered in
  any output format, or purely for the YAML author's own reference?
- ~~**`combat.defense: "4/5"`**~~ Resolved (§2.2): the pair is the
  character's normal Defense Roll alongside their Barrier-Ability
  Defense Roll (Barrier's rules text: *"Instead of making a normal
  Defense Roll in combat, you may roll your Barrier dice"*) — present
  on any sample character with Barrier (confirmed on both Fukiko, who
  gets Barrier via Transformation, and Ai, who has Barrier as a plain
  top-level Ability with no Transformation at all), not a main-form/
  transformed-form split as first guessed. **Decided:** still render
  Defense verbatim as printed (`4/5` etc., an int-or-pair schema
  value, not two separately-named fields); add a short explanatory
  note on Barrier's own list entry instead, so the connection is
  documented where the Ability is, not computed/explained inline at
  the Defense field.
- ~~**Nested-ability rendering may need two distinct shapes, not
  one**~~ Resolved (§2.2): confirmed via the Magic, Arcane rules text.
  A "spell" has no Level of its own — it mimics another Ability at
  that Ability's Level, Endurance cost looked up from a table keyed on
  (mimicked Ability Level, caster's Magic Level). So Magic-linked
  items need a `{spell-name, mimicked-ability, mimicked-level,
  endurance-cost}`-shaped record, structurally different from a
  Transformation-linked sub-ability's plain `{name, level}`.
  `Ova_Fmt.Entities`' domain model needs (at least) these two distinct
  "linked ability content" shapes, not one reused everywhere.
- **Vehicle (Mecha) may need its own nested `combat` sub-block**
  (§2.2, new finding, strengthened by §2.3): the rulebook states a
  Vehicle's Health and Endurance are tracked completely separately
  from its pilot/character's, and its granted Abilities/Weaknesses
  aren't necessarily cumulative with the pilot's own either —
  structurally more like an embedded second (partial) character than
  a simple nested ability list. Karis/Arasuni (§2.3) now confirms
  exactly this "full nested sub-entity" shape is real for Companion,
  which makes it likely (not yet certain) Vehicle works the same way.
  No worked Vehicle example exists in any of the 12 sample characters
  or 3 player books to confirm the exact shape this implies; needs
  either a fabricated test fixture or a wait until a Vehicle-using OVA
  character is available to transcribe from.
- **Which output formats are actually wanted**: §7/§8 now cover terse,
  HTML, raw-ms/`hd`, and Lout; still unconfirmed whether an h-m-m
  outline backend (no OVA attempt exists at all, unlike BESM) is also
  wanted.
- **groff version/`hd` support** (§7): the `hd` table macros are
  reportedly not well supported in groff ~1.24 but are supported in
  1.23, which is what's actually installed here — confirm the
  installed version and re-verify `hd`'s nested-table (and color)
  support directly before committing real implementation time to the
  raw-ms/`hd` backend.
- **`tbl` column/row spanning as a fallback**: floated in §7 as a
  "maybe something could be done" alternative to `hd` if `hd` support
  turns out to be inadequate — not investigated, likely inferior to
  real nesting, but worth a quick sanity check before ruling it out
  entirely if `hd` doesn't pan out.
- **Other files under `~/Reference/RPG/OVA/`** not yet reviewed
  (`OVA-Combat.odt`/`.pdf`, `OVA-ConversionGuide.pdf`, the various
  character-sheet variants, `OVA-CharacterSheet.zip`) — check these
  before finalizing the field set in §5, in case they show a different
  or more complete layout than the one fillable-PDF sheet reviewed so
  far.

## Decisions already made

- Project directory: `~/Repos/RPG/Tools/ova_fmt` (git initialized,
  `origin` set to `git@github.com:tkurtbond/ova_fmt.git`, `main`
  tracking `origin/main`).
- Program name: **ova_fmt** (following `besm2_fmt`'s naming pattern —
  not yet confirmed with the user beyond the directory name itself).
- This is a from-scratch design-and-port effort, not a mechanical
  translation — the Scheme source is an intentionally-unfinished
  skeleton (its own `README.rst`: "nothing in this repository works"),
  so `ova-rst.scm` is a *shape* reference (CLI option table, the
  general `process-file`/dispatch pattern, the terse-format prose
  sketch in its header comment) rather than a behavior oracle the way
  `besm2-rst.scm` was for `besm2_fmt`.
- **Nested-table output strategy (§7), given directly by the user:**
  reST's table syntax is unusable for OVA — no default reST
  grid-table format, unlike BESM. Default/primary text output is
  terse/prose-style. HTML output uses hand-written raw `<table>`
  markup (nests natively) inside `.. raw:: html` blocks. groff/`ms`
  output uses `hd` macros, not `tbl` (`tbl` can't nest tables), still
  via a `.. raw:: ms` block processed through Pandoc. Lout output is a
  separate, directly-generated (non-Pandoc) backend, since Pandoc has
  no Lout writer — `Fukiko-experiment.lout` is a confirmed working
  proof-of-concept for Lout's native nested-table support to model
  that backend on.
- **Build order (§9), given directly by the user:** (1) YAML test data
  for all twelve rulebook sample characters first, generalizing
  `Fukiko.yaml`'s schema to cover companion and transformation-
  description callouts seen on other characters' sheets; (2) terse
  backend; (3) HTML-raw-block backend; (4) `hd`-table raw-ms backend;
  (5) direct-to-Lout backend last, using
  `~/Reference/Document-Tools/lout/`'s docs alongside
  `Fukiko-experiment.lout`.
- **Perks/Flaws are a general Ability modifier, not attack-specific**
  (correction, §4): attachable to any Ability — top-level, linked
  sub-ability, or Attack-typed combat entry alike — so the domain
  model represents them uniformly rather than per attachment point.
- **`combat.defense`'s slash-paired values (e.g. `4/5`) render
  verbatim** (§2.2, refined by the user): don't split or derive them
  at render time; instead add a short explanatory note on the
  Barrier Ability's own list entry, since that's the Ability that
  produces the second Defense option.
