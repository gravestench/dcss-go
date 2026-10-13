# DCSS Go port inventory

Reference: `/Users/dylanknuth/src/crawl` at `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`.

| Domain | Source anchor | Go owner | Status |
| --- | --- | --- | --- |
| Rat fixture ID, glyph, speed, bite base damage | `crawl-ref/source/mon-data.h:1994-2001` | `content.Catalog` | Fixture only |
| Human/Fighter IDs | `crawl-ref/source/species-data.h:483`, `job-data.h:191` | `content.Catalog` | Fixture only; character generation unported |
| Potion of curing ID/name | `crawl-ref/source/potion-type.h:11`, `item-name.cc:671` | `content.Catalog` | Fixture only; potion effect unported |
| Fixed Dungeon terrain and stairs | This plan's test scenario | `game.Level` | Planned; procedural generation unported |
| Movement and logical turns | `crawl-ref/source` movement and scheduler paths | `game.Game`, `game.TurnScheduler` | Planned; full energy rules unported |
| Melee and death | `crawl-ref/source/melee-attack.cc`, `mon-data.h` | `game` and `rules` | Planned narrow fixture; hit, AC, EV, weapons, skills unported |
| Inventory and equipment | `crawl-ref/source/items.cc` | ECS item components, `game` | Planned pickup only; equipment and item use unported |
| Visibility and exploration | `crawl-ref/source/los.cc` | Future visibility domain | Unported |
| Species, backgrounds, skills, mutations | `species-data.h`, `job-data.h`, `mutation-data.h` | Future character domain | Unported |
| Spells and religion | `spl-data.h`, religion code | Future spell/religion domains | Unported |
| Branches, vaults, shops, runes, endgame | `branch-data.h`, `dat/`, generation code | Future world/content domains | Unported |
| C++ save compatibility, tiles, network client | C++ save/client code | Outside Go slice | Excluded from slice |

Every broad category needs a follow-up feature/content inventory before a full-port completion claim. The fixture entries do not count as a port of their categories.
