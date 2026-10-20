-- These four source monsters cannot start asleep even when placed by a
-- vault. The generic statue catalog kind is a base, not a live exception.
local monsters = require("ids.monsters")

return {
    [monsters.MONS_ORANGE_STATUE] = true,
    [monsters.MONS_OBSIDIAN_STATUE] = true,
    [monsters.MONS_ICE_STATUE] = true,
    [monsters.MONS_ROXANNE] = true,
}
