-- _the_powerful_caster_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/randbook.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_the_powerful_caster_",
    entries = {
        {
            weight = 10,
            text = "the @_powerful_caster_@",
        },
        {
            weight = 3,
            text = "Boris",
        },
        {
            weight = 1,
            text = "Sif Muna",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
