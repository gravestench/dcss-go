# Playable Deep Elf Fighter

## Goal

Make Deep Elf Fighter playable on the generated Dungeon start, including
character choice, accurate level-one profile, growth, terminal presentation,
and save/restore. Preserve existing Human and Hill Orc behavior.

## Source basis

Pinned `species-data.h:65-83` defines Deep Elf as a living medium land
species without innate or level-up mutations. Its XP aptitude is -1, HP
modifier -2, MP modifier +2, attributes 5/12/10, and automatic Intelligence
gain every fourth XL. Committed catalogs already contain these values and
the species' skill aptitudes. `skills.cc:224-275` reassesses Fighter grants
against the chosen aptitude; the existing generic rules now implement this.

## Design and scope

Add Deep Elf to the supported ordinary Fighter species. The terminal menu,
game constructor, starting profile, XP and skill advancement, and save
validator continue to use the selected species identity. No new ECS
component is needed because the existing player identity references the
immutable catalog, while attributes, skills, and vitals already live in ECS.
The same medium body uses Fighter gear and cannot wear barding.

Source-value tests assert Deep Elf/Fighter attributes, HP/MP, and the lower
starting skill levels caused by poor martial aptitudes. A terminal start and
save round trip assert the chosen identity. A level-four growth test verifies
the automatic Intelligence gain. Unported jobs and other species remain
visible and explain unavailability.
