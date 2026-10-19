-- trog weapon is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/randname.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "trog weapon",
    entries = {
        {
            weight = 20,
            text = "of @_power_or_anger_@",
        },
        {
            weight = 5,
            text = "of @_adjective_@ @_power_or_anger_@",
        },
        {
            weight = 20,
            text = "of @_battle_or_war_@",
        },
        {
            weight = 5,
            text = "of the @_verbing_@ @_battle_or_war_@",
        },
        {
            weight = 20,
            text = "of @death_or_doom@",
        },
        {
            weight = 5,
            text = "of @_adjective_@ @death_or_doom@",
        },
        {
            weight = 7,
            text = "of @_strategy_name_@",
        },
        {
            weight = 15,
            text = "of @_justice_name_@",
        },
        {
            weight = 30,
            text = "of @_virtue_or_vice_@",
        },
        {
            weight = 1,
            text = "of Trog",
        },
        {
            weight = 20,
            text = "of Trog's @divine_esteem@",
        },
        {
            weight = 10,
            text = "of Trog's @_anger_quality_@",
        },
        {
            weight = 15,
            text = "of the @_weapon_animal_@",
        },
        {
            weight = 15,
            text = "of @_evil_stuff_@",
        },
        {
            weight = 10,
            text = "of @_catastrophe_name_@",
        },
        {
            weight = 15,
            text = "of @_chaos_name_@",
        },
        {
            weight = 20,
            text = "of @_balance_or_order_@",
        },
        {
            weight = 20,
            text = "of @_economics_or_politics_@",
        },
        {
            weight = 15,
            text = "of @branch_name@",
        },
        {
            weight = 15,
            text = "of @_place_name_@",
        },
        {
            weight = 15,
            text = "of @_time_name_@",
        },
        {
            weight = 10,
            text = "of @_sky_or_light_@",
        },
        {
            weight = 20,
            text = "of @_number_or_qualifier_@ @_thing_names_@",
        },
        {
            weight = 10,
            text = "of @_discomfort_weapon_@",
        },
        {
            weight = 10,
            text = "of @_mental_illness_weapon_@",
        },
        {
            weight = 10,
            text = "of the @_item_name_@",
        },
        {
            weight = 15,
            text = "of @_philosophy_name_@",
        },
        {
            weight = 10,
            text = "of @_science_name_@",
        },
        {
            weight = 10,
            text = "of @other_weapon_name@",
        },
        {
            weight = 10,
            text = "of @_monster_name_@@killer_name@",
        },
        {
            weight = 30,
            text = "\"@_plain_weapon_name_@\"",
        },
        {
            weight = 10,
            text = "\"@_adjective_@ @_plain_weapon_name_@\"",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
