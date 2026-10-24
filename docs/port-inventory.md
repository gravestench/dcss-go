# Dungeon Crawl Stone Soup Go port inventory

The reference is DCSS commit
`e60ba3568b0c26447ad36ec5c7b963eb04b2778f` in
`/Users/dylanknuth/src/crawl`. The port has a traversable Dungeon through
D:15 with all 17 active source Dungeon layouts, but is not a complete DCSS
game.

## Where rules live

The bundled game rules are real Lua files under `internal/modfs/builtin`.
Go provides Akara storage, the turn runner, grid and visibility services,
named RNG streams, save encoding, the Lua VM, and terminal drawing. Lua owns
the implemented character, item, combat, monster, generation, command, save
semantics, and presentation policies. The implemented entity systems are
registered in `internal/modfs/builtin/systems`.

Species, jobs, monsters, spells, items, branches, and monster spellbooks are
registered from individual files under `content/<category>`. Gameplay and
the pregame menu read those same registered tables, so an overlay changes
both together. Lua validates the effective definitions and can retain
mod-added fields. Other imported content remains committed under `data`.
Species and job files own their menu descriptions and ordering; the shared
presentation module retains only startup modes, skill columns, and version.
Each job file includes its fixed starting grants. Wanderer keeps an explicit
dynamic marker; its generated equipment comes from its Lua starting rule.
Normal launch and restore read neither the C++ checkout nor the generated
JSON artifacts. Some JSON remains embedded by legacy Go catalog code and
cross-check tests; Lua content is now edited directly.
The effective registered book definitions determine player-book spell
membership through `policy/magic/player_book_catalog.lua`. The separate
committed `data/player_invoked_spells.lua` holds source player spells that
are invoked outside books. Neither rule reads the C++ tree at runtime.

Optional mod directories replace bundled Lua files by relative path and may
add files. Repeated `--mod-dir` flags apply sparse layers in order; the last
file at a path wins. Effective file bytes determine the ruleset hash recorded
by saves. Lua may register systems, policies, content definitions, and Akara
component schemas. The runtime exposes one generic component and grid
context rather than a handler API for each game domain.

## Playable coverage

