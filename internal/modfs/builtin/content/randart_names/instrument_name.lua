-- _instrument_name_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/rand_arm.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_instrument_name_",
    entries = {
        {
            weight = 10,
            text = "Chimes",
        },
        {
            weight = 10,
            text = "Pan-Flutes",
        },
        {
            weight = 10,
            text = "Trumpets",
        },
        {
            weight = 10,
            text = "the Accordion",
        },
        {
            weight = 10,
            text = "the Bagpipe",
        },
        {
            weight = 10,
            text = "the Bells",
        },
        {
            weight = 10,
            text = "the Fiddle",
        },
        {
            weight = 10,
            text = "the Fife",
        },
        {
            weight = 10,
            text = "the Flute",
        },
        {
            weight = 10,
            text = "the Gusle",
        },
        {
            weight = 10,
            text = "the Harp",
        },
        {
            weight = 10,
            text = "the Kettle-Drum",
        },
        {
            weight = 10,
            text = "the Lute",
        },
        {
            weight = 10,
            text = "the Trombone",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
