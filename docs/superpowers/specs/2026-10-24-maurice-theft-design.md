# Maurice theft design

## Source behavior

Maurice's successful `AF_STEAL` contact affects the player only. Confusion
and pacification prevent theft. He scans carried items in inventory order,
skipping equipped items, an item currently being used, unsupported item
classes, and classes whose monster inventory slot is full. Each candidate
replaces the selected item with probability `value / cumulative_value`.
He prefers the selected item but attempts gold when no item is eligible or
on a one-in-ten roll while the player has gold. A stack transfer steals a
random quantity from one through the full stack. Gold theft takes the
lesser of the balance and 20–819 pieces. Taken entities become Maurice's
carried inventory and drop on his death. A stolen two-handed weapon makes
him drop an equipped shield before taking the weapon.

## Go/Lua ownership

One Lua theft policy maps source monster slots to existing item classes,
reads equipped and pending-use state, selects by the shared item valuation,
and transfers ECS item entities. Monster inventory capacity is derived from
carried and equipped components; no shadow copy of slots is saved. Full
stacks change carrier; partial stacks create an item entity with copied
instance knowledge and provenance. The wallet owner debits stolen gold
without recording a shop purchase. A gold item carried by Maurice records
the appropriate Zin tithe state and uses ordinary monster death drops.
The shield also uses the ordinary floor item components after being dropped.

## Verification

Production Lua tests cover eligibility, weighted selection, equipped and
pending item exclusion, partial/full stacks, gold fallback and accumulation,
confused and pacified skips, two-handed shield release, live contact,
death drop, and save validation.
The importer and Go engine require no new runtime handler.
