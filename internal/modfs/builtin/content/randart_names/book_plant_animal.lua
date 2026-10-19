-- _book_plant_animal_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/randbook.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_book_plant_animal_",
    entries = {
        {
            weight = 1,
            text = "@_jewellery_animal_@",
        },
        {
            weight = 1,
            text = "@_critter_name_@",
        },
        {
            weight = 1,
            text = "@_plant_name_@",
        },
        {
            weight = 6,
            text = "@_weapon_animal_@",
        },
        {
            weight = 10,
            text = "@_armour_animal_@",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
