-- Gauntlet encounter pools ported from the pinned source gauntlet.lua.
-- Each entry is one theme, not one monster: the arena hook chooses a theme
-- by source weight, then rolls each named slot's count independently.
-- Keeping this data together makes the tier distribution inspectable.

local first_tier = {
    {
        first = {
            mons = "cane toad simulacrum / wyvern simulacrum " .. "/ hornet simulacrum",
            min = 1,
            max = 1,
        },
        second = {
            mons = "simulacrum place:D:12",
            min = 2,
            max = 4,
        },
        liquid = "water",
        plant = "withered",
    },

    {
        second = {
            mons = "raiju",
            min = 1,
            max = 1,
        },
        third = {
            mons = "steam dragon",
            min = 1,
            max = 2,
        },
        liquid = "water",
    },

    {
        second = {
            mons = "slime creature",
            min = 2,
            max = 4,
        },
        third = {
            mons = "jelly",
            min = 1,
            max = 3,
        },
        liquid = "water",
        plant = "demonic",
    },

    {
        first = {
            mons = "sixfirhy",
            min = 1,
            max = 1,
        },
        second = {
            mons = "ufetubus",
            min = 2,
            max = 4,
        },
        liquid = "water",
        plant = "demonic",
    },

    {
        first = {
            mons = "ice devil",
            min = 1,
            max = 1,
        },
        second = {
            mons = "white imp",
            min = 2,
            max = 4,
        },
        liquid = "water",
        plant = "demonic",
    },

    {
        first = {
            mons = "soul eater",
            min = 1,
            max = 1,
        },
        second = {
            mons = "shadow imp",
            min = 2,
            max = 4,
        },
        liquid = "water",
        plant = "withered",
    },

    {
        first = {
            mons = "ynoxinul",
            min = 1,
            max = 1,
        },
        second = {
            mons = "rust devil",
            min = 0,
            max = 1,
        },
        third = {
            mons = "iron imp",
            min = 2,
            max = 4,
        },
        plant = "demonic",
    },

    {
        first = {
            mons = "smoke demon",
            min = 1,
            max = 1,
        },
        second = {
            mons = "red devil",
            min = 0,
            max = 1,
        },
        third = {
            mons = "crimson imp",
            min = 2,
            max = 4,
        },
        liquid = "lava",
        plant = "demonic",
    },

    {
        first = {
            mons = "neqoxec",
            min = 1,
            max = 1,
        },
        second = {
            mons = "chaos spawn",
            min = 1,
            max = 3,
        },
        plant = "demonic",
    },

    {
        second = {
            mons = "shadow",
            min = 2,
            max = 4,
        },
        liquid = "water",
        plant = "withered",
    },

    {
        first = {
            mons = "catoblepas",
            min = 1,
            max = 1,
        },
        second = {
            mons = "gargoyle",
            min = 1,
            max = 2,
        },
    },

    {
        first = {
            mons = "torpor snail",
            min = 1,
            max = 1,
        },
        second = {
            mons = "yak band / wolf band / elephant band",
            min = 1,
            max = 1,
        },
    },

    {
        first = {
            mons = "fire crab",
            min = 1,
            max = 1,
        },
        second = {
            mons = "fire bat",
            min = 2,
            max = 4,
        },
        liquid = "lava",
    },

    {
        second = {
            mons = "shapeshifter",
            min = 1,
            max = 3,
        },
    },

    {
        first = {
            mons = "flying skull band",
            min = 1,
            max = 1,
        },
        plant = "withered",
    },

    {
        second = {
            mons = "hornet",
            min = 2,
            max = 3,
        },
    },

    {
        first = {
            mons = "queen bee",
            min = 1,
            max = 1,
        },
        second = {
            mons = "killer bee band",
            min = 1,
            max = 1,
        },
    },

    {
        first = {
            mons = "moth of wrath",
            min = 1,
            max = 1,
        },
        second = {
            mons = "wolf band",
            min = 1,
            max = 1,
        },
    },

    {
        first = {
            mons = "worldbinder",
            min = 1,
            max = 1,
        },
        second = {
            mons = "boggart",
            min = 1,
            max = 3,
        },
        plant = "demonic",
    },

    {
        first = {
            mons = "death scarab",
            min = 1,
            max = 1,
        },
        second = {
            mons = "spectre place:Lair:$",
            min = 1,
            max = 1,
        },
        liquid = "water",
        plant = "withered",
    },

    {
        first = {
            mons = "shining eye",
            min = 1,
            max = 1,
        },
        second = {
            mons = "floating eye / golden eye",
            min = 1,
            max = 2,
        },
        loot = "potion of mutation ident:type",
        plant = "demonic",
        weight = 5,
    },

    {
        first = {
            mons = "eye of devastation",
            min = 1,
            max = 1,
        },
        second = {
            mons = "floating eye / golden eye",
            min = 1,
            max = 2,
        },
        weight = 5,
    },

    {
        first = {
            mons = "tengu warrior",
            min = 1,
            max = 1,
        },
        second = {
            mons = "tengu conjurer",
            min = 1,
            max = 2,
        },
    },

    {
        first = {
            mons = "wizard",
            min = 1,
            max = 1,
        },
        second = {
            mons = "white imp / shadow imp",
            min = 1,
            max = 3,
        },
    },

    {
        second = {
            mons = "large abomination",
            min = 0,
            max = 2,
        },
        third = {
            mons = "small abomination",
            min = 3,
            max = 6,
        },
        plant = "demonic",
    },

    {
        first = {
            mons = "ice statue",
            min = 1,
            max = 1,
        },
        second = {
            mons = "rime drake",
            min = 1,
            max = 2,
        },
        liquid = "water",
    },

    {
        first = {
            mons = "oklob plant",
            min = 1,
            max = 1,
        },
        second = {
            mons = "acid dragon",
            min = 1,
            max = 2,
        },
    },

    {
        first = {
            mons = "necromancer",
            min = 1,
            max = 1,
        },
        second = {
            mons = "wolf band",
            min = 1,
            max = 1,
        },
        plant = "withered",
    },

    {
        second = {
            mons = "swamp worm",
            min = 2,
            max = 3,
        },
    },
}

