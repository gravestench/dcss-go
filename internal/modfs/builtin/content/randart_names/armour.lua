-- armour is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/randname.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "armour",
    entries = {
        {
            weight = 10,
            text = "of @_armour_name_shielding_@",
        },
        {
            weight = 8,
            text = "of @_armour_property_name_@",
        },
        {
            weight = 20,
            text = "of @_wacky_armour_name_@",
        },
        {
            weight = 10,
            text = "of the @_profession_name_@",
        },
        {
            weight = 5,
            text = "of the @_adjective_@ @_profession_name_@\nof @_politics_name_armour_@",
        },
        {
            weight = 3,
            text = "of @_weather_name_@",
        },
        {
            weight = 9,
            text = "of @_good_or_divine_@",
        },
        {
            weight = 9,
            text = "of @_adjective_@ @_good_or_divine_@",
        },
        {
            weight = 5,
            text = "of the @_celestial_bodies_@",
        },
        {
            weight = 5,
            text = "of @_instrument_name_@",
        },
        {
            weight = 20,
            text = "of the @_armour_animal_@",
        },
        {
            weight = 1,
            text = "of the @_adjective_@ @_armour_animal_@",
        },
        {
            weight = 3,
            text = "of @_flower_name_@",
        },
        {
            weight = 1,
            text = "of the @_fruit_name_@",
        },
        {
            weight = 2,
            text = "of the @_critter_name_@",
        },
        {
            weight = 1,
            text = "of the @_adjective_@ @_critter_name_@",
        },
        {
            weight = 5,
            text = "of @_evil_being_@",
        },
        {
            weight = 5,
            text = "of @_mental_illness_armour_@",
        },
        {
            weight = 10,
            text = "of @_discomfort_and_inaction_@",
        },
        {
            weight = 10,
            text = "of @_game_name_@",
        },
        {
            weight = 15,
            text = "of @_other_armour_name_@",
        },
        {
            weight = 2,
            text = "\"@_plain_armour_name_@\"",
        },
        {
            weight = 25,
            text = "of @_philosophy_or_science_@",
        },
        {
            weight = 15,
            text = "of @_place_name_@",
        },
        {
            weight = 10,
            text = "of @_time_name_@",
        },
        {
            weight = 8,
            text = "of @_sky_or_light_@",
        },
        {
            weight = 30,
            text = "of @_virtue_or_vice_@",
        },
        {
            weight = 6,
            text = "of @_number_or_qualifier_@ @_verbing_@ @_thing_names_@",
        },
        {
            weight = 10,
            text = "of @_number_or_qualifier_@ @_thing_names_@",
        },
        {
            weight = 20,
            text = "of @god_name@'s @divine_esteem@",
        },
        {
            weight = 4,
            text = "of the @_verbing_@ Gods",
        },
        {
            weight = 4,
            text = "of the @_adjective_@ God",
        },
        {
            weight = 2,
            text = "of @god_name@, @_verbing_@",
        },
        {
            weight = 1,
            text = "of @god_name@",
        },
        {
            weight = 15,
            text = "of @branch_name@",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
