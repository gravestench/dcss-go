-- _sky_colour_name_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/rand_all.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_sky_colour_name_",
    entries = {
        {
            weight = 10,
            text = "Black",
        },
        {
            weight = 10,
            text = "Blue",
        },
        {
            weight = 10,
            text = "Grey",
        },
        {
            weight = 10,
            text = "Orange",
        },
        {
            weight = 10,
            text = "Purple",
        },
        {
            weight = 10,
            text = "Red",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
