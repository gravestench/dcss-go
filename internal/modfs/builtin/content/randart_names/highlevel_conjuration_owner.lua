-- highlevel conjuration owner is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/randbook.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "highlevel conjuration owner",
    entries = {
        {
            weight = 10,
            text = "Asmodeus",
        },
        {
            weight = 10,
            text = "Ereshkigal",
        },
        {
            weight = 10,
            text = "Dispater",
        },
        {
            weight = 10,
            text = "Cerebov",
        },
        {
            weight = 10,
            text = "Lom Lobon",
        },
        {
            weight = 5,
            text = "Vehumet",
        },
        {
            weight = 20,
            text = "@Conjuration owner@",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
