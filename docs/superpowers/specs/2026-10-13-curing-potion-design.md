# Curing Potion in the Fixed Dungeon

## Scope and source

The fixed Dungeon already contains a floor potion of curing and supports pickup, but quaff remains a stub. Make carried curing quaffable through the terminal's `q` command and `game.Step`. Keep other potion effects unavailable until their own domain slices. Pin behavior to C++ revision `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`: `potion.cc:68-137` checks whether curing has a useful effect and heals `5 + random2(7)` in an ordinary Human; `player.cc:7777-7823` gives this Human a healing factor of two; `item-use.cc:2556-2655` consumes the selected potion and one turn only after a successful quaff.

## Ownership and flow

`game` validates that the selected item is a live, carried, positive-quantity `POT_CURING`, and that the player is alive. A rejected quaff consumes no RNG, item, or aut. The pinned source permits an ordinary Human to quaff at full HP, consuming the potion and turn even though the cap prevents an HP gain. The pure curing rule computes the heal from one bounded `potion` stream draw and caps HP at maximum. A quaff ECS system applies the health change, emits a message, and marks one item quantity for post-update consumption. `Game.runAction` applies consumption after Akara systems complete, using the same structural barrier as pickup and death. A successful quaff spends 10 aut and allows the rat to act through the existing scheduler. The generated item catalog remains committed and unchanged; save version 6 already records item quantity, health, RNG streams, and clock.

`terminal` owns only the choice UI: `q` opens a potion list using the inventory's existing pack letters, Esc cancels freely, and choosing curing sends the item ID to `Game.Step`. Choosing an unsupported carried potion explains that its effect is unavailable without spending a turn. No automatic selection of the first potion is allowed. Help text shows curing as available and other effects as pending.

## Verification

Tests cover healing bounds and cap including full-health consumption, wrong item and carrier rejection, quantity decrement and last-item destruction, rat scheduling, same-save continuation of the potion RNG stream, and the `q` choice/cancel path at 79×24. A terminal smoke starts Human/Fighter, picks up curing, quaffs after taking damage, saves, and reloads. Normal builds and play never read the C++ checkout.
