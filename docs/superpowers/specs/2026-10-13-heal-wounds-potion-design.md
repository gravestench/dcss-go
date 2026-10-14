# Potion of heal wounds

This gameplay slice adds the source-backed potion of heal wounds to the supported fixed Dungeon scenario. Its catalog identity and name already come from the committed item artifact. A single potion appears on Dungeon:2 as a floor test encounter; Fighter starting gear remains source-ordered and unchanged.

The player picks it up and chooses its inventory letter with `q`. At ordinary Human/Fighter health below maximum, the effect heals `10 + random2avg(28, 3)` HP, capped by max HP. The first draw is in `[0,28)`, the next two in `[0,29)`, and the average is truncated. The named potion RNG stream and 10-aut quaff cost follow existing item use. At full HP, the source `can_quaff` guard refuses the known potion before time, RNG, or quantity changes, with its source message. Other statuses and species modifiers are outside this slice.

The potion is a normal ECS item. Picked-up and partially consumed stacks persist through the current Go save format; older saves without the new floor item continue loading. Verify the exact draw bounds, full-HP guard, terminal selection, consumption, and deterministic save continuation.
