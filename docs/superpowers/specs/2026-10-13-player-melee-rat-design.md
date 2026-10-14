# Human Fighter melee against the fixed rat

## Intent and boundary

Replace the Go fixture's fixed player damage roll with the pinned DCSS rules for an ordinary, awake Human Fighter attacking the fixed ordinary rat. Every currently selectable starting weapon, including unarmed, must work. This slice covers primary melee accuracy, ordinary damage, the rat's EV and AC, and the resulting HP/death event. It keeps the two-floor fixture and current 10-aut action cost; source attack delay, auxiliary attacks, brands, mutations, stabbing, status effects, and other monsters are later domains. The purpose is faithful gameplay from committed catalogs while preserving readable ownership boundaries.

## Ownership and flow

`combat` owns pure player attack calculations and a bounded roller interface. Input is a value assembled from ECS attributes, the stored starting skill points, the equipped weapon's committed item definition and enchantment, and the rat's committed monster definition. It produces a miss or hit with post-AC damage and no ECS or message side effects. `game` alone locates the target and equipped weapon, invokes the rule, updates rat HP, and emits events. Unarmed has no weapon entity. The existing named `melee` RNG stream is used in C++ phase order so Go saves continue deterministically; no new save field is needed.

The supported source path is `attack.cc:160-310, 1111-1235`, `fight.cc:1270-1310`, `actor.cc:115-119, 336-382`, `melee-attack.cc:750-790`, `monster.cc:3106-3200, 3241-3295`, `random.cc:235-253,313-321`, and normal form `form-data.h:64-75`, all at C++ revision `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`. Skill values use the already stored starting points, not only the displayed level. Normal rat defense is EV 10, AC 1, no shield or GDR. The source's 5% automatic hit/miss and shield phase precede damage; a rat with no shield cannot block, but the phase still consumes its bounded draw.

## Supported outcomes and failure behavior

An attack can miss, hit for zero after AC, or damage the rat. Zero-damage hits never lower HP. Damage reducing HP to zero uses the existing death cleanup. The game rejects a missing or mismatched equipped weapon, invalid combat input, or unsupported monster before advancing play, including on save restore. The pure rule returns errors for unsupported inputs and invalid RNG draws rather than inventing fallback values.

## Verification

Scripted rolls cover weapon and unarmed input, miss and automatic hit/miss, damage and AC absorption, C++ draw order, and source weapon skill/stat differences. Integration tests cover every selectable weapon, inventory independence for unarmed, the 10-aut bump and rat death, and deterministic save continuation. Run the whole Go test suite, vet, and build after integration. Do not read or regenerate C++ content at ordinary build time.