| Domain | Implemented now | Main Lua location |
| --- | --- | --- |
| Character | Every legal selectable species/job pair starts; Lua owns chosen or fixed weapons, starting gear, species adjustments, attributes, skills, HP/MP, spell knowledge, Djinni's future spell schedule, religion, and durable origin state; training, XP, level gains, stat choice | `policy/character`, `schemas/character_origin.lua`, `systems/character_*` |
| Religion conduct | All 26 active gods have source-shaped likes and peeves in individual Lua modules. Existing kills, attacks, spells, item use, exploration, sight, training, damage, banishment, and contamination transitions report typed conduct through action owners. Piety, penance, first-sight and Uskayaw momentum survive saves; god descriptions read the effective rule metadata | `policy/religion/conduct`, `policy/religion/piety.lua`, `systems/religion_*` |
| Dungeon | D:1 terrain and population at launch; D:2–15 terrain, paired stairs, monsters, and vault entities generated from live state on first entry; fixed test scenario | `policy/generation`, `policy/population`, `policy/world`, `systems/world_*` |
| Abyss | 100 committed source DES definitions, including 97 MAP blocks and three mapless weighted definitions; Lua sampler, moving 80×70 window, source-position hooks, depth 1–7, morphing, authored and ambient ECS population, saved monster transit, Abyssal Knight pocket start, rune, XP exits, reentry, descent, teleport, escape, and text snapshots | `vaults/abyss`, `vaults/abyss_entry`, `policy/generation/abyss`, `policy/world/abyss` |
| Snake Pit vaults and end | All 85 source `snake.des` definitions are committed: eight weighted Lair entrances, 68 depth-qualified ordinary and extra maps, and nine mandatory Snake:4 endings. Eight source inline-script sites run as named Lua hooks. The source entry's keyed stair, vault history, typed records, rune, and reciprocal travel survive saves. Source random-item class requests and Snake out-of-depth monster caps reach the live generation path | `vaults/snake_entry`, `vaults/snake`, `vaults/snake_end`, `policy/generation/vaults/branch_entry.lua`, `policy/generation/vaults/primary.lua` |
| Lair vaults and end | All 116 source `lair.des` definitions are committed as 13 weighted Dungeon entrances, 89 ordinary and helper maps, and 14 mandatory Lair:5 endings. Shared woods and Beast Lair source decisions run as Lua hooks; five small endings select one fitting partner through the effective catalog. Keyed entry stairs, end IDs, map records, and reciprocal travel survive saves. Source delayed skeleton decay and feature names are retained as typed effects. A source `plant` script fault and two misspelled unrand names use the intended catalog identities | `vaults/lair_entry`, `vaults/lair`, `vaults/lair_end`, `policy/generation/vaults/lair`, `policy/generation/vaults/lair_end` |
| Orc vaults and end | All 77 source `orc.des` definitions are split into 19 weighted Dungeon gates, 42 ordinary and helper maps, and 16 mandatory Orc:2 endings. Named Lua hooks port every source script site; the gardens and community endings compose child maps with placement-local settings. Keyed Orc and Elf entrances, optional shop or floor choices, typed delayed decay, end IDs, and save validation use the live generation path. Historical corpse decay still depends on its live consumer | `vaults/orc_entry`, `vaults/orc`, `vaults/orc_end`, `policy/generation/vaults/orc_entry`, `policy/generation/vaults/orc_end` |
| Elf vaults | All 115 source `elf.des` definitions are split into 16 Elf:1 arrivals, 55 ordinary rooms, 19 blade-entry helpers, four Elf:2 Hall of Blades primaries, and 21 Elf:3 endings. Source-position Lua hooks own shared Hall monsters and final loot, conditional directives, and the mapless spread controller. The weighted dummy, authored Orc return, tagged Hall helpers, three floor-primary choices, typed records, and saved IDs use the live generation path. Source effects without live consumers remain typed records pending their gameplay slices | `vaults/elf_arrival`, `vaults/elf`, `vaults/elf_blade_entry`, `vaults/elf_blades`, `vaults/elf_end`, `policy/generation/vaults/elf*` |
| Depths entrances | All eight source `depths.des` D:15 gates are individual DES files. The source shared setup is explicit per map, and the grave's feature name uses a named Lua hook. Weighted selection, keyed stair, reciprocal Depths:1 travel, typed records, saved source history, and sparse mod addition use the live branch-entry path | `vaults/depths_entry`, `policy/generation/vaults/branch_entry.lua`, `policy/generation/vaults/depths_entry` |
| Depths encompassing maps | All 17 source `depths_encompass.des` definitions are individual DES files: seven whole-floor maps and ten tagged helpers. Original MAP rows, static directives, named Lua hooks, source weights, shared uniqueness, and helper records use the early Depths floor owner. Depths:2 travel and save/restore are exercised; all 17 MAPs pass the production placement path. Source random monster list intent is stored as a typed record for future ambient respawn behavior | `vaults/depths_encompass`, `policy/generation/vaults/depths_encompass`, `policy/generation/vaults/encompass.lua` |
| Zot vaults and Hall | All 88 source `zot.des` definitions are committed as 15 Depths-side entry maps, 67 ordinary maps, four style helpers, one weighted no-op dummy, and the authored Zot:5 Hall. MAP rows match the pinned source byte-for-byte. Named Lua hooks own source choices; a saved ECS controller handles the overgrown stairs' LOS warning and delayed oklob growth. The Depths:4 gate, Zot:1–5 travel, three-rune first-entry check, one live Orb entity, pickup, timed Orb-run defenders, D:1 escape, victory, and save/restore are exercised. The terminal shows distinct win and Orb-less leave outcomes | `vaults/zot_entry`, `vaults/zot`, `vaults/layout/hall_of_Zot.des`, `policy/generation/vaults/zot`, `policy/world/zot_overgrown.lua`, `policy/character/endgame.lua`, `policy/character/orb_run.lua` |
| Swamp and Shoals Lair entrances | All ten source Swamp and eight source Shoals entrance maps are committed as individual DES files and join source-weighted scheduled entry pools. Their keyed gates, reciprocal travel, typed records, saved history, and Swamp fog machines are live. Shoals' room connectivity check is a named Lua validator | `vaults/swamp_entry`, `vaults/shoals_entry`, `policy/generation/vaults/branch_entry.lua`, `policy/generation/vaults/shoals_entry` |
| Ordinary Swamp vaults | All 107 source ordinary definitions are individual DES files: 104 maps and three mapless decor controllers. Source MAP bytes and static directives are audited; source-position Lua hooks, weighted selection, tagged child placement, keyed actors and items, and the saved Lady of the Lake movement trigger run through production generation. The Lady's delayed avatar retains verified ECS source provenance across save/restore. The source concealment-scroll set uses the saved per-run item choice. Pending effects include delayed corpse decay and feature-name presentation; authored hydra head count and coloured draconian base ID are saved but still need full combat and display traits | `vaults/swamp`, `policy/generation/vaults/swamp`, `policy/world/vault_trigger_callbacks/lady_of_lake.lua` |
| Ordinary Shoals vaults | All 74 source ordinary Shoals maps are committed as individual DES files. Twelve scripted sites run through named Lua hooks; source weighted candidates, keyed entities, depth choices, saved helper IDs, and a sparse mod-added map join the live Shoals generation path. The ghost map uses the live generic ghost identity while historical ghost selection remains a gameplay gap | `vaults/shoals`, `policy/generation/vaults/shoals`, `policy/generation/vaults/regular.lua` |
| Swamp end | All eleven source Swamp:4 end maps are committed as DES with source-position Lua hooks, mandatory weighted placement, one decaying rune, and saved end-map validation | `vaults/swamp_end`, `policy/generation/vaults/primary.lua`, `policy/save/vaults.lua` |
| Spider vaults and end | All 103 source Spider definitions are committed: eleven weighted Lair entrances, 66 ordinary maps, 17 jumping parent and helper maps, and nine mandatory Spider:4 endings. Source scripts run as named Lua hooks. The keyed entry, jumping submaps, typed records, rune, and reciprocal travel survive saves; the Spider basket uses saved one-shot ECS movement triggers. Its source `crawl.more()` acknowledgment prompt remains to port | `vaults/spider_entry`, `vaults/spider`, `vaults/spider_end`, `policy/generation/vaults/spider`, `policy/world/vault_triggers.lua` |
| Shoals end | All 26 source Shoals finale and helper definitions are committed as DES; six weighted endings compose four island controllers or two encompass maps. The Lua island-height layout opens normal Shoals travel and supplies elevations to the tide system. Rune, false-rune, and saved helper ownership are checked through Lua policy | `vaults/shoals_end`, `policy/generation/vaults/shoals_end`, `policy/generation/layouts/layout_shoals.lua` |
| Slime vaults and end | All 29 source `slime.des` definitions are committed: ten weighted Lair entry maps, eighteen depth-qualified Slime:1–4 vaults, and the whole-floor Slime:5 finale. The Royal Jelly or Jiyva's six-star reward opens 44 saved ECS seal walls; the slimy rune is collectible. Source entry links, vault history, rune records, and released terrain survive saves. The live `no_jiyva` property protects cells from Jiyva item pursuit, feeding, spawning, and off-floor eating; Slime:5 lifts only its own restriction when the seals open | `vaults/slime_entry`, `vaults/slime`, `vaults/layout/slime_pit.des`, `policy/generation/vaults/branch_entry.lua`, `policy/generation/vaults/regular.lua`, `policy/world/slime_seals.lua`, `policy/religion/jiyva` |
| Arrival vault population | All 337 selectable source arrivals resolve authored monster and item expressions through Lua content catalogs, place Akara entities with vault origins, and retain source selection in level records; a mod can add a monster and arrival file by path | `policy/generation/vaults/specs`, `policy/population/vaults.lua`, `schemas/vault_origin.lua` |
| Item generation | Source-backed class and subtype selection feeds floor loot, monster equipment, vault requests, and acquirement; selected generated state is committed to saves | `policy/item_generation`, `systems/item_*` |
| Shops | Ten active source shop types, 70 committed source shop vault definitions, scripted shop maps, authored stock and supplemental D:1–15 placement, saved wallet and stock, gold pickup, fixed shop scenario, prices, shopping list, purchase, and terminal menu | `vaults/shop`, `policy/generation/vaults/shop`, `policy/shops`, `schemas/*shop*` |
| Traps | Ten active source trap definitions and effects in Lua; authored vault traps become saved Akara entities; entry, held state, marks, timed passages, Zot outcomes, visibility, and mod-added trap files use one catalog | `content/traps`, `policy/traps`, `systems/world_traps.lua` |
| Dynamic actors | All 908 committed branch population rows feed the generated picker, with source local-depth ranges deciding which monsters can spawn; jackal bands, source HP/speed, decisions, energy, attacks, carried weapons and missiles; all 285 committed monster spellbooks use source-order weighted and conditional slot selection, with effect coverage required before a monster enters the live roster | `policy/ai`, `policy/population`, `policy/monster_energy.lua`, `systems/monster_*` |
| Monster beam, hex, and support spells | Seventy-two source-backed beam profiles, sixteen targeted hex effects, thirteen self-support effects, four ally-support effects, four Serpent of Hell composite breaths, and three life-transfer spells. Lua owns rays, resistance, healing, buffs, auras, clouds, displacement, poison, and temporary terrain; typed target plans carry the selected destination through resolution | `content/monster_beams`, `policy/combat/monster_beams`, `policy/combat/monster_hexes`, `policy/combat/monster_support`, `policy/combat/monster_spells` |
| Monster direct summons | Thirty-nine source direct-creature effects choose species, counts, durations, and placement in their own Lua files. Akara stores caster ownership, named attitude, expiry, Invitation branch choice, Brothers count, and special summoned state; a live monster cast survives restore | `policy/combat/monster_summons`, `policy/combat/monster_spells`, `schemas/magic_*` |
| Monster displacement and recall | Eight Blink variants use focused Lua landing, ally, and foe rules. Word of Recall stores its chant and breath cooldown on the caster, then moves eligible distant allies. Typed plans preserve target cells, and a live Blink cast survives restore | `policy/combat/monster_displacement`, `policy/combat/monster_spells`, `schemas/magic_monster_recall.lua`, `systems/magic_monster_recall.lua` |
| Monster status and enchantment spells | Nine non-ray effects cover Abjuration, Berserk Other, Black Mark, Brain Feed, Corrupting Pulse, Dream Dust, Flay, Injury Bond, and Silence. Focused ECS conditions preserve timers and actor references; shared silence rules cover overlapping auras | `policy/combat/monster_spells`, `policy/combat/monster_flay.lua`, `policy/world/silence.lua`, `schemas/*monster*`, `systems/*monster*` |
| Monster instant afflictions | Malmutate runs as an irresistible targeted ray and changes saved player mutations or monster Wretched state. Entropic Weave directly corrodes equipment without acid damage; both effects preserve state and RNG across a live cast and restore | `policy/combat/monster_spells`, `policy/combat/monster_hexes`, `policy/monsters/malmutation.lua`, `policy/combat/player_corrosion.lua` |
| Monster destructive beams | Throw Barbs uses its physical missile profile beyond melee reach and saves a movement-damaging barbs wound. Major Destruction chooses among seven source zaps; Legendary Destruction draws two weighted explosions. Sticky Flame and Orb of Electricity child profiles are committed, and live casts survive restore | `policy/combat/monster_spells/destruction.lua`, `policy/combat/barbs.lua`, `content/monster_beams` |
| Monster flame conjurations | Marshlight, Holy Flames, and Stoke Flames create saved foxfire and inferno actors or holy cloud cells. Construct turns and the inferno death blast run through Lua ECS ownership | `policy/combat/monster_spells`, `policy/combat/monster_flames`, `policy/magic/effects/summons/foxfire.lua` |
| Monster conjured constructs | Battlesphere, Conjure Ball Lightning, and Spellforged Servitor create saved spell actors. Monster conjurations trigger caster-owned spheres; monster servitors snapshot currently executable source-priority spells and cast through ordinary AI | `policy/combat/monster_spells`, `policy/magic/effects/summons`, `schemas/magic_summon_servitor.lua` |
| Walking tomes and living spells | All four source tome species select their own Petrify, Crystal Spear, Smiting, or Iceblast living spell. Summons carry a saved custom slot, inherit spell HD, obey the six-actor owner cap, cast through ordinary monster AI, and disappear after one cast | `policy/combat/monster_summons/living_spells.lua`, `schemas/magic_summon_living_spell.lua`, `policy/combat/monster_spells` |
| Monster mirror clones | Phantom Mirror and fake Mara summoning copy live monster bodies into saved Akara actors with independent gear, source HP scaling, finite summon lifetimes, and nonrecursive spell selection | `policy/combat/monster_summons/mirror.lua`, `policy/combat/clone_inventory.lua`, `schemas/magic_summon_mirror.lua` |
| Summon Illusion | Mara's spell snapshots a visible player's combat identity into a saved Akara actor or copies a visible enemy monster beside its source; dynamic HP, melee, defenses, resistances, timed boons, and currently executable ghost spells feed ordinary AI and combat | `policy/combat/monster_summons/player_illusion.lua`, `policy/combat/monster_summons/mirror.lua`, `policy/combat/monster_profile.lua`, `schemas/magic_player_illusion.lua` |
| Combat | Fighter melee and headbutts; generated melee brands through shared monster-target Lua effects for player, monster, summon, and illusion attackers; saved spectral allies with damage sharing, distortion banishment, and chaos monster effects; all seven active magical staves with source skill procs and AC/resistance routes; player fire/throw with eight launcher types, penetrating javelins, monster shields, launcher fire/frost/vorpal, and missile poison/curare/dispersal; monster natural/weapon/ranged hits, early weapon brands against the player, Freeze, Slug Dart, sling bullets, stones, poisoned darts, AC/EV, constriction, kills, XP, and corpses | `policy/combat`, `policy/death.lua`, `systems/attack_*`, `systems/actor_death.lua` |
| Items and status | Equipment, consumables, statuses, and identification | `policy/inventory`, `policy/items`, `systems/item_*` |
| XP evokers | All eight source XP evokers have Lua-owned charge debt, XP recharge, item selection, effects, and saved state. Geryon carries the Horn. Phial flooding and Waterlogged, Tin blasts, Condenser clouds, mirror clones, Box beasts, Rod Thunderbolt, Horn beasts, and Chessboard statuses resolve through their existing combat and summon owners | `policy/inventory/evokers`, `systems/item_evoker.lua`, `schemas/character_xp_evokers.lua` |
| Elyvilon active abilities | Purification, Heal Other, Heal Self, and Divine Vigour register as Lua powers. Purification cures represented ailments even while confused; Heal Other can heal or permanently pacify a monster for one nonlethal XP award; Divine Vigour's saved timer changes derived HP and MP until expiry, penance, or departure | `policy/abilities/elyvilon`, `policy/religion/elyvilon`, `schemas/religion_elyvilon_*` |
| Player magic | Spell learning and casting, source-backed spell IDs, Lua effect families for direct damage, zaps, summons, terrain, statuses, forms, and Unravelling | `policy/magic`, `systems/player_spell.lua`, `schemas/magic_*` |
| Player mutations | Source definitions and Lua-owned mutation records, transitions, passive effects, abilities, and saved state; Vampire blood rituals and Bat Form are implemented; source consumers in other unported domains remain inventoried below | `content/mutations`, `policy/mutations`, `policy/abilities`, `schemas/character_*` |
| Client | Full-terminal 79×24 minimum, expanding dungeon view, DCSS-shaped startup and game screens, inventory, skills, help, fire/throw targeting, direction prompts, and unavailable-feature notices | `policy/presentation`, `policy/input`, `internal/terminal` |
| Persistence | Version-39 JSON saves, named RNG state, terrain and ECS state, Lua schemas, ruleset hash, semantic restore validation | `policy/save`, `internal/game/save*.go`, `internal/save` |

The Shoals layout uses source island counts and height bands. Exact source
contour planning and flora are still fidelity work; the current heightmap
feeds the already saved tide rules.

