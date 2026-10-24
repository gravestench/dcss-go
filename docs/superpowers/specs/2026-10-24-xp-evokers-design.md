# XP Evokers Design

## Intent

Port the eight experience-recharged miscellaneous items as one playable
Dungeon Crawl domain. Their effects, targeting, charges, and recharge rules
belong in readable Lua; Go only carries command IDs and terminal input.
The original `crawl-ref` source pinned at `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`
is the rule reference. Content remains committed and usable without it.

## Scope and ownership

`policy.inventory.evokers` owns the eight subtype rules and the player's
per-subtype XP debt. A Lua player component persists a map from item kind ID
to nonnegative debt. Every copy of the same subtype reads that map: picking
up a second rod cannot manufacture four fresh charges. No item-local
charge is stored for XP evokers. The eight item catalog files remain the
moddable definitions of their item identity and may carry evoker metadata.

The base mod auto-loads a separate effect file for each evoker, registered
against its item kind ID. A mod can replace or add an effect without editing
a central effect switch. Effects use existing summon, zap, cloud, and actor
helpers where they match source behavior. Source-specific behavior gets a
focused helper or component, with no inline Lua in Go.

`v` selects an evokable miscellaneous item and `V` continues to select a
wand. The evoker preflight rejects unusable items and cancelled targets
without time or debt. Successful committed use spends one charge and grants
source Evocations practice. Source failure cases that still take a turn
retain that timing even when no charge is spent. The terminal displays
current and maximum XP charges; the item view is derived from player state.

Credited monster XP reduces debt only while a matching evoker is carried.
The recharge factor follows `player.cc:_recharge_xp_evokers`, using the
player's experience level and Evocations skill. Division is stochastically
rounded by the gameplay RNG. Charge recovery emits the source message.
Experience potions do not count as monster XP for this source clock.

## Eight effects

| Item | Debt / max | Source behavior |
| --- | ---: | --- |
| Phial of floods | 10 / 1 | Aimed primal wave, water splash, waterlog and knockback. |
| Horn of Geryon | 10 / 1 | Silence check, noise, 1–4 allied or hostile hell beasts. |
| Lightning rod | 3 / 4 | Aimed thunderbolt with consecutive-turn arc state. |
| Tin of tremorstones | 10 / 2 | Automatic nearby monster focus, fuzzed fragment blasts. |
| Phantom mirror | 10 / 1 | Clone a visible eligible monster with source duration and drain. |
| Box of beasts | 10 / 1 | Summon a tiered mutant beast; failed spawn preserves charge. |
| Condenser vane | 10 / 1 | Weighted cloud type and nearby hostile-centered placement. |
| Xom's chessboard | 2 / 15 | Random eligible monster and weighted status effect. |

Horn of Geryon also enters the defeated Geryon's source item drop. This
is necessary for the forced item to be obtainable through normal play.

## Persistence and invariants

The Lua schema round-trips in the existing dynamic component save path.
Restore validates all debt keys against registered XP evokers and checks
nonnegative integer debt. Saved consecutive rod arc state is validated
independently; it expires when the next action is not a rod evoke.
Inventory entries display charges from player debt instead of `core.item`
wand charges. Mods may add an XP evoker with its own registration and schema
compatible effect without changing Go code.

## Approaches

* **Chosen: player debt plus Lua effect registry.** This matches the source
  shared-subtype state and lets mod files extend the domain.
* Item-local charge components would be easier to draw in the inventory,
  but duplicate items would incorrectly recharge independently.
* A Go effect dispatcher would centralize special cases in a growing switch
  and work against the Lua-first mod architecture.

## Verification

Lua tests exercise all eight registrations, debt and recharge arithmetic,
target rejection, charge spending, and effect outcomes using production
schemas and helpers. Go tests cover input, display, save/restore, and a
playable Horn acquisition/evoke path. Run focused tests first, then the
full repository suite before shipping the domain. Record any unrelated
suite failures precisely.
