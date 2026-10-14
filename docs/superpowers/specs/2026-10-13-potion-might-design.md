# Potion of Might in the Fixed Dungeon

## Scope and source

Make the Human Fighter's guaranteed starting potion of might playable in the fixed Dungeon. Pin the rules to C++ revision `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`: `potion.cc:232-253` grants `35 + random2(40)` turns and caps the accumulated duration at 80; `player.cc:7494-7504` stores turns as aut; `player-reacts.cc:540-556,814-815,1013` decrements the duration by each player action's aut; `duration-data.h:251-255` supplies the status and expiry text; `melee-attack.cc:1430-1437,3263-3265` adds `1 + random2(10)` to a landed primary hit before armour. Other statuses, berserk, auxiliary attacks, and other potions stay outside this slice.

## Ownership and flow

An ECS player duration component owns remaining might aut. New scenarios start at zero; old version-6 saves lacking the optional component restore as zero. Only the player may carry it, and restore rejects negative or over-cap values and monster/item copies. `game` validates a live carried `POT_MIGHT` before the action, then the quaff system draws once from the serializable `potion` RNG stream, increases the duration to `min(800, old + (35 + draw)*10)`, emits the source first/repeat message, and marks one item for post-update consumption. The same 10-aut action permits the rat to act. After the player's action systems, duration loses the action cost; reaching zero emits `You feel a little less mighty now.` and removes the status. Monster turns do not decrement it.

`combat.PlayerMelee` accepts whether the attacker is mighty. It makes the bonus draw from the `melee` stream after the existing base, skill, and enchantment damage rolls, only for a hit, then resolves armour. The game projects the ECS duration into combat. A miss does not draw a might bonus. The read-only `game.View` exposes the status; the 79×24 terminal shows the source's `Might` light in the existing HUD status area. Quaff inventory letters already work for carried potions, so no new menu mode is needed.

## Verification

Scripted tests pin potion bounds, cap and repeat wording, per-action aut decay, hit/miss draw order and damage, save continuation, old-save default, invalid-save rejection, and HUD status. Verify all Go tests, vet, build, and a terminal quaff/save/load smoke. The normal build continues to use only committed content, never the C++ checkout.
