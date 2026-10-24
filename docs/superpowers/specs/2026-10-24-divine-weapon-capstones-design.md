# Divine Weapon Capstones Design

## Goal

Port the complete one-time weapon blessing family from the pinned DCSS
source: the Shining One, Kikubaaqudgha, and Lugonu. Kikubaaqudgha's
alternative forbidden-knowledge gift spends the same one-time choice. A
player sees these powers at the source rank, selects an actual carried
weapon, confirms freely, and commits one timed action. Cancelled choices
spend neither time nor the capstone. The existing Lugonu route is replaced
in the same change, leaving one Lua owner for the shared transaction.

## Ownership and mod shape

`policy/abilities/weapon_blessing.lua` owns the common menu, confirmation,
ownership check, brand change, two enchant calls, one-time worship flag,
and pending choice validation. Individual Lua files register the three
god definitions and their extra effects. Lua catalog IDs and constants are
imported at each use site. Go only carries the existing generic ability
intent, Akara item, and save interfaces; no Go content switch or inline Lua
is added.

The saved `religion.weapon_bless_choice` Akara component replaces the
Lugonu-specific choice and records the selected item plus god. The generic
command gate permits only that god's matching blessing command or cancel
while a choice is open. Restore rejects stale ownership, an altered god,
an ineligible item, or a forged one-time state. A changed schema may bump
the Go save version; old snapshots are never silently reinterpreted.

## Source behavior

All three require the current god, sufficient piety for rank seven, no
penance, and an unspent lifetime capstone. No Grasping suppresses the
weapon blessing. Non-artefact, carried weapon identity governs selection;
the Shining One and Kikubaaqudgha permit ranged weapons, Lugonu does not.
Blessed weapons can be rebranded by a god. The action applies holy wrath,
pain, or distortion, then two source enchant attempts capped at +9. The
source's three demon weapon to blessed weapon pairs convert for the
Shining One; the reverse pairs convert for the evil gods. Item identity,
equipped state, and acquired god provenance survive the conversion.

The Shining One emits a power-100 holy word at the player's location,
damaging and dazing visible undead or demonic monsters, converts blood
fountains to blue, and clears represented blood markings in radius three.
Kikubaaqudgha invokes Torment while temporarily suppressing the usual
Kiku protection, then bloodies eligible squares in radius two with independent
three-in-four draws. Lugonu has no area effect. Extra effects run only
after a successful blessing and use the ordinary damage, status, terrain,
RNG, and message owners.

Kikubaaqudgha may instead grant the five usable source capstone spells.
The player confirms the exact list before spending a turn; no usable spell
aborts freely. The spell grant and pain blessing set the same permanent
Kikubaaqudgha one-time flag, so neither can be taken after the other.
Spell usability reads the same live rule as ordinary spell learning.

## Verification

Lua `_test.lua` cases exercise selection eligibility, conversion pairs,
brand and enchantment, no-grasping, god/penance/rank changes during a
pending choice, effect targets, and the shared Kiku alternative. Game
integration tests exercise free selection and confirmation, cancellation,
timed commitment, equipped item identity, save/restore before and after
commit, and both Kiku choice orders. Mod overlays replace one god's Lua
definition without changing the shared owner. Run focused suites, a Go
build, and the style checker at the category boundary; commit and push
the contiguous capstone category to `main`.
