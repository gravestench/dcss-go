-- _fruit_name_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/rand_all.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_fruit_name_",
    entries = {
        {
            weight = 10,
            text = "Orange",
        },
        {
            weight = 10,
            text = "Banana",
        },
        {
            weight = 10,
            text = "Pear",
        },
        {
            weight = 10,
            text = "Apple",
        },
        {
            weight = 10,
            text = "Apricot",
        },
        {
            weight = 10,
            text = "Tomato",
        },
        {
            weight = 10,
            text = "Peach",
        },
        {
            weight = 10,
            text = "Plum",
        },
        {
            weight = 10,
            text = "Rambutan",
        },
        {
            weight = 10,
            text = "Lychee",
        },
        {
            weight = 10,
            text = "Mango",
        },
        {
            weight = 10,
            text = "Watermelon",
        },
        {
            weight = 10,
            text = "Coconut",
        },
        {
            weight = 10,
            text = "Breadfruit",
        },
        {
            weight = 10,
            text = "Eggfruit",
        },
        {
            weight = 10,
            text = "Dragonfruit",
        },
        {
            weight = 10,
            text = "Guava",
        },
        {
            weight = 10,
            text = "Mangosteen",
        },
        {
            weight = 10,
            text = "Tangerine",
        },
        {
            weight = 10,
            text = "Cherry",
        },
        {
            weight = 10,
            text = "Grape",
        },
        {
            weight = 10,
            text = "Sultana",
        },
        {
            weight = 10,
            text = "Fig",
        },
        {
            weight = 10,
            text = "Date",
        },
        {
            weight = 10,
            text = "Lemon",
        },
        {
            weight = 10,
            text = "Lime",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
