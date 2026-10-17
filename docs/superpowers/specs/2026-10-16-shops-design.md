# Source-backed shops and gold

## Intent and source boundary

Make shops a complete Lua-owned economy feature. A player can collect gold,
enter a shop, inspect and select stock, buy it, and return after saving. A
modder can add a shop type in one discovered Lua definition file, use existing
item definitions, and override any shop rule through the layered mod tree.
The reference is pinned DCSS commit
`e60ba3568b0c26447ad36ec5c7b963eb04b2778f`, especially
`shop-type.h`, `shopping.cc`, `dungeon.cc:place_spec_shop`, and
`dungeon.cc:item_in_shop`.

All ten active version-34 shop types belong to this slice: weapon, armour,
antique weapon, antique armour, assorted antiques, jewellery, book,
distillery, magic scroll, and general store. `SHOP_EVOKABLES` and
`SHOP_FOOD` are legacy enum entries that source generation explicitly
cannot stock. `SHOP_UNASSIGNED` and `SHOP_RANDOM` are selectors, never
saved shop kinds.
The source contains shop vaults in `.des` files. The shop runtime must
accept their typed shop specifications; importing the full shop-vault family
remains part of the broader `.des` vault-content work. A generated shop on
an ordinary floor and a fixed shop fixture make this slice playable now.

## Ownership and content

`character.wallet` is saved on the player. It owns gold held and total gold
spent. Gold on the floor remains an ordinary item entity until picked up;
pickup deposits its quantity into the wallet and destroys that floor item.
Gold cannot be carried, equipped, dropped as an inventory item, or stocked
by a shop. This follows the source's separate `you.gold` balance.

`world.shop` is a saved Akara component on one shop entity at one map cell.
It records type ID, location, displayed name, keeper seed/name data, greed,
and open/closed state. Each stock item is the existing `core.item` entity
with a new `shop.stock` owner component pointing to the shop and a stable
display order. An item has exactly one location among floor, carried,
reserved offer, and shop stock. The shop does not duplicate item records.
Items bought are the same entities with their stock owner removed.

The ten active base shop definitions are individual files under
`content/shops`. They declare source name, eligible item classes,
identification policy, and generation weight. A modded shop type follows
the same schema and is discovered without editing a registry switch. Legacy
gadget and food IDs are rejected as removed instead of silently generating
a different shop. Source provenance is a nearby
comment, never a gameplay field. Shared IDs live in `ids/shops.lua` and are
imported where used.

Lua policies own shop selection, greed, stock count, item generation,
identification, valuation, transaction, shopping-list maintenance, and
presentation labels. The generic Go kernel provides ECS operations, grid
position, RNG, save encoding, and a terminal screen. There is no giant
switch over shop kinds or item kinds. Value rules are small per-item-class
modules; they read the already committed item catalog and item instance
state. The source `item_value` and `item_price` arithmetic, including
quantity, identification, artefacts, brand/ego, pluses, charges, book
spells, minimum value, and stepdown, is preserved. Values that the current
item catalog lacks are committed there during this slice. Normal build and
launch never read the C++ checkout.

## Placement, transactions, and screen

Shop generation uses a named, saved shop RNG stream. It resolves random
shop types once, applies source greed and stock-count rules, generates
stock through the existing item generator, excludes gold, and identifies
non-antique stock. It rejects or retries invalid stock with a finite bound
and a descriptive error. A typed shop specification can override type,
name, suffix, greed, count, depth, and explicit item choices. The generator
requires a walkable shop cell and enforces one shop per cell. A shop entrance
is visible on the grid and remembered after leaving sight.

Opening a shop is a free UI operation. The DCSS-style screen shows its
name, stock hotkeys, selection markers, prices, wallet balance, sorting,
examination, a shopping-list marker, and a purchase confirmation. Commands
for the screen come from focused Lua input/presentation policies; Go only
draws the returned screen model and relays selections. It fills the terminal
under the existing minimum size. Empty shops remain visitable but display
the source empty-shop message until later shop closure policy runs.

The purchase policy rechecks shop, item ownership, quantity, price, and
wallet at confirmation. Selected items are an all-or-nothing transaction:
either total cost is affordable and every selected item transfers exactly
once, or nothing changes. Gold spent increments the purchase counter.
Source identification is applied at purchase, including the source rule
that equipment is identified even from antique shops. An item that cannot
fit in inventory is placed outside at the shop entrance. The shopping list
is saved by stock entity identity and removes purchased items; it never
retains dead references. Source ordering by type, price, and name is
available without changing the underlying stock order.

## Saves and verification

The save format bumps once for new wallet, shop, stock, and shopping-list
state. Restore checks known effective shop type, valid greed and balance,
one shop per cell, valid shop terrain, nonempty stock references, exclusivity
of item locations, stock owner existence, no gold in stock, and shopping-list
references. It does not regenerate stock or reroll prices. Effective
layered-rule checksum behavior remains unchanged.

Lua `_test.lua` tests import the production definitions, schemas, and
policies. They cover all ten active types, both removed IDs, source price examples from each item
class, antique identification, greed and stock generation, gold pickup,
sorting, shopping-list entries, insufficient funds, multi-item atomicity,
inventory overflow, and invalid restore state. Integrated Go and terminal
tests cover entering a shop, buying an item, rendering at minimum and wide
sizes, save/restore continuation, and a mod-added shop. Run focused suites,
build, vet, style, and diff checks after the category. Make one shop
implementation commit, then fast-forward verified work into local `main`.
