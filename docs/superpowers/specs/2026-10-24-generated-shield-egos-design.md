# Generated shield egos

## Intent

All seven egos that the pinned DCSS source generates on bucklers, kite
shields, and tower shields must affect the equipped player. The current
Lua item generator already selects their source weights. A player should
receive the same defenses from any shield size, including a shield found
in a vault or added by a mod.

## Source behavior and current gap

`makeitem.cc` generates Resistance, Fire Resistance, Cold Resistance,
Poison Resistance, Positive Energy, Reflection, and Protection on shields.
The source applies the first five through worn armour resistance, grants
three AC from Protection, and treats Reflection like the reflection amulet
after a successful block. The port's resistance scans omit the shield
slot, its AC calculation omits shield Protection, and its player reflection
check reads only jewellery. Monster shield reflection already exists.

## Design

Use `equipment.worn` as the single live equipment snapshot. It already
checks form-melded slots and artefact brands. Add shield to the existing
resistance scans, add the source three AC through `fighter.defense`, and
extend the existing reflection predicate to a worn Reflection shield.
No new status component, parallel shield-ego dispatcher, or Go gameplay
branch is needed. The same reflection predicate serves thrown missiles,
launcher shots, and blockable monster beams.

The ordinary shield ego remains inert. Generated ego content and weights
stay unchanged. Other armour slots and nongenerated shield egos belong to
their own equipment slices; source eligibility is not inferred from the
generator's shorter weighted set. Monster shield reflection is already
live. Monster armour resistance from body and shield equipment remains a
separate actor-equipment slice.

## Verification

Tests equip each generated shield ego through actual ECS item and equipped
components. They read fire, cold, poison, and negative-energy resistance,
Protection AC, and reflection after a real block. Removing or melding the
shield must remove its benefit. A live game shield survives save/restore.
The category passes focused Lua and Go tests, build, formatting, and diff
checks before one `main` commit and push.
