-- weapon appearance is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/randname.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "weapon appearance",
    entries = {
        {
            weight = 10,
            text = "iridescent",
        },
        {
            weight = 10,
            text = "bloodstained",
        },
        {
            weight = 10,
            text = "crystal",
        },
        {
            weight = 10,
            text = "jewelled",
        },
        {
            weight = 10,
            text = "ichor-stained",
        },
        {
            weight = 3,
            text = "ivory",
        },
        {
            weight = 3,
            text = "bone",
        },
        {
            weight = 1,
            text = "sapphire",
        },
        {
            weight = 3,
            text = "ebony",
        },
        {
            weight = 180,
            text = "@general appearance@",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
