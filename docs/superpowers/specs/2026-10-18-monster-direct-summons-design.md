# Monster direct-summon family

## Intent and source boundary

Port the pinned DCSS monster spells whose primary action creates ordinary
creatures. A monster should choose, cast, own, and eventually lose its
summons through the same Lua and Akara path already used by player spells.
This unlocks complete monster spellbooks without adding a Go spell switch.
The reference is `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`, chiefly
`mon-cast.cc`, `spl-summoning.cc`, `mon-place.cc`, and `mon-ench.cc`.

The port remains faithful to source species pools, weights, count and
duration formulas, placement anchors, ally relationship, and per-spell
post-spawn behavior. Source RNG stream sequence is not a binary-compatibility
target, but the Go port must use saved named streams and continue identically
after save/restore. Monster spells draw their choices from the monster-spell
stream; monster HP rolls keep their existing monster-HP stream.

## Scope

The direct-creature family consists of these source effects, grouped by
their *behavior* rather than by C++ switch position:

- Fixed or small weighted pool: `SUMMON_SMALL_MAMMAL`, `CALL_IMP`,
  `SUMMON_MINOR_DEMON`, `SUMMON_UFETUBUS`, `SUMMON_HELL_BEAST`,
  `SUMMON_ICE_BEAST`, `SUMMON_GREATER_DEMON`, `SUMMON_HOLIES`,
  `SUMMON_EYEBALLS`, `SUMMON_TZITZIMITL`, `SUMMON_HELL_SENTINEL`,
  `CALL_LOST_SOUL`, `SUMMON_MANA_VIPER`, `SUMMON_SCORPIONS`,
  `SUMMON_EMPEROR_SCORPIONS`, `SUMMON_SCARABS`,
  `SUMMON_EXECUTIONERS`, and `GREATER_SERVANT_MAKHLEB`.
- Source or branch population picker: `SHADOW_CREATURES`, `SUMMON_DEMON`,
  `SUMMON_SPIDERS`, `SUMMON_HORRIBLE_THINGS`, `SUMMON_UNDEAD`,
  `SUMMON_DRAKES`, `SUMMON_DRAGON`, `SUMMON_HYDRA`, `FIRE_SUMMON`,
  `SUMMON_VERMIN`, `MONSTROUS_MENAGERIE`, `FORCEFUL_INVITATION`,
  and `PLANEREND`.
- Placement around a foe: `SUMMON_MUSHROOMS`, `HAUNT`, and
  `SUMMON_SPECTRAL_ORCS`.
- Caster-specific ally: `BROTHERS_IN_ARMS`.
- Elemental group: `WATER_ELEMENTALS`, `FIRE_ELEMENTALS`,
  `EARTH_ELEMENTALS`, and `AIR_ELEMENTALS`.

Every name in the list has the `SPELL_` prefix in the registered catalog.
The implementation audit must compare this list with source
`spell_to_logic` and `_mons_cast` before claiming the family complete.
The current player summon effects provide reusable creation, population,
and expiry behavior; their player-specific formulas must not be reused for
a different monster formula merely because a spell ID is shared.

Constructs, clones, and terrain actors have additional owners and form a
later contiguous category: battlesphere, ball lightning, living spells,
servitor, illusion, fake Mara, phantom mirror, spectral gear, dancing
weapons, malign gateway, awakened vines, brambles, spores, and creeping
inferno. Ally recall and movement spells form a movement category. These
are named here to keep the source audit from silently classifying them as
ordinary creature spawns.

## One summon owner

The existing `policy.magic.effects.summons.common` module becomes an
actor-neutral creator and expiry owner. A caller supplies a source spell,
caster handle, source-specific placement request, duration degree, and
optional source-specific actor state. The creator validates the destination,
creates the Akara actor, attaches `magic.summon`, places it through the grid
service, and enforces any source cap. It does not choose species, counts,
targets, or a spell-specific message. A failed placement spends the cast when
the source does, without leaving a partial entity or invalid item reference.

