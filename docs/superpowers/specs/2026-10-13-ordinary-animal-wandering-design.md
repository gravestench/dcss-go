# Ordinary animal wandering and foe memory

Source anchors: pinned `crawl-ref/source/mon-movetarget.cc:714-737,930-955`, `mon-behv.cc:590-632,932-955`, and `mon-act.cc:1482-1483`. Source wanderers choose a target from offsets in `[-6,6]` on each axis, retry up to 150 times for a safe point, and occasionally change course. Animals that see a foe receive 250–550 aut of memory; player time reduces it while unseen.

The fixed rat and quokka use the `ai` RNG stream to choose a walkable floor target within that offset box, retarget on arrival or a 1-in-20 wander check, and move one step toward it. Sight acquisition interrupts wandering. While seeking, a visible player refreshes a 250–550-aut deadline; after sight is lost, the animal pursues only its last-seen tile until reaching it or memory expires. The saved ECS AI component owns the wander target and deadline, so restoring a game does not reroll those decisions. Previous version-6 `chase`, `wander`, and `seek` AI records remain loadable; a legacy zero-deadline `seek` receives a finite 250-aut deadline on its next unseen decision.

This extends the fixed Dungeon AI only. Full source target selection, pathfinding, alert propagation, sleeping, intelligent/other monster behavior, and cross-level pursuit remain later work.
