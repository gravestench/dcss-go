-- highlevel conjuration earth owner is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/randbook.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "highlevel conjuration earth owner",
    entries = {
        {
            weight = 10,
            text = "Dispater",
        },
        {
            weight = 10,
            text = "@Conjuration Earth owner@",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