Items support pickup, drop, wielding, armour delays, and put-on/removal of all
24 active jewellery records. All 17 active potions and 19 active scrolls have
Lua effects. The saved rules also cover buffs, tree form, ammunition, poison,
curare, trapping nets, regeneration, duration decay, unknown appearances,
type discovery, enchantment, and property knowledge. Lua declarations now
project jewellery stat, resistance, vision, flight, MP, wizardry, acrobat,
guardian-spirit, and attuned regeneration effects from the worn ECS items.
Blocked hostile stones, poisoned darts, sling bullets, and Slug Dart now
return to their shooter when an amulet of reflection is worn and the shot is
still clear. The Faith multiplier and ordinary conduct consequences now live
in the Lua piety and conduct owners. God gifts, wrath execution, and other
divine effects still need their religion slices.
The monster beam family now includes player amulet reflection and monster
shield reflection. Player Reflection shields now share the amulet's block
and return path. All seven generated player shield egos have their source
resistance, +3 Protection AC, or reflection effect while worn; a melded
or removed shield loses its effect. Monster shield reflection already
runs. Monster fire, cold, electric, poison, acid, steam, and negative
energy resistance now reads live equipped armour, jewellery, staves,
and artefacts through one Lua owner. Spells, clouds, poison, and drain
consume that result, including source item-use limits and poison's
one-pip equipment cap. Worn Cigotuvi's Embrace also grants monster
miasma immunity. Further spell families remain for their later
combat domains.
Monster willpower now reads the live actor's HD, active artefacts,
armour, jewellery, Trog's Hand, and Lowered Will before each saving
throw. Removing gear changes the next roll immediately; a caster's
Guile armour reduces the target's effective will only for that roll.
Phantom Mirror uses the same rolled margin for clone duration. The
unported Kiku wretch property remains part of the later Kiku domain.
Monster flight and sight now inspect the current actor and its equipped
ring, armour ego, and artefacts. Habitat, web, invisibility detection,
and gazes consume these live results; draconian jobs inherit their saved
base color's innate flight. An active artefact scan centralizes source
item-use, slot-class, and dual-wield limits for these properties plus
monster resistance and willpower. Saved Bat and Weird mutant-beast
facets supply their source flight and sight traits. Zombies, skeletons,
simulacra, spectral things, and bound souls inherit flight from their saved
base species.
Monster melee now visits its complete ordered attack sequence against
players and monsters in one action. Saved hydra and Serpent head counts
repeat the first bite, living hydras can retarget adjacent enemies after
a kill or displacement, derived undead borrow downscaled base attacks,
and dual wielders alternate their active weapons. Cherub and random
attack types choose their contact shape on each attempt. A constricting
slot starts one hold; later damage reads that slot's base damage rather
than a fixed second slot.
Monster reach now derives from natural Reach, Sting, Tongue, and Rift
contacts plus the live primary weapon. Polearms and the Lochaber axe reach
two cells; the Rift artefact reaches three through solid-blocking sight.
The AI offers distant melee only when the current path permits it, combat
checks the path again, and only each eligible reaching slot makes contact.
Removing a weapon changes that capability on the next action.
Tongue and ordinary Acid now share source acid splash on damaging contact;
Rift and ordinary Distort share weighted warp, blink, and banishment through
the existing player and monster distortion owners. Both effects use the
resolved contact after reach geometry and preserve their damage gates.
Drain Stat now selects Strength, Intelligence, or Dexterity on each live
contact. Natural Drain, Vampiric, Scarab, Pain, and Antimagic melee use their
source chances and power formulas against player and monster actors. Their
secondary HP, MP, slow, and drain state stays in the existing ECS owners;
ghost moths regain stolen MP and antimagic vine stalkers shorten their own
enchantment on contact.
Confuse, Barbs, Rage, Vulnerability, and Poison Paralysis now apply after
source monster melee contacts to player and monster victims. Each effect
uses the saved status owner already shared with spells, scrolls, or missiles.
Spore confusion permanently spends the attacker's HD; poison paralysis
keeps its independent poison and control chances and its rPois gates.
Blink and Blink With contact now defer displacement until the monster's
whole melee round ends. The attacker uses the ordinary blink landing and
the original victim joins it on a legal neighboring cell when available.
Repeated contact events merge within the round; stasis and DES no-teleport
cells remain effective at resolution.
Holy, Pure Fire, and Sear monster contacts now run through one Lua flavour
owner for player and monster defenders. Holy checks live undead or demonic
susceptibility; Pure Fire applies half armour and current fire resistance
even when physical contact dealt no HP loss; Sear adds the saved fire
vulnerability read by later fire damage. Summoned fire vortices use the
ordinary melee sequence and burn themselves out after a successful hit.
Mutate and Chaotic natural contacts now reach player and monster mutation
and chaos owners through actual melee rounds. Weapon Chaos and natural
Chaotic contact share source eligibility and weighted selection, while
their chosen effects retain the distinct weapon and natural formulas.
Chaos Venom and ordinary Poison use the same saved player or monster poison
path, so one physical contact cannot apply the dose twice.
Broodmother Spider bites now use the shared Summon Spiders species pool,
create one timed Akara child beside the wounded actor on a successful
contact chance, and preserve native monster provenance through save checks.
Shadowstab now checks the live defender's sight before contact. An unseen
Shadow bypasses evasion but not shields, gains the source pre-armour stab
multiplier, and loses its temporary invisibility after a surviving target's
successful contact even when armour absorbs the hit. Sleeping defenders
grant the same damage bonus to ordinary monster melee.
Maurice's Steal contact now scans eligible carried player items, weights
them by fully identified source value, respects equipment and pending use,
and transfers full or partial stacks into his Akara inventory. Source
slot capacity and the gold diversion decide what he takes. Gold debits the
saved wallet without recording a purchase and becomes recoverable carried
loot with Zin tithe metadata. A stolen two-handed weapon drops his shield.
Monster death drops and save validation use those same item entities.
Five source-guaranteed monster artefacts now enter the same item history and
Akara inventory path as other uniques: Cerebov, Dispater, and Asmodeus carry
their named weapons; the Enchantress and Tiamat wear their named armour.
The latter two also retain their catalogued weapon rolls, and Tiamat's
draconian cloak occupies the monster body-armour inventory slot.
Their `none` generation mode still excludes random drops, while explicit
source gear claims the unique and leaves loot on death.
All nine source one-in-N monster artefact owners now use individual Lua
gear handlers: Nikola, Amaemon, Arachne, Maggie, Margery, Terence, Grunn,
Parghit, and Gastronok. Their saved unique history prevents a second named
item, and losing rolls preserve source ordinary weapons or armour, including
Nikola's electric rapier, Amaemon's venom whip, and Grunn's draining polearm.
Arachne's poison staff uses the shared staff melee profile; Gastronok's hat
maps to the monster body slot. Cerebov's disarm exception and Geryon's
non-artefact horn remain follow-up work.
Vampiric Draining, Drain Life, and Malign Offering share live negative-energy
resistance and HP-transfer rules. Their spell files separately own adjacent,
LOS area, and beam targeting; Malign Offering heals every aligned actor except
the nonliving, while Drain Life excludes aligned victims.
Symbol of Torment and the Torment scroll use one actor-neutral Lua area rule.
The monster's AI declines a cast when no vulnerable enemy is in the area or
an allied caster would torment the player.
Flaming, Petrifying, and Spectral Cloud now leave source-shaped ray trails;
the first and last also place an endpoint field. Ink Cloud is a water-only
self cast. Their cloud cells use the existing saved Lua cloud owner.

Core Akara components remain typed Go stores where the generic engine must
read them; Lua systems and policies change their authoritative values through
the same context used by Lua-defined components. Dense terrain, exploration,
and occupancy remain level grids.

Arrival monsters and items use the same Akara actor, inventory, and corpse
components as ordinary population. A Lua-owned `vault.origin` component
links each live entity to a saved level record. Restore validates that link
and never rerolls the source expression; moved or dead monsters and picked-up
or consumed items retain their natural lifecycle. Authored monsters do not
consume the ambient Dungeon population budget. Source terrain and marker
effects remain typed level records where their gameplay is still pending;
special monster and item behavior beyond the current generic systems remains
for later domain slices.
Authored hostile monsters now start asleep unless their selected `MONS` term
or vault tag says `generate_awake`; nonhostile vault actors start awake.
Visible players test stealth to wake sleepers, while sound and injury also
wake them. A `patrolling` monster stores its source cell in an actor-owned
Lua component and selects idle targets near that anchor. Both AI sleep state
and the patrol anchor survive saves with source validation.

Terminal key and menu policy lives in the embedded `policy/input` Lua modules.
The Go terminal applies their validated decisions and handles drawing, saves,
and game lifecycle. Replacing a single screen module changes its controls and
the effective ruleset hash without adding a Go keymap.

## Committed source content

The import artifacts account for 43 species, 31 jobs, 700 monster rows,
403 spell identities, 285 monster spellbooks, 408 item
identities, 38 branches, and 908 population rows in separate branch
catalogs, plus monster weapon loadouts, starting grants, and console
presentation metadata. All 162 primary and 16 secondary weapon specs live in
their owning monster Lua files. The initial import tools have been removed;
content coverage
does not imply that its behavior is playable. Monster spell selection accepts
every committed book's slot structure, including repeated spell IDs with
distinct flags. Live monster effects include the early roster's Freeze and
Slug Dart, Petrify, source-backed beam spells, 16 targeted hex effects, and all 13
self-support spells: Might, Invisibility, Haste, Minor Healing, Major Healing,
Repel Missiles, Berserker Rage, Sprint, Trog's Hand, Injury Mirror, Woodweal,
Still Winds, and Aura of Brilliance. Missing effects are
reported before a monster joins a generation roster; the remaining effects
are a prerequisite for deeper Dungeon population. Fire, Cold, Searing, and
Chilling Breath now use source zaps and natural HD. Chilling Breath has no
bundled monster-book slot yet but can be used by an overlay.
Metal Splinters and Splinterspray use their committed source zaps and pierce
multiple targets. Their physical fragment flavour rolls armour three times
per contact without an elemental resistance adjustment.
The direct-creature summon family now includes fixed, weighted, level
population, branch, foe-centered, berserker, and elemental casts. Shadow
Creatures currently uses the playable Dungeon population and waits for
branch-specific rosters elsewhere; Pan's local demon allocation waits for
the Pandemonium level owner. Phantom Mirror and fake Mara summoning now
copy live monster bodies; player and monster illusions still require the
dedicated illusion-profile category. Other specialized actors and terrain
effects remain in later source spell categories.
The monster displacement family now covers all eight Blink variants and Word
of Recall. Self and foe blinks share source-shaped landing, habitat, and
no-tele checks; ally blinks reuse existing actors rather than creating new
ones. Recall's chant and cooldown are saved on the caster and are interrupted
by silence or incapacitation. The live spellbook test moves a monster and
restores its position and RNG state.
The shared summon owner preserves friendly and neutral caster allegiance.
Allied monster AI now picks visible enemy monsters and offers its spellbook
before routing; without a foe, it follows the player. The saved spell intent
keeps its foe distinct from a self or cell target plan. Freeze, Petrify, and
Slug Dart resolve against monster health, resistance, status, and defense.
Shared beam and hex resolution now has live allied-caster coverage against
enemy monsters, including a missed ray's friendly-fire planning guard;
other spell effects still need actor-target audits. Hostile casters retain
their player-awareness gate. Direct strikes, support spells, beam contacts,
and shared poison, drain, and enchantment messages test player perception
before naming actors or describing offscreen terrain changes. Other event
paths still need an audit. Invisibility messages sample sight before the
enchantment takes hold.
Monster Cause Fear and Mass Confusion now select unaligned actors across
unobstructed sight, test each victim's will, and write fear or confusion to
the victim's saved ECS state. Player fear retains its source monsters and
blocks approach or sometimes a melee attempt until the sources or timer
expire. Mesmerise and the two siren songs now share player-owned beholder
state: living, audible sources constrain retreat and stairs; breaking the
last hold grants saved temporary immunity. Avatar Song keeps a separate
caster-owned timer, attempts safe player pulls, and calls drowned souls from
open deep water. The song rules still need live roster coverage as later
Shoals and unique-monster population slices become playable.
The 11 wand-to-spell links are committed in their wand definitions, with a
legacy JSON artifact retained for cross-checks. Source appearance words are
committed in `data/item_appearances.lua`. The runtime does not read C++ to
name an item.