Allegiance must follow source `SAME_ATTITUDE(caster)`. Currently the shared
creator treats a monster owner like a player owner, so a hostile caster can
create a friendly summon. Repair that at the owner boundary. A caster can be
hostile, friendly, neutral, or good-neutral; reducing the summon to the
current `hostile` boolean loses source behavior. Replace that saved field
with a named attitude value and update all readers in one pass. Preserve
the player's No Love rule for player-owned summons. Charm changes a caster's
current attitude but does not rewrite a summoned actor's real attitude
after it exists. The source's temporary versus real distinction must remain
explicit in ally selection and target policy.

Forceful Invitation keeps one selected branch on the caster across casts;
Planerend redraws it each time. Store the former in a focused saved caster
component, not in a Lua module variable. Both use the committed source
branch population data and preserve the source slime size special case.

Existing player summons continue to use the creator with their player
formulas. The same saved expiration and cap system applies to both sides.
The summon component retains owner, source category and ID, remaining time,
and source-specific fields such as hydra heads. Every new mutable feature
that must survive a save gets a focused component; no Lua module global
holds summoned state.

## Spell rules and intent flow

Each spell has a discoverable module at
`policy/combat/monster_spells/<spell>.lua` with named `plan` and `resolve`
methods. A small family helper under `policy/combat/monster_summons/` owns
repeated weighted choice, duration, spell-HD, and placement calculations.
It takes explicit values; it is not a dispatcher keyed by spell ID.
Source species pools are named tables with IDs imported from `ids.monsters`
at their use sites. A mod adds a new spell effect file and definition without
editing a central switch or registry.

The existing AI chooses a spellbook slot, asks its effect to plan, saves the
typed plan in the spell intent, and invokes `resolve` after the action is
committed. Ordinary self-centered summons may plan the caster as the anchor;
foe-centered spells save the chosen foe or cell and revalidate it at resolve
time. A target that moved or vanished must not silently redirect a Haunt or
Spectral Orcs cast. Source tactical eligibility belongs in each effect's
`plan`; a poor species roll or blocked placement belongs in `resolve` if
the source spends the action before learning that result.

Use effective monster spell HD, including existing drain, Wretched, and
Aura of Brilliance state. A spell calling for raw hit dice or spellpower
uses that explicit calculation. All count, duration, and weighted picker
draws use named monster-spell RNG. Every resolver comments its source
formula and why its target, cap, or placement differs from the shared case.

## Save, validation, and visibility

The save validator accepts player- and monster-owned summons with a live
owner, registered source ID, valid attitude, placed actor, and nonnegative
expiry. Restoring a saved summon must not rerun the spell's creation logic.
Expiry, cap eviction, carried-item cleanup, AI target choice, rendering,
cloud attribution, and combat use the same effective attitude. Source
messages appear only for visible events using existing message channels;
the UI does not need a monster-ID switch.

The base game can continue to gate generated monsters on effect coverage.
Adding this family should make a spellbook eligible only when *every* slot
also has its own complete resolver. A mod-added monster may use these spells
without modifying Go or bundled Lua registries.

## Verification

One Lua test table imports production spell IDs and invokes every family
resolver, asserting that its plan and resolve methods exist. Source-shaped
cases test species/weight boundaries, count and duration ranges, target
placement, blocked space, caster allegiance, hydra heads, Brother in Arms
special choice, and expiry/cap behavior. Tests import real schemas and
catalogs rather than redeclaring component shapes.

A live Go game test gives a real monster a source spellbook slot, observes
the cast, then saves and restores before checking summon owner, attitude,
kind, position, expiry, and deterministic next-turn behavior. A sparse mod
overlay replaces one effect and adds one monster spell to prove path-based
extension. Run the Lua suite, affected game tests, build, vet, Go style
check, and staged diff check at the category boundary; broaden testing only
for a concrete integration risk.
