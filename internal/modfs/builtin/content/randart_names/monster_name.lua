-- _monster_name_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/rand_wpn.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_monster_name_",
    entries = {
        {
            weight = 10,
            text = "@short_monster_name_@",
        },
        {
            weight = 10,
            text = "@player_species@",
        },
        {
            weight = 10,
            text = "Killer Bee",
        },
        {
            weight = 10,
            text = "Killer Klown",
        },
        {
            weight = 10,
            text = "Orb Guardian",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
