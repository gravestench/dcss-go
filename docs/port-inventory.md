# DCSS Go port inventory

Reference: `/Users/dylanknuth/src/crawl` at `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`.

| Domain | Source anchor | Go owner | Status |
| --- | --- | --- | --- |
| Rat fixture ID, glyph, speed, bite base damage | `crawl-ref/source/mon-data.h:1994-2001` | `content.Catalog` | Fixture only |
| Species definitions (40 YAML and three tag-34 legacy records) | `crawl-ref/source/dat/species/*.yaml`, `util/species-gen/*deprecated-species.txt`, `species-type.h`, `util/species-gen.py` | `speciesimport` build tool, checked-in `generated/species.json`, `content.Catalog` | All 43 concrete tag-34 IDs imported with source revision, file hashes, selection metadata, aptitudes, mutations, and recommendations; no species gameplay yet |
| Human/Fighter scenario IDs | `crawl-ref/source/species-data.h:483`, `job-data.h:191` | `content.Catalog` | Human definition imported; Fighter and scenario HP/damage remain fixtures; character generation unported |
| Potion of curing ID/name | `crawl-ref/source/potion-type.h:11`, `item-name.cc:671` | `content.Catalog` | Fixture only; potion effect unported |
| Fixed Dungeon terrain and stairs | This plan's test scenario | `game.Level` | Fixed two-floor slice; procedural generation unported |
| Movement and logical turns | `crawl-ref/source` movement and scheduler paths | `game.Game`, `game.TurnScheduler` | Playable slice; full energy rules unported |
| Melee and death | `crawl-ref/source/melee-attack.cc`, `mon-data.h:1998` | `game` and `rules` | Narrow fixture damage roll, rat AI and death; hit, AC, EV, weapons, skills unported |
| Inventory and equipment | `crawl-ref/source/items.cc` | ECS item components, `game` | Floor pickup and inventory view; equipment and item use unported |
| Visibility and exploration | `crawl-ref/source/los.cc` | Future visibility domain | Unported |
| Species gameplay, backgrounds, skills, mutations, advancement | `species-data.h`, `job-data.h`, `mutation-data.h`, character rules | Future character domain | Unported; imported definitions are not applied to character creation, progression, or combat |
| Spells and religion | `spl-data.h`, religion code | Future spell/religion domains | Unported |
| Branches, vaults, shops, runes, endgame | `branch-data.h`, `dat/`, generation code | Future world/content domains | Unported |
| Terminal client | New Go implementation | Bubble Tea and Lip Gloss | ASCII slice, keyboard commands and resize |
| Saved runs | New Go format | `save` and `game` | Versioned JSON for this slice; C++ saves unported |
| C++ save compatibility, tiles, network client | C++ save/client code | Outside Go slice | Excluded from slice |

Every broad category needs a follow-up feature/content inventory before a full-port completion claim. The fixture entries do not count as a port of their categories.

Run the slice with `go run ./cmd/dcrawl -seed 1 -save dcrawl-save.json` from this repository. Move with `h/j/k/l` or arrows, wait with `.`, pick up with `g`, take stairs with `<` or `>`, inspect inventory with `i`, save with `S`, load with `L`, and quit with `q`. Gameplay advances only when a valid action spends auts.
