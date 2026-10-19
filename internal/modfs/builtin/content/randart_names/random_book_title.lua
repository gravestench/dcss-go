-- random_book_title is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/randbook.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "random_book_title",
    entries = {
        {
            weight = 15,
            text = "the @_book_plant_animal_@",
        },
        {
            weight = 20,
            text = "@_number_or_qualifier_@ @_thing_names_@",
        },
        {
            weight = 4,
            text = "the @_profession_name_@",
        },
        {
            weight = 13,
            text = "@_philosophy_or_science_@",
        },
        {
            weight = 8,
            text = "@_wacky_armour_name_@",
        },
        {
            weight = 2,
            text = "@_destiny_name_@",
        },
        {
            weight = 6,
            text = "@_place_name_@",
        },
        {
            weight = 1,
            text = "@_magic_name_@",
        },
        {
            weight = 4,
            text = "@_substance_name_@",
        },
        {
            weight = 2,
            text = "@_power_name_@",
        },
        {
            weight = 2,
            text = "@_mental_illness_weapon_@",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
