# Fixed animal pathfinding

Source anchors: pinned `crawl-ref/source/mon-movetarget.cc:97-135` and `mon-behv.cc:469-475`. Crawl pathfinds when an animal cannot travel straight to a target; sight alone does not prove the target is reachable.

For the fixed Dungeon's walkable terrain, an ordinary animal computes a deterministic shortest route to its current seek or wander target whenever a direct step is blocked or the target is outside its sight. The route uses eight neighboring cells and avoids occupied actor tiles except the player's target tile for melee. The animal takes only the first step; the next action recomputes against current occupancy. Route ties follow a fixed direction order. If no route exists, it waits; a wanderer can later retarget. The path is derived state and is not saved.

This does not reproduce Crawl's full movement costs, habitat restrictions, waypoint cache, or pathfinding preferences. It prevents fixed-map animals from oscillating or freezing against the central wall and provides a small owner-local navigation rule for future monster behaviors.
