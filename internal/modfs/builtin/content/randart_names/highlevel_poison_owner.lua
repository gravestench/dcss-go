-- highlevel poison owner is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/randbook.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "highlevel poison owner",
    entries = {
        {
            weight = 10,
            text = "Gloorx Vloq",
        },
        {
            weight = 30,
            text = "@Poison owner@",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
