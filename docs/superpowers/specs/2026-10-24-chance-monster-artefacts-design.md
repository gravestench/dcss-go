# Chance-based monster artefacts design

## Intent

Port every one-in-N named-artefact grant in the pinned `mon-gear.cc` monster
weapon and armour paths. Nikola may receive Arc Blade; Amaemon, Snakebite;
Arachne, Olgreb; Maggie or Margery, Wyrmbane; Terence, Throatcutter; Grunn,
Curses; Parghit, Dragon King; and Gastronok, Pondering. All eight artefacts
already have authoritative Lua catalog records. Their chances and ordinary
fallbacks should be readable beside the owning monster, not in a central ID
switch. This adds nine monster owners because Wyrmbane has two owners.

## Approach and ownership

Use one Lua gear handler per monster. A shared gear helper makes the source
one-in-100 or one-in-10 draw on the saved monster-gear stream, then checks the
player's saved unique item history. A used artefact does not replace its
ordinary item. The handler returns a named artefact entry or its ordinary
weapon or armour entry. The existing factory creates actual carried and
equipped Akara entities via the item generator, which owns the unique claim.
No new Go monster dispatch or duplicate artefact properties are introduced.

The two Wyrmbane grants set the source item plusses (+9 for Maggie, +10 or
+11 for Margery) after selecting the named artefact. Arachne's normal staff
of poison remains a weapon-slot item; shared staff weapon facts supply its
physical melee profile. Parghit's miss gives +6–9 gold dragon armour, and
Gastronok's miss gives an ordinary hat. A monster hat maps to the body
inventory slot for Gastronok, as in source monster equipment rules.
The ordinary fallback for Nikola, Amaemon, and Grunn retains its imported
forced brand and plus range; a generic quality roll would erase those source
weapon specs.

## Boundaries

The nine grants and their necessary ordinary fallbacks form this category.
Other unique gear upgrades, ordinary monster armour, Enchantress distortion,
and Geryon's horn remain separate work. The guarantee slice already handles
the five always-on named artefacts. A failed monster placement must not roll
or claim this gear. The source's order of checks is chance first, then saved
unique status; the same order applies even when an artefact is already used.

## Verification

Production Lua tests force the chance to succeed and fail for all nine
monsters through the real factory. They check the carried item's kind,
artefact ID, equipment slot, plusses, unique history, death drop, and the
ordinary fallback. The shared monster inventory validator accepts both the
staff and hat. A preclaimed artefact remains unclaimed by a later monster,
while the chance draw still occurs. Focused Go/Lua suites and diff checks
run before committing the category to `main`.
