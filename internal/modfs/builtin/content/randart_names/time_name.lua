-- _time_name_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/rand_all.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_time_name_",
    entries = {
        {
            weight = 10,
            text = "Autumn",
        },
        {
            weight = 10,
            text = "Dawn",
        },
        {
            weight = 10,
            text = "Day",
        },
        {
            weight = 10,
            text = "Eternal Night",
        },
        {
            weight = 10,
            text = "Eternity",
        },
        {
            weight = 10,
            text = "Midnight",
        },
        {
            weight = 10,
            text = "Midsummer",
        },
        {
            weight = 10,
            text = "Midwinter",
        },
        {
            weight = 10,
            text = "Noon",
        },
        {
            weight = 5,
            text = "Spring",
        },
        {
            weight = 5,
            text = "Springtime",
        },
        {
            weight = 5,
            text = "Summer",
        },
        {
            weight = 5,
            text = "Summertime",
        },
        {
            weight = 10,
            text = "Tomorrow",
        },
        {
            weight = 10,
            text = "Twilight",
        },
        {
            weight = 10,
            text = "Winter",
        },
        {
            weight = 10,
            text = "Yesterday",
        },
        {
            weight = 10,
            text = "the Distant Future",
        },
        {
            weight = 10,
            text = "the Equinox",
        },
        {
            weight = 10,
            text = "the Evening",
        },
        {
            weight = 10,
            text = "the Everdark",
        },
        {
            weight = 10,
            text = "the Harvest",
        },
        {
            weight = 10,
            text = "the Morning",
        },
        {
            weight = 10,
            text = "the Past",
        },
        {
            weight = 10,
            text = "the Present",
        },
        {
            weight = 10,
            text = "the Solstice",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
