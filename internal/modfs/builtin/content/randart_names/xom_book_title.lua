-- xom_book_title is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/randbook.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "xom_book_title",
    entries = {
        {
            weight = 30,
            text = "@random_book_title@",
        },
        {
            weight = 10,
            text = "@_chaos_name_@",
        },
        {
            weight = 1,
            text = "@_game_name_@",
        },
        {
            weight = 2,
            text = "@player_death@",
        },
        {
            weight = 8,
            text = "@_wacky_armour_name_@",
        },
        {
            weight = 1,
            text = "@_politics_name_armour_@",
        },
        {
            weight = 5,
            text = "@_power_name_@",
        },
        {
            weight = 3,
            text = "@_discomfort_and_inaction_@",
        },
        {
            weight = 3,
            text = "@_discomfort_weapon_@",
        },
        {
            weight = 3,
            text = "@_mental_illness_weapon_@",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
