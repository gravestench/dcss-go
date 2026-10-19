-- armour appearance is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/randname.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "armour appearance",
    entries = {
        {
            weight = 10,
            text = "faintly humming",
        },
        {
            weight = 10,
            text = "bloodstained",
        },
        {
            weight = 10,
            text = "heavily runed",
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
            weight = 10,
            text = "distressingly furry",
        },
        {
            weight = 10,
            text = "spiked",
        },
        {
            weight = 160,
            text = "@general appearance@",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
