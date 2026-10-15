# Source-backed item identification

## Intent

Make item discovery behave like the pinned DCSS game without tying the
rules to a closed list of built-in item IDs. Unknown consumables and magical
items receive stable, run-specific appearances. Knowledge gained by using or
identifying one type applies to every copy of that type, survives a save,
and changes names everywhere the player sees an item. Equipment keeps its
separate per-item knowledge of enchantment and special properties.

The source is pinned at `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`.
The core references are `ng-init.cc:326-420`, `item-name.cc:1272-1815` and
`item-prop.cc:964-1064,1915-2050`. New Lua item files participate through
their catalog class, subtype, and identification metadata. Refresh tools may
regenerate committed catalogs deliberately; normal builds load committed Lua.

## Boundary

Lua owns the identification rules, appearance generation, name formatting,
and policy decisions. Go continues to own the generic item ECS store, save
codec, terminal cells, and calling a presentation policy. Go neither switches
on an item ID nor contains item naming rules or inline Lua.

The player owns a saved `character.item_knowledge` component with
`known_types: map<string,bool>` and `appearance_seeds: map<string,int64>`.
Every item entity may own a saved `item.identification` component with
`known_type`, `known_pluses`, and `known_properties` booleans and a
`cosmetic` integer. A missing component has the ordinary unknown defaults;
there is no second Go identification state.

The effective Lua catalog defines whether a type needs identification. The
five source categories are wands, potions, scrolls, jewellery, and staves.
All other categories display their base type by default. The source's
per-item rules for weapons, armour, and artefacts determine which pluses,
brands, and properties are shown. The first implementation covers existing
non-artefact item records and records artefact-specific knowledge separately
for the later artefact domain; it does not invent artefact behavior.

## Appearance and knowledge

At game creation, one Lua policy iterates all active discoverable item
definitions in stable catalog order. It draws run-specific, unique
descriptors from class-specific source tables and naming rules.
Jewellery uses separate ring and amulet pools under the same item class.
The resulting mapping is saved, so restore never rerolls descriptions.
Added mod items enter the same process without editing an ID switch. A mod
may supply a valid appearance rule in its own item file; duplicate or
invalid descriptors fail clearly at creation or restore.

The first implementation uses the source descriptor words for wands,
potions, jewellery, and staves. Scroll labels are unique and deterministic,
but the exact source `make_name` algorithm and RNG sequence remain a
separate parity task. This does not affect scroll type discovery.

Reading, quaffing, evoking, or an explicit identify effect calls the same
Lua knowledge policy. Discovering a type updates the player's type map; a
known type changes every matching copy's displayed name. Starting items
receive the source's starting knowledge. Enchantment and properties remain
per-item. Stack merging requires identical physical properties and compatible
knowledge; it never merges away a known state.

## Presentation and save

The existing Lua presentation policies receive item entity IDs and resolve
the player's knowledge and the item's catalog definition. They produce
the visible name for both inventory and floor items. Inventory labels,
prompt text, pickup/drop messages, and other item mentions use this one
formatter. The internal item ID remains available to input filtering and
gameplay; it is never used as a visible shortcut around identification.

Save validation checks that known type keys exist in the effective catalog,
appearance descriptors match their class and remain unique within it, and
per-item flags are valid for the item's class. A restore with the same
ruleset preserves both knowledge and visible names. Ruleset hash validation
continues to reject a changed effective mod tree.

## Acceptance

- Every active item in the five identifying classes gets a run-specific,
  stable unknown appearance; the scroll label parity gap is recorded above.
- Identifying one type updates all copies, including one on the floor; a
  save and restore preserves the names and the mapping.
- Known starting gear and unknown found gear show the appropriate weapon or
  armour plus and brand information without exposing hidden values.
- Using a potion or wand identifies its type through the shared policy;
  a mod-added item definition follows the same path.
- Save validation rejects duplicate appearances, unknown type keys, and
  incompatible per-item knowledge without changing the user's save file.
- The new rules are in readable `.lua` files, with source constants imported
  at use sites and no multi-field inline tables.