The pinned C++ source anchors for live behavior are `newgame.cc`,
`ng-setup.cc`, `player.cc`, `skills.cc`, `item-use.cc`, `potion.cc`,
`melee-attack.cc`, `mon-act.cc`, `mon-death.cc`, `timed-effects.cc`,
`dgn-layouts.cc`, and the branch, monster, item, spell, species, job, and
population definition files. Generated modules record their exact source
paths and revision. Source-specific Lua rules cite the relevant C++ paths
and preserve unusual roll order.

## Remaining full-game work

All legal selectable species/job combinations now enter the source-layout
D:1–15 Dungeon. Their starting state is Lua-owned and saved; most later species and
job abilities are still unavailable. The many imported monsters, spells,
items, and branches still need behavior, generation, and UI flows.
Only D:1 Dungeon terrain and population exist at launch. D:2–15 terrain,
paired stairs, ordinary monsters, authored vault entities, and shops are
generated from live state on first entry. The pending frontier stair,
population state, and no-spawn mask survive the Go save format. Scheduled
ordinary branch entrances now use stable IDs and source branch layouts and
population. Lair and Orc first and second floors have exercised reciprocal
entry, save, and restore. Depths opens from one of eight source D:15 gates
on its scheduled Dungeon entrance. Temple now opens through a source
Dungeon entry vault, uses its
saved source map and god partition, and returns through reciprocal stairs.
Vaults opens from its scheduled Dungeon entrance. Vaults:1–4 use eleven
source primary layouts and tagged DES room pools. Vaults:5 uses the authored
`vaults_vault` end map with four source quadrants and one silver rune. The
selected helper IDs, typed records, branch links, terrain, and rune progress
survive save/restore. When loaded under an explicitly accepted ruleset
change, saves made before the end map opened retain their original
unavailable Vaults:5 stair. Normal restore still requires a matching ruleset
hash. Other branch-specific mechanics still need parity.
The Temple content catalog includes all 53 source Dungeon entry maps and all
90 main maps, including 47 with source Lua ported to named hooks. A
source-weighted map, altar count, and complete god partition are chosen at
new-game creation and saved before Temple is visited. Overflow gods are now
grouped and assigned D:3–10 depths in that same saved plan, following the
source's specialized and generic map-size weights. Dungeon generation now
places matching source `.des` maps before ordinary extra vaults, binds both
fixed and random altar cells to the saved gods, and preserves those identities
through save and restore. A ten-seed D:1–10 generation sweep exercised the
integrated path. Live Temple placement uses the selected map, assigns exact
god IDs to its altar records, applies source open-sea or lava-sea borders,
and materializes authored monsters and items without ambient Temple spawns.
Temple altars now render with their saved god names, and restore rejects an
altar identity that disagrees with the plan.
Worship and overflow map event callbacks still need gameplay passes.
All 232 source overflow altar maps are committed as individual `.des` files;
their MAP rows match the source exactly. They load through a dedicated catalog
and are selected only for scheduled overflow groups, rather than as ordinary
extra vaults. Remaining source map event effects still need gameplay rules.
The original script text remains beside each map as comments.
The repeated terrain names and one unconditional corpse-decay effect now
have named Lua hooks. All eight generic overflow maps with count-dependent
geometry now read a local altar-count setting; placement tests verify their
source layouts retain exactly the requested number of altar cells.
Twelve overflow maps now choose their authored monster declarations by
Dungeon, Depths, or Crypt branch. Named spectral monsters in these maps
resolve to the generic spectral actor plus their base species identity.
Ten overflow maps also run their conditional terrain, trap, or substitution
rules from local depth and branch-bottom context. The caller must supply
the branch bottom; a missing value is an error rather than an implicit
assumption that a shaft is safe.
Eleven more overflow maps now choose their depth-scaled monster rosters or
Makhleb's corpse scene in Lua, including the large Trog antimagic and
three-tier torment definitions. Source `god:` monster modifiers persist on
the spawned actor; weighted explicit equipment retains its brand and item
identification state.
The good-god palette and garden choices, Dithmenos shadow scaling, and
Trog-or-Makhleb fire temple altar are now Lua hooks. The selected overflow
god tag is passed as local map context rather than read from a DES global.
Trog and Sif Muna's shared gift vault now selects all three source depth
tiers in one Lua hook. Its authored weapon enchantment and brand, Sif book
owner, spell count, and total spell-level budget pass through item placement
and generation.
Forced source weapon brands now use the source's weapon compatibility rule;
ordinary brand roll weights do not restrict authored shop stock. This allows
the good-god shop's holy club while rejecting melee-only brands on bows and
ranged-only brands on clubs.
Wanderer's gift branches now reuse saved per-run item-set choices for
wand and concealment-scroll gifts. A dedicated Wanderer RNG stream drives
its roles and gifts; minor themed books select a usable two-spell pair
totaling four levels without preferring the 1+3 pattern over 2+2.
The Go RNG does not reproduce the C++ subgenerator byte sequence, and
source-wide spell usability still needs parity work.
Djinni's future spell list is durable, but later innate spell acquisition
and the complete source spell-usability filter remain to be ported.
The D:1 arrival catalog contains all 339 source definitions: 337 selectable
arrivals and two helpers. Their map directives and 36 Lua script blocks are
ported. Authored monsters and items now materialize as ECS entities; terrain,
markers, and other unimplemented effects remain typed pending level records.
Authored water and lava monsters convert their spawn cells to their primary
habitat. Random arrival items use source class weights and preserve ordinary,
depth-boosted `*`, good, and superb requests. The completed item-generation
slice selects source-backed subtypes and properties for floor loot, gear,
vault requests, and acquirement. Artefact type, plus, and property discovery
now belongs to each item; hidden fixed names, the Octopus King exception,
and random artefacts retain their appearance through save/restore. All 182
weighted source name groups are committed as individually replaceable Lua
definitions; generated equipment uses their class and appearance groups.
Themed and single-level random books now use the source book groups for
titles, owners, school wording, difficulty bands, and hidden appearances.
All 26 active gods now have layered Lua definitions. The shared Lua
eligibility rule covers species, mutation, form, and Gozag fee restrictions;
Gozag's fee reads saved gold generated on non-Abyss floors. The piety owner
stores changes in the player ECS component and signals rank and gift checks;
its random draws replay after save/restore. Kiku now grants both permanent
spell-library sets, and Vehumet makes thirteen escalating temporary book
spell offers. Current offers, prior offer history, cooldown, and gift counts
are saved on the player; memorisation turns an accepted offer into permanent
library knowledge, and renunciation withdraws the rest. One Lua transition
path now joins or renounces any registered god, preserves good-god piety
transfer, records
source penance, charges Gozag, and preserves Ignis's spent reserve. Ru,
Ashenzari and Yredelemnul entry exceptions retain typed pending state.
Xom's ecumenical altar now increases his saved interest immediately through
the same stimulation rule used by ordinary events.
The saved god-time clock now starts at 200 aut, then runs source 100–300 aut
checks. Nineteen gods use their source one-in-17 or one-in-35 piety decay;
seven gods use alternative piety mechanics and skip that roll. A zero-piety
check forces departure, while voluntary renunciation alone can preserve
good-god piety for transfer.
Both stair keys pray on an altar. Conversion, refusal, ecumenical identification,
two-step renunciation, saved altar identity, and the god/piety/penance HUD now
run through Lua command, system, and presentation rules. The pending
entry rewards and most god-specific leave cleanup still need their
behavior owners. Conduct responses now cover all 26 active gods. New action
domains must report their corresponding conduct at the action owner; current
producers cover actions the port can execute today. Sif Muna now gives
source-weighted books, Trog weapons, and Okawaru equipment or throwing
stacks. Each is a positioned ECS item with saved god provenance and its
own piety and timeout rule. Jiyva now prunes acquired mutation ranks and
grants four good or slime ranks through the saved mutation ECS records.
Nemelex now gifts source-weighted counts to three saved player decks,
including source capacity and cooldown behavior. Draw, Triple Draw, Deal
Four, and Stack Five now save their sampled choices, charge source ability
costs, and resolve Lua card modules through the generic command bridge.
The 21 active card IDs have effect modules and focused scenarios. Divine
Wrath routes every eligible god to a dedicated Lua handler. Makhleb's
servant and destruction pools now resolve, including Shock and lasting
Sticky Flame. Vehumet's nine conjuration bands now cast through the god
avatar, including source-backed Sting, Flame Tongue, and Mephitic Cloud.
Fedhas's three wrath branches now convert visible corpses to hostile
spores, fire nature spells through the avatar, or plant source-sized rings
of hostile plants.
Yredelemnul's wrath now reclaims permanent undead gifts from current
worshippers, chooses source-weighted Dungeon zombie or skeleton bases, and
sends level-scaled hostile undead servants. The god source, allegiance,
expiry, and derived monster base survive save and restore. Source branches
Ignis now tries a source-bounded shaft, anoints the strongest eligible
visible enemy, then falls back to fire elementals. Shafts stage and
populate missing Dungeon floors before the player lands, and a failed
destination restores the card action and RNG. The permanent champion
marker survives saves and changes first-attack Fire flavour, movement
energy, visibility, alertness, and Beogh conversion eligibility through
their usual owners. Shaft arrival checks dangerous terrain, clouds,
teleport masks, slime walls, and hostile sight through Lua. A committed
text snapshot shows D:1–D:3 and their stair links after a three-floor
fall. The Xom branch now invokes his complete action owner. All eligible
Wrath gods have named Lua handlers, while five source gods decline a
Wrath card draw. Royal Jelly death now has a saved player flag; after
Jiyva is mollified and no longer worshipped, a Wrath draw skips him.
A lingering god spell now retains an inert Lua ECS source
for burn, cloud, terrain, and summon attribution through save and restore.
Other god abilities, remaining passives, and ordinary timed wrath remain
separate religion slices.
Okawaru's Heroism, Finesse, and Duel are now playable Lua powers with the
source rank, failure, MP, and piety gates. Heroism projects mundane skill
levels without changing training; Finesse changes attack delay and is
cancelled by Berserk. Their saved timers expire, refresh, and clear on
penance or departure. Duel selects one of four committed source Arena
maps, alerts and moves an eligible challenger, preserves the exact outside
return site, and opens the authored barrier after the final marked enemy
dies. Bennu revival and Jiyva splits preserve the mark; banished targets
release it. Victors receive the source 15–25-turn return clock. Live
opponents return beside the player, and renunciation or automatic
excommunication forces a return. Player banishment is blocked in Arena as
in source. Text snapshots
show all four Arena maps and the entry, target, barrier, and exit cells.
Ordinary slime merge lineage is not yet represented; Arena mode outside
Okawaru's Duel is a separate feature.
Fedhas now neutralises eligible hostile plants as they act, reverses plant
allegiance across loaded levels on desertion, cancels an active forest on
joining, and prevents hostile Awaken Forest under its passive. Okawaru now
dismisses friendly player-owned summons on the current floor when joined.
Jiyva now converts source jelly and eye genera on their monster turns.
Attempted conversion under penance, retry when that debt ends, desertion,
temporary charm removal, and off-level allegiance use saved actor state.
Owned summons on the former side expire when a slime changes allegiance.
At six stars, Jiyva spends a saved one-time reward and opens the Slime:5
clear-stone seals immediately or on the first later entry. The Royal
Jelly's death and this reward now share the Lua seal owner.
Jiyva's zero-rank ecology now makes good-neutral slime actors seek edible
items, consume stacks before their usual action, heal and split. A saved
random 100–300 aut timer attempts active-floor jelly spawning and
source-filtered item destruction on visited inactive floors. Per-cell
`no_jiyva` records protect all four paths. Source submerged state and the
parent jelly's split experience bookkeeping are still outside the actor
model; these remain explicit fidelity gaps rather than hidden substitutes.
Jiyva's defensive ranks now use live worship queries: zero-star protection
from adjacent slimy walls, one-star HP/MP regeneration, and two-star acid
and corrosion resistance. Slimy-wall terrain damages unprotected players
and visible non-slime monsters after their actions; penance or departure removes
the relevant passives immediately. The existing health, regeneration,
corrosion, grid, and worship owners carry their saved state.
At five stars, surviving monster-caused hits that take at least a quarter
of maximum HP eject one to five friendly, short-lived source slime species.
The hit source becomes their saved target when alive, and all four species
and count tiers run through the Lua reaction and ordinary ECS summon owner.
Xom's heavy-hit butterflies now use that saved summon path. Dithmenos,
the cloak of the Thief, and Xom resolve hit smoke through one ordered Lua
cloud policy. Worn `*Corrode` and `*Slow` artefacts react after mutation
effects and use the saved corrosion and Slow statuses; poison excludes
both drawbacks. Ru's hit retribution and Xom's damage amusement still
belong to their broader god-action domains.
Zin's entry and pickup tithes now share one Lua rule. Saved gold remembers
whether it was seen before conversion or acquired, and the wallet keeps
donations and fractional carry across piles and save/restore.
Trog's source magic-skill restriction now runs through its god behavior
module and the shared training owner; Gnoll distributed training keeps its
source exception without a permanent skill-point loss.
Trog's Berserk, Trog's Hand, and Brothers in Arms now use three Lua ability
modules. The Hand's saved timer adds source regeneration and willpower;
Brothers creates a friendly, temporary, berserk ECS monster from one shared
source roster. Its summon expiry follows its monster-action Berserk clock.
Confusion blocks invocations, and deliberate Berserk bypasses Clarity.
Penance and departure end the Hand and dismiss temporary
Trog summons. The ordinary ability menu and Go save path exercise these
powers without Trog-specific Go handlers.
Elyvilon's four active powers now use the same command bridge. The
pacification marker is durable, and the source's class intelligence,
holiness, mobility, and average HP gate the offer. A pacified monster now
routes toward a reachable stair, gate, or qualifying trap, then leaves
without a corpse, carried gear, or another XP award. Geryon discards the
Horn on conversion; constriction and flaying stop immediately.
Pacifying Pikel dismisses his marked lemures through the same owner as
death or banishment. Pacifying Kirke restores her marked hogs through her
existing release rule. Dowan and Duvessa find one another by original
class after polymorph, and the other hostile twin becomes neutral without
a second chance roll or healing; each gains its once-only nonlethal XP.
Player attack contact now checks religious conduct before changing peace.
A miss still angers the attacked twin and its same-floor partner. The
marker keeps nonlethal XP history when its active peace flag becomes false,
so anger, restore, and later pacification cannot pay that XP twice.
Death, Abyss banishment, and Okawaru's Arena challenge leave a surviving
twin with a saved grief state. Dowan's unpolymorphed spellbook gains Stone
Arrow, Throw Icicle, and Blink in the source slots and he gains permanent
Haste; Duvessa gains permanent Berserk. A survivor that cannot yet see the
player activates its pending power on a later decision. The saved climb
allowance now determines whether a lone twin can follow an ordinary stair;
exact source speech selection is still pending.
Ordinary up and down stair actions tag nearby eligible monsters before
their decision phase and carry their ECS identities, inventory, and status
to free connected cells near the player's landing. Allies can form a
five-cell chain; an adjacent nonfriendly actor reduces that range to one.
The source's 18-follower cap, energy and body gates, paired twins, and
disconnected-branch exclusion are Lua rules. Action-only marks are removed
before save. Portal and transporter followers remain for their separate
travel handlers. The current AI records a target cell rather than the
source's foe identity, so hostile follower selection checks pursuit near
the player's present cell.
Temporary terrain sourced by any monster, including Vault Warden's seals,
reverts immediately when its source is pacified or killed. Unrelated
markers and later permanent terrain edits remain intact.
Major missing domains include the remaining spell mechanics, religion
actions, mutation-adjacent systems, unported forms, full monster abilities,
still-unported vault families and their Lua scripts,
remaining branch-specific layouts and entrances,
full source parity for chaos clone allegiance and exact shapeshifter RNG order,
exact random-name RNG parity, gift-origin equipment name preference, runes,
endgame, and the
complete item and equipment system. The committed monster spellbook IDs
now have Lua effect resolvers. Several effects still need source parity
follow-ups, tracked in the monster spellbook slice; Porkalator now releases
Kirke's band and spell-transformed victims when she dies.
Monster polymorph requests now return active shapeshifters to their durable
variant and usually force merged slime creatures to split before each body
chooses a form. The same Lua route serves player Polymorph, monster hexes,
chaos, Xom, and relative-power effects. Each monster now saves a persistent
three-form polymorph set, generated at placement and rebuilt after a body
change. Same-power casts select from that set; relative-power and shifter
requests use the source species and tier gates. Byte-for-byte C++ RNG parity,
including its draconian thinning draw, remains a follow-up.
Monster corpses now record the original class and its corpse species
separately. Polymorphed monsters leave their original species' corpse. A
shifter marked before polymorph uses its permanent variant; an earlier
polymorph origin survives a later shifter mark. Ordinary classes such as
Orc Knights leave their broader species. Save validation retains these
identities across generated rosters, Beogh Resurrection, and authored vault
origins. Classed draconians now own a colored base ECS component, with source
job defaults and authored overrides. First polymorph records that color as
corpse lineage while keeping the job as roster lineage; corpse restore uses
the branch of the saved floor for membership checks.
Malmutate's abomination tile reroll remains. Ugly things now save their own
colour, attack, damage, resistance, and spontaneous kin mutation traits;
combat and display read that actor state after spawn, polymorph, and
Malmutate. Source-wide band colour coordination and exact mutation RNG
draw order remain follow-ups.
Native C++ saves, tiles, and network
client compatibility are outside this Go port.