-- Harder second-tier themes use the same slot contract. The source
-- writes two `third` fields in its balrug entry; Lua retains only the
-- latter, hell hound value. We state the effective rule once below.
local second_tier = {
    {
        first = {
            mons = "hydra simulacrum / harpy simulacrum " .. "/ ice dragon simulacrum",
            min = 1,
            max = 1,
        },
        second = {
            mons = "simulacrum place:D:15",
            min = 2,
            max = 4,
        },
        liquid = "water",
        plant = "withered",
    },

    {
        first = {
            mons = "dire elephant",
            min = 1,
            max = 1,
        },
        second = {
            mons = "elephant",
            min = 1,
            max = 3,
        },
    },

    {
        first = {
            mons = "catoblepas",
            min = 1,
            max = 1,
        },
        second = {
            mons = "molten gargoyle",
            min = 1,
            max = 2,
        },
        third = {
            mons = "gargoyle",
            min = 1,
            max = 2,
        },
        liquid = "lava",
    },

    {
        second = {
            mons = "shadow",
            min = 3,
            max = 6,
        },
        liquid = "water",
        plant = "withered",
    },

    {
        first = {
            mons = "fire crab",
            min = 1,
            max = 1,
        },
        second = {
            mons = "hell hound",
            min = 1,
            max = 3,
        },
        third = {
            mons = "fire bat",
            min = 3,
            max = 6,
        },
        liquid = "lava",
    },

    {
        first = {
            mons = "efreet",
            min = 1,
            max = 1,
        },
        second = {
            mons = "hell hound",
            min = 1,
            max = 3,
        },
        third = {
            mons = "fire elemental",
            min = 1,
            max = 3,
        },
        liquid = "lava",
        plant = "demonic",
    },

    {
        first = {
            mons = "hell hog",
            min = 1,
            max = 1,
        },
        second = {
            mons = "hell hound",
            min = 1,
            max = 3,
        },
        third = {
            mons = "fire bat",
            min = 2,
            max = 4,
        },
        liquid = "lava",
        plant = "demonic",
    },

    {
        first = {
            mons = "quicksilver ooze",
            min = 1,
            max = 1,
        },
        liquid = "water",
    },

    {
        second = {
            mons = "sixfirhy",
            min = 2,
            max = 4,
        },
        liquid = "water",
        plant = "demonic",
    },

    {
        first = {
            mons = "hell beast",
            min = 1,
            max = 1,
        },
        second = {
            mons = "hell hound",
            min = 0,
            max = 2,
        },
        liquid = "lava",
        plant = "demonic",
    },

    {
        first = {
            mons = "green death",
            min = 1,
            max = 1,
        },
        second = {
            mons = "orange demon",
            min = 0,
            max = 2,
        },
        plant = "demonic",
    },

    {
        first = {
            mons = "hellion",
            min = 1,
            max = 1,
        },
        second = {
            mons = "sun demon / smoke demon / red devil",
            min = 0,
            max = 1,
        },
        third = {
            mons = "hell hound",
            min = 0,
            max = 2,
        },
        liquid = "lava",
        plant = "demonic",
        weight = 5,
    },

    {
        first = {
            mons = "balrug",
            min = 1,
            max = 1,
        },
        third = {
            mons = "hell hound",
            min = 0,
            max = 2,
        },
        liquid = "lava",
        plant = "demonic",
        weight = 5,
    },

    {
        first = {
            mons = "cacodemon",
            min = 1,
            max = 1,
        },
        second = {
            mons = "neqoxec",
            min = 0,
            max = 3,
        },
        loot = "potion of mutation ident:type",
        plant = "demonic",
        weight = 5,
    },

    {
        first = {
            mons = "blizzard demon",
            min = 1,
            max = 1,
        },
        second = {
            mons = "white imp / ice devil",
            min = 0,
            max = 3,
        },
        liquid = "water",
    },

    {
        first = {
            mons = "reaper",
            min = 1,
            max = 1,
        },
        second = {
            mons = "hellwing / shadow imp",
            min = 1,
            max = 3,
        },
        liquid = "water",
        plant = "withered",
    },

    {
        first = {
            mons = "glowing shapeshifter",
            min = 1,
            max = 1,
        },
        second = {
            mons = "shapeshifter",
            min = 2,
            max = 3,
        },
    },

    {
        first = {
            mons = "apocalypse crab",
            min = 1,
            max = 1,
        },
        plant = "demonic",
    },

    {
        second = {
            mons = "flying skull band",
            min = 2,
            max = 3,
        },
        plant = "withered",
    },

    {
        first = {
            mons = "death drake",
            min = 1,
            max = 1,
        },
        second = {
            mons = "zombie place:D:15 / spectre place:D:15",
            min = 2,
            max = 4,
        },
        liquid = "water",
        plant = "withered",
    },

    {
        first = {
            mons = "ghost crab",
            min = 1,
            max = 1,
        },
        liquid = "water",
        plant = "withered",
    },

    {
        first = {
            mons = "meliai band",
            min = 1,
            max = 1,
        },
    },

    {
        first = {
            mons = "torpor snail",
            min = 1,
            max = 1,
        },
        second = {
            mons = "death yak band / hydra",
            min = 1,
            max = 1,
        },
    },

    {
        first = {
            mons = "entropy weaver",
            min = 1,
            max = 1,
        },
        second = {
            mons = "wolf spider",
            min = 0,
            max = 1,
        },
        third = {
            mons = "redback / jumping spider",
            min = 1,
            max = 2,
        },
        liquid = "water",
    },

    {
        first = {
            mons = "moth of wrath",
            min = 1,
            max = 1,
        },
        second = {
            mons = "wolf spider / nothing",
            min = 0,
            max = 1,
        },
        third = {
            mons = "redback",
            min = 2,
            max = 4,
        },
        liquid = "water",
    },

    {
        second = {
            mons = "thrashing horror",
            min = 1,
            max = 2,
        },
        third = {
            mons = "small abomination",
            min = 2,
            max = 4,
        },
        plant = "demonic",
    },

    {
        first = {
            mons = "great orb of eyes",
            min = 1,
            max = 1,
        },
        second = {
            mons = "ugly thing",
            min = 1,
            max = 2,
        },
        plant = "demonic",
    },

    {
        second = {
            mons = "glowing orange brain",
            min = 1,
            max = 2,
        },
        third = {
            mons = "ugly thing",
            min = 1,
            max = 2,
        },
        plant = "demonic",
    },

    {
        second = {
            mons = "large abomination",
            min = 2,
            max = 3,
        },
        third = {
            mons = "small abomination",
            min = 3,
            max = 6,
        },
        plant = "demonic",
    },

    {
        first = {
            mons = "wretched star",
            min = 1,
            max = 1,
        },
        second = {
            mons = "neqoxec / small abomination",
            min = 1,
            max = 3,
        },
        loot = "potion of mutation ident:type",
        plant = "demonic",
    },

    {
        second = {
            mons = "wizard",
            min = 2,
            max = 2,
        },
        third = {
            mons = "white imp / shadow imp",
            min = 3,
            max = 6,
        },
    },

    {
        first = {
            mons = "necromancer",
            min = 1,
            max = 1,
        },
        second = {
            mons = "death yak band",
            min = 1,
            max = 1,
        },
        liquid = "water",
        plant = "withered",
    },

    {
        second = {
            mons = "death scarab",
            min = 2,
            max = 2,
        },
        third = {
            mons = "spectre place:Lair:$",
            min = 2,
            max = 4,
        },
        liquid = "water",
        plant = "withered",
    },

    {
        first = {
            mons = "orange crystal statue",
            min = 1,
            max = 1,
        },
    },

    {
        first = {
            mons = "obsidian statue",
            min = 1,
            max = 1,
        },
        liquid = "water",
        plant = "withered",
    },

    {
        -- Guarantee that one places in the central location.
        first = {
            mons = "lightning spire",
            min = 1,
            max = 1,
        },
        second = {
            mons = "lightning spire",
            min = 0,
            max = 1,
        },
        third = {
            mons = "raiju",
            min = 1,
            max = 2,
        },
    },

    {
        first = {
            mons = "tyrant leech",
            min = 1,
            max = 1,
        },
        second = {
            mons = "swamp worm",
            min = 2,
            max = 4,
        },
    },
}

return {
    first = first_tier,
    second = second_tier,
}
