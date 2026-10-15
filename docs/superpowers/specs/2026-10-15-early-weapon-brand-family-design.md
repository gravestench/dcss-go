# Early weapon brand family

## Purpose and scope

The five weapon kinds already generated for early humanoids are club, whip,
dagger, short sword, and sling. Their committed source tables can produce
normal, spectral, venom, electrocution, draining, freezing, flaming,
vampirism, pain, holy wrath, distortion, antimagic, speed, protection, and
vorpal. The live melee code rejects several of these after the item has
already entered the world. A legal generated weapon must never become a
runtime error or quietly act unbranded.

Complete this whole generated weapon family on one branch. Preserve the
source behavior for the current player and monster roster, including effect
roll order, damage, status duration, action timing, messages, save/restore,
and any branch or ally transition an effect causes. Do not broaden the
playable monster roster or player starts solely to make a brand test pass.

## Rule ownership

The brand ID resolves directly to a Lua effect module. The dispatcher only
validates IDs and calls the module; it contains no growing brand effect
switch. Shared poison, resistance, and roll utilities stay in focused Lua
modules. Source specific choices and text remain in Lua. Lua uses Akara
components for persistent drain, antimagic, summons, and other effects.

Go remains the kernel for entity lifecycle, level grids, deterministic turn
scheduling, save encoding, and terminal drawing. Pass an actor entity to a
generic Lua scheduler policy so speed brand timing can inspect the weapon
through the same component API as other Lua rules. Do not add a Go brand
switch, a Go effect adapter, or parallel Go combat behavior.

## Effects and source anchors

- The ordinary damage and poison brands follow
  `crawl-ref/source/attack.cc:1320-1560`, with source roll order preserved.
- Speed modifies monster melee and launcher costs through the Lua scheduler;
  source `monster.cc:400-411`. None of the five early weapons can generate a
  speed-branded launcher, while a thrown missile keeps its ordinary cost.
- Holy wrath checks the defender's holiness; living Human starts take no
  bonus. Vampirism heals a wounded living attacker after a damaging hit,
  including the source proc and heal draws; source `attack.cc:1380-1470`.
- Draining, pain, antimagic, and distortion follow their source effect
  functions in `attack.cc:471-570` and `attack.cc:848-875`. Distortion's
  damage, blink, and banishment outcomes must be real outcomes, not notices.
- Monster-wielded spectral weapons have no summon effect in the pinned
  source (`mon-act.cc:2222-2226` explicitly leaves them as TODO). Player
  spectral attacks do summon an ally (`melee-attack.cc:642-648,675-676`).
  The brand module must preserve that distinction. Player weapon brands
  belong to the player-attack slice, where the allied actor will use Akara.

## Complete flow

Generation creates a legal weapon from committed Lua data. Wielding and
save validation accept its exact brand. A melee or launcher attack resolves
base contact and damage, then the brand effect in source order. The result
updates Akara state, level occupancy, messages, and action timing before the
turn completes. A save taken immediately after any persistent effect restores
that effect and continues with the same named RNG state. Overlaying one brand
module changes the effective ruleset hash and that attack without rebuilding
Go.

## Acceptance

All positive-weight brands for the five early weapons have a complete
resolution path. Representative whole-turn tests cover damaging and
zero-damage hits, pre-killed targets, each brand family, deterministic RNG,
save/restore, and a same-path Lua override. Run the full suite, vet, build,
style and catalog checks once at the integrated category boundary. Commit
the whole category once and fast-forward local Go `main` while preserving the
paused C++ branch and the user's untracked save.