Monster Ensnare now uses the source projectile profile and the shared
magical-web owner; a landed hit makes a durable web restraint without HP
damage. Awaken Forest, Grasping Roots, Awaken Vines, Wall of Brambles, and
Sporulate now cast from their source spellbooks. Their timed conditions,
physical plant actors, root and vine grips, briar thorns, and spore blasts
are ECS state and survive the Go save format. Source sanctuary suppression
awaits the religion and sanctuary domain; no current game action creates a
sanctuary.

Shops now have ten source-backed active types, a saved player wallet, saved
shop and stock entities, gold pickup, item-class valuation, purchases,
shopping-list markers, and a full-terminal stock screen. The 70 source shop
vault definitions are committed as `.des` files, with Lua ports for their
scripts. Eligible maps place authored shops and stock in ordinary D:1–15
generation; the fixed shop scenario remains available. Supplemental maps
retain source IDs in saves, and sparse mod overlays can add a vault or replace
one handler. The temporary one-in-eight shop draw has been replaced with
source-style CHANCE maps, one weighted explicit `PLACE` minivault attempt,
then weighted depth minivaults. The six
builder dummy maps include the Dungeon suppression chance, and an `extra`
minivault asks for another bounded draw. The eligible pool is still partial
until the remaining source vault families are imported. The five-map `serial_curves`, eleven-map
`serial_corexii_hall`, fourteen-map `serial_rivers`, and thirteen-map
`serial_bayou` families now use the general CHANCE and post-place controller
path. Their tagged corridors, statue halls, streams, and ponds run through
the shared selector. River monster-generation masks and bayou plant intent
remain typed level records. Deeper branch placement needs the
corresponding branch generator. The rare `bzr_entry` request can now draw
from all 13 committed source Bazaar entrances. All 42 Bazaar layouts are
also in the effective DES catalog, with named Lua hooks for their source
script sites and production placement coverage. Timed entrances use saved
ECS portal clocks, and entering builds a weighted source Bazaar map with
its authored shops and exit. Bazaar shops apply the source bargain and
stock depth rules. The player's saved visit points to the outside arch;
leaving retires the market and its stock. Restore validates portal markers,
the active map, and the reciprocal return pointer.
The Sewer portal corpus now includes all 15 source D:3–6 entrance maps and
19 source one-floor Sewer maps. A `chance_sewer` entry creates one saved ECS
drain clock for the source 600–800-turn lifetime. Global action time closes
the drain even while its Dungeon floor is inactive. An accepted entry stages
one weighted source Sewer map through the ordinary vault population path;
its exit returns to the saved outside cell and retires the temporary floor.
Restore checks the source marker, deadline, selected layout, exit, and
reciprocal visit. The two source discovery messages are attempted on first
arrival when the drain is audible; the saved timer emits the source
rust-speed bands and final warning. Visible and unseen collapse use the
source marker's different messages.
Timer messages use the source hearing limit and the Lua Silence field at
both the drain and player; source distance bands only change the wording.
Terrain, keyed entities, and other source records survive in the
saved level, but broader gameplay for some authored features remains tied
to their respective domain slices.
The Ossuary now carries all 14 source D:4–8 entrances and 20 one-floor
destinations as individually replaceable DES files. An entrance places one
saved 600–800-turn ECS gate clock; global action time can bury it while the
Dungeon floor is inactive. Entering stages a weighted source map with a
return exit and saved exact outside cell. Return retires its temporary
entities. The boxes layout opens its linked stone walls and consumes its
trigger group in one event. Restore checks portal deadlines, reciprocal
visits, source map identity, and the all-or-none wall group. Source sand
messages and Silence hearing use Lua timer policy. Other authored effects
remain subject to their respective gameplay domains.
The Bailey now carries all nine source D:7–10 entrances and all 15 source
axe and polearm destination maps. The mapless source dispatcher chooses one
tagged child through the effective Lua/DES catalog. The entrance theme and
600–800-turn lifetime are drawn once, saved in an ECS gate, and checked
against the authored marker on restore. Time closes the gate even when its
Dungeon floor is inactive. Entry stages the chosen map, spends the gate,
and stores an exact return pointer; return retires the temporary floor and
its entities. Source portcullis messages, Silence hearing, and five time
bands run in Lua. Text snapshots under `docs/level-snapshots/bailey/` show
every generated map and its test return connection. The broader effects of
some authored monster equipment and feature records still depend on their
respective gameplay domains.
The Ice Cave now carries all 15 source entrances and 11 source destination
maps as individually replaceable DES files. Its source-position Lua hooks
draw one 600–800-turn clock and save the origin's easy/hard choice. A live
Akara gate continues counting on inactive floors, emits source frost and
crackling messages, and closes to `expired_portal`. The destination is one
weighted whole-floor source map with its authored monsters, cold loot,
fog machines, transporter links, and exact return exit. Save validation
checks the marker, deadline, difficulty, grid, selected map, and reciprocal
visitor pointer. All 22 easy/hard map variants populate through the live
staged owner; terrain snapshots and connections are under
`docs/level-snapshots/ice-cave/`. Explicit duplicate unrand requests now
use the source fallback randart rule. Wider gameplay for any authored
entity effects not yet ported remains subject to those separate domains.
The Volcano corpus carries all 11 source Lair/Orc entrance definitions,
14 weighted whole-floor destination maps, and nine tagged nested helpers
as individually replaceable DES files. Named Lua hooks execute at their
source positions. The live gate saves one 600–800-turn draw and the exact
outside return cell; inactive-floor expiry, last-turn entry, multi-exit
return, staged rollback, and reciprocal save checks are implemented.
Chained fog emitters share one saved clock. Cave door collapse and all
nine overflow lava phases have Lua systems, Akara clocks, source-marker
validation, and grid mutations. All 14 destination maps populate through
the live staging owner; text maps and return connections are under
`docs/level-snapshots/volcano/`. The source `no_cloud_gen` record is
preserved; ambient lava/water cloud generation is a separate unported
world effect, so this flag currently has no ambient producer to veto.
Treasure Trove carries all 14 source entrances and 21 source reward rooms
as individually replaceable DES files with exact MAP rows. Named Lua hooks
retain the source directive sites and six character-dependent map vetoes.
Population rolls one saved toll on its own RNG stream, then joins a source
marker price witness to an Akara gate. Item, named rune, and no-piety paths
confirm before a staged floor is committed; successful payment saves a
receipt and the exact outside return address. The 21 reward rooms use
source weights, authored exits, item requests, and character-aware
acquirement for their placed rewards. Restore compares marker, gate,
receipt, destination, and visitor without rerolling them. Text maps live
under `docs/level-snapshots/trove/`. Sparse Lua price modules can add a
new toll kind through the same saved gate and receipt contract. The source
shop pool considers only remembered, high-value, nonstackable stock.
The `useful` item request uses the current anatomy, artifice, potion, and
book rules; remaining source `is_useless_item` cases will follow their item
domains. God-qualified acquirement details and some wider authored
monster/item effects still need their related domain
policies; the corresponding source requests remain in saved records.
The four-map `serial_nicolae_subway` family adds its controller and three
linked stations. Its named markers pair across separately placed stations,
paint one-way transporters and landings, and retain their links in saved level
records. Either stair key enters a portal; the Lua travel policy handles
nearby followers, a short translocation cloud, and learned destinations.
The demonic and
undead serials add fifteen source maps with depth-scaled monster requests,
typed fog markers, and the undead gravestone name. Hook-attached markers
retain their positions even when a later source substitution changes the
underlying terrain glyph. The twenty-map park serial adds an open-layout
controller, eleven placeable pieces, and eight nested garden helpers.
`SUBVAULT` now chooses its tagged helper by source weight instead of always
taking the first matching map. The thirteen-map gnoll camp adds its open-layout
controller and twelve weighted pieces, including Grum's kennel and a guarded
shop. Comma-separated monster slots now try later candidates at the same
cell when an earlier one cannot spawn; the kennel uses this to fall back
from a duplicate Grum to a gnoll. The twenty-nine-map window family adds its
controller plus five small, eighteen common, and five rare glass-barrier
pieces. All three window pools place through named tags. Its optional
`serial_glass` request now draws from three common maps in the separate
`mini_features.des` corpus. The fifteen-map sigils family adds a rare
Depths, Elf, and Crypt controller with fourteen weighted stone shapes. Its
source helper's common tags and three surface rules are carried by each
committed map; branch generation will activate these maps when those floors
are ported. The sixteen-map ice family adds a Dungeon/Cocytus controller
and fifteen weighted pieces. One named Lua module applies the source's
branch-specific monster pools, ice surface rules, and typed fog markers.
The controller can request an Ice Cave entrance from the committed source
`uniq_icecv` pool; a mod may add another eligible entry by one DES file. The
one-map `serial_glass`
controller adds a non-flat common draw and an independent rare draw that
is skipped in Dis. The nine tagged maps came from the separate variable
source corpus.
Dis-only crystal pillars and the depth-dependent unseen-horror display run
through named Lua hooks. The source `generate_awake` modifier now controls
the initial sleep state of each selected vault monster.

