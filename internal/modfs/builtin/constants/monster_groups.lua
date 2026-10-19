-- Monster groups are population categories; members still have their own monster IDs.

local monsters = require("ids.monsters")

local groups = {}

groups.tentacles = {
    [monsters.MONS_ELDRITCH_TENTACLE] = true,
    [monsters.MONS_ELDRITCH_TENTACLE_SEGMENT] = true,
    [monsters.MONS_KRAKEN_TENTACLE] = true,
    [monsters.MONS_KRAKEN_TENTACLE_SEGMENT] = true,
    [monsters.MONS_STARSPAWN_TENTACLE] = true,
    [monsters.MONS_STARSPAWN_TENTACLE_SEGMENT] = true,
}

-- DCSS exempts these diagnostic monsters from its harmless-obstacle rule.
-- A modded test scenario may therefore target them with an allied spell.
groups.test_monsters = {
    [monsters.MONS_TEST_SPAWNER] = true,
    [monsters.MONS_TEST_STATUE] = true,
    [monsters.MONS_TEST_BLOB] = true,
}

return groups
