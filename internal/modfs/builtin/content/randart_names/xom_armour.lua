-- xom armour is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/randname.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "xom armour",
    entries = {
        {
            weight = 5,
            text = "of @_chaos_name_@",
        },
        {
            weight = 5,
            text = "of Xom's @_xom_esteem_@",
        },
        {
            weight = 2,
            text = "of Xom's @divine_esteem@",
        },
        {
            weight = 2,
            text = "\"@_adjective_@ Xom\"",
        },
        {
            weight = 1,
            text = "of @xom_name@",
        },
        {
            weight = 1,
            text = "of @_game_name_@",
        },
        {
            weight = 1,
            text = "of @player_death@",
        },
        {
            weight = 400,
            text = "@armour@",
        },
        {
            weight = 10,
            text = "@jewellery@",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
