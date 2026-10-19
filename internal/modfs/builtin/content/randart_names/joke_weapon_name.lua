-- _joke_weapon_name_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/rand_wpn.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_joke_weapon_name_",
    entries = {
        {
            weight = 10,
            text = "Aubergine",
        },
        {
            weight = 10,
            text = "Backscratcher",
        },
        {
            weight = 10,
            text = "Bingo",
        },
        {
            weight = 10,
            text = "Blob",
        },
        {
            weight = 10,
            text = "Brush",
        },
        {
            weight = 10,
            text = "Bung",
        },
        {
            weight = 10,
            text = "Cookie Cutter",
        },
        {
            weight = 10,
            text = "ETAOIN SHRDLU",
        },
        {
            weight = 10,
            text = "Egg",
        },
        {
            weight = 10,
            text = "Fish",
        },
        {
            weight = 10,
            text = "Giant's Toothpick",
        },
        {
            weight = 10,
            text = "Globulus",
        },
        {
            weight = 10,
            text = "Grom",
        },
        {
            weight = 10,
            text = "Grum",
        },
        {
            weight = 10,
            text = "Hulk",
        },
        {
            weight = 10,
            text = "Lorem Ipsum",
        },
        {
            weight = 10,
            text = "Mud Pie of Death",
        },
        {
            weight = 10,
            text = "No More Talking",
        },
        {
            weight = 10,
            text = "Omelette",
        },
        {
            weight = 10,
            text = "Ox",
        },
        {
            weight = 10,
            text = "Q",
        },
        {
            weight = 10,
            text = "Raisin",
        },
        {
            weight = 10,
            text = "Rummage",
        },
        {
            weight = 10,
            text = "Secret Weapon",
        },
        {
            weight = 10,
            text = "Starlight",
        },
        {
            weight = 10,
            text = "String",
        },
        {
            weight = 10,
            text = "Stringbean",
        },
        {
            weight = 10,
            text = "Tattletale",
        },
        {
            weight = 10,
            text = "Thing",
        },
        {
            weight = 10,
            text = "With Two Names",
        },
        {
            weight = 10,
            text = "X",
        },
        {
            weight = 10,
            text = "Xom's @_xom_esteem_@",
        },
        {
            weight = 10,
            text = "Z",
        },
        {
            weight = 10,
            text = "Glorpo",
        },
        {
            weight = 10,
            text = "Loopy",
        },
        {
            weight = 10,
            text = "Plojy",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
