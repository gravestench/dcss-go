-- short_monster_name_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/rand_wpn.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "short_monster_name_",
    entries = {
        {
            weight = 1,
            text = "Acarine",
        },
        {
            weight = 10,
            text = "Beast",
        },
        {
            weight = 10,
            text = "Beetle",
        },
        {
            weight = 10,
            text = "Demon",
        },
        {
            weight = 10,
            text = "Dragon",
        },
        {
            weight = 10,
            text = "Giant",
        },
        {
            weight = 10,
            text = "Goblin",
        },
        {
            weight = 10,
            text = "Hydra",
        },
        {
            weight = 10,
            text = "Imp",
        },
        {
            weight = 10,
            text = "Jelly",
        },
        {
            weight = 1,
            text = "Lacertilian",
        },
        {
            weight = 10,
            text = "Newt",
        },
        {
            weight = 10,
            text = "Ogre",
        },
        {
            weight = 10,
            text = "Spider",
        },
        {
            weight = 1,
            text = "Testudine",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
