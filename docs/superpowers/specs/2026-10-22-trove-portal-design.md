# Treasure Trove Portal Design

## Intent and boundary

Port Treasure Trove as one playable portal domain, including its toll rather
than merely its maps. A player encounters an authored entrance, sees the
rolled price, can refuse it without spending time, pays or demonstrates the
required resource, enters one source treasure map, collects its rewards, and
returns to the exact outside gate. A saved game preserves the price, payment,
chosen map, remaining loot, and return address. The domain remains modifiable
through sparse Lua and DES overlays.

The source is the pinned `crawl-ref/source/dat/des/portals/trove.des` and
`crawl-ref/source/dat/dlua/lm_trove.lua`. The former has 35 active `NAME`
definitions: 14 entrances and 21 whole-floor destinations. The latter is
the gameplay contract for showing a rune, giving an item, or losing piety.
The source map format stays `.des`; substantial executable rules live in
commented Lua files. No inline Lua is added to Go, and no import tool is
needed during an ordinary build.

This is an architectural slice because payment must join inventory,
religion, source markers, staging, and portal travel atomically. The
recommended approach is a focused Lua Trove owner using the existing
generic staged portal transaction. A map-only pass would leave a nonplayable
treasure room; a generic toll framework would introduce an abstraction
without a second concrete user. The Trove owner may call existing generic
item and acquirement policies, but owns no duplicate versions of them.

## Committed maps and selection

Commit each of the 35 source definitions as a separately replaceable file
under `vaults/trove_entry/` or `vaults/trove/`. Preserve MAP rows byte for
byte and keep static depth, tags, weight, chance, orientation, substitution,
item, monster, trap, colour, and tile directives in their original order.
Executable source-script sites call named Lua hooks at those same positions.
Leave the established TODO to move those hook bodies back into DES when the
engine supports documented map-local Lua. Source provenance belongs in
comments, not data fields. Do not commit a runtime importer or regeneration
tool.

The source `default-depth` and per-map rules govern entry eligibility. The
shared entrance hook adds `uniq_trove no_monster_gen chance_trove`, the
one-time `O` marker, Trove terrain and appearance, and its source price.
Selection draws from effective, positive-weight source destinations using
stable IDs, never filesystem enumeration. `allow_dup` on a destination
does not let a consumed outside entrance reopen. A requested destination
ID is accepted only for production-path verification and sparse mod tests
when that ID is eligible.

The 21 destinations encompass one temporary level. Their ordinary ambient
monster and item generation is disabled as specified by the branch and
vault tags; all authored monsters, plants, items, shops, clouds, traps,
doors, water, lava, windows, and exits are populated through the existing
grid and Akara owners. Shared reward hooks use existing source-shaped item
requests and acquirement policies. Character skill weighting and source
random choices execute in Lua at generation, then become saved entities
and records. A rare reward or monster is never dropped merely because its
downstream mechanic is incomplete; any wider gap is recorded explicitly.

## Toll generation and saved ownership

Each realized entrance draws one toll from a dedicated, saved generation
stream so later gameplay RNG does not depend on which price appeared. The
source offers a one-in-twenty no-piety option except for its excluded gods,
then chooses among its item-price pool according to species, god, and the
source's existing shop-item consideration. Prices include item class and
subtype, quantity, required enchantment, ego, artefact identity, a specific
rune, or the horn of Geryon as applicable. Source item names and enums come
from shared ID modules imported at their use sites. The price is immutable
after population and is stored in a Lua-defined Akara component linked to
the exact source marker, cell, and vault ID. Display, save, and entry read
that component rather than rerolling the price.

The component also records whether the gate is open or spent, its closure
reason, and the accepted payment receipt. A separate player visit component
holds the exact outside level and coordinate, the chosen destination ID,
and the temporary floor ID. The map grid owns the open or expired portal
feature; Akara owns dynamic state and every item. Neither source markers nor
module globals are mutable gameplay state.

## Entry and payment transaction

Pressing downstairs on the outside gate first asks the source-style
confirmation. Refusal and insufficient payment are free and leave the
gate, inventory, piety, RNG, and world unchanged. The existing command
confirmation protocol carries the request; a forced retry identifies the
same gate to avoid confirming a different marker after movement.

For item prices, search carried inventory only. Match source base/subtype,
known type, properties, enchantment, quantity, ego, and artefact name. A
higher enchantment satisfies a minimum. When several qualify, prefer an
exact enchantment match, otherwise use the lowest qualifying enchantment;
without an enchantment requirement use the first source-order candidate.
An equipped item cannot be surrendered. A successful entry consumes exactly
the requested stack quantity or the single selected item. A specified rune
is shown and retained. The horn and other miscellaneous prices follow
their source matching and consumption rules.

For no-piety prices, Ashenzari refuses at entry, including a character who
converted after finding the gate. A confirmed entry reduces current piety
to 15 when it was higher and leaves a godless player unchanged. The source
message and a payment note name the actual resource surrendered or shown.

The generic staged portal transaction must finish generation and validate
the destination before accepting payment. Gate closure, item debit or piety
change, visit creation, player movement, and payment receipt commit as one
reversible action. A failed hook, placement, population, landing, debit, or
save validation must leave the player and every resource unchanged. Only an
accepted entry spends the source stair action time. Return through any
authored exit goes to the exact outside cell, rejects an occupied return
site without spending time, then retires the temporary floor and its
remaining entities. The outside gate stays spent.

## Save, presentation, and mod contract

Add distinct Trove entrance and exit feature IDs and terminal rendering.
The entrance's inspection text names the saved price and says whether a
rune must be shown, an item given, or divine favour lost. On return, the
outside cell displays the source expired portal. A save validator joins
each realized source marker to one gate; checks the toll shape, source
identity, feature, spent state, and receipt; and checks any active visitor
against exactly one spent gate and one Trove floor. It rejects missing,
duplicate, foreign, or altered payment and visit state without rerolling
source content. Existing effective-ruleset hashes protect modded saves.

Document the map and hook directories, toll component fields, price and
confirmation flow, how to add or replace one definition, and how mods may
add a new price policy without editing Go or a central switch. Every Lua
function needs a comment explaining how and why it operates; system files
need a theory of operation, and policy files need usage examples. Keep lines
at most 120 characters, prefer about 80, and break up multi-field literals.

## Verification

- Compare all 35 committed MAP blocks and metadata to the pinned source;
  normal tests read only committed content.
- Place and populate all 14 entrances and all 21 destinations through
  production code. Confirm authored exits, rewards, actors, traps, fog,
  and source-position hook effects.
- Exercise the full price table, species and god exclusions, shop-item
  consideration, exact and higher enchantment, unidentified or equipped
  items, partial stack consumption, rune proof, and no-piety payment.
- Exercise confirmation refusal, insufficient payment, successful entry,
  save and restore before and after payment, occupied return, return floor
  retirement, and failed staging rollback including item and piety state.
- Test sparse mod addition, same-path replacement, zero-weight exclusion,
  malformed hook, and impossible map fit through the layered VFS.
- Export text snapshots of all 21 destination floors and an index showing
  each exit's exact outside connection. Run focused Lua, game, terrain,
  and terminal checks, plus changed-file readability and whitespace checks.
  Commit and push the contiguous Trove product category to `main`.