The forty-one-map forest family now adds its early-Dungeon/Lair controller
and forty individually weighted shapes. D:1 and D:2 raise each child's
source weight; Lair uses its separate value. One shared Lua setup applies
vegetation, placement masks, and the branch-dependent tree density while
each `.des` retains its authored geometry and substitutions. The source
`infiniplex_forest_clump_C` spelling is preserved as a stable vault ID.

The magic research family adds one rare controller and ten distinct school
rooms for Depths, Vaults, and Elf. The original `.des` maps retain their
creatures, terrain, markers, and local directives; one documented Lua helper
adds branch-specific casters, shared substitutions, and a themed book plus a
star item at the D glyph. Vault item requests now carry a book discipline and
spell count through to the ordinary item generator, using the floor's
absolute depth for depth-scaled quality. Source `ident:type`
reveals the placed item's instance type. The thanatology room preserves its
smoke marker and delayed skeleton decay. The source's `place:Depths:$`
monster selector is parsed and retained, but branch-specific random monster
population still needs the Depths population slice.

The fifty-seven-definition column ruins family adds its open-layout
controller and all fifty-six authored pillars, portals, temples, and
ruined-city shapes. Shared Lua setup applies the source pillar, hut,
portal, and Depths water rules; source MAP rows stay unchanged. The rare
controller mode stores its whole-level floor and rock tile choice as a
typed level record. Solid `no_exits` decorations now place without
inventing an entry corridor. Pan portal travel now has a live destination;
Hell's persistent Vestibule now has entry and return travel through typed
gates, including saved return sites and nearby landing when a gate is occupied.
The 60 maps from
`hell.des` are now committed as 23 entrance maps, one required Vestibule
layout, and 36 tagged wing maps. Their original geometry and directives
place through the production DES engine; the Big Baal shop and two random
Vestibule choices run through named Lua hooks. All ten Hell entrance and
exit features now project to distinct walkable terrain IDs, preserving
their destinations through the grid and save format. The source
`chance_enter_hell` family selects one Depths entrance through the shared
vault chance stage, with `hell_entry` as a failed-fit fallback. The four
subbranches now have source-backed ordinary-depth (1–6) catalogs: 36 Dis
maps, 30 Gehenna maps, 26 Cocytus maps, 39 Tartarus maps, ten shared Hell
maps, and 39 Gehenna lava-maze definitions. Compact 40×35 generation,
branch gate travel, and persistent floor records use the live generation
path. The 51 source seventh-floor definitions are committed as 15 Dis, seven
Gehenna, eight Cocytus, and 21 Tartarus controllers and helpers. One weighted
controller owns each 80×70 ending. Its source rune, boss records, and exit
are generated and saved; a single saved branch choice determines where the
Serpent of Hell can appear. Named Lua hooks replace the source inline
scripts, including Tartarus maze carving and tagged helper placement.
Remaining Hell monster and boss behavior still depends on later combat
and content slices.
On every subbranch arrival, Lua now performs the source Zin protection,
message, noise, and four-way consequence draw. Temporary bad mutations,
drain, and stat loss use their saved character owners. The message groups
are committed Lua content. Sanctuary and divine-stamina protection still
depend on the later religion domain; no current action creates those states.

