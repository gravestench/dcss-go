-- okawaru armour is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/randname.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "okawaru armour",
    entries = {
        {
            weight = 400,
            text = "@armour@",
        },
        {
            weight = 2,
            text = "of @player_name@'s @_valour_name_@",
        },
        {
            weight = 2,
            text = "of Okawaru's @divine_esteem@",
        },
        {
            weight = 2,
            text = "of the @_armour_animal_@",
        },
        {
            weight = 1,
            text = "of @_good_or_divine_@",
        },
        {
            weight = 2,
            text = "of @_armour_name_shielding_@",
        },
        {
            weight = 1,
            text = "of @_armour_property_name_@",
        },
        {
            weight = 1,
            text = "of @_wacky_armour_name_@",
        },
        {
            weight = 2,
            text = "of @_politics_name_armour_@",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
