-- xom weapon is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/randname.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "xom weapon",
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
            text = "\"Xom, @_verbing_@ and @_verbing_@\"",
        },
        {
            weight = 2,
            text = "of the @_verbing_@ @_fruit_name_@",
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
            weight = 400,
            text = "@weapon@",
        },
        {
            weight = 10,
            text = "@jewellery@",
        },
        {
            weight = 10,
            text = "@armour@",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
