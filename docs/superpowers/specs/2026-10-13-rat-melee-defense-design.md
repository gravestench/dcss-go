# Source-backed rat melee defense

## Intent and scope

Replace the fixed rat damage roll in the playable Human/Fighter scenario with the ordinary DCSS tag-34 melee path for a plain rat bite against an awake, unmodified Human Fighter. This is one combat slice, not a claim that all melee effects are ported. It must make misses, dodges, shield blocks, armour absorption, HP loss, death, messages, and save continuation coherent. The following slice will replace the player's fixed attack with source-backed weapon and unarmed rules.

The source is `/Users/dylanknuth/src/crawl` at `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`: `crawl-ref/source/{attack.cc,melee-attack.cc,fight.cc,actor.cc,player.cc,monster.cc,mon-data.h,item-prop.cc,random.cc}`. Normal Go builds and play consume only committed catalogs; they never read that checkout.

## Design

`game.Game` continues to own the run, Akara world, health, equipment, skills, and deterministic RNG streams. A small pure `internal/combat` package receives value inputs for the rat and Fighter, plus a bounded-roll interface. It resolves one bite and returns `Miss`, `Dodge`, `Block`, or `Hit` with nonnegative HP damage. It neither reads ECS nor emits text. `game.combatSystem` builds those inputs from the committed monster and item catalogs and live ECS components, applies damage, and emits DCSS-shaped messages. No duplicate rat attack, HD, AC, EV, or Fighter armour properties are stored in `Combatant.BaseDamage`.

The supported rat has `MONS_RAT` HD 1, AC 1, EV 10, speed 10, and its first `AT_BITE`/`AF_PLAIN` attack with damage 3 from the committed monster catalog. The Fighter has source-derived Strength 16, Dexterity 12, Armour 3, Shields 3, scale mail, and buckler. The defense projection uses the pinned source's integer formulas for normal Human size: body-armour encumbrance, shield penalty, EV, base AC, shield class, and GDR. It reads the current equipped item kind, plus, and current skills so future equipment changes can reuse it. It rejects unsupported effects explicitly rather than silently treating them as ordinary melee.

For this ordinary bite, resolution follows source order: monster base to-hit `18 + HD*3/2`, one `random2(toHit+1)` roll, randomized player EV for a monster attack, the 5% automatic hit/miss check, shield contest even if the bite would dodge, then `1 + random2(attackDamage)` and normal AC reduction on a hit. DCSS's `random2avg(max,2)` rolls `random2(max)` and `random2(max+1)`, then divides the sum by two. The Go RNG sequence need not match C++'s generator, but the distribution and call order in the supported path must match. All combat draws use the named `melee` stream so save/load continuation is deterministic.

`Combatant` becomes a dynamic defense component containing the current round's successful shield-block count. It resets when the defender begins a new action, matching the source's per-round reset; the count affects later blocks in that round. The component is serialized, validated, and restored. The save schema advances from 5 to 6 because the previous component shape and combat semantics are incompatible. Version-5 and C++ saves receive an explicit unsupported-version error.

Only the plain rat bite and baseline Human/Fighter defenses are supported here. Player attacks still use the existing fixed damage formula until the immediately following player-melee slice. Brands, statuses, alternate species, monster equipment, multiattacks, ripostes, resistances, and special damage remain separate work and are recorded in the port inventory.

## Verification

Table tests pin source-derived baseline defense values and bounded-roll outcomes at miss, dodge, block, armour absorption, and HP-damaging hit boundaries. Game tests prove a rat uses catalog fields, consumes a turn on all outcomes, reports the right outcome without false hit text, and persists deterministic continuation across save/load. Tests also reject corrupt combat state and old save versions. Run the full Go test suite, vet, build, and a short terminal smoke after the slice.
