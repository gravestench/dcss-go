-- weapon is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/randname.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "weapon",
    entries = {
        {
            weight = 10,
            text = "of @_power_or_anger_@",
        },
        {
            weight = 10,
            text = "of @_battle_or_war_@",
        },
        {
            weight = 1,
            text = "of @player_doom@",
        },
        {
            weight = 8,
            text = "of @death_or_doom@",
        },
        {
            weight = 1,
            text = "of @_verbing_@ @death_or_doom@",
        },
        {
            weight = 6,
            text = "of @_adjective_@ @_strategy_or_justice_@",
        },
        {
            weight = 10,
            text = "of @_strategy_or_justice_@",
        },
        {
            weight = 3,
            text = "of the @_verbing_@ @_people_name_@",
        },
        {
            weight = 3,
            text = "of the @_people_name_@",
        },
        {
            weight = 2,
            text = "of the @_verbing_@ @_diviner_name_@",
        },
        {
            weight = 5,
            text = "of the @_verbing_@ @_weapon_animal_@",
        },
        {
            weight = 5,
            text = "of the @_weapon_animal_@",
        },
        {
            weight = 2,
            text = "of the @_plant_name_@",
        },
        {
            weight = 7,
            text = "of @_evil_stuff_@",
        },
        {
            weight = 5,
            text = "of @_catastrophe_name_@",
        },
        {
            weight = 8,
            text = "of @_chaos_name_@",
        },
        {
            weight = 8,
            text = "of @_balance_or_order_@",
        },
        {
            weight = 10,
            text = "of @_economics_or_politics_@",
        },
        {
            weight = 8,
            text = "of @branch_name@",
        },
        {
            weight = 7,
            text = "of @_place_name_@",
        },
        {
            weight = 5,
            text = "of @_discomfort_weapon_@",
        },
        {
            weight = 3,
            text = "of @_mental_illness_weapon_@",
        },
        {
            weight = 4,
            text = "of the @_item_name_@",
        },
        {
            weight = 1,
            text = "of @_magic_name_@",
        },
        {
            weight = 5,
            text = "of @_substance_name_@",
        },
        {
            weight = 7,
            text = "of @_science_name_@",
        },
        {
            weight = 5,
            text = "of @other_weapon_name@",
        },
        {
            weight = 30,
            text = "\"@_plain_weapon_name_@\"",
        },
        {
            weight = 5,
            text = "of @_time_name_@",
        },
        {
            weight = 5,
            text = "of @_sky_or_light_@",
        },
        {
            weight = 18,
            text = "of @_virtue_or_vice_@",
        },
        {
            weight = 10,
            text = "of @_number_or_qualifier_@ @_thing_names_@",
        },
        {
            weight = 5,
            text = "of @_destiny_name_@",
        },
        {
            weight = 9,
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
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
