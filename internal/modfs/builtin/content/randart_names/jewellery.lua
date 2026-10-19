-- jewellery is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/randname.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "jewellery",
    entries = {
        {
            weight = 3,
            text = "of the @_jewellery_animal_@",
        },
        {
            weight = 10,
            text = "of @_jewellery_special_name_@",
        },
        {
            weight = 10,
            text = "of @_suspicion_name_@",
        },
        {
            weight = 10,
            text = "of the @_people_name_@",
        },
        {
            weight = 5,
            text = "of the @_verbing_@ @_people_name_@",
        },
        {
            weight = 17,
            text = "of @_balance_or_order_@",
        },
        {
            weight = 14,
            text = "of @_philosophy_name_@",
        },
        {
            weight = 7,
            text = "of @_mental_illness_weapon_@",
        },
        {
            weight = 10,
            text = "of @other_weapon_name@",
        },
        {
            weight = 20,
            text = "of the @_armour_animal_@",
        },
        {
            weight = 3,
            text = "of @_flower_name_@",
        },
        {
            weight = 3,
            text = "of the @_adjective_@ @_fruit_name_@",
        },
        {
            weight = 5,
            text = "of @_evil_being_@",
        },
        {
            weight = 20,
            text = "of @_good_or_divine_@",
        },
        {
            weight = 12,
            text = "of @_politics_name_armour_@",
        },
        {
            weight = 2,
            text = "\"@_plain_armour_name_@\"",
        },
        {
            weight = 13,
            text = "of @_time_name_@",
        },
        {
            weight = 10,
            text = "of @_sky_or_light_@",
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
            weight = 10,
            text = "of Xom's @_xom_esteem_@",
        },
        {
            weight = 7,
            text = "of @_virtue_name_@",
        },
        {
            weight = 13,
            text = "of @_vice_name_@",
        },
        {
            weight = 10,
            text = "of @_number_or_qualifier_@ @_thing_names_@",
        },
        {
            weight = 10,
            text = "of @_number_or_qualifier_@ @_verbing_@ @_thing_names_@",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
