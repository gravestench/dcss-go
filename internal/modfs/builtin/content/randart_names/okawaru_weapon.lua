-- okawaru weapon is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/randname.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "okawaru weapon",
    entries = {
        {
            weight = 400,
            text = "@weapon@",
        },
        {
            weight = 2,
            text = "of @player_name@'s @_valour_name_@",
        },
        {
            weight = 3,
            text = "of Okawaru's @divine_esteem@",
        },
        {
            weight = 1,
            text = "of Okawaru, @_verbing_@",
        },
        {
            weight = 10,
            text = "of @_strategy_or_justice_@",
        },
        {
            weight = 5,
            text = "of @_philosophy_name_@",
        },
        {
            weight = 3,
            text = "of @_balance_or_order_@",
        },
        {
            weight = 5,
            text = "of @_power_name_@",
        },
        {
            weight = 2,
            text = "of @_virtue_name_@",
        },
        {
            weight = 1,
            text = "of the @_diviner_name_@",
        },
        {
            weight = 5,
            text = "of the @_weapon_animal_@",
        },
        {
            weight = 5,
            text = "of @_place_name_@",
        },
        {
            weight = 2,
            text = "of @_item_name_@",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
