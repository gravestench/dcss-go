-- _ashenzari_object_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/randname.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_ashenzari_object_",
    entries = {
        {
            weight = 10,
            text = "Adversity",
        },
        {
            weight = 10,
            text = "Affliction",
        },
        {
            weight = 10,
            text = "Burden",
        },
        {
            weight = 10,
            text = "Fetters",
        },
        {
            weight = 10,
            text = "Gnosis",
        },
        {
            weight = 10,
            text = "Loss",
        },
        {
            weight = 10,
            text = "Omen",
        },
        {
            weight = 10,
            text = "Ordeal",
        },
        {
            weight = 10,
            text = "Portent",
        },
        {
            weight = 10,
            text = "Prison",
        },
        {
            weight = 10,
            text = "Regret",
        },
        {
            weight = 10,
            text = "Repose",
        },
        {
            weight = 10,
            text = "Sorrow",
        },
        {
            weight = 10,
            text = "Vision",
        },
        {
            weight = 10,
            text = "Yoke",
        },
        {
            weight = 100,
            text = "@_diviner_name_@",
        },
        {
            weight = 150,
            text = "@_discomfort_weapon_@",
        },
        {
            weight = 100,
            text = "@_philosophy_name_@",
        },
        {
            weight = 100,
            text = "@_discomfort_and_inaction_@",
        },
        {
            weight = 100,
            text = "@_suspicion_no_conflict_name_@",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
