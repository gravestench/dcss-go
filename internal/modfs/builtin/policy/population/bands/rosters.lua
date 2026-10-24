-- Shared source band memberships. Monster definitions own the size and
-- eligibility of their bands; these named rosters avoid repeating weighted
-- follower lists for leaders that recruit from the same source band type.
local monsters = require("ids.monsters")

local rosters = {
    ORCS = {
        { id = monsters.MONS_ORC_PRIEST, weight = 6 },
        { id = monsters.MONS_ORC_WIZARD, weight = 7 },
        { id = monsters.MONS_ORC, weight = 35 },
    },
    ORC_WARRIOR = {
        { id = monsters.MONS_ORC_PRIEST, weight = 5 },
        { id = monsters.MONS_ORC_WIZARD, weight = 7 },
        { id = monsters.MONS_ORC, weight = 22 },
    },
    ORC_KNIGHT = {
        { id = monsters.MONS_ORC, weight = 12 },
        { id = monsters.MONS_ORC_WARRIOR, weight = 9 },
        { id = monsters.MONS_WARG, weight = 2 },
        { id = monsters.MONS_ORC_WIZARD, weight = 2 },
        { id = monsters.MONS_ORC_PRIEST, weight = 2 },
        { id = monsters.MONS_OGRE, weight = 1 },
        { id = monsters.MONS_TROLL, weight = 1 },
        { id = monsters.MONS_ORC_SORCERER, weight = 1 },
    },
    GNOLLS = { monsters.MONS_GNOLL },
    CENTAURS = { monsters.MONS_CENTAUR },
    TENGU = {
        monsters.MONS_TENGU_WARRIOR,
        monsters.MONS_TENGU_CONJURER,
    },
    MERFOLK = { monsters.MONS_MERFOLK },
    DEEP_ELF_KNIGHT = {
        { id = monsters.MONS_DEEP_ELF_AIR_MAGE, weight = 46 },
        { id = monsters.MONS_DEEP_ELF_FIRE_MAGE, weight = 46 },
        { id = monsters.MONS_DEEP_ELF_KNIGHT, weight = 24 },
        { id = monsters.MONS_DEEP_ELF_ARCHER, weight = 24 },
        { id = monsters.MONS_DEEP_ELF_DEATH_MAGE, weight = 3 },
        { id = monsters.MONS_DEEP_ELF_DEMONOLOGIST, weight = 2 },
        { id = monsters.MONS_DEEP_ELF_ANNIHILATOR, weight = 2 },
        { id = monsters.MONS_DEEP_ELF_SORCERER, weight = 2 },
    },
}

return rosters
