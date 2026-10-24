# Pacified Monster Departure Design

## Intent

Finish the monster lifecycle started by Elyvilon's Heal Other. A pacified
monster must stop fighting, seek a level exit, and leave the floor with its
possessions. This is monster behavior, not a second divine-ability effect:
later mods may pacify a monster by another route and use the same owner.

## Source behavior

The pinned DCSS source changes the monster's real attitude to neutral,
ends its constriction, drops pursuit, and lets its wander behavior choose
the nearest level exit. Stairs, gates, teleport traps, and shafts count.
On an exit, or when at least three ordinary sight radii away from the
player, the monster leaves. It takes carried items with it, creates no
corpse, and gives no second experience award. Source periodically retries
another exit when a chosen route is blocked.

The port already saves `religion.elyvilon_pacified`, makes its real side
neutral, and awards XP once. It currently routes a neutral monster through
ordinary wandering. The Go grid already exposes level size, terrain,
travel-feature checks, and route steps to Lua; traps are ECS entities.

## Runtime ownership

`policy.ai.pacified_departure` owns exit recognition, destination choice,
and a route intent. It scans the active dense grid only when a destination
must be chosen, preferring the nearest reachable exit; a failed route
tries another candidate rather than sticking to an impossible target.
The existing saved AI target stores the chosen coordinates so ordinary
turns do not rescan every cell. If no exit can be reached, the monster may
wander and recheck later; the pacification marker remains an allegiance
and XP fact rather than a second route component.

The monster decision system asks this owner before generic neutral AI.
A post-movement system detects an exit underfoot or sufficient distance
from the player and dismisses the actor. Dismissal clears links and carried
items before removing it from the grid and ECS. A visible departure emits
the source-shaped exit message. The dismissal path never runs death hooks.

## Verification

Game integration checks that a pacified rat moves toward an exit, leaves
from a stair, and survives save/restore while traveling. A focused Lua
test covers exit choice, blocked routes, and no-exit fallback. The existing
Elyvilon XP and save tests continue to prove one award.

No inline Lua enters Go. The new Lua functions explain their reasons and
operation, use imported IDs, and keep lines within 120 columns.