The fifty-three-definition aquarium family retains the source controller
and all fifty-two authored child maps. One Lua controller picks a shared
pool width and requests bridge, window, view, balcony, and pool pieces in
source order. Each child keeps its exact `.des` MAP rows and calls the
shared ecology hook at the authored point. Nested bridge helpers use their
original 3:2:1 weights. All nine Dungeon depth bands and Elf are placed;
fog-machine instructions now create saved ECS clocks and live cloud sources
when the selected floor is populated. Source-sized slime creatures now use a
shared Akara component for HP, natural damage, and display, including
Planerend summons.

All 80 unique-placement source definitions are now individual `.des` files.
The 11 source MAP blocks remain byte-for-byte unchanged; 69 inline source
helper calls became one-cell maps with their original MONS, tags, branch,
depth, and weight rules. A Lua stage now performs the source continuation,
available-map, weighted-dummy, and placement draws after secondary vaults.
The player owns saved monster uniqueness alongside unique-item claims.
Source unique follower bands now use per-monster Lua definitions and one
ECS follower policy, including Kirke's transformation marker. Every
follower now keeps a saved band origin even after its live leader link
is cleared. Restore validation reads the leader's catalog band instead
of a second monster list. Pikel's lemures carry an additional marker:
his death or banishment dismisses only those actors and leaves black smoke.
Common orc, gnoll, centaur, naga, tengu, merfolk, deep elf, and basic
draconian leaders now declare source natural bands through that same
policy. Beogh and Okawaru wrath permit these bands, and every wrath
follower retains its god source and hostile allegiance through saves.
Pan veto hooks read saved rune progress and Ignacio's one-time decision.
Boris releases his unique claim on death and gets a one-in-six replacement offer
on a new Depths, Vaults, Tomb, or Crypt floor. Natasha's first two deaths
create distant replacement actors with her carried equipment and saved
revival count; her third death is final. Pan now selects and populates an
authored primary, saves one current region, and replaces it through entry,
transit, ordinary exit, and Abyss exit portals. Source upward stairs become
transit portals after DES terrain resolution. The random lord owns its rolled
body, resistances, attack form, brand, flight, spell slots, and ring choice
in an Akara component. Its saved cloud ring now places and refreshes the
source cloud family through the ordinary ECS cloud owner. The same policy
reads immutable species flags for Asmodeus's flames, Bai Suzhen's storm,
and the tainted leviathan's miasma. All three place their first clouds on
spawn and refresh them after acting; clouds remain saved ECS entities.
Integrated tests
compare a restored next-region draw with uninterrupted play and verify that
uncollected floor runes disappear with a retired region. Generated lord
stat drain, drowning, web ensnare, speed drain, corrosion, weakness, and
trample now use the ordinary saved combat owners. Trample now pushes the
defender first and follows only after attack reactions, with source size,
habitat, constriction, flight-expiry, Mountain Boots, trap-entry, and
Passwall-interruption checks. An authored Hellion Island Pan rune now has a
live test through DES placement, pickup, two transits, restore, and exit.
Pan lord Pain brands inspect the actor's rolled spell list for Necromancy
instead of looking up the source's dynamic `MST_GHOST` as a static book.
Player movement now checks source-style opportunity attacks before leaving
an adjacent hostile monster's reach. The Lua rule checks visibility,
incapacitation, attack ability, effective speed, and possible action energy
before its one-in-three roll. It refunds up to ten attack-energy points and
passes `player_moving` through melee, suppressing trample, ensnare, constrict,
and movement-disrupting distortion outcomes. Sanctuary and Wujian movement
exceptions belong to their future religion and ability slices. Generated
lords now save source-style names and source colour rolls; their
names reach combat messages and both values reach the terminal entity view.
Source `ETC_RANDOM` now redraws visible monsters and clouds with UI-only
nonblack IRGB draws, without changing the saved game seed. All 20 named lord
map variants now resolve their matching rune through source placement. One
selected realm from each of the four lord families also runs through a live
Pan portal, ECS floor item, pickup, and saved player progress.

Intrinsic death effects now use the actor death phase for Ball Lightning,
Fulminant Prism, Bloated Husk, Lurking Horror, and Bennu. Construct timeout
reaches the same death owner as a lethal hit; a zero-charge prism stays
quiet. Bennu's radius-two pyre precedes its one saved rebirth, and a later
death is final. Explosion geometry and source message timing still need
whole-game parity review alongside the remaining monster death effects.
Death-cloud rules now share one Lua path for lethal deaths and summon
teardown. Fire vortices leave fire, simulacra leave cold, and chaos spawn
leave chaos whether or not they were summoned. Ordinary summons leave one
randomly coloured smoke cloud; shadow, holy, mirrored, drowned-soul, and living
spell departures omit smoke. Source-specific death wording remains part of
the presentation parity pass. Xom and Jiyva poof variants still need
per-monster god state from the religion domain.

An audit of the pinned `builder/` and `serial/` DES files finds 600 unique
`NAME` values, all of which now occur in the committed vault catalog. The
last ten procedural layouts use the source GeoElf and Halls families. GeoElf
draws its room and corridor geometry in Lua, including the castle layout
that wraps a preselected authored primary vault. Halls applies the source
layer shapes and pinned noise functions before the shared stair pass.
Their Lua hooks preserve source terrain and typed placement records; whole
gameplay parity still depends on the mechanics those records request.
The weighted `layout_delve`
family covers the Depths cross, Zot circle, Spider galleries, and
Cocytus dry-route/water split. The completed `layout_cc` family
includes Chaotic City. The completed `layout_cellular` family now includes
Cellular Growth's weighted wall islands and Gridlike's branch-specific
rooms, corridors, keyed material fills, and plant records. Both use one
local grouped-cell model and preserve source branch weights. A forced
Gridlike game fixture exercises its plant records through ECS population
and Go save/restore.
All eight monster recipes from `builder/rooms.des` now have committed DES
definitions and Lua hooks. The two source parents from
`variable/mini_monsters.des` build variable-size local maps and select one
weighted room recipe through the ordinary tagged SUBVAULT path. The same
placement owner records parent and helper IDs, resolves monster and item
records, and saves their ECS origins. A live Dungeon fixture verifies one
room through population and restore; Lua tests exercise all eight recipes
and both parent forms. The bee recipe's `never_decay` corpse modifier now
reaches the saved corpse component and prevents timed decay. Morgue remains
retain typed delayed-decay records until that separate gameplay effect runs.

All 22 source arena builder maps are committed as individual `.des` files.
Their original
MAP blocks are intact, and the two shared palette scripts are a named Lua
hook. Arena maps have no Dungeon depth rule, so normal Dungeon generation
does not draw them. An arena game mode and whole-level palette behavior
remain future work. Okawaru's separate Duel Arena uses its four authored
one-floor `.des` maps as described above. The deep Dungeon decoration
controller now draws from
the effective `decor` tagged map pool at source chance and depth. All 22
Pandemonium division definitions are committed: two authored layouts and
twenty weighted helpers. Both parent layouts assemble and complete stairs
through the production layout owner. Pan's repeated-region flow now uses
those layouts alongside its authored primary maps.
Forest generation exposed a missing bow and crossbow missile policy;
arrows and bolts now use one Lua launcher resolver with their catalog
projectile values.
Monster-thrown missiles now validate saved egos before spending a shot.
Poisoned, Curare, flame, frost, blinding, frenzy, dispersal, silver, and
Chaos effects run through focused Lua owners after contact. Exploding
missiles use a radius-one fragment blast on contact, including a returned
shot. Reflected hits reuse monster-facing missile effects. The Zot route
integration test exports text maps and stair connections at
`docs/level-snapshots/zot-route` when requested.
All twelve source-legal launcher weapon brands now validate before firing.
The player and monster projectile actions send active brands through the
ordinary Lua weapon-brand owners. Speed changes launcher delay; Protection
refreshes a saved, short +7 AC aura after a qualifying player hit; and
Penetration bypasses shields and continues along the player's traced ray.
Holy Wrath recognizes live undead or demonic
players, Electrocution respects rElec, and Venom uses the shared player
poison gate. The pinned DCSS source creates ordinary, nonconsuming
projectiles for launcher shots; arrows, bolts, and sling bullets are removed
as physical item drops. Its branded-ammo suppression branch is therefore
inactive in ordinary current gameplay. Modded physical ammo would require
an explicit rule for that case.
The three Dis:1–6 divisions layouts now use their source weights and map
geometry: recursive rooms, an irregular-room lattice, and overlapping boxes.
Their procedural Lua hooks retain source statue style directives as typed
records. Dis branch travel and its seventh-floor content remain separate work.
The complete `layout_grids.des` family is now registered. Its remaining
Lair Big Grid and Snake/Pan Grid Shapes maps use the shared subdivision and
zone passes, with their source branch weights and shape choices in Lua.
The complete `layout_pools.des` family is also registered. Honeycomb now
grows bordered pool territories and opens sampled walls. Gehenna's three
canyon layouts share source-style lava pools, rounded stone buildings, zone
cleanup, and optional authored up stairs. Branch travel outside Dungeon is
still pending, so these layouts are exercised through the layout catalog.
The last missing `layout_type_open` definition, Depths' once-per-run
Forbidden Donut, now carves its broad ring, optional cross and central
octagon, and source-shaped spotty or boxy smear. It also runs through the
shared connected-stair postpass. Depths travel remains future work.
The Worley cave category now includes source Chambers for Snake, Spider,
and Pan, plus Cocytus Water Paths and Ice Bergs. Their branch weights,
depth rules, water terrain, and connected stair landings run through the
same effective layout catalog. Pan uses its layouts during portal travel;
Cocytus travel remains pending.
The remaining noise-based Cave Shapes and Gehenna Lava Caves layouts are
also registered. Cave Shapes selects one of four source silhouettes before
adding cave-edge noise; Gehenna grades simplex noise into floor, lava, and
rock, then uses the same stone-building owner as its canyon layouts.
The last two `layout_caves.des` maps are now registered. Falls Marsh unwraps
Worley noise into drips, grows mixed pools, then runs the Swamp water cleanup.
Snake Cave Town paints one broad cave and follows it with two passes of
same-style walled rooms. All nine source maps in this file now have committed
DES declarations and executable Lua hooks; branch travel remains separate.

