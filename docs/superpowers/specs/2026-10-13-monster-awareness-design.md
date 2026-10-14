# Monster awareness: fixed Dungeon slice

Source anchors: pinned `crawl-ref/source/mon-behv.cc:263-270,449-505,632-695` and `monster.cc:78-81`. Source monsters begin wandering, switch to seeking when a foe enters their own line of sight, and continue toward a remembered target after sight is lost.

The fixed rat and quokka use the existing terrain LOS calculation from each monster's tile. A newly spawned animal starts unaware. Seeing the player switches it to seeking and records the player's last visible position. When sight is lost, it heads only toward that position; on reaching it, it becomes unaware and waits. A monster on another floor never acquires the player. This slice leaves random wandering, shout/alert propagation, foe-memory decay, and pathfinding for later AI work.

The ECS AI component owns its behavior and last-seen target. Existing version-6 saves with the old `chase` value load; the first AI decision updates them to the new behavior. New saves preserve the target. Restore rejects invalid behavior or targets. No synthetic action notices are emitted for hidden monsters.
