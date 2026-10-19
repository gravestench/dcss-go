# Monster destructive beams

Throw Barbs, Major Destruction, and Legendary Destruction now resolve from
committed monster books through the normal Lua monster spell intent. Their
beam contacts use the existing hit, shield, armour, resistance, damage,
and save owners.

Throw Barbs uses the source two-dice physical missile and declines a foe
within ordinary melee reach. A damaging hit lodges barbs as saved ECS
state. Moving with barbs causes two dice of additional damage; action time
ages the wound, with source-style extraction and monster movement rolls.
Hop, Rolling Charge, and ordinary stairs also pay barbs movement damage.
Repeat monster hits stack degree and duration, while an incapacitated
player cannot extract spikes.

Major Destruction draws uniformly from seven source spells: Bolt of Fire,
Fireball, Lightning Bolt, Sticky Flame,
Iron Shot, Bolt of Draining, and Orb of Electricity. Sticky Flame and Orb of
Electricity have new, individually discoverable Lua zap profiles.
Its tracer chooses before the cast and the cast chooses again, matching
the source's separate setup steps. The wrapper's six-cell range remains
authoritative even when its chosen child normally has a shorter range.

Legendary Destruction uses source weights 25:20:15 for Fireball, Iceblast,
and Ghostly Fireball. It fires two independently drawn explosions unless
the first kills its foe. Its wrapper range is five cells. Negative-energy
children reuse the existing drain hook; Sticky Flame reuses the ongoing
status owner. A live cast and save/restore continuation cover the new
book paths. A lethal double blast restores its final game-over state.

Chaos Breath is not an ordinary fixed-flavour beam. It needs a per-cell
chaos effect path and remains part of the outstanding chaos domain.