The source `layout_city.des` family is now complete. Onion City recursively
splits and nests rooms using Elf and Pandemonium source weights, opens
eligible shared walls, and gives Elf transparent windows and clear doors.
Its terrain decoder preserves the clear-door feature instead of treating it
as a plain door. The map is registered for both branches; their travel flow
is still pending.

The remaining four `layout.des` definitions are now committed. Regular City
places source-sized, branch-adjusted rooms; Misc Corridors joins random
points before its spotty pass; Caves grows three authored stair bubbles;
Diamond Mine grows weighted concentric rooms and keeps up to three Orc
regions. The shared stair owner now preserves separate authored bubbles and
adds a local return landing for each. These maps are registered for their
source branches; ordinary branch travel and primary-vault avoidance remain
to be integrated.

The source Swamp heightmap layout is also committed. Lua scatters the
source's depth-scaled island bumps, smooths the height field, and paints
mangrove, floor, and shallow water. Its Swamp-only declaration is registered
and ordinary branch travel can select it.

The ordinary branch travel slice is specified in
`docs/superpowers/specs/2026-10-20-ordinary-branch-travel-design.md` and
planned in `docs/superpowers/plans/2026-10-20-ordinary-branch-travel.md`.
The 38 committed population catalogs preserve 908 source rows. Go saves
branch-local depth and arbitrary scheduled frontiers; Lua validates the
entrance graph rather than assuming every level is Dungeon ID plus one.

Generated Dungeon levels now save every successfully placed map ID, including
controllers without cell records. Lua reconstructs run-wide names and
`uniq_*` tags plus current-floor `luniq` names and `luniq_*` tags from those
IDs. Save version 29 rejects older snapshots that lack complete map-use
history, rune progress, or the current band and revival schemas.
Keeper names, exact source RNG sequences, and every special price case still
need parity review; the saved keeper seed leaves a place for that work without
changing the ECS ownership model.

Trap placement and activation are playable for all ten active trap IDs. The
pressure plate emits a position event; vault marker listeners remain for the
broader vault-marker domain. Monster shaft avoidance and web immunity use
the currently imported monster traits; native-branch and allegiance cases
need the fuller monster AI domain. Malevolence uses newly seen cells on
player movement; other visibility updates need the wider view-event pass.

The mutation source audit also found Vampire references in weapon equip
messages, unrand item effects, religious evil status, monster spell choice,
and extended character status. Those consumers belong to the item, religion,
monster AI spell, and status screen slices; they must read the saved Vampire
state when those domains are implemented.
Ru's Missing Hand sacrifice must also release a newly unavailable ring slot
and recalculate derived MP if that ring grants magical power. The current
mutation has no playable acquisition path.

The item identification policy now gives each active identifying type a
saved, unique appearance and discovers all copies when a potion is quaffed
or a wand is successfully evoked. The current scroll label generator keeps
unique deterministic labels but does not yet reproduce DCSS's exact
`make_name` syllable algorithm or its RNG sequence. Artefact discovery now
uses per-item knowledge and source self-identifying fixed-name rules; random
equipment artefacts use the source weighted name and appearance groups.
Random books use source title groups, though exact source RNG parity remains
future work. Item-inscription UI and naming details beyond
the implemented non-artefact classes remain. Source religion conduct
remains part of the religion domain.
The experience potion keeps level XP separate from allocatable skill XP; its
saved pending pool is spent on the skills screen. Lignification confirms
before entering tree form in a live fire or cold cloud; the wider cloud
catalog now uses the same saved world state. Potion effects are
registered by file, and a mod-added active
potion or scroll without an effect fails during startup.

The first scroll-reading pass covers every active scroll ID and uses saved
cloud, summon, teleport, vulnerability, acquirement-offer, and map state.
The acquirement item picker follows the source class shuffle and guaranteed
gold offer, but its subtype weighting, artefact generation, and god filters
still need the wider item and religion domains. Fog uses opaque smoke in
the map view and sight calculation. All 34 concrete cloud definitions now
load from committed Lua files. One saved world-cloud component owns each
occupied cell; Lua policies handle placement, actor exposure, monster
avoidance, field aging, and presentation. Rain and summoned terrain share
saved temporary-terrain state. Cloud damage, statuses, source credit, acid
corrosion, and deterministic spread have source-backed implementations.
Wind, sanctuary, and terrain-destruction veto need their neighboring world
systems to supply live conditions before those interactions are complete.
Committed fog-machine markers use a Lua reader and saved ECS clock. Level
entry emits their opening burst; active turns emit later clouds offscreen as
well as in view. The shared cloud owner handles decay and attribution. A
restore checks each machine against its realized source marker.

All seven active magical staves now use one base weapon profile and Lua
metadata in their individual item definitions. Wielded staves enhance their
school's spells and grant the source resistance where applicable. Their
melee procs use the source skill formula; poison also applies a saved poison
effect. Staff of death's god conduct awaits the religion-action domain,
and the exact source messaging and exposure interactions remain to be
checked with the broader elemental combat pass.

Wizard Labs now use all eleven source entrance maps and fifteen source
destination maps as committed `.des` files. The full-size rooms preserve
their MAP geometry; source-position Lua hooks supply their conditional
directives and typed markers. One saved gate clock starts when its outside
floor is populated, and the staged portal returns through any authored arch
to that exact gate. Doroklohe's collapse, Wucad's monks and shared room
messages, Borgnjor's death-driven lost souls, and Zonguldrok's escalating
graves, lich, and door have focused Lua event owners with Akara state.
Generic door interaction reads authored door verbs, and teleport destination
policy honors `no_tele_into` until Zonguldrok's door appears. Cigotuvi's
mutant beast retains its source tier and facets in a saved ECS component;
the projected form drives live HD and HP, ordered melee contacts, Sting
poison and reach, intrinsic resistance and armour, Bat speed and retreat,
and Fire/Shock spells. Fire Breath has saved recovery state. The
[Wizard Lab snapshot index](level-snapshots/wizlab/index.txt) shows all
fifteen generated floors and their return connections. The outstanding
cross-domain work is the full source interaction pass for terrain-destruction
vetoes, animated source map props, and every exceptional item/monster effect
inside the labs; these are tracked with their neighboring systems rather than
hidden behind an inert lab-specific adapter.

Gauntlet now has its one source entrance, 43 arenas, six minotaur exits,
and ten parent layouts as individual layered `.des` files. All 60 MAP
blocks match pinned source geometry. The named Lua hooks choose source
encounter tiers, reward slots, and route branches with local placement
state. A timed gate starts on the outside floor, expires with world time,
and enters one staged parent floor; each return arch leads to the saved
outside cell. Akara stores the gate clock and visitor pointer. Source
transporter markers resolve into exact links and restore validates them.
Long-range teleportation, Passage of Golubria, and teleportitis are
blocked inside Gauntlet, while blinking remains available. The
[Gauntlet snapshot index](level-snapshots/gauntlet/index.txt) shows all
ten generated parent floors and their transporter routes. Exceptional
item and monster effects still follow their wider combat and equipment
domains.

Crypt now has all 59 pinned source maps as individually layered `.des`
files: 13 Vaults-side entrances, 38 Crypt floor maps, and eight mandatory
Crypt:3 endings. MAP blocks are byte-identical to the pinned source. Lua
hooks preserve source-position conditional terrain, monster, and loot
decisions. The scheduled Vaults entry leads through three Crypt floors;
each ending binds its authored Tomb gate or receives one connected fallback
gate. Saved ECS trigger groups handle sarcophagus guards and the glass
Crypt's grates when the player sees their trigger. The
[Crypt snapshot index](level-snapshots/crypt/index.txt) shows connected
floors and all eight endings. Tomb now accepts that entrance and stages its
three source floors together. Its 31 active DES maps include ten Crypt-side
entries, three full floors, and 18 helpers; four old-save compatibility maps
are excluded. Lua resolves source-named one-way hatch markers after final
placement and shares the three active guardian pools across one build.
The golden rune is placed and pickable, the full route travels in both
directions through its separate hatches, and saves retain the floors and
links. The [Tomb snapshot index](level-snapshots/tomb/index.txt) shows each
floor and exact connections. Exceptional monster, item, and
terrain effects in Crypt continue to depend on their broader rule domains.

For each new domain, convert the full rule category in one pass. Put its
definitions, policies, and ECS systems in actual Lua files; extend Go only
for reusable engine primitives. Delete the previous rule path in the same
change. Do not add compatibility adapters or parallel implementations. Keep
generated content checked in and refresh it explicitly.

Xom's 42 source event IDs now resolve through individual Lua catalog
definitions and focused effect owners. The good and bad selectors keep
source priority and RNG order as named stages; a sparse mod may replace
one event file or add an event with its own selector at a numeric stage.
Ordinary worship and Divine Wrath share the action owner. Per-action mood,
interest, and stimulation use saved worship state. Cloud trails, Cleaving,
stair repulsion, displaced timed portals, generated allies, item gifts,
and Abyss return sites use real saved ECS or level records. The focused
Lua cases, game rollback, timing, and save/restore tests cover these paths.
Interested, unpenitent Xom also restores a worshipper after an accidentally
lethal action; boredom and penance leave that action lethal. Save version 36
rejects the earlier Xom schema and pre-detection level records explicitly.
Unusual death and item-destruction stimulation hooks still belong to their
later action domains; Xom's stimulation policy is ready for those calls.

## Running the slice

`go run ./cmd/crawl -seed 1 -save crawl-save.json` starts the terminal
client. Choose Dungeon Crawl, any legal selectable species and background,
a weapon when that background offers a choice, and a name. Use the in-game
`?` help for commands. Commands whose gameplay is not yet ported remain
visible and explain that they are unavailable without spending a turn.
