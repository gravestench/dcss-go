-- _plain_weapon_name_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/rand_wpn.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_plain_weapon_name_",
    entries = {
        {
            weight = 15,
            text = "@short_monster_name_@@_short_killer_name_@",
        },
        {
            weight = 8,
            text = "@_monster_name_@@killer_name@",
        },
        {
            weight = 2,
            text = "@short_monster_name_@@_long_killer_name_@",
        },
        {
            weight = 1,
            text = "@player_death@",
        },
        {
            weight = 15,
            text = "@_real_weapon_name_@",
        },
        {
            weight = 5,
            text = "@_joke_weapon_name_@",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
