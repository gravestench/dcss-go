# Rat Kill Experience

## Goal and source

The fixed rat can die, but that kill currently grants no experience and the HUD shows `XL: --`. Port the ordinary source XP result for the fixed Human/Fighter versus rat encounter and persist it. At pinned C++ revision `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`, `mon-util.cc:2345-2535` computes `exper_value` from live HD, maximum HP, speed, and monster XP modifier; for the scenario rat (HD 1, HP 4, speed 10, modifier 1), it yields **1 XP** after the minimum-one rule. `mon-death.cc:289-310` gives full credit for player damage, `player.cc:2448-2505` pools then applies gained XP, and `player.cc:2292-2302` and `3355-3436` give Human XL1 progress as 100 × total XP / 9, truncated. The 79×24 source HUD displays `XL:  1 Next: 11%` after the rat kill and `Next:  0%` at start.

## Ownership and boundaries

The pure `character` rule computes the source rat XP and Human XL1 progress. An ECS `Progression` component owns total XP for the player. The player combat system records which rat it actually killed; the death system awards XP only for that recorded player kill before the rat entity is removed. A rat already dead before the turn, or killed by another cause, awards nothing. The HUD projects XL1 and next-level progress from the component. Save snapshots persist progression and restore validates it. Keep version 6 backward-readable: an older version-6 save without this newly optional component initializes zero XP, while new snapshots include it. This avoids invalidating a user's current Go save. A later save-schema redesign may bump the version.

The fixed scenario has one rat worth one XP, so XL2, HP/MP gains, automatic skill training, and stat choices cannot occur in normal play here. Those require a later advancement slice before more XP-producing monsters are made playable. To keep this invariant explicit, restore rejects XP outside the fixed scenario's 0–1 range and rejects one earned XP while a rat entity is still present. Older version-6 saves with no progression field default to zero even if their rat is already gone. C++ RNG sequences remain out of scope; this XP result needs no draw.

## Verification

Tests cover the rat's one-XP source value, Human progress rounding, player-kill attribution, no award on pre-dead cleanup, HUD change, save/restore continuation, and rejection of malformed progression. A live 79×24 kill shows `XL: 1` and `Next: 11%`; save/load preserves them. Normal builds use the committed monster catalog.
